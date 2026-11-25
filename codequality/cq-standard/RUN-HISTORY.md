# CI run history

Status and gate summary for every Jenkins build of the code-quality jobs, taken
from `$JENKINS_HOME/jobs/*/builds/*/` before the archived artefacts were deleted
to reclaim disk. `build.xml` and the console logs stay on the controller, so the
builds are still listed and still have their output; only `archive/` is gone.

Three generations of gate output are represented - the monolithic design's
one-line `GATE ... net-new CRITICAL/HIGH`, the split design's `SPLIT GATE` block
and the combined design's `CODE QUALITY GATE` block. An empty gate row is a
build that never reached the gate: a base-image build, or a failure before it.

187 builds across 17 jobs; 98 carry a gate verdict.

## codequality-demo-ai-fix

2 builds, no gate stage. Results: SUCCESS 2. Builds 1-2, 2026-09-14 15:34 to 2026-09-14 15:39.

## codequality-demo-cq

30 builds, no gate stage. Results: FAILURE 8, SUCCESS 21, UNSTABLE 1. Builds 30-59, 2026-09-10 14:46 to 2026-09-15 09:53.

## codequality-demo-gate

2 builds, no gate stage. Results: FAILURE 1, SUCCESS 1. Builds 1-2, 2026-09-14 21:29 to 2026-09-14 21:30.

## fixhub-ee-combined-cq

| # | when | result | min | target vs baseline | profile | refresh | cfg | new HIGH | new-cov | overall | gate |
|---:|---|---|---:|---|---|---|---|---:|---:|---:|---|
| 1 | 2026-11-24 20:47 | FAILURE | 4.9 | cq-std / cq-std | cpp-cmake | false |  |  |  |  |  |
| 2 | 2026-11-24 20:57 | ABORTED | 4.8 | cq-std / cq-std | cpp-cmake | false |  |  |  |  |  |
| 3 | 2026-11-24 21:02 | ABORTED | 6.2 | cq-std / cq-std | cpp-cmake-targets | false |  |  |  |  |  |
| 4 | 2026-11-24 21:15 | SUCCESS | 33.7 | cq-fail / cq-std | cpp-cmake-targets | false |  | 19 | unmeasured | unmeasured | FAIL |
| 5 | 2026-11-25 08:12 | SUCCESS | 18.6 | cq-fail / cq-std | cpp-cmake-targets | false |  | 20 | 0 | 13.13 | FAIL |
| 6 | 2026-11-25 08:32 | SUCCESS | 18.0 | cq-pass / cq-std | cpp-cmake-targets | false |  | 3 | 100 | 14.19 | FAIL |
| 7 | 2026-11-25 10:29 | ABORTED | 15.0 | cq-fail / cq-std | cpp-cmake-targets | false |  |  |  |  |  |
| 8 | 2026-11-25 10:44 | SUCCESS | 18.5 | cq-pass / cq-std | cpp-cmake-targets | false |  | 0 | 100 | 14.19 | PASS |
| 9 | 2026-11-25 12:02 | SUCCESS | 33.7 | cq-fail / cq-std-refresh | cpp-cmake-targets | true |  | 17 | 0 | 13.13 | FAIL |

## fixhub-qc-docker

