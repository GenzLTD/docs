# GenzLTDbackup 仓库总索引（CATALOG）

> 生成时间：2026-09-02
> 扫描范围：`D:/servbay-win-kit/GenzLTDbackup/` 下 34 个 git 仓库
> 方法：逐仓库提取 remote / 技术栈 / 文件数 + 两两 Jaccard 相似度 + 逐文件 hash 比对（雷同簇）
> 文件数口径：剔除依赖目录（node_modules / .git / dist / .next 等）与二进制后的有效文件数

---

## 一、总览

| 项 | 数量 |
|---|---|
| 仓库总数 | 34 |
| GitHub 组织 | 2 个：`szpeter2026`（个人，9 仓）+ `GenzLTD`（公司，25 仓） |
| 主线（active） | 4 |
| 共识网络产品线（需合并） | 4（Iamgeek + kung-fu 三件套） |
| 文档 / 实验大杂烩（归档） | 2（Genzltd + zervi.test） |
| 历史血缘（只读归档） | 24 |

---

## 二、主线（active，继续维护）

| 仓库 | 定位 | 技术栈 | 文件 | 组织 | 关系 |
|---|---|---|---|---|---|
| looma-zervi | 主 monorepo：T 空间（B2B HR SaaS）+ PlaneX（C 端）+ Looma（底座） | node + python(uv) | 658 | GenzLTD | 唯一主仓 |
| PlanetX | C 端游戏化职业探索 | node | 131 | szpeter2026 | C 端产品 |
| steedar | looma-zervi 的**海外白标快照**（GitHub→Vultr 部署，默认 steedar.db） | node + python | 507 | szpeter2026 | looma-zervi 派生快照 |
| planex-miniprogram | PlaneX 微信小程序 | — | 30 | szpeter2026 | PlanetX 小程序端 |

---

## 三、共识网络产品线（P0，需合并）

> 四个仓库是同一产品「共识网络 · 超级个体身份主权社区」的不同阶段/分支，README 高度同源。

| 仓库 | 定位 | 技术栈 | 文件 | 组织 | 与主线差异 |
|---|---|---|---|---|---|
| Iamgeek | **全栈完整版**：backend + frontend + admin + 大量过程文档 | — | 347 | GenzLTD | 血缘源头，唯一含后端 |
| kung-fu | Next.js 前端，**最全**（含关注/邀请码/个人主页） | node | 116 | GenzLTD | 前端主线（候选唯一保留） |
| kung-fu-2026 | 同上前端，2026 版快照 | node | 102 | GenzLTD | 缺关注/邀请码等，居中 |
| kungfu | 同上前端，精简版 | node | 96 | GenzLTD | 最精简，独有 middleware.ts |

- 三件套逐文件 hash 对比：Jaccard 0.81~0.92，README 一字不差。
- **处置**：以 kung-fu 为基线，diff 吸收 kung-fu-2026 与 kungfu 的独有文件；Iamgeek 的后端作为独立遗产归档保留。

---

## 四、文档 / 实验大杂烩（P0，归档）

| 仓库 | 定位 | 文件 | 组织 | 处置 |
|---|---|---|---|---|
| Genzltd | AI 身份 / 阿里云 / 区块链等上百篇分析报告 + SQL + 目录堆 | 4960 | GenzLTD | 只读归档，非代码库 |
| zervi.test | zervi 实验场：含 go-zervi 子目录 + 6 套 docker-compose + 数十个 .ps1 脚本 + 报告 | 2492 | GenzLTD | 只读归档，拆出有效子项目 |
| zervi-test | zervi.test 的 Java 整理迁移版（Spring Cloud 微服务，218 文件 11 服务） | java | — | szpeter2026 | **反面教材**：central-brain 实为网关+服务治理（非智能大脑），WorkflowEngine 假实现（sleep+return true）；仅 `WorkflowStep` 的 cloud+service 二元定位思想可借鉴（呼应决策⑤⑥） |

---

## 五、历史血缘（只读归档）

### 5.1 Go / zervi 后端线

| 仓库 | 定位 | 技术栈 | 文件 | 组织 | 关系 |
|---|---|---|---|---|---|
| go-zervi | Go-Zervi 框架 / Zervigo MVP | go | 710 | GenzLTD | 分支 feature/oauth2-provider |
| looma | Looma Go 微服务重构（单体 gRPC 拆微服务） | go | 371 | GenzLTD | looma-zervi 底座前身 |
| zervi-rust | zervi 的 Rust 实现 | rust | 152 | GenzLTD | 实验性 |

