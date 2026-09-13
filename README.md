# GenLTD 架构知识库

> 团队架构设计的单一真源（single source of truth），供全体成员研讨、评审、追溯演进。

## 评审流程（Review Process）

任何 PR 合并前，**必须**取得以下 CODEOWNER 之一的 review approval：

| 改动路径                 | 必审人（CODEOWNER）             | 兜底人                        |
| ------------------------ | ------------------------------- | ----------------------------- |
| `docs/adrs/`（ADR 文档） | `@szjason72` 或 `@xiajason`     | `@zervi-genz`、`@szpeter2026` |
| `*.md`（其他文档）       | `@zervi-genz` 或 `@szpeter2026` | —                             |
| `.github/`（治理配置）   | `@zervi-genz` 或 `@szpeter2026` | —                             |

执行细则：

1. 作者**不能**自己 approve 自己的 PR。
2. 改动落在多个路径时，**每条**路径上的 CODEOWNER 都要 review。
3. CODEOWNERS 配置见 [`.github/CODEOWNERS`](.github/CODEOWNERS)。
4. **过渡说明** —— GenzLTD 当前为 Free plan，GitHub 不允许在私有仓强制 `require_code_owner_reviews`。升级到 Pro 或将本仓转 public 后，本节规则将由 GitHub 自动强制执行。在过渡期内，请每位 Maintainer **自觉遵守**上述评审流程；如发现未走评审的直推，请评论提醒或 revert。

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
| [治理口径-实验边界与执行规范-20260914.md](docs/治理口径-实验边界与执行规范-20260914.md) | 统一口径：允许试验 / 禁止伪装事实 / 保留创新 / 守住合规；dsh-bridle 冻结维持（ADR-0011）；pgvector=技术准备项非业务承诺；owner 拍板机制与 PR review 依据 | Owner Directive（2026-09-14） | evaluation_edge Schema v0 虚拟互评沙盘：36 条样例 + 9 红线校验器 + k-匿名共识聚合（零真实个人信息） | 验证通过 6/6；设计输入，非立项 |

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
- 架构决策变更走 PR + 评审，保留完整历史追溯。
- 血缘关系、仓库索引的更新见 `CATALOG.md`。
