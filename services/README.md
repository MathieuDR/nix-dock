# Services
## Creating Docker Images for GitHub Packages

To create and publish Docker images for our custom services (like Hillchart and OSRS Automator), follow these steps:

1. Create a Dockerfile to package and run your application
2. Add the following to your `.envrc` and `envrc_secret` files

`.envrc`
```
source_up_if_exists
source_env_if_exists '.envrc_secret'
```

`.envrc_secret`
```
export GITHUB_USERNAME='****'
export GITHUB_PAT='ghp_****'
```
3. Add the following commands to your justfile

```
# Variables
IMAGE_NAME := "ghcr.io/<USERNAME>/<REPO>"
TAG := "latest"
DOCKERFILE := "Dockerfile"

# Recipe to build docker
build:
    @echo "Building Docker image..."
    docker build -t {{IMAGE_NAME}}:{{TAG}} -f {{DOCKERFILE}} .

push:
    @echo "Logging in to GitHub Container Registry..."
    echo $GITHUB_PAT | docker login ghcr.io -u $GITHUB_USERNAME --password-stdin

    @echo "Pushing Docker image to GitHub Container Registry..."
    docker push {{IMAGE_NAME}}:{{TAG}}
```

## Adding a New Service

To add a new service:

1. Create a new `.nix` file for the service in this directory or a subdirectory if it requires multiple files.
2. Configure the service in the new file.
    1. Use `Restic` for backup purposes
    2. Use `Caddy` for the reverse proxy
3. Import the new service file in `./services/default.nix`.
4. Update the main `configuration.nix` if necessary.

## Other info

We use Podman for virtualisation instead of Docker.