### 5.2 鸿蒙 IoT 线

| 仓库 | 定位 | 技术栈 | 文件 | 组织 | 关系 |
|---|---|---|---|---|---|
| Ctrl4U | 鸿蒙骑行智能操控（指环 + App） | ArkTS + python | 116 | szpeter2026 | smartOS→Ctrl4U 血缘 |
| smartOS | BC4 Pro 光感智能窗帘控制系统 | — | 56 | GenzLTD | Ctrl4U 血缘上游 |
| YeDall3.0.1 | AI-Native IoT 平台（架构设计阶段） | — | 431 | GenzLTD | YEDALL LIMITED 线 |
| ImartOS-Innox-camp-Deliverables | ImartOS 营期交付物 | — | 8 | GenzLTD | 比赛交付 |
| ImartOS-Innox-camp-Demo | ImartOS 营期演示 | — | 4 | GenzLTD | 比赛演示 |

### 5.3 AI 求职线

| 仓库 | 定位 | 技术栈 | 文件 | 组织 | 关系 |
|---|---|---|---|---|---|
| Tatha | AI 求职匹配 + 社区治理（FastAPI 后端） | python | 74 | GenzLTD | 后端 |
| tatha-frontend | Tatha 前端（静态） | — | 6 | GenzLTD | Tatha 前端 |

### 5.4 前端 / 门户线

| 仓库 | 定位 | 技术栈 | 文件 | 组织 | 关系 |
|---|---|---|---|---|---|
| genz-web | genz.ltd Stripe 审核站（PlanetX 产品，release/overseas 分支） | Vite + React | 28 | szpeter2026 | PlanetX 海外官网 |
| szbolent-portal | www.szbolent.cn 智能化诗词门户 | Vue3 SPA | 111 | szpeter2026 | 诗词门户主线 |
| szbolent-frontend | Vue3 + Vite 模板（README 仍为脚手架默认） | Vue3 | 63 | GenzLTD | portal 前身/模板 |
| poetries-of-bolent | Bolent 诗词战略 / 溯源文档仓（无业务代码） | — | 4 | GenzLTD | 战略文档 |
| Poetry-modown | Modown 主题 + Lyanna 个人主页 + ErphpDown | WordPress | 60 | GenzLTD | 诗词下载站 |

### 5.5 社区 / 合约线

| 仓库 | 定位 | 技术栈 | 文件 | 组织 | 关系 |
|---|---|---|---|---|---|
| gfcc | 格契 GFCC：社区共同体牵引力层（契约/价值/端口） | — | 331 | GenzLTD | 独立产品 |
| genzer-contracts | Genzer 社区智能合约 MVP（Phase 1） | — | 18 | GenzLTD | 合约 |

### 5.6 早期项目 / 其他

| 仓库 | 定位 | 技术栈 | 文件 | 组织 | 关系 |
|---|---|---|---|---|---|
| DemoPPI | 共识网络 + 社区自治（Next.js 14 + Supabase） | node | 159 | szpeter2026 | 共识网络早期雏形 |
| DemoPeter | Flask + ChromaDB RAG 知识库 | python | 88 | szpeter2026 | 早期 RAG 实验 |
| progressive-professional-identity | PPI 渐进式专业身份 MVP 战略仓 | — | 4 | GenzLTD | 战略文档 |
| guibu | 不积硅步 / 可审计微步 | python | 13 | szpeter2026 | 独立小工具 |
| jobfirst-future | Zervigo Future 微服务 CI/CD 部署套件（阿里云 47.115.168.107） | — | 418 | GenzLTD | 部署套件 |
| TimesSquare | GoZervi 知识库管理系统 | — | 48 | GenzLTD | 知识库 |
| nextjs-with-supabase | Supabase 脚手架模板（DemoPPI 模板源） | node | 51 | GenzLTD | 模板，非业务 |

---

## 六、血缘关系（文字版）

