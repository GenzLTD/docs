# Wukong ↔ lab-genz-brain-m2：Layer0/1/2 Schema 同步对接规范

> 状态：**可执行规范**（Proposed）· 维护人：8bt8rcrg95-coder（你，负责人）
> 日期：2026-09-06 · 关联仓库：`GenzLTD/Wukong`（真源）、`GenzLTD/lab-genz-brain-m2`（消费方）
> 配套脚本：`docs/scripts/sync_wukong_schemas.py`

---

## 一、为什么需要这条链

`lab-genz-brain-m2` 的 `schemas/` 目录就是 `GenzLTD/Wukong` 的 **Layer0/1/2 共识 schema 真源的拷贝**。
lab 的全部判定能力（`describe` / `cross_border_evaluate` / `matrix` / `drift`）都建立在「字段 → 隐私分级」之上，
而这些分级定义**只住在 Wukong 里**。

`registry.py` 源码自己也在报错提示里写明了这一层血缘：

> `schema 缺失: {p}（应从 Wukong-main/docs/schemas 同步）`

**但当前这条同步只靠「手动拷贝 + 人的自觉」，没有任何工具或 CI 强制**。一旦两边漂移，
lab 的 64 矩阵、17 个测试、甚至线上门控口径都会建立在过期字段定义之上。本文档把这条链固化下来。

### 权威路径

| 角色 | 仓库/路径 | 说明 |
|---|---|---|
| **真源（Single Source of Truth）** | `GenzLTD/Wukong/docs/schemas/` | layer0/1/2 三个 JSON，改字段分级先改这里 |
| **消费方（拷贝）** | `GenzLTD/lab-genz-brain-m2/schemas/` | 与真源**逐字节一致**；lab 引擎读取这里 |
| 衍生态 | `GenzLTD/wukong-core/rules/` | 认知内核 PoC 再拷贝（见对账表文档） |
| 实施 | `docs/scripts/sync_wukong_schemas.py` | 唯一 promote 入口 |

> ⚠️ **只允许从上往下单向流动**：Wukong → lab →（lab 的 fixture/tests）。禁止反向把 lab 的改动当作真源。

---

## 二、同步范围（scope）

只同步这三个真源 JSON，**不**搬运其他资产：

| 文件名 | 内容 | 备注 |
|---|---|---|
| `layer0_identity.json` | Layer0 身份核心字段（20 字段，含 privacy_tier） | 真源 |
| `layer1_interest.json` | Layer1 兴趣字段（15 字段） | 真源 |
| `layer2_profile.json` | Layer2 档案字段 | 真源 |

明确**不在同步范围**（各有其归属）：
- `vc_layer0/1_identity.json` —— DID/VC 凭证版，属 Wukong，不在 lab 判定链。
- `consensus_formula.md`、`zkp_consensus_protocol.md` —— 共识/零知识协议文档，非 lab 运行时输入。
- `policy_rules.yaml` —— 这是**两个仓库各自的本地规则源**：真源在 lab 的 `config/`；Wukong 也有一个
  `config/data-localization.json`。两者语义需对齐（由 `main.py drift` 对拍），但**不走 schema 同步**。

---

## 三、Promote 流程（可执行步骤）

> 目标：一次变更 → 三个产物同时升级，且任意一侧未跟上，lab 测试即红（期望告警，勿绕过）。

### Step 1 · 改真源（Wukong）

```bash
gh repo clone GenzLTD/Wukong   # 若未 clone
# 编辑 docs/schemas/layerX_*.json（加字段、调 privacy_level、加 source_aliases 等）
git add docs/schemas/
git commit -m "schema: <变更说明>（Layer0/1/2）"
git push
# 建议同步触发 GH 通知 + 评论 @负责评审的人
```

### Step 2 · 同步到 lab（唯一入口 = 脚本）

```bash
# 先做差异审计（只读，不写）
python3 docs/scripts/sync_wukong_schemas.py --mode diff --wukong /tmp/Wukong

# 确认是预期变更后，写回 lab
python3 docs/scripts/sync_wukong_schemas.py --mode sync --wukong /tmp/Wukong \
  --lab /Users/.../lab-genz-brain-m2
```

`sync` 完成会自动提示后续命令（见 Step 3/4）。

### Step 3 · lab 侧验证（必须全绿）

```bash
cd lab-genz-brain-m2
.venv/bin/python -m unittest discover -s tests     # 17 用例全绿
.venv/bin/python main.py drift                     # OK: 与 zervi-looma(Rust) 语义全一致
.venv/bin/python main.py matrix --json             # 抽查新字段矩阵
```

> 若测试红：说明 YamlPolicy / RustPolicy / fixture 任一未同步。**不要绕过**。
> 按 `docs/parity-verification.md` 流程补同步或重生成 fixture。

### Step 4 · 提交并推送 lab

```bash
cd lab-genz-brain-m2
git add schemas/ config/ tests/ src/
git commit -m "schema: 同步 Wukong Layer0/1/2 变更（<说明>）"
git push
```

### Step 5 · （可选）认知内核 wukong-core 对齐

`wukong-core/rules/` 也持有同一份拷贝。若它仍消费旧字段，需按
`wukong-core/docs/WUKONG_SOURCE_MAP.md` 的方式同步，防止认知内核漂移（这个话题在 ADR-0001 / 对账表文档详述）。

---

## 四、漂移发现（未走流程时的自愈路径）

| 症状 | 判断 | 处置 |
|---|---|---|
| lab 某 schema sha256 与 Wukong 不一致 | 一侧更新未同步 | 跑 `--mode diff` 看谁新，跑 `sync` |
| `main.py drift` 报 DRIFT | yaml 与 Rust 语义漂移 | 按 parity-verification 重对拍 |
| lab 测试红 | 字段/分级变更未联动测试 | 同步 yaml/fixture，勿绕过 |

持续加固（后续可做）：在 lab 的 CI（`.github/workflows/`）加一步 `--mode check`，
任何 Wukong 有推送而 lab 未同步即阻断——这条稳定后，本文档的 Step 1 可在 Web 完成、Step 2-4 交给 bot。

---

## 五、责任人

- **维护/收敛**：8bt8rcrg95-coder（你，Wukong 转入方、lab Admin）——schema 是该线核心资产，你是默认义务人。
- **评审**：lab 现有 CODEOWNERS 体系（`szpeter2026`、`zervi-genz` 参与 review）。
- **拍板**：发生「改分级口径」级别的变更（如 L0_PII↔SG 改 deny）时，走 ADR-0002 的业务复核流程，不在此脚本内决定。

## Links

- 真源：`GenzLTD/Wukong/docs/schemas/` → [Wukong 仓库](https://github.com/GenzLTD/Wukong)
- 消费方：`GenzLTD/lab-genz-brain-m2/schemas/` → [lab 仓库](https://github.com/GenzLTD/lab-genz-brain-m2)
- 对拍口径：[lab docs/parity-verification.md](https://github.com/GenzLTD/lab-genz-brain-m2/blob/main/docs/parity-verification.md)
- 规范性参考：[ADR-0001 lab ↦ wukong-core canonical](./adrs/0001-lab-wukong-canonical.md)
- 命名区分：[Wukong 命名与归属对账表](./Wukong-命名与归属对账表.md)