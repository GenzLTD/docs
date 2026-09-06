# ADR 0003: cortex-mcp 策略包加载、pin 与 genz-gate CI

- **Status**: Accepted
- **Date**: 2026-09-05
- **Deciders**: szpeter2026, zervi-genz（Accepted 2026-09-06）
- **Consulted**: szjason72, cortex-mcp 维护者
- **Tags**: M3, cortex-mcp, compliance, CI, policy

## Context

`cortex-mcp` 在 `remember` 前通过 `compliance.py` 加载跨境策略，设计目标：

- 与 M2 矩阵一致（64 组合，51/6/7）
- 运行时读 yaml，**mtime 热加载**，避免与 wukong/lab 漂移

待决问题：

1. 策略文件物理路径：环境变量 `CORTEX_WUKONG_CORE_RULES` vs git submodule vs 发布 bundle
2. 三仓（lab / wukong / cortex）如何 **一条 CI** 证明未漂移
3. cortex 仍在演进 M3 namespace（device/edge/cloud），但合规层应先 pin 策略版本

## Decision

1. **策略包 canonical 路径（运行时）**  
   - 首选：`GenzLTD/wukong-core` 仓库内 `rules/policy_rules.yaml`（与 ADR-0001 promote 目标一致）  
   - 环境变量：`CORTEX_WUKONG_CORE_RULES` 指向该文件绝对路径；本地 dev 默认可 clone  sibling 目录  
   - **禁止**在 cortex 仓内维护第二份 yaml 副本（仅允许测试 fixture 最小子集）

2. **版本 pin（生产）**  
   - Docker/部署镜像构建时，**pin git commit SHA** of `wukong-core`（或 pin lab fixture commit）  
   - 镜像 label：`genz.policy_bundle_commit=<sha>`  
   - 与 lab `rust_cartesian_matrix.json` 的 git blob SHA 记录在 release notes

3. **genz-gate CI（最小集）**  
   - 权威 workflow 模板：`lab-genz-brain-m2/.github/workflows/genz-gate.yml`（见 drafts）  
   - 触发：`lab-genz-brain-m2`、`wukong-core`、`cortex-mcp` 的 PR 与 main push  
   - 必过 job：  
     - `m2-lab-python`：17 tests  
     - `m2-matrix-parity`：wukong `_verify/verify_matrix.py` vs lab fixture（允许只读 checkout lab fixture 文件）  
     - `m3-compliance`：cortex compliance 测试  
   - **改 `policy_rules.yaml` 的 PR**：三 job 全绿方可 merge

4. **M3 namespace（后续，不在本 ADR 阻塞）**  
   - `remember` metadata 预留 `namespace: device|edge|cloud`  
   - `cloud` + `L0_PII` 适用本策略引擎 deny；物理分库后续 ADR 定义

## Consequences

### Positive

- cortex 与 M2 真源单线；生产可 audit pin SHA。
- CI 替代「人工记得 promote」。

### Negative

- 私有仓 CI checkout 需 `GH_PAT` 或 GitHub App（org 配置一次）。
- 三仓 PR 联动增加流程感（可后续 bot 化）。

## Implementation checklist

- [x] Accept ADR-0001、0002、0003
- [ ] 将 `genz-gate.yml` 复制到三仓 `.github/workflows/`（或 lab 为 canonical 副本，他仓 symlink/reuse）
- [ ] org secret：`GENZ_GATE_PAT`（read org private repos）
- [ ] wukong-core：`gate.py` 读 yaml，删除长期硬编码 RULES
- [ ] Release：cortex 镜像打 `policy_bundle_commit` label

## Links

- [cortex-mcp compliance.py](https://github.com/GenzLTD/cortex-mcp)
- [ADR 0001](0001-lab-wukong-canonical.md)
- [genz-gate workflow 草案](https://github.com/GenzLTD/lab-genz-brain-m2/blob/main/.github/workflows/genz-gate.yml)（合并前见 `E:\genzltd-kb\drafts\lab-genz-brain-m2\.github\workflows\genz-gate.yml`）
- Supersedes: （无）
- Superseded by: （无）
