# GenLTD 架构知识库

> 单人决策日志与 AI 跨会话长期记忆源（single source of truth）。评审为记录性，CI（`mkdocs build --strict`）为唯一守门人；ADR 不可变、统一对账表、Owner 指令为保留资产。

## 评审与维护口径（Record-first，CI 为守门人）

> **口径变更（2026-10-06）**：本仓实际为单人维护的决策日志（组织内仅一个真人在持续提交）。原 CODEOWNER 批准式评审在 Free plan + 私有仓下无法由 GitHub 强制，且历史 PR 过半零 review 直合，已事实失效。现改为**记录性**口径，CI 为唯一合入门禁。

- **评审矩阵 = 记录性，非批准性**：记录「谁 / 何时 / 基于何据」做了什么决策与变更，不再要求成员互批、不再设合并门槛。
- **唯一守门人 = CI**：`mkdocs build --strict` 通过（站点可构建、链接不断）方可合入；任何破坏 build 的改动不得合并。
- **保留不可变资产**：ADR 不可变（Superseded 只链新 ADR、不改原文，见 `docs/adrs/README.md`）、统一对账表（季度复核，owner 裁定唯一事实源）、Owner 指令（merge 即生效，修订走新 PR 不静默改正文）。
- **维护节奏**：月度批量回写一次，不追每条现网变化；避免文档滞后于现实反向误导 AI。
- **每篇文档头部须带「最近核实现网日期」**；现网已变或超季度未核者标注 ⚠️ 过期。
- 历史 CODEOWNER 表（见 `.github/CODEOWNERS`）保留为参考，但不再作为合并门槛。

## 文档索引

| 文档                                                                 | 内容                                                                 | 状态        |
| -------------------------------------------------------------------- | -------------------------------------------------------------------- | ----------- |
| [聚焦决策-Career-Cosmos-90天.md](docs/聚焦决策-Career-Cosmos-90天.md) | 团队聚焦决策：一条主线（Career Cosmos 矩阵为融资服务）+ 90 天硬动作   | 已决策；dsh-bridle 冻结见 [ADR-0011](docs/adrs/0011-dsh-bridle-freeze-career-cosmos.md) |
| [90天主线作战清单.md](docs/90天主线作战清单.md) | 90 天聚焦决策的执行层展开：5 硬动作看板 + 技术欠债 P0-P3 + 资产真实状态 + SQLite/PG 待拍板 | 执行清单（v1，持续更新） |
| [信任层数据审计报告.md](docs/信任层数据审计报告.md) | 信任层数据审计：52 声明 + 78 证据的 9 项发现，结论「可信度计算未实现、签名未落地」 | 审计报告（2026-09-10） |

