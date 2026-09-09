# GenzLTD Docs Agent Guide

## Repository purpose

- This is an architecture and governance documentation repository, not a business-code repository.
- Treat the repository as the long-term source for ADRs, architecture decisions, repository lineage, and collaboration rules.
- Keep detailed policy and process content in the existing documentation; link to it instead of duplicating it here.

## Important locations

- `docs/adrs/`: architecture decision records. Follow the numbering, status, and immutability rules in [`docs/adrs/README.md`](docs/adrs/README.md).
- `docs/`: MkDocs site source, configured by [`mkdocs.yml`](mkdocs.yml).
- `scripts/sync_wukong_schemas.py`: explicit `diff`, `check`, and `sync` workflow for copying the three approved schemas from Wukong to the lab repository.
- `.github/CODEOWNERS`: required review owners for ADRs, documents, and governance configuration.
- `.devcontainer/`: the supported Codespaces/local-container setup; keep `post-create.sh` idempotent.

## Working rules

- Preserve the single-source intent documented in [`README.md`](README.md) and [`docs/访问与参与指南.md`](docs/访问与参与指南.md). ADRs live only under `docs/adrs/`; ordinary root Markdown may still have a corresponding site copy until a separate migration decision removes that duplication.
- New ADRs use `docs/adrs/NNNN-short-title.md`, with the next available four-digit number. Do not rewrite an accepted or superseded ADR; record follow-up decisions in a new ADR.
- Update indexes and `mkdocs.yml` navigation when adding or renaming a document.
- Never commit tokens, credentials, private keys, personal data, or unverified cross-repository claims.
- Changes under `docs/adrs/`, `.github/`, `.devcontainer/`, or Markdown files require the applicable CODEOWNER review. The author must not approve their own PR.
- Treat schema synchronization as a reviewed promotion: inspect `diff`/`check` output before using `sync`, and run the consumer repository's tests after synchronization. Do not modify external repositories unless the task explicitly requires it.
- Before answering organization status, current priorities, or “what should the team work on”, the local `GenzLTD/docs` clone must match `origin/main` (gate), then **grounded** retrieve — `python scripts/docs_grounded_search.py` from the bridle clone after `python scripts/sync_genz_docs.py`, with `GENZ_DOCS_DIR` set. Do not treat raw `kb_search` / hybrid neighbors as evidence. Cite SHA + path + Status (Accepted / 已决策 / Proposed). If the identifier is not in filename, title, or snippet, say `docs 未记载`. Chat history is not memory; do not `remember` Proposed or “未记载” as Accepted. See [ADR-0011](docs/adrs/0011-dsh-bridle-freeze-career-cosmos.md).
- Do not treat `GenzLTD/dsh-bridle` as a product line, public plugin, knowledge cortex, or 90-day work item. It is a **local working-memory probe**. Trust-layer memory writes stay on cortex `remember` (ADR-0003) + Wukong gate + `genz-verify`. This does not revive ADR-0009’s frozen Agent-loop / M3 memory-layer delivery. Poetry corpus pipelines and talent RAG indexes are out of current scope.

## Validation commands

Run these from the repository root when applicable:

```bash
mkdocs build --strict --site-dir /tmp/docs-site-check
git diff --check
```

For a live preview:

```bash
mkdocs serve -a 0.0.0.0:8000
```

For schema work, first inspect the usage and then run the selected mode:

```bash
python scripts/sync_wukong_schemas.py --mode diff --wukong <Wukong-local-path>
python scripts/sync_wukong_schemas.py --mode check --wukong <Wukong-local-path>
```

`--mode sync` writes to the lab repository and is not a read-only validation.

## Change workflow

1. Read the relevant index or ADR before editing.
2. Make the smallest document, index, navigation, or script change that preserves existing terminology and links.
3. Run the narrowest relevant validation, then `mkdocs build --strict` for site-facing changes.
4. Summarize affected documents, validation commands, and any required CODEOWNER review in the PR.

The fuller onboarding, preview, review, and Codespaces guidance lives in [`docs/访问与参与指南.md`](docs/访问与参与指南.md); the repository overview and review matrix live in [`README.md`](README.md).
