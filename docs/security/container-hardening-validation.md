# Container Hardening Validation



## 1. Overview



This document records the security validation performed on the `depi-worker:dev` Docker image.



- **Image:** `depi-worker:dev`

- **Base image:** `python:3.12-slim-trixie`

- **Base image pinning:** SHA-256 digest



The base image is pinned by digest to ensure reproducible builds.



## 2. Docker Build Validation



**Command:**



```powershell

docker build --no-cache -t depi-worker:dev .

```



**Result:** Passed. The image built successfully using the pinned Python base image digest.



## 3. Non-Root User Validation



**Command:**



```powershell

docker run --rm --entrypoint python depi-worker:dev -c "import os; print('UID:', os.getuid()); print('GID:', os.getgid())"

```



**Output:**



```text

UID: 10001

GID: 10001

```



**Result:** Passed. The container runs as a non-root user.



## 4. Dropped Capabilities Validation



All Linux capabilities are dropped using `--cap-drop=ALL`.



**Command:**



```powershell

docker run --rm --cap-drop=ALL --entrypoint python depi-worker:dev -c "print('Capability restriction test passed')"

```



**Output:**



```text

Capability restriction test passed

```



**Result:** Passed.



## 5. Read-Only Filesystem Validation



The container root filesystem is mounted as read-only. A temporary writable `/tmp` filesystem is provided with a 64 MB limit and `noexec,nosuid` options.



**Command:**



```powershell

docker run --rm --read-only --tmpfs /tmp:rw,noexec,nosuid,size=64m --cap-drop=ALL --entrypoint python depi-worker:dev -c "import tempfile; f=tempfile.TemporaryFile(); f.write(b'test'); print('Read-only filesystem test passed')"

```



**Output:**



```text

Read-only filesystem test passed

```



**Result:** Passed.



## 6. Worker Import Validation



The worker module was imported under read-only filesystem and dropped-capabilities restrictions.



**Command:**



```powershell

docker run --rm --read-only --tmpfs /tmp:rw,noexec,nosuid,size=64m --cap-drop=ALL --entrypoint python depi-worker:dev -c "from src.worker.worker import Worker; print('Worker import passed')"

```



**Output:**



```text

Worker import passed

```



**Result:** Passed.



Note: This is an import smoke test only. It does not validate live AWS connectivity or SQS message processing.



## 7. Unit Tests



**Command:**



```powershell

.\.venv\Scripts\python.exe -m unittest discover -s tests/unit -v

```



**Result:** Passed. All 12 unit tests passed.



## 8. Scope and Limitations



### Confirmed



- The container runs as UID/GID `10001`, not root.

- The container supports read-only root filesystem execution.

- The tested operations work with all Linux capabilities dropped.

- The Docker image builds successfully using the pinned base image digest.

- All 12 unit tests passed.



### Not Covered



- Live AWS connectivity was not tested.

- Live SQS message processing was not tested.

- `process_task()` remains a placeholder until the task payload contract is finalized.



**Deployment note:** The worker must not be deployed until the actual task-processing logic is implemented.
