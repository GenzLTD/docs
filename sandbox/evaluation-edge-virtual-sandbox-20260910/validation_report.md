# 虚拟互评样例完备性验证报告 (v1, PR#13 review 修复版)

- 样例总数: 37（正常 30，检出违例 7）
- Schema: docs/evaluation_edge.schema.v0.json (draft 2020-12)
- R4/R5 扫描范围: 全字段（含 items[].anchored_text / consent.scope）
- L3 聚合: 已按 (cycle,source,target) 去重，重复边/自评/未同意不入共识

## L2 红线检出明细

| edge_id | source→target | 检出问题 |
|---|---|---|
| edge_dead0001 | 李白→李白 | R1 自评边被拦截(source==target) |
| edge_dead0002 | 杜甫→李白 | R2 重复边(cycle,source,target) |
| edge_dead0003 | 欧阳修→孟浩然 | R4 全字段扫描检出手机号@$.free_text→脱敏闸门拒绝 |
| edge_dead0004 | 苏轼→刘禹锡 | R5 全字段扫描含真实姓名『元稹』@$.free_text→需化名 |
| edge_dead0005 | 黄庭坚→柳宗元 | R3 未获知情同意→不入共识 |
| edge_dead0006 | 韩愈→王维 | R7 forced_choice 评分不一致(pair_01); R9 Ed25519 签名验证失败(疑似篡改) |
| edge_dead0007 | 王维→孟浩然 | R4 全字段扫描检出手机号@$.items[25].anchored_text→脱敏闸门拒绝 |

## 注入违例 → 检出对照

| 注入 | 预期 | 实际 |
|---|---|---|
| 自评边 | R1 拦截 | ✅ R1 自评边被拦截(source==target) |
| 重复边 | R2 拦截 | ✅ R2 重复边(cycle,source,target) |
| 手机号(free_text) | R4 拦截 | ✅ R4 全字段扫描检出手机号@$.free_text→脱敏闸门拒绝 |
| 真名泄漏(free_text) | R5 拦截 | ✅ R5 全字段扫描含真实姓名『元稹』@$.free_text→需化名 |
| 未同意 | R3 拦截 | ✅ R3 未获知情同意→不入共识 |
| 篡改签名 | R9 拦截 | ✅ R7 forced_choice 评分不一致(pair_01); R9 Ed25519 签名验证失败(疑似篡改) |
| 手机号(anchored_text) | R4 拦截 | ✅ R4 全字段扫描检出手机号@$.items[25].anchored_text→脱敏闸门拒绝 |

**违例检出率: 7/7**

## L3 共识分聚合（k-匿名 ≥3 入边才发布；已去重）

| 虚拟目标 | 入边数 | 共识分(加权均值) | 备注 |
|---|---|---|---|
| 王维 | 4 | 3.538 |  |
| 杜甫 | 4 | 3.413 |  |
| 白居易 | 4 | 3.425 |  |
| 孟浩然 | 2 | — | k<3 不发布 |
| 柳宗元 | 2 | — | k<3 不发布 |
| 苏轼 | 3 | 3.383 |  |
| 黄庭坚 | 4 | 3.575 |  |
| 李白 | 4 | 3.575 |  |
| 刘禹锡 | 3 | 3.6 |  |
| 元稹 | 4 | 3.1 |  |