#!/usr/bin/env bash
# GenzLTD/docs Codespace post-create script
# Idempotent: safe to re-run. Designed to finish in <60s on Codespace warm cache.
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
echo "::group::docs post-create (repo=${GENZLTD_REPO:-docs})"

# 1. tooling baseline
need_cmd() { command -v "$1" >/dev/null 2>&1; }
for cmd in git gh python3 pip; do
  need_cmd "$cmd" || { echo "missing required: $cmd"; exit 1; }
done

# 2. mkdocs preview (only if user wants to render the docs site)
if ! python3 -c "import mkdocs_material" >/dev/null 2>&1; then
  echo "installing mkdocs-material..."
  pip install --quiet --disable-pip-version-check \
    "mkdocs-material>=9.5" \
    "mkdocs-mermaid2-plugin>=1.1" \
    "pymdown-extensions>=10.7"
fi

# 3. mkdocs scaffold (only if absent)
if [[ ! -f "${REPO_ROOT}/mkdocs.yml" ]]; then
  cat > "${REPO_ROOT}/mkdocs.yml" <<'YAML'
site_name: GenzLTD Governance Docs
site_description: ADR / process / catalog for GenzLTD projects
docs_dir: .
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

# 5. ensure git identity hint (Codespace git config may be empty)
if ! git config --global user.email >/dev/null 2>&1; then
  git config --global user.email "codespace@users.noreply.github.com"
  git config --global user.name  "GenzLTD Codespace"
  echo "git identity stub configured (override with gh auth login)"
fi

echo "::endgroup::"
echo "✅ post-create done. Run 'mkdocs serve' for live preview on :8000"