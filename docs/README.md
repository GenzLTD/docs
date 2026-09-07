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

| 文档                                                                 | 内容                                                                 | 状态        |
| -------------------------------------------------------------------- | -------------------------------------------------------------------- | ----------- |
| [聚焦决策-Career-Cosmos-90天.md](聚焦决策-Career-Cosmos-90天.md)     | 团队聚焦决策：一条主线（Career Cosmos 矩阵为融资服务）+ 90 天硬动作   | 已决策      |
| [聚焦决策-Career-Cosmos-90天-调研建议.md](聚焦决策-Career-Cosmos-90天-调研建议.md) | 对 90 天聚焦决策的外部调研、风险判断和执行重排建议 | 评审建议 |
| [ADR-0010-owner产品化评审意见-20260907.md](ADR-0010-owner产品化评审意见-20260907.md) | 三端支付作为统一现金流管道与商业期权的 Owner 评审意见 | 评审建议 |
| [访问与参与指南](访问与参与指南.md)                                  | 成员访问仓库、使用 Codespaces、提交评审和运行维护知识库的入口说明    | 持续维护    |
| [新一代智能大脑架构设计.md](新一代智能大脑架构设计.md)               | 八大设计决策 + 业界参考 + 与 DeepSeek Harness 差异化                 | v0.2 研讨稿；受 [ADR-0009](adrs/0009-trust-layer-over-world-model.md) Accepted 约束 |
| [新一代智能大脑-落地路线图.md](新一代智能大脑-落地路线图.md)         | M0–M6 里程碑 + 验收标准                                              | v0.1；承诺范围见 ADR-0009 |
| [新一代智能大脑-信任层评审-20260907.md](新一代智能大脑-信任层评审-20260907.md) | CI ≠ 大脑；近期做信任层，不做世界模型幻想                    | 评审 / 已 Accept（ADR-0009） |
| [CATALOG.md](CATALOG.md)                                             | 34 仓库血缘总索引（含 Wukong 隐藏主线）                              | 持续更新    |
| [Wukong-lab-Schema同步对接规范.md](Wukong-lab-Schema同步对接规范.md) | Wukong(真源)→lab 的 Layer0/1/2 schema 同步规范 + promote 流程 + 脚本 | 可执行      |
| [Wukong-命名与归属对账表.md](Wukong-命名与归属对账表.md)             | Wukong vs wukong-core vs lab 命名与归属对账（不合并/锁真源/负责人 szjason72） | 已拍板      |
| [72changes-Nazha语料盘点与决策.md](72changes-Nazha语料盘点与决策.md) | 72changes 与 RAG 主线 Nazha 差异盘点 + 归档决策（方案 A）             | 已拍板      |

## 关联代码仓库

| 仓库                     | 定位                                         | 对应决策 |
| ------------------------ | -------------------------------------------- | -------- |
| `GenzLTD/wukong-core`    | 认知内核（Layer0/1/2 + 门控 + 认知偏差检测） | ②⑧       |
| `szpeter2026/cortex-mcp` | 记忆层（分层认知记忆）                       | ③⑦       |
| `GenzLTD/Wukong`         | 认知内核原生真源（跨境数据共识匹配平台）     | ② 参考   |
| `GenzLTD/72changes`      | RAG 知识库原生实现（Spring Boot）            | ③ 参考   |
| `GenzLTD/looma-zervi`    | 主 monorepo                                  | 主体     |

## 演进约定

- 本文库为**文档真源**，代码仓库的 docs/ 只放该组件自身的设计产物。
- 架构决策变更走 PR + 评审，保留完整历史追溯。
- 血缘关系、仓库索引的更新见 `CATALOG.md`。