```
Wukong 血缘（隐藏主线）：
  Wukong 工作区（跨境数据共识匹配平台 + 72changes RAG + data 运维）
    ├→ DemoPeter（个人知识库，吸收 Wukong 精华）
    ├→ YeDall3.0.1 / zervi-looma（Rust 门控，对齐 Layer0/1/2）
    └→ 共识网络 kung-fu / Iamgeek（Layer0/1/2 概念继承）

共识网络产品线：
  DemoPPI（早期雏形）→ Iamgeek（全栈完整版）→ kung-fu（前端主线）
                                          ├→ kung-fu-2026（分支）
                                          └→ kungfu（精简分支）

Looma / zervi 产品线：
  go-zervi / looma（Go 底座）→ looma-zervi（主 monorepo）
                             ├→ steedar（海外白标快照）
                             ├→ PlanetX（C 端）
                             └→ planex-miniprogram（小程序）
  zervi-rust / zervi.test（实验性 / 实验场）

鸿蒙 IoT 产品线：
  smartOS → Ctrl4U（骑行操控）
  YeDall3.0.1（AI-Native IoT，YEDALL LIMITED）

诗词 / 门户产品线：
  poetries-of-bolent（战略）→ szbolent-portal（Vue3 门户）← szbolent-frontend（模板前身）
  Poetry-modown（WordPress 下载站）
```

---

## 七、Wukong 血缘（隐藏主线，重要补充）

> 34 个仓库里**没有**名为 Wukong 的独立仓库，但 Wukong 作为「跨境数据共识匹配平台」是这套体系的**技术源头**，其影子以 schema 资产、代码注释、文档提及的形式，散布在至少 4 个仓库中。

### 残留形态清单

| 残留形态 | 位置 | 内容 |
|---|---|---|
| schema 真源资产 | `YeDall3.0.1/backend/crates/zervi-looma/assets/` | layer0/1/2 JSON + policy_rules.yaml，作者 "Wukong Project" |
| Rust 重实现 | `YeDall3.0.1/backend/crates/zervi-looma/src/` | 数据门控语义层，注释「Wukong 赋能」，共识度算法移植自 Wukong `backup_analyzer.py` |
| 72changes 文档（7 篇） | `DemoPeter` 与 `gfcc/services/demopeter` 的 `knowledge_base/documents/md/72changes/` | Spring Boot + Spring AI RAG 知识库完整功能文档（**无源码**） |
| 架构 / 来源提及 | `gfcc/services/demopeter/docs/架构设计.md`、`README.md` | Wukong 定位 + DemoPeter 模块吸收来源对照 |

### Wukong 工作区三子项目

- **Wukong** — 多源元数据管理、schema 映射、工具链（ai_sql / metadata / web_dashboard / report_gen）
- **72changes**（七十二变）— RAG 知识库，Spring Boot 3.3 + Spring AI + Chroma
- **data/** — 多数据库统一运维、Web 看板

### Layer0/1/2 共识 schema

`schema` 命名空间 `https://wukong.zervi.io/schemas/`，由 **103 数据源**衍生：
- Layer0 = 身份（identity）→ Layer1 = 兴趣（interest）→ Layer2 = 档案（profile）

与 kung-fu / Iamgeek 共识网络的「Layer0 公开人格 / Layer1 兴趣图谱 / Layer2 深度档案」是**同一概念体系**。

### 缺失（原件不在本备份）

- Wukong 的 Python 源码（`backup_analyzer.py` 等）
- 72changes 的 Spring Boot 源码（`.java` / `pom.xml`）
- data 子项目

> 结论：**只能从「schema 资产 + 文档 + Rust 重实现」重建规格，无法还原可运行源码。**

---

## 八、处置建议汇总（优先级）

| 优先级 | 动作 | 对象 |
|---|---|---|
| P0 | 三（四）合一：diff 吸收独有文件后归档其余 | kung-fu / kung-fu-2026 / kungfu（+ Iamgeek 后端遗产） |
| P0 | 只读归档（不删 .git） | Genzltd、zervi.test |
| P1 | 蒸馏 Wukong + 72changes：抽取 schema 资产与文档，重建 Wukong 工作区规格 | 见「七、Wukong 血缘」 |
| P1 | 只读归档 | 第五节全部历史血缘仓 |
| P1 | 标注关系（不动作，仅登记） | steedar（looma-zervi 快照）、nextjs-with-supabase（模板） |
| P2 | 建立持续扫描脚本，新仓 clone 后自动比对 | 全目录（脚本见工作区 `distill_scan.py`） |

---

*本索引为只读产物，未对任何仓库执行删除/移动/合并操作。*