| # | when | result | min | target vs baseline | profile | refresh | cfg | new HIGH | new-cov | overall | gate |
|---:|---|---|---:|---|---|---|---|---:|---:|---:|---|
| 1 | 2026-11-03 16:32 | FAILURE | 0.0 | fixhub-ee / main |  |  |  |  |  |  |  |
| 2 | 2026-11-03 16:33 | SUCCESS | 0.1 | fixhub-ee / main |  |  |  |  |  |  |  |
| 3 | 2026-11-03 17:54 | SUCCESS | 26.4 | sanitizer-defects / fixhub-ee |  |  |  |  |  |  |  |
| 4 | 2026-11-03 18:35 | FAILURE | 0.5 | sanitizer-defects / fixhub-ee |  |  |  |  | erage | erage | FAIL |
| 5 | 2026-11-03 18:39 | ABORTED | 2.6 | sanitizer-defects / fixhub-ee |  |  |  |  |  |  |  |
| 6 | 2026-11-03 18:42 | FAILURE | 44.2 | sanitizer-defects / fixhub-ee |  |  |  |  |  |  |  |
| 7 | 2026-11-03 19:29 | SUCCESS | 26.9 | sanitizer-defects / fixhub-ee |  |  |  |  | erage | erage | FAIL |
| 8 | 2026-11-17 19:04 | FAILURE | 0.2 | cq-pass-v1.0.0 / fixhub-ee |  |  |  |  |  |  |  |
| 9 | 2026-11-17 19:06 | ABORTED | 12.6 | cq-pass-v1.0.0 / fixhub-ee |  |  |  |  |  |  |  |
| 10 | 2026-11-17 19:19 | SUCCESS | 31.1 | cq-pass-v1.0.0 / fixhub-ee |  |  |  |  | erage | erage | PASS |
| 11 | 2026-11-17 19:51 | SUCCESS | 30.5 | cq-fail-v1.0.0 / fixhub-ee |  |  |  |  | erage | erage | FAIL |
| 12 | 2026-11-17 22:11 | ABORTED | 0.4 | cq-pass-v1.0.0 / fixhub-ee |  |  |  |  |  |  |  |
| 13 | 2026-11-17 22:12 | SUCCESS | 33.3 | cq-pass-v1.0.0 / fixhub-ee |  |  |  |  | erage | erage | PASS |
| 14 | 2026-11-17 22:45 | SUCCESS | 20.6 | cq-fail-v1.0.0 / fixhub-ee |  |  |  |  | erage | erage | FAIL |

## fixhub-vc14-cq

3 builds, no gate stage. Results: ABORTED 1, SUCCESS 2. Builds 1-3, 2026-09-14 19:38 to 2026-09-14 21:54.

## fixhub-vc14-qc-docker

