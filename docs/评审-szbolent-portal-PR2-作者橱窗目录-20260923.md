# 评审：szbolent-portal PR #2「将博客页改为作者橱窗目录，卡片外链回原文站」

> 评审日期：2026-09-23 · 被评审对象：`GenzLTD/szbolent-portal#2`（**open，未合并**）
> 结论：**方向与「书店-橱窗」同构，但当前实现不具备合并条件 —— 建议不合并，由作者按 §5 改造后重开分支**
> 口径依据：[Owner 指令：szbolent.cn = T2 书店参考实现（橱窗另开 · AI 只帮作者）](Owner指令-szbolent.cn书店参考实现-20260918.md)
> 状态：评审意见（Review）。本次**未改变**被评审 PR 的任何状态（未合并、未关闭、未评论、未改其分支）。

## 1. 评审对象

| 项 | 值 |
| --- | --- |
| 仓库 / PR | `GenzLTD/szbolent-portal`（PUBLIC）/ **#2**，`state=OPEN`，`isDraft=false` |
| head 到 base | `feat/author-showcase` 到 `main` |
| head 分支状态 | **已被删除**（`GET /branches/feat%2Fauthor-showcase` 返回 404）；因 `refs/pull/2/head` 仍在，GitHub 仍判 `mergeable=MERGEABLE`、`mergeStateStatus=CLEAN` |
| head 提交 | `5e26564cdfa1a424ea7c49594661daa9831b4eb2`（2026-09-11T15:13:35Z） |
| 作者 | `@szjason72`（Co-authored-by: Cursor `cursoragent@cursor.com`） |
| 创建 / 最后更新 | 均为 2026-09-11T15:31:47Z，**12 天零更新** |
| 规模 | 2 文件 `+186 −5`（`changedFiles=2`） |
| 基线漂移 | `main` 上 `src/views/Blog.vue` 最后改动为 `c713520`（2026-09-13）；`src/config/showcase.ts` 在 `main` 上不存在 |

## 2. 改动清单（逐文件）

### 2.1 `src/config/showcase.ts`（新增，+110）

- 文件头自述：*「橱窗目录（Bolent 侧管理，不是作者博客的镜像）… 增删、上下架、排序只改本文件；不要去改对方站点，也不要全量同步」*
- 类型：
  - `ShowcaseAuthor{ id, name, site }` —— `site` = 作者自己的站点，「阅读原文」必须落在这个域名
  - `ShowcaseWork{ id, authorId, url, title, excerpt?, enabled, weight }` —— `enabled`：下架后橱窗不出现、作者站原文不受影响；`weight`：越大越靠前
- 数据：
  - `showcaseAuthors` 2 条：`myblog`（「作者博客」）、`demo-author`（「示例作者（本地）」）；**`site` 均为 `http://myblog.szbolent.local`**
  - `showcaseWorks` 3 条：`myblog-servbay`（「本机 ServBay 适配说明」w=20）、`myblog-welcome`（「欢迎来到作者作品子站」w=10）、`demo-writing`（「写作从这里开始」w=5）；**全部 `enabled: true`，`url` 全部为 `http://myblog.szbolent.local/...`**
- 函数：`listShowcaseCards(authorId?)`（过滤 `enabled` 后过滤作者，再按 `weight` 降序，最后 join 作者）、`authorsWithPublishedWorks()`

### 2.2 `src/views/Blog.vue`（+76 −5）

- 新增作者筛选按钮区与 `selectShowcaseAuthor()`
- 新增橱窗卡片墙：缩略图占位「精选」、`post-meta` 显示 `authorName`、标题 `<a :href="item.url" target="_blank" rel="noopener">`、摘要、页脚「阅读原文 →」（同为 `target="_blank" rel="noopener"`）
- **行为切换**：`const useShowcase = showcaseAuthors.length > 0`（本 PR 恒为真），既有筛选区改 `v-else-if="!useShowcase"`、分页改 `v-if="!useShowcase && totalPages > 1"`、`onMounted` 与 `watch(route.query)` 均**早退**
- 样式：`.blog-filters` padding 由 `40px 0` 改为 `24px 0 40px`，并加 `position: relative; z-index: 1`

## 3. 与 Owner 指令逐条比对

依据：[Owner 指令 2026-09-18](Owner指令-szbolent.cn书店参考实现-20260918.md) 的 S2 条（`www.szbolent.cn` 首页 = 打标卡片列表；每张卡 `href` 指向 `szbolent.cn/{slug}`；无登录、无支付、无对话窗）与 L20（打标真源）。

