# ADR 0011: 冻结 dsh-bridle 产品化争论，注意力回到 Career Cosmos 90 天

- **Status**: Accepted
- **Date**: 2026-09-09
- **Deciders**: `szjason72`（GenzLTD owner / admin，Accepted 2026-09-09）
- **Consulted**: Win 本机验证（2026-09-09，`origin/main` `a346ca1`）；`GenzLTD/dsh-bridle` 适配脚本；对齐 [Career Cosmos 90 天](../聚焦决策-Career-Cosmos-90天.md)、[ADR-0009](0009-trust-layer-over-world-model.md)、[ADR-0003](0003-cortex-policy-bundle-pin.md)
- **Tags**: strategy, career-cosmos, dsh-bridle, docs-ssot, trust-layer, agent-memory

## Context

2026-09-08～09，内部把 `GenzLTD/dsh-bridle`（Nazha 白标 MCP RAG，挂 DeepSeek Harness）从「能装」做到「本机可用」：keyword CI、hybrid 黄金集、离线 text2vec 缓存、未脱敏 `kb_ask` 只打本机 Ollama。公开插件市场没有独门口，仓已是组织私有。

随后出现三条容易把编制拖离 90 天主线的说法：

1. 继续把 bridle 当主插件打磨（stdio、全量诗词语料、云端 78k 索引等）。
2. 把「进 bridle 前的简历脱敏脚本」或「诗词试验弹 → Tier 3 人才库」写成尚未落地、却仿佛已是 docs 口径的工序。
3. 用对话记录代替 `GenzLTD/docs` 回答组织进度，Cursor + 提交者组合容易给出与 Accepted ADR 冲突的回复。

本仓全文检索：**没有** `dsh-bridle`、没有 `desensitize.py`、没有「诗词=试验弹 / 78k 上云」立项。已拍板的是：诗词门户归档、72changes 方案 A 不迁移、近期只承诺信任层（ADR-0009）、融资主线是 Career Cosmos。

待决：bridle 是产品线，还是到此为止的内部工具？开口前只钉 git / 只做 RAG，够不够？

## Decision

1. **结束 dsh-bridle 产品化争论。**  
   它不是公开 DSH 插件，不是 90 天交付物，不是 GFCC 主产品。功能迭代冻结。内部已经可用：检索（含 hybrid）+ 未脱敏问答走本机 Ollama。禁止将 DeepSeek 云 Key 当作内部完成标准（那是语料出域，不是「开放服务」）。

2. **不把诗词语料或人才 RAG 做成下一场战役。**  
   诗词半成品不能当业务数据；90 天决策已归档诗词门户。不必为验证再跑全量 78k 或上云。人才/简历的合规能力走 **信任层**（Wukong 门控 + `genz-verify` 对拍），不是把简历导入 bridle 建第二座知识库。进口脱敏脚本若要做，须**新开文档**立项，不得声称「docs 里设计已定、只差代码」。

3. **注意力回到 90 天硬动作。**  
   仍以 [聚焦决策-Career-Cosmos-90天.md](../聚焦决策-Career-Cosmos-90天.md) 为准：T空间 / X星球 / 信任层 / Looma。技术欠债读法见 ADR-0010（**Proposed**，Accept 前以聚焦决策原文为准）。个人仓与 Agent 回答组织口径时，以本仓 `main` 的 Accepted / 已决策文档为准，不以聊天记录为准。

4. **bridle 的组织用途：本机工作记忆探针，不是产品，不是知识皮层。**  
   每位成员在自己机器构建 dsh-bridle。凡回答组织进度、主线、产品处置、ADR 状态：**先把门控跑完，再做有落地点名的检索，再开口。** 真源仍是 git。回答必须同时给出 `origin/main` SHA、文档路径、Status（Accepted / 已决策 / Proposed / 评审建议）。对不上这三项，或标识符未出现在文件名/标题/片段中 → **docs 未记载**。禁止用聊天记录补事实，禁止把 Proposed 说成已拍板。**RAG 不是治理阀门。** 强制力仍是 CODEOWNERS、ADR 状态、genz-gate。