| # | when | result | min | target vs baseline | profile | refresh | cfg | new HIGH | new-cov | overall | gate |
|---:|---|---|---:|---|---|---|---|---:|---:|---:|---|
| 1 | 2026-09-17 00:29 | FAILURE | 0.0 | FIXEngine-V5.1.12.0 / linuxWin_2.0 |  |  |  |  |  |  |  |
| 2 | 2026-09-17 00:29 | SUCCESS | 20.1 | FIXEngine-V5.1.12.0 / linuxWin_2.0 |  |  |  |  | erage | erage | PASS |
| 3 | 2026-09-17 00:53 | FAILURE | 34.5 | FIXEngine-V5.1.12.0 / linuxWin_2.0 |  |  |  |  |  |  |  |
| 4 | 2026-09-17 01:35 | FAILURE | 0.0 | FIXEngine-V5.1.12.0 / linuxWin_2.0 |  |  |  |  |  |  |  |
| 5 | 2026-09-17 01:35 | SUCCESS | 19.9 | FIXEngine-V5.1.12.0 / linuxWin_2.0 |  |  |  |  | erage | erage | PASS |
| 6 | 2026-09-17 11:42 | FAILURE | 0.2 | FIXEngine-V5.1.12.0 / linuxWin_2.0 |  |  |  |  |  |  |  |
| 7 | 2026-09-17 11:47 | SUCCESS | 19.7 | FIXEngine-V5.1.12.0 / linuxWin_2.0 |  |  |  |  | erage | erage | PASS |
| 8 | 2026-09-17 12:11 | SUCCESS | 19.9 | FIXEngine-V5.1.12.0 / linuxWin_2.0 |  |  |  |  | erage | erage | PASS |
| 9 | 2026-09-17 12:46 | SUCCESS | 10.0 | FIXEngine-V5.1.12.0 / linuxWin_2.0 |  |  |  |  | erage | erage | PASS |
| 10 | 2026-09-17 12:49 | FAILURE | 0.1 | FIXEngine-V5.1.12.1 / linuxWin_2.0 |  |  |  |  |  |  |  |
| 11 | 2026-09-17 13:03 | SUCCESS | 5.6 | FIXEngine-V5.1.12.0 / linuxWin_2.0 |  |  |  |  | erage | erage | PASS |
| 12 | 2026-09-17 13:15 | SUCCESS | 5.1 | FIXEngine-V5.1.12.0 / linuxWin_2.0 |  |  |  |  | erage | erage | PASS |
| 13 | 2026-09-17 13:23 | SUCCESS | 5.2 | FIXEngine-V5.1.12.0 / linuxWin_2.0 |  |  |  |  | erage | erage | PASS |
| 14 | 2026-09-22 14:02 | FAILURE | 0.2 | V5.1.12.0 / linuxWin_2.0 |  |  |  |  |  |  |  |
| 15 | 2026-09-22 14:04 | SUCCESS | 9.8 | V5.1.12.0 / linuxWin_2.0 |  |  |  |  | erage | erage | PASS |
| 16 | 2026-11-02 18:20 | FAILURE | 0.3 | FIXEngine-V5.1.12.0 / linuxWin_2.0 |  |  |  |  |  |  |  |
| 17 | 2026-11-02 18:22 | FAILURE | 20.6 | FIXEngine-V5.1.12.0 / linuxWin_2.0 |  |  |  |  |  |  |  |
| 18 | 2026-11-02 18:44 | ABORTED | 0.4 | V5.1.12.0 / linuxWin_2.0 |  |  |  |  |  |  |  |
| 19 | 2026-11-02 18:45 | ABORTED | 14.0 | CAT-12346-pass / linuxWin_2.0 |  |  |  |  |  |  |  |
| 20 | 2026-11-02 20:10 | FAILURE | 27.0 | CAT-12346-pass / linuxWin_2.0 |  |  |  |  |  |  |  |
| 21 | 2026-11-17 20:23 | FAILURE | 0.0 | cq-pass-v1.0.0 / linuxWin_2.0 |  |  |  |  |  |  |  |
| 22 | 2026-11-17 20:24 | SUCCESS | 31.6 | cq-pass-v1.0.0 / linuxWin_2.0 |  |  |  |  | erage | erage | PASS |
| 23 | 2026-11-17 21:13 | FAILURE | 51.7 | cq-pass-v1.0.0 / linuxWin_2.0 |  |  |  |  | erage | erage | FAIL |
| 24 | 2026-11-17 22:07 | FAILURE | 1.2 | cq-pass-v1.0.0 / linuxWin_2.0 |  |  |  |  |  |  |  |
| 25 | 2026-11-17 22:52 | ABORTED | 0.6 | cq-pass-v1.0.0 / linuxWin_2.0 |  |  |  |  |  |  |  |
| 26 | 2026-11-17 23:07 | SUCCESS | 26.9 | cq-pass-v1.0.0 / linuxWin_2.0 |  |  |  |  | erage | erage | FAIL |
| 27 | 2026-11-17 23:54 | SUCCESS | 16.2 | cq-fail-v1.0.0 / linuxWin_2.0 |  |  |  |  | erage | erage | FAIL |

## muxerxpress-combined-cq

