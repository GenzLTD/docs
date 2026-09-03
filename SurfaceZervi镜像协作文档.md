# SurfaceZervi 本地镜像协作文档

> 致 Mac 维护者（jason / MacBook）· 请配合完成以下数据整理任务
> 日期：2026-09-04 · 发起：GenLTD 仓库血缘梳理

---

## 一、背景（为什么需要这些数据）

我们在梳理 GenLTD 仓库血缘时，发现 **Wukong（跨境数据共识匹配平台）** 的完整数据不在 GitHub 上，而在 Mac 上的 **SurfaceZervi 本地镜像**里。

GitHub 上的 `GenzLTD/Wukong` 是快照，缺失了两样关键东西：
1. **`db/backups/` 的完整多库备份** —— GitHub 上只有 1 个 mysql 视图备份，但 Wukong 的 `backup_analyzer.py` 设计是扫描 8 类数据库（mysql/postgresql/mongodb/neo4j/sqlite/redis/elasticsearch/weaviate）的完整备份。
2. **Fossil 仓库文件（`.fossil`）** —— Wukong 原始用 Fossil 版本控制，GitHub 上只有 git 快照，缺失完整版本历史。

这两样是 Wukong「103 数据源 · 7799 字段」认知本体的**原始数据来源**，对认知内核（wukong-core）落地有直接价值。

---

## 二、需要配合的任务

### 任务 1：定位 SurfaceZervi 目录

请确认 SurfaceZervi 本地镜像的完整路径，预期结构类似：

```
SurfaceZervi/
├── Wukong-main/          # Wukong 的 Fossil 导出快照
└── 72changes-main/       # 72changes 的独立顶层目录
```

- 线索：曾在 `c:\Users\szben\CodeBuddy\Wukong`（Windows）对应到 Mac 路径。
- 请列出 `SurfaceZervi/` 下的**完整目录树**（`find SurfaceZervi -maxdepth 3` 输出）。

### 任务 2：打包 db/backups/ 完整备份（最高优先级）

请确认 `SurfaceZervi/Wukong-main/db/backups/` 下有哪些数据库类型的**实际备份文件**：

```bash
ls -R SurfaceZervi/Wukong-main/db/backups/ | head -100
```

重点确认：mysql / postgresql / mongodb / neo4j / sqlite 各类型是否都有完整备份文件（不只是目录）。

- 若备份体积大，可只打包 **mysql + postgresql + mongodb + neo4j + sqlite** 五类，其余（redis/elasticsearch/weaviate/docker）可后续再说。

### 任务 3：找 Fossil 仓库文件

请确认 Wukong 是否有 `.fossil` 仓库文件：

```bash
find SurfaceZervi -name "*.fossil" -o -name "*.fossil-repo"
```

若有，请一并打包（这是 Wukong 的完整版本历史）。

### 任务 4：确认 72changes-main 是否有 GitHub 外的文件

GitHub 上 `GenzLTD/72changes` 是完整 Spring Boot 源码（12 个 .java + pom.xml）。请确认 `SurfaceZervi/72changes-main/` 是否有 GitHub 快照里**没有**的文件（如语料库 `md_documents_collected/`、模型文件 `.onnx` 等大文件）：

```bash
ls -la SurfaceZervi/72changes-main/
```

### 任务 5：整体打包

将上述内容打包成一个 tar.gz：

```bash
tar -czf SurfaceZervi-export-$(date +%Y%m%d).tar.gz \
  SurfaceZervi/Wukong-main/db/backups/ \
  SurfaceZervi/Wukong-main/db/wukong_metadata.db \
  $(find SurfaceZervi -name "*.fossil") \
  SurfaceZervi/72changes-main/
```

> 若备份体积过大（>10GB），请先只做任务 2 的五类备份 + 任务 3 的 .fossil，并告知总大小。

---

## 三、交付方式

1. 打包后，将文件上传到**网盘（百度/阿里云盘）**并分享链接，或
2. 通过其他已约定的通道（如 agent-mail 附件、直连传输）发送。

请一并回复：
- 打包文件的总大小
- `db/backups/` 里实际有哪些数据库类型、各多大
- 是否有 `.fossil` 文件

---

## 四、接收后我们会做什么

- 用 `backup_analyzer.py` 解析完整备份，重建 103 源元数据。
- 对照 Layer0/1/2 schema，为认知内核（wukong-core）补齐真实数据。
- Fossil 历史若在，补全 Wukong 的版本演进记录。

*有任何疑问（目录找不到、体积过大、格式不确定），先拍照/列目录发回来，不必硬传。*

---

## 五、Mac 侧回执（jason，2026-09-04）

> 结论先行：**本任务要找的数据不在 `SurfaceZervi/` 里，而在 `~/Documents/Wukong-Backup/`**（2026-05-18 从原 Wukong U 盘 `/Volumes/Wukong/` 完整镜像到本机）。`SurfaceZervi/Wukong-main` 与 GitHub 快照逐文件一致、无增量；真实资产比预想更全：**`Wukong.fossil`（808MB，含完整提交历史）已被找到**。交付已按下方清单打包至 szpeter 移动 U 盘。

