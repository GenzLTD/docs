# Nazha 归口 · 本机 ServBay 承载方案

> 状态：**方案已钉死（2026-09-07）· 只文档化、不铺常驻** · 决策：org owner（szpeter2026）
> 更新（2026-09-08）：首笔主线归口实证 `GenzLTD/Nazha 095efc5`（agent_memory 语料）回应「归口＝本地跑测试」质疑；§五第 1 项转「已实证」。详见文末附录。
> 对象：Nazha/DemoPeter 知识库归口的**本机承载宿主**，先于「归口流程/语料源/审核」三件事落地
> 前文关联：[72changes-Nazha语料盘点与决策.md](./72changes-Nazha语料盘点与决策.md)（语料侧，方案 A 已拍板）

---

## 〇、一句话结论

- **归口不是「本地跑一次测试」**：语料要进知识库并持续可检索，就必须先有一个能长住的宿主。
- 经 2026-09-07 实地核查：**本机 ServBay 能撑 Nazha 系服务，且现成宿主树已存在**——
  `~/Projects/gfcc/services/demopeter`（内嵌于 gfcc 仓、默认端口 **5220**、`.venv` 为 Python 3.13.13，
  与 ServBay 自带 python 同版本；`db/szpeter2026.db` 116MB + `chroma_data/` + `knowledge_base/` 数据齐全）。
- **决定**：域名新增 `nazha.servbay.host → 127.0.0.1:5220`，走现成 `deploy-servbay-sites.sh` 机制；
  Flask 进程用 **launchd 用户级托管**（替代临时 nohup）；数据/语料全部留在 gfcc 树内随仓演进与云上对齐。

---

## 一、为什么先解决「承载」而不是直接谈归口

上一轮提出「归口形态 / 归口源 / 审核人」三件事，被正确质疑为像是在安排「本地跑测试」。
本质缺口是：**这台 Mac 上当时没有任何 Nazha 活实例**（:5200/:5220 均无监听、原记忆路径 `services/`
为空）。先于流程拍板的，应是「归口成果最终住在哪、由谁常驻」。本文档即钉死该承载。

---

## 二、实测基线（2026-09-07，只读核查）

### 2.1 ServBay 侧 —— 反代与运行时均齐备

| 项 | 实测 |
|---|---|
| 安装 | `/Applications/ServBay` 存在，nginx vhosts 9 站 |
| 运行时 | 自带 `python 3.13.13` / nginx / postgresql / mysql / node / ollama |
| 反代模式 | 全部 vhost = `server_name → proxy_pass http://127.0.0.1:<端口>` |
| 证书 | ServBay 用户 CA 签发，`ssl/private/tls-certs/<域名>/` |
| 生成机制 | `~/THOMAS/scripts/deploy-servbay-sites.sh`：签发证书 + 写 vhost + `nginx -t` + reload |

现有站点：`api.servbay.host→5200`(Looma)、`gfcc.servbay.host→5211`、`planetx→5173`、`tspace→5174`、
`ppi→3000`、`portal→5175`、`ollama→11434`、`circle.genz.ltd→5211`、`servbay.host`(静态)。

> 注意：ServBay GUI 若「保存全部站点」可能覆盖 `vhosts/*.conf`，重跑上述脚本即可恢复（脚本注释已声明）。

### 2.2 Nazha/DemoPeter 侧 —— 宿主树已存在，无需从零

| 项 | 实测 |
|---|---|
| 本机活体树 | `~/Projects/gfcc/services/demopeter`（**随 gfcc 仓分发**，非独立 git 仓） |
| Web 入口 | `static/src/web_dashboard.py`，`config/settings.py` `WEB_PORT` 默认 **5220** |
| 启动 | `.venv/bin/python static/src/web_dashboard.py`（README/本机实测入口，默认绑定 127.0.0.1:5220） |
| 数据 | `db/szpeter2026.db`（116M）、`db/chroma_data/`（persistent 向量）、`knowledge_base/` |
| 语料分类 | `knowledge_base/documents/md/{postmortems, 72changes, cursor_import_guide, 项目介绍}` |
| 导入管线 | `scripts/import_docs.py` / `import_corpus.py` / `query.py` 均在树内 |
| 云上对照 | 同树部署于天翼 `/data/gfcc` = `gfcc-demopeter`（:5220 带认证，健康 401 属预期） |