5. **只靠门控不够，必须有 agent memory 参与——但不在 bridle 里重做皮层。**  
   本机验证（2026-09-09）：`sync_genz_docs.py` 能拒绝脏工作区与旧 SHA（门控有效）；裸 `kb_search` / hybrid 仍把「像」当成「有」（`dsh-bridle` 命中 ADR-0002/0009）。这与 [ADR-0009](0009-trust-layer-over-world-model.md) 已写明的分工相同，不是新发现：
   - **门控**（Wukong / `genz-gate` / 本 ADR 的 git pin）：同一输入同一 verdict，管放行与拒绝。
   - **记忆**（[ADR-0003](0003-cortex-policy-bundle-pin.md) 的 cortex `remember` 前合规）：管什么可以写成「已发生的事实」、下次能否召回、过期能否忘记。
   bridle 只提供工作记忆探针（当前 SHA + 路径 + Status）。会话聊天不是记忆。把检索邻居或对话补丁 `remember` 成 Accepted，等于绕过信任层。本 ADR **不**把 M3 记忆三层化、Agent loop、五槽落地重新写成 90 天承诺（仍受 ADR-0009 约束）。cortex 继续当带合规挂钩的记忆服务，不当「知识皮层已完成」。

## Docs 仓安置（本仓怎么对待 dsh-bridle）

这不是「远端 GitHub 不支持 bridle Building」。两仓 CI 分工如下，互不替代：

| 仓库 | GitHub Actions 编什么 | 不编什么 |
|---|---|---|
| `GenzLTD/docs` | `.github/workflows/docs.yml` → `mkdocs build --strict`（治理站点） | 不 checkout、不 pip install、不 pytest `dsh-bridle`；不替成员做本机索引 |
| `GenzLTD/dsh-bridle` | `.github/workflows/ci.yml` → `pytest -m "not embedding and not ollama"`（插件单元测试） | 不把本仓 markdown 编进 MkDocs；不在 CI 里 clone docs 当语料 |

因此：**bridle 代码不进 docs 仓**（不做 submodule、不 vendor、不把 `corpus/` / torch / HuggingFace 缓存推进本仓）。GitHub 不能替每位成员的 Cursor/DSH 执行「开口前同步」——那是本机纪律。本仓只保留治理口径：本 ADR、Career Cosmos 处置清单一行、参与指南中的适配步骤、索引与 `mkdocs.yml` 导航。

### 成员本机强制步骤（回答组织问题之前）

1. 分别 clone `GenzLTD/docs` 与 `GenzLTD/dsh-bridle`，在 bridle 目录完成本机 venv / 依赖（各人自己构建适配环境）。
2. 设置 `GENZ_DOCS_DIR` 指向 docs 克隆。工作树必须干净且在 `main`（或 HEAD 已等于 `origin/main` 的游离检出）。
3. **门控**：`python scripts/sync_genz_docs.py` → `git fetch` + 与 `origin/main` fast-forward，再把 `docs/`（站点源）导入本机隔离索引（`CORPUS_DB` / `CHROMA_PERSIST_DIR` / `CHROMA_COLLECTION`，勿混进其他语料）。不要指根目录杂项，不要指 `site/` 构建产物。
4. **落地点名**：`python scripts/docs_grounded_search.py "<问题>"`。禁止把裸 `kb_search` / hybrid 邻居当组织证据。文件名、标题或片段中未出现查询标识符 → **docs 未记载**。
5. 有落地则引路径与 Status。未脱敏禁止填 DeepSeek 云 Key。
6. **记忆**：本轮 SHA / 路径 / Status 只作为工作记忆。不得把「未记载」或 Proposed 写入任何 `remember` 成已拍板。过期聊天与旧 SHA 必须丢弃。组织级记忆写入仍走 cortex（`remember` 前合规，ADR-0003），不在 bridle 仓实现第二套记忆皮层。
7. 改口径仍走 docs PR。禁止在 bridle 索引里「改真源」。

