# GenzLTD/docs Codespace image.
#
# Why not mcr.microsoft.com/devcontainers/python:3.11-bullseye?
#   That base image ships a Yarn apt source (dl.yarnpkg.com) whose GPG key
#   (NO_PUBKEY 62D54FD4003F6525) can no longer be verified. Any devcontainer
#   feature build that runs apt-get update then fails (observed on the sshd
#   feature), GitHub Codespaces falls back to a bare devcontainers/base:alpine
#   container without gh / pip / GITHUB_TOKEN injection.
#
# The official python image carries no Yarn source, so builds and postCreate
# run cleanly. sshd is installed here because the Codespaces connection layer
# (`gh codespace ssh` / VSCode) requires an SSH server inside the container.
# The `vscode` user + passwordless sudo mirror what devcontainers images ship,
# since Codespaces runs the container with `containerUser: vscode`.
FROM python:3.11-bookworm

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        openssh-server \
        openssh-client \
        ca-certificates \
        curl \
        git \
        sudo \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} \
    && echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME} \
    && mkdir -p /run/sshd \
    && sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
