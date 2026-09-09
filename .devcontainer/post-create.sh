#!/usr/bin/env bash
# GenzLTD/docs Codespace post-create script
# Idempotent: safe to re-run. Designed to finish in <60s on Codespace warm cache.
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
echo "::group::docs post-create (repo=${GENZLTD_REPO:-docs})"

# 1. tooling baseline
need_cmd() { command -v "$1" >/dev/null 2>&1; }
for cmd in git python3; do
  need_cmd "$cmd" || { echo "missing required: $cmd"; exit 1; }
done
# pip may be exposed as `pip` or only via `python3 -m pip`; derive a working invocation.
if need_cmd pip; then
  PIP="pip"
elif python3 -m pip --version >/dev/null 2>&1; then
  PIP="python3 -m pip"
else
  echo "missing required: pip (tried bare 'pip' and 'python3 -m pip')"
  exit 1
fi
# gh is a SOFT dependency: docs preview (mkdocs) does not need it. Warn, don't abort,
# so postCreateCommand still completes even if the github-cli feature is unavailable.
if ! need_cmd gh; then
  echo "warning: 'gh' not found (github-cli feature unavailable). git identity/PR hints skipped."
fi

# 2. Keep the preview toolchain aligned with CI.
# sudo when available (custom Dockerfile images ship passwordless sudo), so pip
# can write to the system site-packages owned by root.
SUDO=""
if need_cmd sudo; then SUDO="sudo"; fi
echo "installing locked MkDocs dependencies..."
$SUDO $PIP install --quiet --disable-pip-version-check \
  -r "${REPO_ROOT}/requirements-docs.txt"

# 3. mkdocs scaffold (only if absent)
# mkdocs.yml is tracked in-repo since df4b8c4 (ADR-0008 context). This scaffold
# only boots legacy checkouts that predate the committed config.
if [[ ! -f "${REPO_ROOT}/mkdocs.yml" ]]; then
  cat > "${REPO_ROOT}/mkdocs.yml" <<'YAML'
site_name: GenzLTD Governance Docs
site_description: ADR / process / catalog for GenzLTD projects
docs_dir: docs
theme:
  name: material
  features: [navigation.instant, navigation.tracking, toc.follow]
  palette:
    - media: "(prefers-color-scheme: light)"
      scheme: default
      primary: indigo
    - media: "(prefers-color-scheme: dark)"
      scheme: slate
      primary: indigo
markdown_extensions:
  - admonition
  - attr_list
  - def_list
  - footnotes
  - md_in_html
  - tables
  - toc:
      permalink: true
  - pymdownx.highlight
  - pymdownx.superfences:
      custom_fences:
        - name: mermaid
          class: mermaid
          format: !!python/name:mermaid2.fence_mermaid_custom
plugins:
  - search
nav:
  - Home: README.md
  - ADR Index: adrs/README.md
  - ADR 0001: adrs/0001-lab-wukong-canonical.md
  - ADR 0002: adrs/0002-l0-pii-sg-deny-policy.md
  - ADR 0003: adrs/0003-cortex-policy-bundle-pin.md
  - ADR 0004: adrs/0004-tatha-frontend-deployment-pipeline.md
  - ADR 0005: adrs/0005-remote-codespace-development.md
  - ADR 0006: adrs/0006-docs-governance-codespace.md
  - ADR 0007: adrs/0007-tatha-frontend-deploy-governance.md
  - 执行计划: ADR001-004落地执行计划.md
  - 架构设计: 新一代智能大脑架构设计.md
  - 路线图: 新一代智能大脑-落地路线图.md
YAML
  echo "mkdocs.yml scaffolded"
fi

# 4. ADR cross-link guard: warn on ADR file without README entry
for f in adrs/*.md; do
  [[ "$(basename "$f")" == "README.md" ]] && continue
  if ! grep -q "$(basename "$f" .md)" adrs/README.md 2>/dev/null; then
    echo "::warning file=$f::ADR not listed in adrs/README.md index"
  fi
done

# 5. git identity: never write an unowned stub email. Codespaces injects the
#    creator identity at the SYSTEM level (/etc/gitconfig). Overriding it with a
#    fake user-level identity (e.g. codespace@users.noreply.github.com) produces
#    grey, unattributed commits on GitHub. Leave the global level empty so git
#    falls back to the injected system identity; only warn if none exists.
if ! git config --global user.email >/dev/null 2>&1; then
  if git config --system user.email >/dev/null 2>&1; then
    echo "git user.email unset at --global level; using injected system identity:"
    echo "  $(git config --system user.name 2>/dev/null) <$(git config --system user.email)>"
  else
    echo "warning: no git user.email anywhere (global or system). Set it explicitly:"
    echo "  git config --global user.name 'Your Name'"
    echo "  git config --global user.email 'you@example.com'"
  fi
fi

echo "::endgroup::"
echo "✅ post-create done. Run 'mkdocs serve' for live preview on :8000"