| # | when | result | min | target vs baseline | profile | refresh | cfg | new HIGH | new-cov | overall | gate |
|---:|---|---|---:|---|---|---|---|---:|---:|---:|---|
| 1 | 2026-11-24 14:05 | FAILURE | 0.1 | cq-fail-combined / cq-std-combined | cpp-cmake | false |  |  |  |  |  |
| 2 | 2026-11-24 14:06 | FAILURE | 1.6 | cq-fail-combined / cq-std-combined | cpp-cmake | false |  |  |  |  |  |
| 3 | 2026-11-24 14:08 | FAILURE | 2.3 | cq-fail-combined / cq-std-combined | cpp-cmake | false |  |  |  |  |  |
| 4 | 2026-11-24 14:13 | FAILURE | 1.5 | cq-fail-combined / cq-std-combined | cpp-cmake | false |  |  |  |  |  |
| 5 | 2026-11-24 14:16 | FAILURE | 2.6 | cq-fail-combined / cq-std-combined | cpp-cmake | false |  | 25 | 40 | 36.96 | FAIL |
| 6 | 2026-11-24 14:22 | SUCCESS | 1.5 | cq-fail-combined / cq-std-combined | cpp-cmake | false |  | 25 | 40 | 36.96 | FAIL |
| 7 | 2026-11-24 14:27 | SUCCESS | 1.5 | cq-pass-combined / cq-std-combined | cpp-cmake | false |  | 0 | 100 | 37.32 | PASS |
| 8 | 2026-11-24 14:29 | SUCCESS | 1.6 | cq-fail-combined / cq-std-combined | cpp-cmake | false |  | 25 | 40 | 36.96 | FAIL |
| 9 | 2026-11-24 14:35 | SUCCESS | 2.8 | cq-fail-combined / cq-std-combined | cpp-cmake-targets | true |  | 0 | 40 | 36.96 | FAIL |
| 10 | 2026-11-24 14:40 | SUCCESS | 2.7 | cq-fail-combined / cq-std-combined | cpp-cmake-targets | true |  | 25 | 40 | 36.96 | FAIL |
| 11 | 2026-11-24 18:19 | SUCCESS | 2.5 | cq-fail-combined / cq-std-combined | cpp-cmake | true |  | 29 | 40 | 36.96 | FAIL |
| 12 | 2026-11-24 18:22 | SUCCESS | 1.6 | cq-pass-combined / cq-std-combined | cpp-cmake | false |  | 0 | 100 | 37.32 | PASS |
| 13 | 2026-11-24 18:24 | SUCCESS | 2.8 | cq-fail-combined / cq-std-combined | cpp-cmake-targets | true |  | 29 | 40 | 36.96 | FAIL |
| 14 | 2026-11-24 18:27 | SUCCESS | 1.6 | cq-pass-combined / cq-std-combined | cpp-cmake-targets | false |  | 0 | 100 | 37.32 | PASS |
| 15 | 2026-11-24 19:25 | SUCCESS | 1.8 | cq-fail-combined / cq-std-combined | cpp-cmake | false |  | 29 | 40 | 36.96 | FAIL |
| 16 | 2026-11-25 11:15 | ABORTED | 1.9 | cq-fail / cq-std-combined | cpp-cmake | false |  | 29 | 40 | 36.96 | FAIL |
| 17 | 2026-11-25 11:18 | SUCCESS | 1.8 | cq-fail-combined / cq-std-combined | cpp-cmake | false |  | 29 | 40 | 36.96 | FAIL |
| 18 | 2026-11-25 11:20 | SUCCESS | 1.9 | cq-pass-combined / cq-std-combined | cpp-cmake | false |  | 0 | 100 | 37.32 | PASS |
| 19 | 2026-11-25 11:33 | SUCCESS | 2.7 | cq-fail-combined / cq-std-refresh | cpp-cmake | true |  | 29 | 40 | 36.96 | FAIL |
| 20 | 2026-11-25 11:52 | SUCCESS | 1.6 | cq-fail-combined / cq-std-combined | cpp-cmake-targets | false |  | 29 | 40 | 36.96 | FAIL |
| 21 | 2026-11-25 11:54 | SUCCESS | 1.9 | cq-fail-combined / cq-std-combined | cpp-cmake | false |  | 29 | 40 | 36.96 | FAIL |
| 22 | 2026-11-25 11:56 | SUCCESS | 1.8 | cq-pass-combined / cq-std-combined | cpp-cmake | false |  | 0 | 100 | 37.32 | PASS |

## muxerxpress-split-cq