| # | 指令要求 | PR #2 实际 | 判定 |
| --- | --- | --- | --- |
| 1 | 只展示标题/摘要，不在门户域下展开全文 | 卡片仅 `title` + `excerpt`，全文靠外链 | 一致 |
| 2 | **点击必须回原文站** | `:href="item.url"` + `rel="noopener"`，「阅读原文 →」 | 一致 |
| 3 | 无登录 / 无支付 / 无对话窗 | 纯列表 + 作者筛选 | 一致 |
| 4 | 不做双写、不碰对方站 | 文件头注释明确禁止改对方站与全量同步 | 一致 |
| 5 | **打标真源 = WP REST `meta._bsb_shelf_featured`；不再发明第二套「是否上架」表** | 新建 `src/config/showcase.ts` 手维护 `enabled` / `weight`，即第二套上架表 | **冲突** |
| 6 | 卡片 `href` 指向真实原文 | 指向 `http://myblog.szbolent.local/...`（本地演示域、明文 http） | **不可上线** |
| 7 | 只读面，不改既有体验 | `useShowcase=true` 时 WP 文章列表 / 分类筛选 / 分页整体 bypass | **行为替换** |
| 8 | 橱窗面 = `www.szbolent.cn`（T1）；`szbolent-portal` 在 90 天归档清单内 | 落点在 `szbolent-portal` 的 `/blog` | **待对齐口径**（见 §4 I-3） |

## 4. 不一致清单（含证据）

- **I-1 外链域不可上线**：`showcaseAuthors[*].site` 与 3 条 `showcaseWorks[*].url` 全部为 `http://myblog.szbolent.local`。一旦合并上线，官网 `/blog` 的卡片外链全部是**不可解析的本地域**，且为明文 http。
- **I-2 上架真源自立**：[Owner 指令 2026-09-18](Owner指令-szbolent.cn书店参考实现-20260918.md) L20 明示打标真源为 `_bsb_shelf_featured`，且「不再发明第二套『是否上架』表」；本 PR 的上架状态写在 `src/config/showcase.ts` 的 `enabled`，与指令**直接冲突**。该文件自述「上下架只改本文件」，等于把第二套表固化。
- **I-3 落点未对齐**：指令把橱窗面定义在 `www.szbolent.cn`（T1 / Variety），并重申「**90 天聚焦决策对 `szbolent-portal` 的归档仍然有效**」；本 PR 在 `szbolent-portal` 新增产品面。另 `成员分工与后续任务-20260913.md` §51 有「**门户只做橱窗外链**」口径，两个口径需先裁定，否则会演变成**第三套面**。
- **I-4 会让线上博客回退**：`Blog.vue` 现行实现走 `getPosts`（`@/api/wordpress`）+ 分类筛选 + 分页；`useShowcase=true` 后这些路径全部不可达，官网 `/blog` 将由 3 条本地演示卡片接管。属**功能回退**，不是纯增量。
- **I-5 流程与状态**：head 分支已删除（404）、12 天零更新、基线期间 `main` 已前进（含 `c713520`）。即便 GitHub 判 `CLEAN`，也应**重开分支**而非在已删分支上继续；同时按仓规「作者不得自批自己的 PR」，改造后需走 CODEOWNER 评审。

## 5. 改造清单（交作者，逐条给验收口径）

- [ ] **C-1 打标真源落地**：在 WP 侧（`szbolent-cn`）以 mu-plugin 注册 `_bsb_shelf_featured` 并 `show_in_rest`，使 `GET /wp-json/wp/v2/posts?_fields=id,link,title,excerpt,meta` 可读到该标记。**验收**：REST 响应中出现该 meta 字段，且真值可由作者后台打标。
- [ ] **C-2 删除第二套上架表**：`src/config/showcase.ts` 的 `enabled` / `weight` 不再承载「是否上架」；改为消费 C-1 的契约（门户已有同源反代 `/wp-json/`，可直接读取）。**验收**：仓库内不再存在手维护的上架清单。
- [ ] **C-3 外链换真实原文域**：卡片 `href` 改为 `https://szbolent.cn/{slug}`。**验收**：线上点击卡片可落到源站文章页。
- [ ] **C-4 落点口径先裁定**：明确「官网 `/blog` 做橱窗外链」与「`www.szbolent.cn` = T1 橱窗」的关系（二选一或分层，禁止变成第三套面）。**验收**：docs 存在对应执行口径条目，且本 PR 落点与之相符。
- [ ] **C-5 不做整体替换**：要么保留既有 WP 列表、把橱窗作为显式区块（默认关、可开关），要么在 PR 描述中明确「这是有意替换线上 `/blog`」并提供回退开关。**验收**：切换可逆，`/blog` 不出现空内容白屏。
- [ ] **C-6 补自动化测试**：至少覆盖 `listShowcaseCards` 的过滤 / 排序 / 作者 join，以及 `enabled=false` 下架路径；PR 模板的 Test plan 由手动 `npm run dev` 升级为可执行断言。**验收**：CI 中可跑通。
- [ ] **C-7 重开分支**：从当前 `main` 新建分支提新 PR，并在描述中关联 / 关闭旧的 #2。

