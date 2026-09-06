# ADR-0008: docs 仓文档单真源化（根 ↔ `docs/` 双份收敛到 `docs/`）

| 字段                | 值                                                                                                                   |
| ------------------- | -------------------------------------------------------------------------------------------------------------------- |
| Status              | **Accepted**                                                                                                         |
| Date                | 2026-09-06                                                                                                           |
| Deciders            | Accept：szpeter2026 (Admin)、zervi-genz (Admin)；起草：xiajason (Member)                                             |
| Scope               | `GenzLTD/docs`                                                                                                       |
| Supersedes / Amends | Amends `README.md` 与 `docs/访问与参与指南.md` 的「根 ↔ `docs/` 同步」条款；承接 ADR-0006 确立的 docs 唯一治理源定位 |

## Context

ADR-0006 及此后 owner 的目录重组（`df4b8c4`）使 docs 仓同时存在两条内容轨道：

1. **根目录 markdown** —— GitHub 网页默认视图，评审流程的常规操作对象（CODEOWNERS 路径、`gh` / 网页浏览均以根为入口）；
2. **`docs/` 目录** —— MkDocs 站点源（`mkdocs.yml` `docs_dir: docs`，nav 全部指向 `docs/` 下文件，**站点只渲染 `docs/` 副本**）。

两条轨道要求每次内容改动**同步两份**。同步面与风险已实测：

- **重复面**：根一级业务 markdown 与 `docs/` 一级一一重复（8 对 8），另加 `CATALOG.md`、`README.md`（内容级重复）、`adrs/` 下 9 个文件双份，合计 **约 18 个文件 × 2 个维护点**；
- **已分叉（实锤）**：
  - 根 `adrs/0005` 与 `docs/adrs/0005` 内容不一致 —— `90f787f`（backfill Codespace 经验：bullseye yarn-key、Dockerfile 修复、identity stub 移除）只改了根副本，**站点当前展示过期的 ADR-0005**；
  - 根 `adrs/0006` 与 `docs/adrs/0006` 内容不一致 —— `df4b8c4`（markdownlint 表格对齐）只改了根副本；
- **机制缺失**：无 CI、无脚本、无 git 级校验保证双份一致；纯人工同步在 GitHub Free plan（私有仓无法启用 branch protection 强制 review）下尤其脆弱。

对 ADR 这类治理文件，副本滞后意味着**站点读者可能参考到过期决策**，与 ADR-0006「`GenzLTD/docs` 远端才是治理唯一源」的定位相悖——docs 站点成为第二个、且不可信的「源」。

## Decision（Accepted 2026-09-06）

**文档单一真源迁移至 `docs/`；根目录只保留仓库元数据与一个跳板 `README.md`。**

```text
现状（双份 + 已分叉）                        目标（单真源 docs/）

根 = GitHub 网页视图                         根 = 仓库元数据 + 门户跳板
├─ README.md（门户正文）                     ├─ README.md（3~5 行定位 + 链接
├─ 8× 业务 md ──┐                             到 docs/README.md）
├─ CATALOG.md  ├─ 人工同步，已漏            ├─ .github/ .devcontainer/ .vscode/
├─ adrs/ (9) ──┘                              ├─ scripts/  mkdocs.yml  .gitignore
│                                              └─ （业务 md / CATALOG / adrs 迁入 docs/）
docs/ = MkDocs 站点源
├─ README.md ──┐（站点实际只渲染这些）      docs/ = 全部文档唯一真源
├─ 8× 业务 md ├─ 站点 = 副本 → 过期风险     ├─ README.md（门户正文 = 站点首页）
├─ CATALOG.md ┤                             ├─ 业务 md + CATALOG
└─ adrs/ (9) ──┘                            └─ adrs/ (9) —— ADR 唯一路径
```

要点：