### 2.3 与 GenzLTD/Nazha 仓库的关系（防混淆）

- `GenzLTD/Nazha` = GitHub 私有仓，**代码主线**，默认 `WEB_PORT=5200`（Linux/Windows 通用演进态）。
- 本机/天翼 `gfcc/services/demopeter` = DemoPeter 同源部署树，默认 `5220`，内嵌在 gfcc 仓中随部署对齐。
- **本机 5200 已被 Looma 占用**，故即便跑独立 Nazha 仓也需改端口；采用现成 5220 树是零成本路径。
- 归口语料写入 `knowledge_base/documents/md/` 四类子目录后由导入脚本进库，两类树共用同一语料契约。

---

## 三、承载方案（钉死）

### 3.1 端口分配

| 端口 | 用途 | 现状 |
|---|---|---|
| 5200 | Looma（api.servbay.host） | 已被占，Nazha 不用 |
| 5211 | gfcc kernel（gfcc.servbay.host） | 已被占 |
| **5220** | **Nazha/DemoPeter Web 面板** | **空，待恢复**（config 默认即 5220） |

### 3.2 域名与反代（走现成脚本，不手写 vhost）

在 `~/THOMAS/scripts/deploy-servbay-sites.sh` 的 `SITES` 数组追加一行：

```bash
  "nazha.servbay.host|5220|Nazha KB"
```

然后执行：

```bash
bash /Users/jason/THOMAS/scripts/deploy-servbay-sites.sh
```

效果：签发 `nazha.servbay.host` 证书 → 写 vhost（80→301 https，443 ssl 反代 5220）→ `nginx -t` → reload。
ServBay App「网站」列表不显示该项属正常（未写 GUI 数据库，与现有 9 站同待遇）。

### 3.3 进程托管（launchd 用户级，替代 nohup）

新建 `~/Library/LaunchAgents/com.genzltd.nazha.plist`（模板）：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>com.genzltd.nazha</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/jason/Projects/gfcc/services/demopeter/.venv/bin/python</string>
        <string>/Users/jason/Projects/gfcc/services/demopeter/static/src/web_dashboard.py</string>
    </array>
    <key>WorkingDirectory</key><string>/Users/jason/Projects/gfcc/services/demopeter</string>
    <key>RunAtLoad</key><true/>
    <key>KeepAlive</key><true/>
    <key>StandardOutPath</key><string>/Users/jason/Projects/gfcc/services/demopeter/logs/nazha.launchd.out.log</string>
    <key>StandardErrorPath</key><string>/Users/jason/Projects/gfcc/services/demopeter/logs/nazha.launchd.err.log</string>
</dict>
</plist>
```

控制命令：

```bash
launchctl load -w ~/Library/LaunchAgents/com.genzltd.nazha.plist   # 启动
launchctl unload -w ~/Library/LaunchAgents/com.genzltd.nazha.plist # 停止
launchctl list | grep nazha                                        # 状态
```

> 生效前提：树内 `.venv` 已有依赖（现成）、`static/src/web_dashboard.py` 可直接启动、日志目录存在。

### 3.4 数据与归口流（保持树内，不另起炉灶）

```
浏览器 → https://nazha.servbay.host → ServBay nginx :443 → 127.0.0.1:5220
        → Flask web_dashboard → SQLite(db/szpeter2026.db) + Chroma persistent(db/chroma_data)

归口写入：~/Projects/gfcc/services/demopeter/knowledge_base/documents/md/
          {postmortems, runbooks, decisions, onboarding}/xxx.md
归口入库：scripts/import_docs.py（或 import_corpus.py），随后 query.py 验证可检索
```

---

## 四、验收口径（方案就绪后执行，非本阶段）

```bash
# 1. 本机服务
curl -s http://127.0.0.1:5220/api/health/config        # 200，version/config 可见
curl -s http://127.0.0.1:5220/api/health/vector        # 200，chroma 可用

# 2. 反代
curl -sk https://nazha.servbay.host/api/health/config  # 200（证书为 ServBay 用户 CA）