| [访问与参与指南](docs/访问与参与指南.md)                             | 成员访问仓库、使用 Codespaces、提交评审和运行维护知识库的入口说明    | 持续维护    |
| [新一代智能大脑架构设计.md](docs/新一代智能大脑架构设计.md)               | 八大设计决策 + 业界参考 + 与 DeepSeek Harness 差异化                 | v0.2 研讨稿；受 [ADR-0009](docs/adrs/0009-trust-layer-over-world-model.md) Accepted 约束 |
| [新一代智能大脑-落地路线图.md](docs/新一代智能大脑-落地路线图.md)         | M0–M6 里程碑 + 验收标准                                              | v0.1；承诺范围见 ADR-0009 |
| [新一代智能大脑-信任层评审-20260907.md](docs/新一代智能大脑-信任层评审-20260907.md) | CI ≠ 大脑；近期做信任层，不做世界模型幻想                    | 评审 / 已 Accept（ADR-0009） |
| [CATALOG.md](CATALOG.md)                                             | 34 仓库血缘总索引（含 Wukong 隐藏主线）                              | 持续更新    |
| [Wukong-lab-Schema同步对接规范.md](Wukong-lab-Schema同步对接规范.md) | Wukong(真源)→lab 的 Layer0/1/2 schema 同步规范 + promote 流程 + 脚本 | 可执行      |
| [Wukong-命名与归属对账表.md](Wukong-命名与归属对账表.md)             | Wukong vs wukong-core vs lab 命名与归属对账（不合并/锁真源/负责人 szjason72） | 已拍板      |
| [72changes-Nazha语料盘点与决策.md](72changes-Nazha语料盘点与决策.md) | 72changes 与 RAG 主线 Nazha 差异盘点 + 归档决策（方案 A）             | 已拍板      |
| [Nazha归口-ServBay承载方案.md](docs/Nazha归口-ServBay承载方案.md)     | Nazha 知识库归口的本机承载宿主：nazha.servbay.host → 127.0.0.1:5220（gfcc demopeter，launchd 托管） | 方案已钉死（2026-09-07）· 归口实证见附录（2026-09-08） |
| [sandbox/evaluation-edge-virtual-sandbox-20260910](sandbox/evaluation-edge-virtual-sandbox-20260910/README.md) |
| [治理口径-实验边界与执行规范-20260914.md](docs/治理口径-实验边界与执行规范-20260914.md) |
| [成员分工与后续任务-20260913.md](docs/成员分工与后续任务-20260913.md) | 四条工作线（合规 / 双线适配 / Variety+dsh / pgvector 智能化）任务分工 + 协作约定 | 已批准（Owner Directive 2026-09-14，批准记录见文档 §8）；§7 开放项继续跟踪；§2 个人线「AI」表述已被 [Owner 指令 2026-09-18](docs/Owner指令-szbolent.cn书店参考实现-20260918.md) 覆盖 |
| [Owner指令-szbolent.cn书店参考实现-20260918.md](docs/Owner指令-szbolent.cn书店参考实现-20260918.md) | `szbolent.cn` = T2 书店参考实现；`www.szbolent.cn` = 橱窗只读精选；AI 只帮作者 | Owner Directive（2026-09-18）⚠️ **现网已变**：apex 与 www 均=「放翁文库」，详见 [统一对账表 §九 #2](docs/统一对账表-20260915.md) |

现网核对记录（2026-10-06 核定的 4 条脱节：放翁文库零记载 / www→apex 同源 / circle 违规未迁 / Stripe 护栏待核）见 [统一对账表-20260915](docs/统一对账表-20260915.md) §九。

## 关联代码仓库

| 仓库                     | 定位                                         | 对应决策 |
| ------------------------ | -------------------------------------------- | -------- |
| `GenzLTD/wukong-core`    | 认知内核（Layer0/1/2 + 门控 + 认知偏差检测） | ②⑧       |
| `szpeter2026/cortex-mcp` | 记忆层（分层认知记忆）                       | ③⑦       |
| `GenzLTD/Wukong`         | 认知内核原生真源（跨境数据共识匹配平台）     | ② 参考   |
| `GenzLTD/72changes`      | RAG 知识库原生实现（Spring Boot）            | ③ 参考   |
| `GenzLTD/looma-zervi`    | 主 monorepo                                  | 主体     |
| `GenzLTD/dsh-bridle`     | Nazha 白标 MCP RAG（内部冻结；各人本机口径适配器） | ADR-0011 |

## 演进约定

- 本文库为**文档真源**，代码仓库的 docs/ 只放该组件自身的设计产物。
- 架构决策变更走 PR；评审为**记录性**（记录谁/何时/基于何据），不再要求 CODEOWNER 互批，合入门禁唯一为 CI（`mkdocs build --strict`）。
- **每篇文档头部须带「最近核实现网日期」**；超季度未核或现网已变者标注 ⚠️ 过期，并在对应 ADR / 统一对账表回写。
- 维护节奏：月度批量回写一次，不追每条现网变化。
- 血缘关系、仓库索引的更新见 `CATALOG.md`。
