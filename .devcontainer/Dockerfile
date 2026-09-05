# GenzLTD/docs Codespace image.
#
# Why not mcr.microsoft.com/devcontainers/python:3.11-bullseye?
#   That base image ships a Yarn apt source (dl.yarnpkg.com) whose GPG key
#   (NO_PUBKEY 62D54FD4003F6525) can no longer be verified. Any devcontainer
#   feature build that runs apt-get update then fails (observed on the sshd
#   feature), GitHub Codespaces falls back to a bare devcontainers/base:alpine
#   container without gh / pip / GITHUB_TOKEN injection.
#
# The official python image carries no Yarn source, so feature builds and
# postCreate run cleanly. sshd is installed here because the Codespaces
# connection layer (`gh codespace ssh` / VSCode) requires an SSH server inside
# the container.
FROM python:3.11-bookworm

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        openssh-server \
        openssh-client \
        ca-certificates \
        curl \
        git \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /run/sshd \
    && sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