| # | when | result | min | target vs baseline | profile | refresh | cfg | new HIGH | new-cov | overall | gate |
|---:|---|---|---:|---|---|---|---|---:|---:|---:|---|
| 1 | 2026-11-23 21:47 | FAILURE | 0.0 |  |  |  |  |  |  |  |  |
| 2 | 2026-11-23 21:47 | FAILURE | 0.1 | cq-fail-v1 / cq-std |  | false |  |  |  |  |  |
| 3 | 2026-11-23 21:49 | FAILURE | 0.1 | cq-fail-v1 / cq-std |  | false |  |  |  |  |  |
| 4 | 2026-11-23 21:50 | FAILURE | 0.2 | cq-fail-v1 / cq-std |  | false |  |  |  |  |  |
| 5 | 2026-11-23 21:51 | SUCCESS | 3.4 | cq-fail-v1 / cq-std |  | false |  | 8 |  | 36.87 | FAIL |
| 6 | 2026-11-23 21:59 | SUCCESS | 4.3 | cq-fail-v1 / cq-std |  | false |  | 8 | 40 | 36.87 | FAIL |
| 7 | 2026-11-23 21:59 | SUCCESS | 4.2 | cq-pass-v1 / cq-std |  | false |  | 0 | 100 | 37.32 | PASS |
| 8 | 2026-11-23 22:09 | SUCCESS | 2.0 | cq-pass-v1 / cq-std |  | false |  | 0 | 100 | 37.32 | PASS |
| 9 | 2026-11-23 22:12 | SUCCESS | 3.5 | cq-pass-v1 / cq-std |  | true |  | 0 | 100 | 37.32 | PASS |
| 10 | 2026-11-23 23:06 | SUCCESS | 2.0 | cq-pass-v1 / cq-std |  | false |  | 0 | 100 | 37.32 | PASS |
| 11 | 2026-11-23 23:09 | SUCCESS | 3.4 | cq-pass-v1 / cq-std |  | true |  | 0 | 100 | 37.32 | PASS |
| 12 | 2026-11-23 23:13 | SUCCESS | 3.4 | cq-pass-v1 / cq-std |  | false |  | 0 | 100 | 37.32 | PASS |
| 13 | 2026-11-23 23:17 | SUCCESS | 3.5 | cq-pass-v1 / cq-std | cpp-cmake | false |  | 0 | 100 | 37.32 | PASS |
| 14 | 2026-11-23 23:21 | SUCCESS | 3.8 | cq-pass-v1 / cq-std | cpp-cmake-targets | false |  | 0 | unmeasured | 37.32 | FAIL |
| 15 | 2026-11-23 23:29 | SUCCESS | 3.5 | cq-pass-v1 / cq-std | cpp-cmake | false |  | 0 | 100 | 37.32 | PASS |
| 16 | 2026-11-23 23:33 | SUCCESS | 3.3 | cq-pass-v1 / cq-std | cpp-cmake-targets | false |  | 0 | 100 | 37.32 | PASS |
| 17 | 2026-11-23 23:36 | SUCCESS | 4.0 | cq-fail-v1 / cq-std | cpp-cmake | false |  | 8 | 40 | 36.87 | FAIL |
| 18 | 2026-11-23 23:41 | SUCCESS | 4.3 | cq-fail-v1 / cq-std | cpp-cmake-targets | false |  | 8 | 40 | 36.87 | FAIL |
| 19 | 2026-11-23 23:57 | SUCCESS | 5.0 | cq-fail-v1 / cq-std | cpp-cmake | false |  | 20 | 22 | 36.45 | FAIL |
| 20 | 2026-11-24 00:02 | SUCCESS | 4.8 | cq-fail-v1 / cq-std | cpp-cmake-targets | false |  | 20 | 22 | 36.45 | FAIL |
| 21 | 2026-11-24 00:07 | SUCCESS | 4.5 | cq-pass-v1 / cq-std | cpp-cmake | false |  | 0 | 100 | 37.32 | PASS |
| 22 | 2026-11-24 00:12 | SUCCESS | 4.5 | cq-pass-v1 / cq-std | cpp-cmake-targets | false |  | 0 | 100 | 37.32 | PASS |
| 23 | 2026-11-24 08:20 | SUCCESS | 4.0 | cq-fail-v1 / cq-std | cpp-cmake | false |  | 25 | 66 | 37.59 | FAIL |
| 24 | 2026-11-24 08:25 | SUCCESS | 3.6 | cq-fail-v1 / cq-std | cpp-cmake-targets | false |  | 25 | 66 | 37.59 | FAIL |
| 25 | 2026-11-24 08:29 | SUCCESS | 3.3 | cq-pass-v1 / cq-std | cpp-cmake | false |  | 0 | 100 | 37.32 | PASS |
| 26 | 2026-11-24 08:32 | SUCCESS | 3.5 | cq-pass-v1 / cq-std | cpp-cmake-targets | false |  | 0 | 100 | 37.32 | PASS |

## muxerxpress-std-cq