### 本机验证（2026-09-09，不作为「已入库」证据）

对照当时 `origin/main` `a346ca1`（该 commit **不含** 本 ADR）：脏克隆拒绝；停在旧 `504dbe6` 的游离 HEAD 拒绝；干净导入 31 篇。`Career Cosmos 90` / `ADR-0010` 经落地点名可命中（0010 的 Status 仍是 Proposed）。裸 hybrid 问 `dsh-bridle` 仍返回无关 ADR。落地点名后 `dsh-bridle` / `ADR-0011` → **docs 未记载**。

因此：门控通过 ≠ 可以开口；hybrid 有命中 ≠ 记载为真。验收仍是 SHA + 路径 + Status；缺一项视为瞎说。

解冻或改成「docs 站点内嵌 bridle 产品章 / bridle 充当知识皮层」须新 ADR。当前 MkDocs nav 只挂本 ADR，不挂插件 README。

## Consequences

### Positive

- 编制不再消耗在插件差异化、诗词语料流水线、torch/HF 分发叙事上。
- 信任层与 90 天支付/三端工作重新成为默认话题。
- docs 单真源得到一条可执行的 Agent 约束（见本仓 `AGENTS.md`）。
- 用一次失败的「只检索」坐实 ADR-0009 / 0003：阀门与记忆分工，而不是再开一条 RAG 产品线。

### Negative

- 希望把 bridle 做成团队知识平台或人才库的成员会感到被叫停。归档不等于否定；解冻须新 ADR，且须证明服务 90 天主线。

### Risks

- 有人把「冻结」读成「本地 RAG 也禁止」。本 ADR 要求的是各人本机口径适配，禁止的是产品化与主线抢编制。
- 有人把「必须有 agent memory」读成「立刻交付 M3 记忆三层 / Agent loop」。本 ADR 只禁止把 bridle/hybrid 当已信任记忆；记忆写入仍受 ADR-0009 承诺范围约束。
- 有人把「人才走信任层」读成「不要处理简历」。处理简历仍可能是 T空间业务；要过的是门控与授权，不是 bridle 索引。

## Implementation checklist

- [x] Accept 本 ADR（组织 owner `szjason72`，2026-09-09）
- [x] 回写 Career Cosmos 产品线处置清单：`dsh-bridle` = 内部工具冻结
- [x] `AGENTS.md`：组织口径以本仓 Accepted/已决策为准
- [x] 写明 docs 仓安置：本仓只登记决策；插件构建在 `GenzLTD/dsh-bridle` CI；禁止把 bridle 编进本仓 MkDocs
- [x] 成员本机协议：开口前 `sync_genz_docs.py`（门控）+ `docs_grounded_search.py`（落地点名）；裸 hybrid 不当证据
- [x] 写明门控 ≠ 记忆：bridle 只做工作记忆探针；`remember` 仍走 cortex 合规（ADR-0003）；不复活 ADR-0009 已冻结的 Agent loop 承诺
- [ ] 成员停止在 PR/聊天中把 bridle、诗词语料、云端全量索引当作当前迭代目标
- [ ] 信任层验收回到 `genz-verify` / 三仓 `genz-gate`，不在 bridle 仓继续开功能 PR（文档与 bugfix 除外）

## Links

- [Career Cosmos 90 天](../聚焦决策-Career-Cosmos-90天.md) · [ADR-0009](0009-trust-layer-over-world-model.md) · [ADR-0003](0003-cortex-policy-bundle-pin.md) · [ADR-0010](0010-cn-wechat-pay-three-client-ops.md)（Proposed）
- 代码仓（私有、冻结产品化）：https://github.com/GenzLTD/dsh-bridle
- 信任层本机验证：https://github.com/szjason72/genz-verify
- Supersedes: （无）
- Superseded by: （无）
