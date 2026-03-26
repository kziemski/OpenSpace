# OpenSpace Dockerfile
# Multi-stage build for the OpenSpace core Python service

FROM python:3.12-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy dependency files first for better layer caching
COPY pyproject.toml requirements.txt ./

# Install dependencies
RUN pip install --no-cache-dir --user -e .

# Production stage
FROM python:3.12-slim

# Install runtime dependencies only (libffi8 for Debian trixie/sid)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libffi8 \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN groupadd --gid 1000 openspace && \
    useradd --uid 1000 --gid openspace --shell /bin/bash --create-home openspace

# Set working directory
WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /root/.local /home/openspace/.local

# Copy application source
COPY --chown=openspace:openspace . .

# Create directories and set permissions for openspace user
RUN mkdir -p /app/data /app/logs /app/.openspace && \
    chown -R openspace:openspace /app

# Set environment variables
ENV PATH="/home/openspace/.local/bin:$PATH"
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Expose ports
# 7788 - Dashboard API server (default from code)
# 5000 - Local server (default from code)
EXPOSE 7788 5000

# Health check - use a simpler endpoint that doesn't require the store
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:7788/')" || exit 1

# Run as non-root user
USER openspace

# Default command: show help
CMD ["python", "-m", "openspace", "--help"]