| # | when | result | min | target vs baseline | profile | refresh | cfg | new HIGH | new-cov | overall | gate |
|---:|---|---|---:|---|---|---|---|---:|---:|---:|---|
| 1 | 2026-11-23 13:57 | FAILURE | 0.4 | cq-std /  |  |  |  |  |  |  |  |
| 2 | 2026-11-23 14:24 | SUCCESS | 2.3 | cq-std / main |  |  |  | 0 | unmeasured | 0% | FAIL |
| 3 | 2026-11-23 14:39 | SUCCESS | 1.8 | cq-std / main |  |  |  | 0 | nolines | 37.0 | FAIL |
| 4 | 2026-11-23 15:19 | SUCCESS | 56.2 | cq-pass-v1 / cq-std |  |  |  | 0 | 100 | 37.32 | PASS |
| 5 | 2026-11-23 15:19 | SUCCESS | 34.7 | cq-fail-v1 / cq-std |  |  |  | 6 | 14 | 36.59 | FAIL |
| 6 | 2026-11-23 18:10 | SUCCESS | 2.0 | cq-pass-v1 / cq-std |  |  |  | 0 | 100 | 37.32 | PASS |
| 7 | 2026-11-23 18:55 | SUCCESS | 10.5 | cq-pass-v1 / cq-std |  |  |  | 0 | 100 | 37.32 | PASS |
| 8 | 2026-11-23 19:13 | SUCCESS | 2.5 | cq-pass-v1 / cq-std |  |  |  | 0 | 100 | 37.32 | PASS |
| 9 | 2026-11-23 19:52 | SUCCESS | 2.6 | cq-fail-v1 / cq-std |  |  |  | 8 | 40 | 36.87 | FAIL |
| 10 | 2026-11-23 20:15 | ABORTED | 0.1 | cq-fail-v1 / cq-std |  |  |  | 8 | 40 | 36.87 | FAIL |
| 11 | 2026-11-23 20:15 | SUCCESS | 2.8 | cq-fail-v1 / cq-std |  | false |  | 8 | 40 | 36.87 | FAIL |

## muxerxpress-std-cq-targets

| # | when | result | min | target vs baseline | profile | refresh | cfg | new HIGH | new-cov | overall | gate |
|---:|---|---|---:|---|---|---|---|---:|---:|---:|---|
| 1 | 2026-11-23 18:08 | FAILURE | 0.0 | cq-pass-v1 / cq-std |  |  |  |  |  |  |  |
| 2 | 2026-11-23 18:08 | FAILURE | 0.0 | cq-fail-v1 / cq-std |  |  |  |  |  |  |  |
| 3 | 2026-11-23 18:12 | SUCCESS | 3.8 | cq-pass-v1 / cq-std |  |  |  | 0 | 100 | 37.32 | PASS |
| 4 | 2026-11-23 18:12 | SUCCESS | 7.2 | cq-fail-v1 / cq-std |  |  |  | 6 | 14 | 36.59 | FAIL |
| 5 | 2026-11-23 18:55 | ABORTED | 7.6 | cq-fail-v1 / cq-std | cpp-cmake-targets |  |  | 6 | 14 | 36.59 | FAIL |
| 6 | 2026-11-23 19:04 | SUCCESS | 1.8 | cq-pass-v1 / cq-std | cpp-cmake-targets |  |  | 0 | 100 | 42.4 | PASS |
| 7 | 2026-11-23 19:13 | SUCCESS | 2.4 | cq-pass-v1 / cq-std | cpp-cmake-targets |  |  | 0 | 100 | 37.32 | PASS |
| 8 | 2026-11-23 19:52 | SUCCESS | 2.5 | cq-fail-v1 / cq-std | cpp-cmake-targets |  |  | 8 | 40 | 36.87 | FAIL |

## vantage-combined-cq

| # | when | result | min | target vs baseline | profile | refresh | cfg | new HIGH | new-cov | overall | gate |
|---:|---|---|---:|---|---|---|---|---:|---:|---:|---|
| 1 | 2026-11-24 14:45 | SUCCESS | 57.7 | cq-fail-v1 / cq-std | cpp-cmake | false |  | 26 | 35 | 55.15 | FAIL |
| 2 | 2026-11-24 16:40 | SUCCESS | 30.0 | cq-fail-v1 / cq-std | cpp-cmake | true |  | 26 | 35 | 53.38 | FAIL |
| 3 | 2026-11-24 18:29 | SUCCESS | 30.6 | cq-fail-v1 / cq-std | cpp-cmake | true |  | 29 | 35 | 53.39 | FAIL |
| 4 | 2026-11-24 19:00 | SUCCESS | 17.1 | cq-pass-v1 / cq-std | cpp-cmake | false |  | 0 | 100 | 53.54 | PASS |
| 5 | 2026-11-24 19:37 | SUCCESS | 17.3 | cq-fail-v1 / cq-std | cpp-cmake | false |  | 29 | 35 | 53.39 | FAIL |
| 6 | 2026-11-25 12:41 | SUCCESS | 27.7 | cq-fail-v2 / cq-std-refresh | cpp-cmake | true |  | 29 | 35 | 53.39 | FAIL |

