# Wukong 命名与归属对账表（Wukong vs wukong-core vs lab）

> 对象：GenzLTD org owner · 提供：8bt8rcrg95-coder · 日期：2026-09-06
> 目的：一次性厘清三个/四个都带「Wukong」或「lab」名的仓库，避免"改规则改哪个仓""谁是 schema 真源"扯皮。

---

## 一、一句话快读

GenzLTD 同时存在 **`Wukong` 与 `wukong-core`** 两个名字高度相近的仓，且都与 `lab-genz-brain-m2` 有关系。
**这是三份不同的东西**：

| 名字 | 真身 | 一句话定位 |
|---|---|---|
| **`GenzLTD/Wukong`**（你转入） | 数据层"真源" | **跨境共识 schema（Layer0/1/2）+ 共识算法 + 元数据工具链**，schema 的唯一权威 | 
| **`GenzLTD/wukong-core`** | 认知内核 PoC（新仓） | **决策②⑧ 认知内核黑匣子（gate/trace/verify）**，瓦片小、单独演进 |
| **`GenzLTD/lab-genz-brain-m2`** | M2 验收资产仓 | **YamlPolicy/RustPolicy 三方对拍 + 64 矩阵 fixture**，跨境门控判定 | 
| （陷阱）`YeDall Wukong/Qiankun` | 微前端门控目录 | **≠ 上面任何 Wukong**，仅命名重叠，勿混 |

---

## 二、逐项对账

| 属性 | `Wukong` | `wukong-core` | `lab-genz-brain-m2` |
|---|---|---|---|
| 组织 | GenzLTD | GenzLTD | GenzLTD |
| 来源 | **你（8bt8rcrg95-coder）转入** | 9-03 新建（szpeter2026 首提） | 9-04 新建（zervi-genz 首提） |
| 技术栈 | Python+Java+JS · Fossil/SQLite · DeepSeek | Python（纯标准库优先） | Python + Rust-parity · YAML |
| 角色 | **schema/元数据真源** | **认知内核消费方（PoC）** | **M2 验收资产（canonical 规则源）** |
| 门控判定 | 有思路（data-localization）非实现 | 有，但曾是手工转录 RULES | **唯一权威矩阵（64=51/6/7）** |
| 权威文件 | `docs/schemas/layer0/1/2.json` | `rules/`（拷贝） | `config/policy_rules.yaml` + `tests/fixtures/rust_cartesian_matrix.json` |
| 在 ADR-0001 中的角色 | （真源，文档未直接点名） | 消费方 → "与 lab canonical" | canonical 资产方 |
| 维护负责人 | **你**（转入 + 关注线） | szpeter2026 主力 | 你 / szpeter2026 / zervi-genz（lab Admin） |
| topics | schema/`reference` 型 | `genzltd-production` · `m1-cognitive-kernel`，待定 | `genzltd-assets` · `m2-gate-parity` |

### 数据流（谁给谁）
```
Wukong（真源 layer0/1/2.json）
   │  （拷贝 >> sync_wukong_schemas.py）     （派生規則 >> WUKONG_SOURCE_MAP）
   ▼                                              ▼
lab-genz-brain-m2/schemas/               wukong-core/rules/
   │ evaluate（YamlPolicy/RustPolicy 对拍）         │ gate/trace/verify（认知偏差检测）
   ▼
64 矩阵 fixture / 17 测试 / DNA 口径
```

---

## 三、命名混淆的两个根因 + 处置

1. **同一个词「Wukong」被用在"真源"和"认知内核 PoC"两个仓上**（`Wukong` vs `wukong-core`）。
   → 处置建议：给 GitHub topics + README 首行分别打上 `# GENZ-SCHEMA-SOURCE` / `# GENZ-COGNITIVE-KERNEL` 识别标签，
   并在两个 README 互相链本对账表。**不强制改名**（改名破坏 URL/history），靠标注消歧。
2. **YeDall 工程里还有个 `Wukong/Qiankun` 微前端目录**，与数据层 Wukong 完全无关（Nazha lineage 已确认仅命名重叠）。
   → 落到具体代码/PR 时，遇到 `Wukong` 先看**仓库名**再谈。

---

## 四、拍板结果（2026-09-07 · org owner）

| # | 待决点 | 拍板结果 | 影响 |
|---|---|---|---|
| 1 | `wukong-core` 与 `Wukong` 是否合并/链接 | **不合并**，保留独立仓 + topics/README 标注血缘 | 认知内核小而持续演进，真源不求并 |
| 2 | schema 真源是否官方锁定为 `GenzLTD/Wukong/docs/schemas` | **锁定**，写进 ADR-0001 冻结 | 终结"改哪个"争论；lab/wukong-core 都消费它 |
| 3 | 是否把 [同步规范](./Wukong-lab-Schema同步对接规范.md) 提到的 `--mode check` 接入 CI | **先人工，稳定后再接 CI** | 防漂移的长治久安 |
| 4 | 谁是默认负责人 | **szjason72**（schema 线 + 72changes 接管） | 责任明确 |

> 已拍板（2026-09-07）：Schema 真源 = `GenzLTD/Wukong`；负责人 = szjason72；不合并、不强制 CI。后续按本表执行，可访问外部仓库后补充 ADR/CI 落地。

---

## Links

- [Wukong 仓库](https://github.com/GenzLTD/Wukong) · [wukong-core 仓库](https://github.com/GenzLTD/wukong-core) · [lab-genz-brain-m2 仓库](https://github.com/GenzLTD/lab-genz-brain-m2)
- [同步对接规范](./Wukong-lab-Schema同步对接规范.md) · [72changes-Nazha 盘点](./72changes-Nazha语料盘点与决策.md)
- [ADR-0001 lab ↦ wukong-core canonical](./adrs/0001-lab-wukong-canonical.md)
- [Nazha lineage WUKONG_RAG_DECISION](https://github.com/GenzLTD/Nazha/tree/main/docs/lineage)