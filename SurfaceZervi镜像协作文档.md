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
