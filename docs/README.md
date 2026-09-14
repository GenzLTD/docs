# GenLTD 架构知识库

> 团队架构设计的单一真源（single source of truth），供全体成员研讨、评审、追溯演进。

## 评审流程（Review Process）

任何 PR 合并前，**必须**取得以下 CODEOWNER 之一的 review approval：

| 改动路径               | 必审人（CODEOWNER）             | 兜底人                        |
| ---------------------- | ------------------------------- | ----------------------------- |
| `adrs/`（ADR 文档）    | `@szjason72` 或 `@xiajason`     | `@zervi-genz`、`@szpeter2026` |
| `*.md`（其他文档）     | `@zervi-genz` 或 `@szpeter2026` | —                             |
| `.github/`（治理配置） | `@zervi-genz` 或 `@szpeter2026` | —                             |

执行细则：

1. 作者**不能**自己 approve 自己的 PR。
2. 改动落在多个路径时，**每条**路径上的 CODEOWNER 都要 review。
3. CODEOWNERS 配置见 [`.github/CODEOWNERS`](https://github.com/GenzLTD/docs/blob/main/.github/CODEOWNERS)。
4. **过渡说明** —— GenzLTD 当前为 Free plan，GitHub 不允许在私有仓强制 `require_code_owner_reviews`。升级到 Pro 或将本仓转 public 后，本节规则将由 GitHub 自动强制执行。在过渡期内，请每位 Maintainer **自觉遵守**上述评审流程；如发现未走评审的直推，请评论提醒或 revert。

## 文档索引

| 文档                                                                                 | 内容                                                                          | 状态                                                                                |
| ------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| [聚焦决策-Career-Cosmos-90天.md](聚焦决策-Career-Cosmos-90天.md)                     | 团队聚焦决策：一条主线（Career Cosmos 矩阵为融资服务）+ 90 天硬动作           | 已决策；第 4 条 Proposed 读法见 [ADR-0010](adrs/0010-cn-wechat-pay-three-client-ops.md)；dsh-bridle 冻结见 [ADR-0011](adrs/0011-dsh-bridle-freeze-career-cosmos.md) |
| [聚焦决策-Career-Cosmos-90天-调研建议.md](聚焦决策-Career-Cosmos-90天-调研建议.md)   | 对 90 天聚焦决策的外部调研、风险判断和执行重排建议                            | 评审建议                                                                            |
| [90天主线作战清单.md](90天主线作战清单.md)                                          | 90 天聚焦决策的执行层展开：5 硬动作看板 + 技术欠债 P0-P3 + 资产真实状态 + SQLite/PG 待拍板 | 执行清单（v1，持续更新）                                                          |
| [信任层数据审计报告.md](信任层数据审计报告.md)                                        | 信任层数据审计：52 声明 + 78 证据的 9 项发现，结论「可信度计算未实现、签名未落地」 | 审计报告（2026-09-10）                                                          |

| [实证记录-诗词语料共识评价模型沙盘-20260909.md](实证记录-诗词语料共识评价模型沙盘-20260909.md) | 已归档诗词门户语料的资产回收：78,656 首中 12.2% 为"人际评价边"，验证同行共识/同侪评价可计算 —— 服务 T空间/Looma 差异化与 BP 素材 | 实证记录（Proposed，待评审）                                                        |
| [草稿-人际评价边立项-可信度验证设计输入-20260910.md](草稿-人际评价边立项-可信度验证设计输入-20260910.md) | 人际评价边立项的可信度验证**设计输入**（非立项决策）：跨 docs 真源/looma 契约/转录记忆三类线索清点 + 候选机制（共识双向对证、双伪匿名 ID、attestation 状态机、凭证权威锚定、验证池扩池、share_code 审计）+ 红线（几何层≠信任、防自证、匿名≠不可审计、图级脱敏缺口）+ 5 项待决问题 | 草稿（Draft，待 CODEOWNER 评审） |
| [ADR-0010-owner产品化评审意见-20260907.md](ADR-0010-owner产品化评审意见-20260907.md) | 三端支付作为统一现金流管道与商业期权的 Owner 评审意见                         | 评审建议                                                                            |
| [ADR-0010-团队配合事项-20260907.md](ADR-0010-团队配合事项-20260907.md)               | ADR-0010 落地所需商户、回调、三端演示配合；非 Accept 证据                     | Proposed 配套                                                                       |
| [访问与参与指南](访问与参与指南.md)                                                  | 成员访问仓库、使用 Codespaces、提交评审和运行维护知识库的入口说明             | 持续维护                                                                            |
| [新一代智能大脑架构设计.md](新一代智能大脑架构设计.md)                               | 八大设计决策 + 业界参考 + 与 DeepSeek Harness 差异化                          | v0.2 研讨稿；受 [ADR-0009](adrs/0009-trust-layer-over-world-model.md) Accepted 约束 |
| [新一代智能大脑-落地路线图.md](新一代智能大脑-落地路线图.md)                         | M0–M6 里程碑 + 验收标准                                                       | v0.1；承诺范围见 ADR-0009                                                           |
| [新一代智能大脑-信任层评审-20260907.md](新一代智能大脑-信任层评审-20260907.md)       | CI ≠ 大脑；近期做信任层，不做世界模型幻想                                     | 评审 / 已 Accept（ADR-0009）                                                        |
| [CATALOG.md](CATALOG.md)                                                             | 34 仓库血缘总索引（含 Wukong 隐藏主线）                                       | 持续更新                                                                            |
| [Wukong-lab-Schema同步对接规范.md](Wukong-lab-Schema同步对接规范.md)                 | Wukong(真源)→lab 的 Layer0/1/2 schema 同步规范 + promote 流程 + 脚本          | 可执行                                                                              |
| [Wukong-命名与归属对账表.md](Wukong-命名与归属对账表.md)                             | Wukong vs wukong-core vs lab 命名与归属对账（不合并/锁真源/负责人 szjason72） | 已拍板                                                                              |
| [72changes-Nazha语料盘点与决策.md](72changes-Nazha语料盘点与决策.md)                 | 72changes 与 RAG 主线 Nazha 差异盘点 + 归档决策（方案 A）                     | 已拍板                                                                              |
| [Nazha归口-ServBay承载方案.md](Nazha归口-ServBay承载方案.md)                           | Nazha 知识库归口的本机承载宿主：nazha.servbay.host → 127.0.0.1:5220（gfcc services/demopeter，launchd 托管） | 方案已钉死（2026-09-07）· 归口实证 + 检索回归黄金集见附录（2026-09-08）                            |
| [探针-真实简历验证-合规范围与设计输入-20260910.md](探针-真实简历验证-合规范围与设计输入-20260910.md) | **自述（简历）侧验证**的合规范围与设计输入（非立项决策；与两份评价边草稿互补）：缺口诊断（简历补「验证」不补「评价」；现有实现里自述恒为 `weak`，多跑简历边际收益为零）+ 交叉印证设计（S1–S4 来源分层 / 三态输出）+ 契约映射与已存在的 `evidence_type` 漂移（`resume`、`match_scan`、`match_consensus` 未入 enum）+ 合规四件套差距 + 6 项待决问题 | 探针（Proposed，待评审） |
| [终端角色分工-研讨稿-20260913.md](终端角色分工-研讨稿-20260913.md) | 生态的每个「终端」是**自治节点**而非功能模块：T1–T7 终端角色清单（含「书架」首次正式立项）+ 博客主「布道者/知音」闭环论证 + 按终端归口的分工口径（含 AI 协作方边界）+ 与 90 天**已决策**主线的张力（T1/T2/T4 在「归档/暂停」清单内，三条路径，建议 B 最小解冻）+ 8 项待决 | Proposed（待 CODEOWNER 评审） |
| [方案-个人知识库边缘车间-20260911.md](方案-个人知识库边缘车间-20260911.md) | Win 个人知识库车间：D 出料、C 热库、天翼只加工放行批次、E 只归档；关联 Nazha/DemoPeter/`genz-verify`；非 90 天产品、不复活 bridle | 方案（Proposed，§七已由 owner 拍板，Accept 范围见 PR #14 评论） |
| [genz-ltd子域命名与归属表-20260914.md](genz-ltd子域命名与归属表-20260914.md) | genz.ltd 全量子域映射（api/circle/app/edge）+ 海外边侧生态 = `edge.genz.ltd` 命名决策；落地 ADR-0007 映射表 checklist | Proposed（edge 命名已拍板，DNS 待落地） |

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
