# 72changes 与 Nazha（RAG 主线）差异盘点与「复用 or 归档」决策清单

> 状态：**盘点报告 + 待拍板清单** · 维护人：8bt8rcrg95-coder（你）
> 日期：2026-09-06 · 对象：`GenzLTD/72changes`（你转入） vs `GenzLTD/Nazha`（线内 canonical）
> 数据来源：实拉两仓库只读审计 + Nazha `docs/lineage/*` 三份决策文档 + docs/CATALOG

---

## 〇、一句话结论

- **RAG 代码主线 = Nazha/DemoPeter（Python 单栈，在演进）**；72changes 是它**上游的旧 Java 实现 + 大语料**。
- 决定性事实：**72changes 的 ~2.5 万 MD 语料被 `.gitignore` 排除（`md_documents_collected/`），根本不在 git 里**，
  只存在于本地 `E:\72Changes\md_documents_collected`。这个仓**离了那台机器就是空壳**（仅 30 个 git 文件、12 个 .java）。
- 因此推荐方向：**社会性资产（大语料）值得"复用来料"，Java 实现不复活、"归档"其代码**。详见决策清单。

---

## 一、两个仓库横向对比（实测）

| 维度 | 72changes（你转入） | Nazha / DemoPeter |
|---|---|---|
| 定位 | 需求层 RAG 知识库 | 知识库/知识运营平台（演进中） |
| 技术栈 | **Java 17 · Spring Boot 3.3 · Spring AI · Chroma** | **Python 3.10 · Flask · SQLite · Chroma/pgvector** |
| 向量库 | Chroma（Docker 8000） | Chroma + pgvector（双持久化） |
| LLM | DeepSeek | DeepSeek / Ollama 双模式 |
| 语料现状 | **~2.5 万 MD / 327MB，git 外**（E:\ 本机） | `knowledge_base/documents/` + 外部 corpus 配置 |
| 代码规模 | 30 个 git 文件，12 个 .java | 9+ commits，持续提交（混合检索/MCP/持久化） |
| RAG 能力 | 文档加载 + 向量检索 + 问答 | 文档管道 + 混合检索 + RAG + Web 面板 + 报告 + MCP |
| 维护节奏 | 只 1 个 commit（first commit），停滞 | 活跃 |
| 生平 | 首 commit 后被 Nazha 吸收**思路+文档语料** | 吸收 Wukong(web/report/db) + 72changes(vector/rag) |

> 依据：
> - 72changes `.gitignore` 明确写：`md_documents_collected/`（语料约 2.5 万文件，可从 `E:\72Changes\...` 复制）。
> - Nazha `docs/lineage/WUKONG_RAG_DECISION.md` 三线结论：**停做双栈并行；新 RAG 只在 Nazha/DemoPeter 开发**；
>   DemoPeter 首 commit 只吸收了 72changes 的**文档语料（7 篇 MD）**，Java 实现未被迁入。
> - CATALOG 第七节校准：RAG 代码主线是 Nazha，不是 72changes；72changes 作 Java/Spring AI 历史样本保留只读。

---

## 二、差异盘点（逐项）

