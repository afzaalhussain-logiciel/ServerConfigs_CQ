# ServerConfigs_CQ

Build configs the CI clones at run time, following the same convention as
`ServerConfigs_QA`: one directory per pipeline, holding the Dockerfile and
everything it `COPY`s, so that directory is the docker build context.

    base-image/
      Dockerfile.base          the shared analysis environment (cq-std-env).
                               Built and pushed by ops; no job builds it.

    codequality/cq-standard/   the code-quality pipeline. Cloned by the Jenkins
                               job, which then builds Dockerfile with this
                               directory as context.

See `codequality/cq-standard/README.md` for the design and the deployment
steps, and `FINDINGS.md` beside it for why each choice was made.

## Pin a tag, never a branch

The code-quality pipeline produces a **gate verdict**, so a run has to be
reproducible: if these scripts can change under a pinned pipeline, last week's
"26 new HIGH" cannot be reproduced and two repos can quietly disagree about
what "analysed" means.

Tag every change here and let the job pass the tag as `CONFIG_REF`. Tracking a
moving branch is what `ServerConfigs_QA` does for image builds, where it is
tolerable; it is not tolerable for a gate.

## Changing a script

The analysis behaviour lives here, not in the Jenkins library - the library
only orchestrates. So a change to `stages.sh` or `analyze.sh` changes what
every repo's gate reports. Re-run both reference repos on their pass and fail
refs before tagging, and check the gate numbers against the previous tag.
