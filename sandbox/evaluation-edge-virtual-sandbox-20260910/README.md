# 沙盘：evaluation_edge Schema v0 虚拟互评完备性验证（v1，PR#13 review 修复版）

> **性质声明（ADR-0011 合规）**：本目录是 `evaluation_edge.schema.v0.json` 的离线完备性验证沙盘，**设计输入验证，不是立项，不是产品代码**。不触 dsh-bridle 产品化，不回写 PR#11（已按 ADR-0011 冻结口径归档）。

## 零真实个人信息声明

- 12 位虚拟员工人格全部取自诗词语料作者（李白、杜甫、元稹、白居易等历史人物），伪匿名化 `psn_<sha256前10位>`；
- `identity_map.json` 即"物理分离的身份映射表"示意，姓名只出现在该文件，入图数据全部为伪匿名 ID；
- 签名密钥为一次性测试密钥：公钥 `demo_ed25519_public.pem` 随 PR 提交（保证 R9 可独立复现），私钥 `demo_ed25519_private.pem` 已被 `.gitignore` 排除，无任何生产用途。

## v1 修复（回应 PR#13 review）

| review 指出 | 修复 |
|---|---|
| 硬编码 `F:/` 绝对路径 | 两脚本全部相对化/参数化：`--schema` 默认定位仓库内 `docs/evaluation_edge.schema.v0.json`；`--corpus` 默认用随 PR 提交的语料子集 |
| 公钥未提交 → R9 不可复现且校验器崩溃 | 公钥随 PR 提交；公钥缺失时 R9 显式 `SKIPPED(不可验证)` 而非崩溃 |
| 语料不在仓库 → 样例不可重复生成 | 提交 `corpus-persona-subset.json`（12 人格各前 300 首，语料序确定性截取）；生成器同时改用 sha256 派生种子（原内置 `hash()` 进程级随机，重跑不可复现——自查发现），**同盐值重跑字节级一致**（已实测） |
| CI 不覆盖 sandbox | `docs.yml` 触发路径加 `sandbox/**`，新增 `sandbox-validation` job 跑 `validate_edges.py` |
| **L3 聚合未去重 → 重复边可刷过 k=3 隐私阈值** | L3 复用 R2 去重判定，重复边/自评/未同意一律不入共识与 k 计数 |
| SALT 硬编码 → 伪匿名可反查 | SALT 走 `--salt`/环境变量 `GENZ_PSEUDO_SALT`，不入库不入代码；**明确：伪匿名 ≠ 匿名，仅是可标识符替换**，若沿用真实员工必须配密钥管理 |
| R4/R5 只扫 free_text | 改全字段递归扫描（含 `items[].anchored_text`、`consent.scope` 等）；新增 T7 注入样例（手机号放 `anchored_text`）验证覆盖 |

## 文件清单

| 文件 | 说明 |
|---|---|
| `gen_virtual_edges.py` | 生成器：37 条边 = 30 正常 + 7 类故意注入违例 |
| `validate_edges.py` | 校验器：JSON Schema (draft 2020-12) + 应用层红线 + k-匿名(≥3)共识聚合（已去重） |
| `corpus-persona-subset.json` | 诗词语料子集（每人 ≤300 首），保证样例可复现 |
| `virtual_edges.jsonl` | 样例数据（37 行，每行一条 EvaluationEdge） |
| `identity_map.json` | 伪匿名映射表（分离保管示意） |
| `demo_ed25519_public.pem` | 测试公钥（R9 验证用） |
| `validation_report.md` | 验证报告（结果见下） |

## 验证结果（2026-09-10，v1）

- Schema 校验：30/30 正常边通过，0 误报
- 违例检出：**7/7 全部命中**（R1/R2/R3/R4×2/R5/R7/R9）
- 图级聚合（去重后）：10 个虚拟目标中 8 个入边 ≥3 发布共识分，2 个被 k-匿名压制
- 可复现：同语料子集 + 同盐值重跑，`virtual_edges.jsonl` 字节级一致（md5 已实测）

## 复现步骤

```bash
pip install jsonschema cryptography
# 1) 校验（无需盐值/私钥，公钥已随库）
python sandbox/evaluation-edge-virtual-sandbox-20260910/validate_edges.py
# 2) 重新生成（盐值一次性，不入库；重跑会得到与归档不同的 pseudo_id，属预期）
GENZ_PSEUDO_SALT=<你的盐值> python sandbox/evaluation-edge-virtual-sandbox-20260910/gen_virtual_edges.py
```

## 与 PR#12 的关系

本沙盘验证的是"评价边"的他述数据结构；PR#12（探针-真实简历验证）论证"简历补验证、不补评价"。两者互补：简历自述 → `weak`，评价边他述 → 共识分，共同构成信任层的验证/评价两翼。PR#12 c26f49d 的对齐引用已同步阅读。