1. **不推翻 `docs_dir: docs`**：保留 ADR-0006 及 owner 已定案的「站点内容隔离在 docs/」设计，迁移只是把真源从根挪进站点源目录；
2. **根 `README.md` 跳板化**：正文（评审流程、文档索引）迁至 `docs/README.md`（同时即 MkDocs 首页），根 README 只保留定位说明与链接——GitHub 网页读者多一次点击，换内容单真源；
3. **之后新增/修改文档只写一份**：新增 ADR 只落 `docs/adrs/`，不存在「根一份 + 站点一份」；
4. GitHub 网页阅读能力不受影响：仓库内任意 markdown 在网页点击均可渲染，`docs/` 内文件同样可读；
5. 评审路径随之单一化：CODEOWNERS 的 `/adrs/` 改为 `/docs/adrs/`。

### 候选方案

| 方案                                         | 说明                       | 结论                                                                                                                                                                                     |
| -------------------------------------------- | -------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| A. `docs_dir: .`，根为唯一源                 | 站点直接读根，删除 `docs/` | 否决：根含 `.github/` `.devcontainer/` `scripts/` 等非文档资产，MkDocs 会把非 `.md` 文件当静态资源复制进 `site/`（且 `site/` 在根下存在目录递归风险）；并推翻 owner 已定案的站点隔离设计 |
| **B. 真源迁入 `docs/`（本决策）**            | 根仅元数据 + 跳板 README   | **采纳**：顺 `docs_dir: docs` 定案而行；同步成本归零；ADR/CODEOWNERS 路径单一；GitHub 网页可经跳板与 `docs/` 内直链访问                                                                  |
| C. 维持双份 + 同步纪律/CI 校验               | 现状 + 人工纪律与校验脚本  | 否决：分叉已在 0005/0006 发生；纯纪律在 Free plan 无强制力；CI 校验脚本引入新的维护面，且修复分叉仍需人工                                                                                |
| D. `docs/` 为构建产物（gitignore + CI 生成） | 真源在根，CI 生成 `docs/`  | 否决：`docs/` 已入库、owner 已将其作为评审与浏览对象；私有仓 Free plan 无法用 GitHub Pages 直接服务站点，收益不抵复杂度                                                                  |

## Consequences

### Positive

- 消灭约 18 文件 × 2 的同步面，及访问指南 §4 自述的「GitHub 仓库页 ↔ MkDocs 站点内容不一致」风险；
- `docs/adrs/` 成为 ADR 唯一存放路径：**站点 = 评审对象 = 真源**，治理闭环；
- 新增 ADR / 文档只需一次提交、一次评审，CODEOWNERS 归属路径明确；
- ADR-0005 / 0006 现有分叉随迁移以「根副本（较新）」为准一次性收敛，站点立即展示最新版。

### Negative / 过渡

- 一次性迁移动作较大（见下方执行清单），触碰 CODEOWNERS 与多份 `*.md`，需 Admin review —— 本 ADR 即提交 szpeter2026 / zervi-genz Accept；
- 迁移后根目录旧 markdown 链接 404。docs 仓处于早期、外部引用极少，可接受；README 跳板提供新路径指引；
- 根 `README.md` 由门户降为跳板，GitHub 主页正文需一次点击进入。

### 采纳后执行清单（单独实施 PR）

1. `git mv` 根 8× 业务 md + `CATALOG.md` + `adrs/`（9 文件）→ `docs/`（保留历史）；
2. 门户正文合并：根 `README.md` 正文迁至 `docs/README.md`，根 README 改写为跳板；
3. `.github/CODEOWNERS`：`/adrs/` 路径改为 `/docs/adrs/`；
4. `docs/访问与参与指南.md` §2.1/§4 与根 `README.md` §2.1 删除「根 ↔ `docs/` 同步」条款；
5. 本 ADR 迁移至 `docs/adrs/` 并同步 `docs/adrs/README.md` 索引；
6. `mkdocs.yml` nav 校验 `mkdocs build --strict` 通过后合并。

## Related

- Amends：根 `README.md`（§文档索引 / §2.1）、`docs/访问与参与指南.md`（§2.1/§4 双份同步条款）
- Follows：ADR-0006（docs 为唯一治理源）——本 ADR 消除其双份模式带来的副本分叉
- Review 路径：`/docs/adrs/` CODEOWNER @szjason72 @xiajason（起草主线）；Accept 权 szpeter2026 / zervi-genz（Admin，per `docs/adrs/README.md`）