### 2.1 语料资产——72changes 独有、价值最大的一块
- 72changes 声称/引用 **~2.5 万 MD、327MB、约 58M 字符**语料库（`md_documents_collected/`）。
- 这份语料是**散落在各业务/知识来源的原始文档汇聚**，无论技术栈怎么选，它本身是可复用的内容资产。
- **弱点**：不在 git、不含版本信息、依赖 `E:\72Changes\` 单一来源，未纳入任何持久化管线。

### 2.2 代码实现——几乎完全被 Nazha 替代
- 72changes 的 RAG 三件套（VectorStore / RAGService / DocumentService）在 Nazha 有**等效且更进化的 Python 版**
  （`vector_store.py` / `rag_engine.py` / `doc_processor.py` + 混合检索/MCP）。
- 唯一 Nazha 尚未完整继承的：**Java/Spring AI 生态的 Q&A 服务形态**（REST `/api/rag/query`、文档管理 API）。
  → 这只适合"要一个 Spring 服务"的场景，而团队已明确不复活 Java 栈。

### 2.3 生态/血缘
- 三者（Wukong/72changes/Nazha）**无 git 血缘**，纠缠只在"工作区分工 + 设计吸收 + 人员环境"（Nazha lineage 原话）。
- 72changes 曾规划过接入 `zervi.test`（JobFirst）——**建议书仅存在于文档，代码零落地**。

### 2.4 与 lab-genz-brain-m2 的关系
- 72changes 与 lab **无直接代码依赖**：它既不消费 Layer0/1/2 schema，也不做跨境门控判定（已 grep 源码验证）。
- 两者分属两条线：72changes/Nazha = RAG/知识运营；lab = 跨境数据判定。互不阻塞。

---

## 三、决策清单（供 org owner 拍板 + 你执行）

> 推荐合并为**方案 C**（复用内容、归档代码），既守住内容资产又避免维护两条栈。

| 方案 | 动作 | 收益 | 代价/风险 | 推荐度 |
|---|---|---|---|---|
| **A · 完全归档** | 加 `ARCHIVED` 标记/降权，只读，语料不管 | 最省事 | 2.5 万 MD 内容资产可能丢失；Nazha 无同源大语料 | ⭐⭐ |
| **B · 完全复用/续工** | 恢复 72changes Java 继续开发 | 保留 Spring Q&A 形态 | ①违背 Nazha lineage 已定结论 ②需复活 Java 环境 ③与 lab/Wukong 线割裂 | ⭐ |
| **C · 复用来料 + 归档代码（推荐）** | ①把 `E:\72Changes\md_documents_collected` 语料**纳入 Nazha 语料管线**（`import_corpus.py`）；②72changes 代码仓标记 ARCHIVED 只读，不再开发 | 内容资产保值且进主线；代码不再双栈维护 | 需一次语料迁移/去重；Nazha 需加索引容量评估 | ⭐⭐⭐⭐⭐ |
| **D · 仅留档** | 语料长期存 NAS/冷备，不进 Nazha | 内容不丢但不增值 | 要决定冷备位置；Nazha 短期缺大语料 | ⭐⭐⭐ |

### 执行 checklist（选 C 时）
- [ ] 盘点 `E:\72Changes\md_documents_collected` 实际文件数/大小/格式分布（write 清单）。
- [ ] 抽样几份进 Nazha `scripts/import_corpus.py` 试跑，验证分块与向量质量。
- [ ] 定去重策略（与 Nazha 现 knowledge_base 文件 Jaccard 兜底，参考 CATALOG 的 hash 比对法）。
- [ ] 全量导入 + 重跑 `tests/test_hybrid_search.py` / 持久化验证。
- [ ] 72changes 仓加 `archived` topic + README 顶部 banner 说明"代码已归档，语料已并入 Nazha"。
- [ ] 在 Nazha `docs/lineage/` 补一笔"语料接管"记录，更新 CATALOG。

### 不许做的事（红线）
- ❌ 新建「72changes-2026 / Wukong 2.0」GitHub 仓。
- ❌ 恢复 Wukong + 72changes 双栈日常开发。
- ❌ 把 72changes 默认并入 jakfirst/JobFirst 部署拓扑（无独立 ADR 前）。

---

## 四、责任人

- **盘点/决策建议**：8bt8rcrg95-coder（你）——你是 72changes 转入方 + 该线未来负责点。
- **拍板**：org owner（`zervi-genz` / `szpeter2026`）——方案 A/B/C/D 二选一。
- **语料/数据确认**：szhen 环境（`E:\72Changes\`，Windows 本机维护者）。

## Links

- [72changes 仓库](https://github.com/GenzLTD/72changes)
- [Nazha 仓库](https://github.com/GenzLTD/Nazha)
- 三线决策：[Nazha docs/lineage/WUKONG_RAG_DECISION.md](https://github.com/GenzLTD/Nazha/tree/main/docs/lineage)（`GenzLTD/Nazha/docs/lineage/`）
- 契约参考：[docs/CATALOG.md](./CATALOG.md)（第七节 Wukong 血缘）