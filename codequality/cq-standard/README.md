# Code-quality CI: one image, three build passes

One Docker image, three build passes, both refs in the same image. An earlier
layout used five build trees per image and a second image for the baseline; the
numbers below compare against it where that is the useful reference.

    step 1  docker build        cq_analyse_memory, cq_measure_coverage,
                                cq_build_thread - for the target, and for the
                                baseline when the server has no run for it
    step 2  docker run          cq_run_thread: executes TSan, both refs
    step 3  docker run          analyze.sh: store, diff, gate

## The three passes

| pass | flags | produces | tree |
|---|---|---|---|
| `cq_analyse_memory` | `-fsanitize=address,undefined` + compile DB | clangsa, cppcheck, asan, lsan, ubsan | deleted |
| `cq_measure_coverage` | `-g -O0 -fno-inline --coverage` | cobertura, diff-cover | deleted |
| `cq_build_thread` | `-fsanitize=thread` | nothing yet - built only | kept, pruned |

Three is the floor. `address,undefined` is a supported pair, so one compile
serves both plus the compile DB; `address,thread` is rejected by the compiler;
coverage needs `-O0 -fno-inline`, and a sanitizer abort destroys `.gcda`.

A sanitized compile DB gives static analysis the same findings as a plain one -
measured 13 vs 13, same checker, file and line - which is what lets the memory
pass carry `-DCMAKE_EXPORT_COMPILE_COMMANDS=ON` instead of a fourth tree.

## Why the trees are deleted where they are

`rm -rf` only shrinks an image if it runs in the **same** `RUN` layer that
created the files. Deleting in a later layer leaves the bytes in the earlier
one. Both deleted passes therefore build, report and delete inside one layer.

The thread tree survives because TSan cannot execute during `docker build`: it
calls `personality(ADDR_NO_RANDOMIZE)`, which Docker's default seccomp profile
blocks. Step 2 runs it under `--security-opt seccomp=unconfined` with
`setarch -R` (measured 10/10 starts with, 0-2/10 without). Its objects are
pruned because nothing later needs them - ctest runs the executables and
`cq_sanitize` is an `add_custom_target`, so it relinks nothing. Measured
814MB -> ~200MB.

Footprint, vantage, both refs in one image: 4.66GB against a 3.27GB base, so
1.39GB of run data. The five-tree layout cost 10.1GB per image, two per run.

See [FINDINGS.md](FINDINGS.md) for the measurements behind every choice here,
and for the known limitations.

---

# Deploying on a Jenkins controller

## Prerequisites

**On the Jenkins agent that will run the job**

| requirement | why |
|---|---|
| Docker with BuildKit | the build uses `RUN --mount=type=ssh` and heredoc `RUN` |
| `docker run --security-opt seccomp=unconfined` permitted | TSan calls `personality(ADDR_NO_RANDOMIZE)`, blocked by the default profile |
| disk for one image per run | measured 1.4GB of run data above the base image, plus the base itself |
| cores | compile is the whole cost; `JOBS` defaults to `nproc` |

The agent needs **no** compiler, CodeChecker or analyser install. Everything
runs inside the image, including the baseline probe, which answers from a
throwaway container built on the base image.

**On the Jenkins controller**

`python3` with `pyyaml`. The `cq.yaml` parse uses Groovy's `.execute()`, which
runs in the controller's JVM rather than on the agent, and reads the file by
workspace path.

> **This currently pins the job to a node that shares the controller's
> filesystem** - the built-in node, or an agent on the same host. On a remote
> agent the controller cannot see `${WORKSPACE}/.cqcfg/cq.yaml` and the parse
> fails. Converting `yamlToJson` to a `sh`-based step removes the constraint;
> until then, deploy accordingly. Verified only on a single-node controller.

**Jenkins plugins**

- `pipeline-groovy-lib` - loads this shared library
- `credentials-binding`, `ssh-credentials` - `withCredentials`
- `warnings-ng` - `recordIssues` with the `codeChecker` tool
- `coverage` - `recordCoverage` for the Cobertura reports

The `junit` step is deliberately **not** used, so the JUnit plugin is optional.
`ctest-junit.xml` is still archived as an artifact.

## 1. Build and publish the base image

```bash
cd resources/cq
docker build -f Dockerfile.base -t cq-std-env:1.0.0 .
```

It carries two layers with different owners: the repos' build dependencies
(team-owned) and the analysis toolchain - CodeChecker, cppcheck, clang-sa,
gcovr, diff-cover, report-converter (platform-owned). The platform layer is the
one that must never differ between repos; push the image to your registry and
reference that tag, so no agent builds its own.

