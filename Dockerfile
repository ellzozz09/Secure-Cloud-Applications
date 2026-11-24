
# Stage 1: Build dependencies
FROM python:3.12-slim-bookworm AS builder

WORKDIR /app

COPY src/worker/requirements.txt ./requirements.txt

RUN pip install --no-cache-dir --prefix=/install -r requirements.txt


# Stage 2: Runtime image
FROM python:3.12-slim-bookworm AS runtime

WORKDIR /app

# Create a non-root user
RUN groupadd --gid 10001 appuser \
    && useradd --uid 10001 --gid 10001 \
       --no-create-home --shell /usr/sbin/nologin appuser

# Copy installed dependencies from builder
COPY --from=builder /install /usr/local

# Copy worker source code
COPY src/ ./src/

# Python runtime settings
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Run as non-root user
USER 10001:10001

# Start the worker
CMD ["python", "-c", "from src.worker.worker import Worker; Worker().run()"]