### 1. 任务逐项回复

| 任务 | 结果 |
|---|---|
| 1. 定位 SurfaceZervi | `/Users/jason/SurfaceZervi/`，含 `Wukong-main/`（18 项）与 `72changes-main/`；目录树见回执附件 `tree.txt` |
| 2. db/backups 完整备份 | **`SurfaceZervi/Wukong-main/db/backups/` 仅有 1 个 mysql 视图备份**（`looma_crm_views_backup_20260302_132138.sql`，GitHub 已有）。真实完整备份在 `~/Documents/Wukong-Backup/data/`（见下节） |
| 3. .fossil 仓库文件 | **找到：`~/Documents/Wukong-Backup/Wukong.fossil` = 808MB**（含完整提交历史）。SurfaceZervi 全程无 `.fossil`，仅 `Wukong-main/.fossil-settings/ignore-glob` 证明其曾为 Fossil checkout |
| 4. 72changes GitHub 外文件 | **无**：`SurfaceZervi/72changes-main` 与 `GenzLTD/72changes` 逐文件一致（仅 GH 多 `._.DS_Store` 一个垃圾）。无 `md_documents_collected/`、无 `.onnx` 模型 |
| 5. 打包 | 核心集已打 `Wukong-export-20260904.tar`（sha256 见下），存入 szpeter U 盘 `/Volumes/szpeter/` |

### 2. 真实备份位置与规模（`~/Documents/Wukong-Backup/data/`，合计约 1.8GB）

覆盖 **8 类数据库 + 多轮**（backup_logs 显示备份原输出于旧机 `/Users/szjason72/*_backups/`，已随 U 盘镜像迁入本目录）：

| 类型 | 目录 | 规模 | 轮次 |
|---|---|---|---|
| MySQL 全量 | `data/mysql/` | ~530M / 701 文件 | 2026-03-03 多次全量（`all_databases_20260303_*.sql.gz` + 单库） |
| MySQL | `data/mysql_backups/` | ~25M / 63 文件 | 2026-03-02（与 backup_logs 对应） |
| MongoDB | `data/mongodb/` | ~304M / 736 文件 | mongodump 目录式 |
| Neo4j | `data/neo4j/` | ~517M / 107 文件 | 数据目录 |
| PostgreSQL | `data/postgres/` | ~39M / 973 文件 | + `postgres_backups/` 412K（dump） |
| SQLite | `data/sqlite_backups/` | ~5.1M / 26 文件 | 2026-03-02 |
| Docker 混合 | `data/docker_backups/` | ~84M / 7 文件 | + `data/backups/` 115M（03-03 轮 docker/es/h2/memcached/mongo/mysql…） |
| 迁移 | `data/migration_backups/` | ~126M | |
| Redis/ES/Weaviate/H2/Memcached | `data/redis|elasticsearch|weaviate|h2|memcached/` | <1M | |
| 元数据库 | `db/wukong_metadata.db` | 1.0M | **2026-03-17 版（比 GitHub 03-10 版新）** |

> 注：`SurfaceZervi/Wukong-main/db/defaultsqlserver` 是指向 `C:/ServBay/db/mysql` 的死链接（Windows 路径残留），非实际数据。

### 3. 交付包（szpeter U 盘 `/Volumes/szpeter/Wukong-export-20260904.tar`）

包内结构（解压即得 `Wukong-export-20260904/`）：
```
Wukong-export-20260904/
├── Wukong.fossil          # 808MB，完整 Fossil 提交历史
├── wukong_metadata.db     # 1.0MB，03-17 最新元数据库
├── data/                  # 1.8GB，8 类多库备份全集
├── 72changes/             # 子项目源码（与 GitHub 一致，留档）
└── ASSET-INVENTORY.md     # 资产清单说明
```
- 总大小 **2,773,711,872 字节（约 2.58 GiB）**（数据主体已为 .gz/.dump/tar.gz 自带压缩，故未二次 gzip，`backup_analyzer.py` 支持直接解析）
- sha256：**`a537b56f35691e937ce678b36e72340b88be4106f647d0a569c46a350cf9b466`**（校验文件 `Wukong-export-20260904.tar.sha256` 同目录）

### 4. 给接收方的建议

- `backup_analyzer.py` 扫描 `db/backups/` 的 8 类子目录约定 → 用 `data/` 全量即可覆盖 103 源（MySQL 61/SQLite 25/MongoDB 7/PG 3/Neo4j 1 与元数据库规模吻合）。
- Fossil 历史在 `Wukong.fossil`，`fossil open` 或 `fossil clone` 本地副本即可还原版本演进。
- 如需查看 `data/mysql/`（03-03 全量轮）与 `data/mysql_backups/`（03-02 轮）两份差异：后者与 `Wukong-main/db/backup_logs/latest/mysql.log` 逐库对应。
