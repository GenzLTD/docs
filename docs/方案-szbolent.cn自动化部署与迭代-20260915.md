# szbolent.cn 自动化部署与迭代方案（草案 · 2026-09-15）

> **状态**：Proposed（草案，待讨论）—— 本方案仅为提议，不构成任何拍板；红线、主体归属、域名语义等仍由 owner 裁定（治理口径 §三.4）。
> **作者**：@szpeter2026
> **关联**：统一对账表-20260915（资源 #1，内容体验线，见 PR #23）· [成员分工与后续任务-20260913](成员分工与后续任务-20260913.md)（适配线 A）· [variety 仓库](https://github.com/GenzLTD/variety)

## 0. 一句话

szbolent.cn 的**架构已契约驱动、边界清晰**，但**前端 Portal 部署仍靠本地手动脚本**，与 WordPress 的 CI 自动部署割裂，且域名 / HTTPS / 回滚未固化。本方案提议补齐自动化，目标：**push 即部署、域名 + HTTPS 固化、可回滚**。

## 1. 现状（架构与部署事实）

### 1.1 架构拓扑（variety 仓，入口层）

```
Variety Portal (Vue3 · :3000)
  ├─ /v1/menus|pages|permissions → Page Engine (Rust :5300)  菜单 / 页面 / RBAC
  ├─ /v1/*（兜底）               → Looma (Flask :5200)       诗词 / RAG / 认证 / 支付
  └─ /wp-json                    → WordPress (:8800)         博客 CMS
```

契约 `contracts/entry.json` 为唯一真源，nginx / docker-compose / 冒烟脚本均由它生成。

### 1.2 现有部署资产

| 资产 | 覆盖 | 触发方式 |
|---|---|---|
| `.github/workflows/deploy.yml` | WordPress 主题 + compose + nginx | push main 自动 |
| `scripts/deploy.sh` | 前端 Portal（build + rsync + nginx） | **本地手动** |
| `scripts/verify-offline.sh` / `smoke.sh` / `report-prod.sh` | 验证 / 冒烟 / 生产回执 | 手动 |

### 1.3 现状问题（部分需现网核实）

1. **前端 Portal 部署未进 CI**：靠 `scripts/deploy.sh` 本地 `npm run build` + `rsync` 手动推。
2. **两套部署割裂**：`deploy.yml` 管 WP 主题，`deploy.sh` 管前端，各自为政。
3. **用 IP 不用域名**：部署脚本与目标写死 `47.115.168.107` + `http`，`WP_HOME/WP_SITEURL` 亦为 IP；域名 `szbolent.cn` 与 HTTPS 未固化进流水线（线上是否已手动配 HTTPS，待核实）。
4. **无回滚**：`rsync --delete` 直接覆盖，不留版本。
5. **后端部署无自动化**：Page Engine（Rust）/ Looma（Flask）未见于流水线。

## 2. 方案（分阶段）

### P0 · 前端并入 CI（收益最大）

把 `deploy.sh` 的「build → rsync → nginx reload → 冒烟」搬进 `deploy.yml`，与 WP 主题合成一条流水线（或拆 job），push main 即部署前端 + 主题，彻底告别手动。

### P0 · 域名 + HTTPS 固化

部署目标 IP → `szbolent.cn`；补 Let's Encrypt（certbot + 自动续期）；`WP_HOME/WP_SITEURL` → `https://szbolent.cn`。个人站 HTTPS 是基本盘，也利于备案合规观感。

### P1 · 版本化 + 回滚

`dist/` 按 commit SHA 落盘，nginx 软链指向当前版本、保留上一版，出问题 `ln -sf` 一键回滚。

### P2 · 后端部署自动化

Page Engine（Rust）/ Looma（Flask）若高频迭代，接入 CI（build → 重启容器）。

## 3. 待讨论项（请各位给意见）

1. **前端 CI 触发粒度**：全量 push 即部署，还是 tag / release 触发？
2. **域名与 HTTPS 现网状态**：`szbolent.cn` + 证书是否已在线配置？若已配，是否回填进 deploy 脚本（避免流水线覆盖线上配置）？
3. **回滚是否必要**：个人站场景下版本化保留几版？是否值得为回滚增加复杂度？
4. **后端是否纳入**：Page Engine / Looma 的部署自动化，并入本方案还是另立提案？
5. **部署密钥管理**：是否复用 `deploy.yml` 现有 `SSH_PRIVATE_KEY` / `SSH_KNOWN_HOSTS` secrets？

## 4. 不在本方案范围

- 页面文案与内容（归 Page Engine）、诗词 / 认证 / 支付（归 Looma）、博客 CMS 本体升级。
- 备案与合规（归 Issue #16 与统一对账表）。
- 域名 / 主体 / 收费归属（owner 拍板事项，本方案不越权）。