# 3. 归口检索
cd ~/Projects/gfcc/services/demopeter && .venv/bin/python scripts/query.py "任意语料问题"
```

红线：
- 不新建独立 Nazha 运行树（5200 与 Looma 冲突；现成 5220 树零成本）。
- 不手写散落 vhost，一律经 `deploy-servbay-sites.sh`（GUI 覆盖后一键恢复）。
- 不动 `db/chroma_data` 之外的云上权威数据；本树仅承载归口导入。

---

## 五、仍待拍板（承载之外的归口三件事，收敛为两项）

| # | 待拍板项 | 现状 | 备注 |
|---|---|---|---|
| 1 | **归口语料源** | 72changes 大语料已拍「方案 A 不迁移」 | **已实证（2026-09-08）**：agent_memory（L3/nazha_ready，4 mac + 16 win，`095efc5`，见文末附录）；四类目录其余首轮输入仍待定 |
| 2 | **审核人与节奏** | CONTRIBUTING.md 已有 Review 流程 | 待定：归口 MR/PR 的具名 reviewer |

（原「归口形态」已被本文档替代：宿主 = 本机 `nazha.servbay.host:5220` gfcc 树 + 天翼同树。）

---

## 六、责任人

- **核查与方案**：8bt8rcrg95-coder（2026-09-07 只读盘点，未创建/修改运行实例）。
- **拍板**：org owner（szpeter2026）——先文档化、不铺常驻。
- **执行前置动作**（进入执行阶段时才做）：追加 `deploy-servbay-sites.sh` SITES 行 → 写 launchd plist → 按第四节验收。

## 附录：归口实证与困惑消解（2026-09-08）

> 本附录回应 §一 被质疑项「像是在安排本地跑测试」，并据首笔主线归口实证更新 §五 第 1 项。决策：org owner（szpeter2026）。

### 实证：首笔主线归口 commit

| 项 | 内容 |
|---|---|
| 提交 | `GenzLTD/Nazha` `095efc5` `feat(kb): 归口 agent_memory 记忆语料(L3/nazha_ready, 4 mac + 16 win)`，2026-09-08 push main |
| 身份 | szpeter2026（org owner） |
| 规模 | 21 文件 / +8927 行：`knowledge_base/documents/md/agent_memory_mac-jason/`（4，Cline 任务卡）+ `agent_memory_windows-szben/`（16，cline 对话转录） |
| 出处 | 跨机记忆蒸馏（memory_distill 范式）→ `memory_vault layers/L3/nazha_ready`，P0 脱敏；每份带 front matter（source_agent/machine/verdict 等），按机分目录、不混灌 |
| 契约 | Nazha README 新增「记忆语料归口」节：备份蒸馏 → L3 人审 → 归口 → 导入 + RAG 验证 → 提交；禁改语料正文、禁回拷 vault 原文 |

### 消解与边界（防 org 误读）

- **已消解（归口不是本地跑测试）**：语料已作为真实 commit 进 `GenzLTD/Nazha` 主线，远端可拉取、可走既有 Review 流程；§五第 1 项「归口语料源」**待定 → 已实证**（agent_memory 为首笔输入，策略沿用方案 A 语境：只收蒸馏后 L3 就绪料，不为历史包袱迁移大语料）。
- **未消解 / 未执行**：本文档 §三 执行前置动作（ServBay SITES 行、launchd plist）与 §四 本机承载验收（`nazha.servbay.host:5220` 起服 + `query.py` 可检索）**仍未触发**；`gfcc/services/demopeter` 宿主树尚未导入 agent_memory。本附录不改「先文档化、不铺常驻」结论。
- **仍待拍板**：§五 第 2 项「审核人与节奏」（归口 MR/PR 具名 reviewer）。

## Links

- [Nazha 仓库](https://github.com/GenzLTD/Nazha)（代码主线）
- 本机宿主树：`~/Projects/gfcc/services/demopeter`（随 gfcc 仓部署，云上同树于天翼 `/data/gfcc`）
- ServBay 站点生成：`~/THOMAS/scripts/deploy-servbay-sites.sh`（追加 SITES 行后重跑）
- 语料决策：[72changes-Nazha语料盘点与决策.md](./72changes-Nazha语料盘点与决策.md)
