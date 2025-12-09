#!/bin/bash
# Security Scanning Wrapper (Unix/macOS/Linux)
# This is a convenience wrapper around the Docker container

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="security-scanning:latest"

# Build image if it doesn't exist
if ! docker image inspect "$IMAGE_NAME" &> /dev/null; then
    echo "Building Docker image..."
    docker build -t "$IMAGE_NAME" "$SCRIPT_DIR"
fi

# Check if we need interactive mode
INTERACTIVE=""
if [ "$1" = "shell" ] || [ -t 0 ]; then
    INTERACTIVE="-it"
fi

# Run the container
docker run --rm $INTERACTIVE \
    -v "$SCRIPT_DIR/output:/output" \
    -v "$SCRIPT_DIR/targets:/targets:ro" \
    --memory=12g \
    "$IMAGE_NAME" \
    "$@"