## vantage-cq

3 builds, no gate stage. Results: SUCCESS 2, UNSTABLE 1. Builds 4-6, 2026-09-11 21:40 to 2026-09-14 21:33.

## vantage-split-cq

| # | when | result | min | target vs baseline | profile | refresh | cfg | new HIGH | new-cov | overall | gate |
|---:|---|---|---:|---|---|---|---|---:|---:|---:|---|
| 1 | 2026-11-24 00:17 | FAILURE | 41.4 | cq-fail-v1 / cq-std | cpp-cmake | false |  |  |  |  |  |
| 2 | 2026-11-24 00:59 | FAILURE | 440.9 | cq-fail-v1 / cq-std | cpp-cmake-targets | false |  |  |  |  |  |
| 3 | 2026-11-24 08:36 | SUCCESS | 56.9 | cq-fail-v1 / cq-std | cpp-cmake | false |  | 26 | 64 | 53.52 | FAIL |
| 4 | 2026-11-24 10:11 | ABORTED | 20.5 | cq-fail-v1 / cq-std | cpp-cmake | false |  |  |  |  |  |
| 5 | 2026-11-24 10:31 | ABORTED | 3.0 | cq-fail-v1 / cq-std | cpp-cmake-targets | false |  |  |  |  |  |
| 6 | 2026-11-24 10:37 | SUCCESS | 65.2 | cq-fail-v1 / cq-std | cpp-cmake | false |  | 26 | 64 | 53.53 | FAIL |
| 7 | 2026-11-24 11:45 | SUCCESS | 68.4 | cq-pass-v1 / cq-std | cpp-cmake | false |  | 0 | 100 | 53.54 | PASS |

## vantage-std-cq

| # | when | result | min | target vs baseline | profile | refresh | cfg | new HIGH | new-cov | overall | gate |
|---:|---|---|---:|---|---|---|---|---:|---:|---:|---|
| 1 | 2026-11-20 20:32 | FAILURE | 0.2 |  |  |  |  |  |  |  |  |
| 2 | 2026-11-20 20:32 | FAILURE | 0.4 | cq-std /  |  |  |  |  |  |  |  |
| 3 | 2026-11-20 20:34 | SUCCESS | 82.8 | cq-std / main |  |  |  |  |  |  | FAIL |
| 4 | 2026-11-20 21:59 | ABORTED | 7.7 | cq-std / main |  |  |  |  |  |  | FAIL |
| 5 | 2026-11-20 22:07 | FAILURE | 8.9 | cq-std / main |  |  |  |  |  |  | FAIL |
| 6 | 2026-11-20 22:18 | FAILURE | 8.9 | cq-std / main |  |  |  |  |  |  | FAIL |
| 7 | 2026-11-20 22:30 | SUCCESS | 39.8 | cq-std / main |  |  |  |  |  |  | FAIL |
| 8 | 2026-11-20 23:12 | SUCCESS | 34.9 | cq-std / main |  |  |  | 1 | 55 | 53.5% | FAIL |
| 9 | 2026-11-23 15:04 | SUCCESS | 46.4 | cq-std / main |  |  |  | 0 | 55 | 53.49 | FAIL |
| 10 | 2026-11-23 15:19 | SUCCESS | 53.1 | cq-pass-v1 / cq-std |  |  |  | 0 | 100 | 53.52 | FAIL |
| 11 | 2026-11-23 15:19 | SUCCESS | 69.8 | cq-fail-v1 / cq-std |  |  |  | 7 | 17 | 53.45 | FAIL |

## vantage-std-cq-targets

4 builds, no gate stage. Results: ABORTED 2, FAILURE 2. Builds 1-4, 2026-11-23 18:08 to 2026-11-23 18:12.

## zz-gate-stage-test

2 builds, no gate stage. Results: FAILURE 1, SUCCESS 1. Builds 1-2, 2026-09-14 18:00 to 2026-09-14 18:01.

