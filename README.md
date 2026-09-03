# GenLTD 架构知识库

> 团队架构设计的单一真源（single source of truth），供全体成员研讨、评审、追溯演进。

## 文档索引

| 文档 | 内容 | 状态 |
|---|---|---|
| [新一代智能大脑架构设计.md](新一代智能大脑架构设计.md) | 八大设计决策 + 业界参考 + 与 DeepSeek Harness 差异化 | v0.2 研讨稿 |
| [新一代智能大脑-落地路线图.md](新一代智能大脑-落地路线图.md) | M0–M6 里程碑 + 验收标准 | v0.1 |
| [CATALOG.md](CATALOG.md) | 34 仓库血缘总索引（含 Wukong 隐藏主线） | 持续更新 |

## 关联代码仓库

| 仓库 | 定位 | 对应决策 |
|---|---|---|
| `GenzLTD/wukong-core` | 认知内核（Layer0/1/2 + 门控 + 认知偏差检测） | ②⑧ |
| `szpeter2026/cortex-mcp` | 记忆层（分层认知记忆） | ③⑦ |
| `GenzLTD/Wukong` | 认知内核原生真源（跨境数据共识匹配平台） | ② 参考 |
| `GenzLTD/72changes` | RAG 知识库原生实现（Spring Boot） | ③ 参考 |
| `GenzLTD/looma-zervi` | 主 monorepo | 主体 |

## 演进约定

- 本文库为**文档真源**，代码仓库的 docs/ 只放该组件自身的设计产物。
- 架构决策变更走 PR + 评审，保留完整历史追溯。
- 血缘关系、仓库索引的更新见 `CATALOG.md`。