## 6. 评审期间的独立发现（非本 PR 责任）

- **F-1 门户 WP 数据源与源站不一致**：`https://www.szbolent.com.cn/wp-json/wp/v2/posts` 返回 **`[]`**，而源站 `https://szbolent.cn/wp-json/wp/v2/posts` 返回 **1 篇**（`X-WP-Total: 1`，`id=1`，标题 `Hello world!`）。门户同源反代当前指向一个**空** WP。建议单独立项排查；否则任何契约驱动的橱窗读到的都是空集。
- **F-2 `_bsb_shelf_featured` 尚无实现**：在 `szbolent-cn` / `szbolent-portal` / `variety` / `dsh-bridle` / `looma-zervi` 五个仓内检索 `_bsb_shelf_featured|bsb_shelf|shelf_featured`，命中 **0 处**；线上 `meta` 仅暴露 WP 默认 `footnotes`。即指令 L20 表述的「打标真源已经存在」目前是**纸面契约**，§5 C-1 是前置工程。

## 7. 复现命令（评审用）

```bash
# 1) PR 元数据（注意 head 分支已删但 GitHub 仍判 CLEAN）
gh pr view 2 --repo GenzLTD/szbolent-portal \
  --json number,state,headRefName,mergeable,mergeStateStatus,changedFiles,additions,deletions,files
gh pr diff 2 --repo GenzLTD/szbolent-portal

# 2) head 分支确已删除（预期 404 Branch not found）
gh api 'repos/GenzLTD/szbolent-portal/branches/feat%2Fauthor-showcase'

# 3) 书店 / 门户两侧的 WP REST 对照（F-1）
curl -s 'https://szbolent.cn/wp-json/wp/v2/posts?per_page=1&_fields=id,link,title,meta'
curl -s 'https://www.szbolent.com.cn/wp-json/wp/v2/posts?per_page=1&_fields=id,link'

# 4) 基线漂移（在 szbolent-portal 本地 clone 内）
git log --format='%h %ci %s' -5 -- src/views/Blog.vue
git show main:src/config/showcase.ts 2>&1 | head -1   # 预期：文件不存在
```

## 8. 发布边界

- `szbolent-portal` 为 **PUBLIC** 仓。若要把本意见贴成 PR 评论，须先**脱敏**：`1.14.202.161`、`47.115.168.107`、`127.0.0.1:8080`、`myblog.szbolent.local` 应替换为角色描述（门户机 / 书店机 / 本机回环 / 本地演示域），口径参照 `fix/sanitize-public-docs-20260918`。
- 本仓（`GenzLTD/docs`）为 **PRIVATE**，可承载含内网细节的完整版（即本文件）。

## 9. 关联文档

| 文档 | 关系 |
| --- | --- |
| [Owner 指令：szbolent.cn = T2 书店参考实现](Owner指令-szbolent.cn书店参考实现-20260918.md) | 本次比对的口径真源（L17 橱窗定义 / L20 打标真源 / L25 归档口径 / L52 S2 验收） |
| [成员分工与后续任务 2026-09-13](成员分工与后续任务-20260913.md) | §51「门户只做橱窗外链」，为 I-3 落点争议的另一侧口径 |
| [终端角色分工-研讨稿 2026-09-13](终端角色分工-研讨稿-20260913.md) | §6.2 路径 B 收窄为「T2 书店参考实现 + T1 橱窗只读」 |
| [资源-主体-服务对账表 2026-09-15](资源-主体-服务对账表-20260915.md) | 资源 #1 拆分为 apex 书店与 www 橱窗（L25） |
| [统一对账表 2026-09-15](统一对账表-20260915.md) | 资源 #1 归属与对外称法（L23） |


