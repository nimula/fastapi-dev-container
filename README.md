# Template for Python FastAPI with Dev Container

Simple template to get started with FastAPI using Podman and Dev Container for VS Code.

## Features

- Preconfigured for FastAPI development
- Uses Podman and Dev Containers for consistent development environments
- Zsh as the default terminal shell
- Python linting and formatting via `ruff` and `formatOnSave`
- Preinstalled VS Code extensions for Python, comments, colorizing, and more

## Getting Started

1. Install Podman and ensure it's configured correctly for rootless containers.
2. Open this folder in VS Code.
3. If prompted, reopen in the container.
4. Start coding your FastAPI application in the `/workspace` directory.

## Dev Container Configuration

The `.devcontainer/devcontainer.json` file supports two approaches:

- **Single Dockerfile**: Uncomment the `"build"` section and specify your custom Dockerfile and context. You need to uncomment `"runArgs": [ "--userns=keep-id" ]` to ensure the container uses the same UID/GID as your host user, which helps avoid file permission issues on shared volumes.
- **Docker Compose**: By default, this setup uses `docker-compose-dev.yml` to define multi-service configurations. You can adjust the `dockerComposeFile` and `service` fields as needed.

Choose the one that best fits your development workflow.

## Requirements

- [Podman](https://podman.io/)
- [Standalone docker compose](https://docs.oracle.com/en/learn/ol-podman-compose/)
- [Visual Studio Code](https://code.visualstudio.com/)
- [Remote - Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