Each repo names the tag it wants in `cq.yaml` as `base_image`.

## 2. Run a CodeChecker server

```bash
CodeChecker server --workspace /var/lib/codechecker --port 8002 --host 0.0.0.0
```

Create one product per repo, up front - the pipeline does not create them:

```bash
CodeChecker cmd products add --url localhost:8002 \
    -n my-repo --description "my-repo: static analysis, sanitizers, coverage" \
    my_repo
```

The last argument is the product endpoint used in the URL; with SQLite it is
also the database file name, and it must be a **relative** name.

The pipeline reaches the server from inside containers as
`http://host.docker.internal:8002` by default, which is a Docker Desktop
convenience. The containers that talk to the server run with `--network=host`,
so on a real controller point this at the server's own hostname instead:

```groovy
codeQualityCombinedPipeline(repo_url: '...', cc_url: 'http://codechecker.internal:8002')
```

## 3. Add the credentials

Two, with these exact IDs unless you override them:

| ID | kind | used for |
|---|---|---|
| `cq-git-ssh` | SSH private key | cloning the repo, and submodules inside the image via `--mount=type=ssh` |
| `codechecker-store` | username + password | `CodeChecker store` and `cmd diff` |

The git ID is overridable per job (`git_credentials_id:`); the CodeChecker one
is fixed. The key needs read access to the repo and its submodules only.

Credentials never reach the image as build args. The CodeChecker ones are
written to a `.cc_pass.json` in the workspace under `umask 077`, bind-mounted
read-only at `/run/secrets/cc_pass.json`, and the SSH key is forwarded by the
BuildKit ssh agent rather than copied into a layer.

## 4. Register the shared library

Manage Jenkins -> System -> Global Trusted Pipeline Libraries:

- **Name** `cq`
- **Default version** a tag, not a branch - a branch means every job silently
  follows the next commit
- **Retrieval** Modern SCM -> Git -> this repository
- Leave *Load implicitly* off; jobs request the library explicitly

A local filesystem path works for trials, but needs
`-Dhudson.plugins.git.GitSCM.ALLOW_LOCAL_CHECKOUT=true` on the controller.

## 5. Create the job

A pipeline job whose definition is just:

```groovy
@Library('cq@v1.0') _
codeQualityCombinedPipeline(
    repo_url: 'git@github.com:org/my-repo.git',
    product:  'my-repo'          // optional; defaults to cq.yaml's product
)
```

The job's parameters are declared by the pipeline itself, so the first build
seeds them - run it once, then use *Build with Parameters*:

| parameter | effect |
|---|---|
| `TARGET_REF` | required; branch or tag to analyse |
| `BASELINE_REF` | defaults to `cq.yaml`'s `baseline` |
| `JOBS` | parallel compile jobs; defaults to `nproc` |
| `PROFILE` | empty uses `cq.yaml`; `cpp-cmake-targets` builds the repo's `cq_*` targets |
| `REFRESH_BASELINE` | re-analyse the baseline even if the server has it |

## 6. What the repo must provide

`cq.yaml` at the repo root is the entire per-repo footprint. Required:

```yaml
product:    my-repo              # CodeChecker product endpoint
base_image: cq-std-env:1.0.0     # the image from step 1
```

Everything else is optional and defaults sensibly: `baseline`, `profile`,
`skipfile`, `analyzers`, `configure_flags`, `sanitizer_flags`,
`coverage_exclude`, `test_exclude`, `prepare`, `thresholds`.

The build contract is that `cmake` configures with `configure_flags` and
produces `compile_commands.json`, and that `ctest` runs the tests. The
`cpp-cmake-targets` profile instead requires `cmake/CodeChecker.cmake` in the
repo exposing `cq_analyze`, `cq_sanitize`, `cq_coverage` and
`cq_coverage_diff`.

Thresholds in `cq.yaml` may only be **tightened**. The config is read from
`TARGET_REF`, so a branch could otherwise raise its own ceiling; the pipeline
clamps `max_new_high` to 0 and `min_diff_cov` to a floor of 50 and says so in
the log.

## 7. First run

Expect the first build on a new product to analyse both refs, because the
server has no baseline yet - the log says
`baseline <ref> missing - it will be analysed`. Later builds reuse the stored
baseline unless the ref changes or `REFRESH_BASELINE` is set.

The verdict lands in three places: the build's display name
(`#12 PASS my-ref`), its description, and `qc-out/gate/summary.txt` in the
artifacts. **A failed gate never fails the build** - a red run means the
pipeline itself broke.
