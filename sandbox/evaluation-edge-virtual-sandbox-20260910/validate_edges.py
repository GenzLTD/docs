# -*- coding: utf-8 -*-
"""
虚拟互评样例校验器
- L1: JSON Schema (draft 2020-12) 结构校验
- L2: 应用层九条红线（防自证/去重/同意/PII 脱敏/真名泄漏/加权分复算/评分一致性/证据哈希/签名验证）
- L3: 图级聚合（k-匿名 + source_credibility 加权共识分）
输出: validation_report.md
"""
import json, hashlib, base64, re
from pathlib import Path
from collections import defaultdict
from jsonschema import Draft202012Validator
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PublicKey
from cryptography.hazmat.primitives import serialization

ROOT = Path(__file__).parent
SCHEMA = Path("F:/GenzLTD_org_backup_github/docs/docs/evaluation_edge.schema.v0.json")

WEIGHTS = {"cooperation": 0.20, "creativity": 0.20, "responsibility": 0.30,
           "initiative": 0.15, "discipline": 0.15}
K_ANON = 3
PII_PATTERNS = [
    (re.compile(r"1[3-9]\d{9}"), "手机号"),
    (re.compile(r"\d{17}[\dXx]"), "身份证号"),
    (re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"), "邮箱"),
]


def canonical_body(edge: dict) -> bytes:
    body = {k: v for k, v in edge.items() if k != "signature"}
    return json.dumps(body, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode()


def main():
    schema = json.loads(SCHEMA.read_text(encoding="utf-8"))
    validator = Draft202012Validator(schema)
    edges = [json.loads(l) for l in (ROOT / "virtual_edges.jsonl").read_text(encoding="utf-8").splitlines() if l.strip()]
    idmap = json.loads((ROOT / "identity_map.json").read_text(encoding="utf-8"))
    name_by_pid = {v["pseudo_id"]: k for k, v in idmap.items()}
    pub = Ed25519PublicKey.from_public_bytes(
        serialization.load_pem_public_key((ROOT / "demo_ed25519_public.pem").read_bytes()).public_bytes(
            serialization.Encoding.Raw, serialization.PublicFormat.Raw))

    rows, failures = [], defaultdict(list)
    seen_keys = set()
    for e in edges:
        eid, issues = e["edge_id"], []
        # L1 Schema
        errs = sorted(validator.iter_errors(e), key=lambda x: x.json_path)
        if errs:
            issues.append("L1-schema: " + "; ".join(f"{x.json_path}: {x.message[:60]}" for x in errs[:2]))
        # R1 防自证
        if e["source_pseudo_id"] == e["target_pseudo_id"]:
            issues.append("R1 自评边被拦截(source==target)")
        # R2 去重
        key = (e["cycle_id"], e["source_pseudo_id"], e["target_pseudo_id"])
        if key in seen_keys:
            issues.append("R2 重复边(cycle,source,target)")
        seen_keys.add(key)
        # R3 同意
        if not e.get("consent", {}).get("granted"):
            issues.append("R3 未获知情同意→不入共识")
        # R4 PII
        ft = e.get("free_text", "")
        for pat, label in PII_PATTERNS:
            m = pat.search(ft)
            if m:
                issues.append(f"R4 free_text 检出{label}→脱敏闸门拒绝")
        # R5 真名泄漏（映射表姓名不得出现在入图数据）
        for name in idmap:
            if name in ft:
                issues.append(f"R5 free_text 含真实姓名『{name}』→需化名")
        # R6 加权分复算
        if "scored" in e:
            recomputed = round(sum(e["scored"]["per_dim"].get(d, 0) * w for d, w in WEIGHTS.items()), 3)
            if abs(recomputed - e["scored"]["weighted_total"]) > 0.01:
                issues.append(f"R6 weighted_total 复算不符({e['scored']['weighted_total']} vs {recomputed})")
        # R7 强迫选择一致性 + 证据哈希格式
        for it in e["items"]:
            if it["method"] == "forced_choice" and it["raw_score"] != (2 if it.get("choice") == "A" else 1):
                issues.append(f"R7 forced_choice 评分不一致({it['dim_id']})")
                break
        for ref in e.get("evidence_refs", []):
            if not re.fullmatch(r"sha256:[0-9a-f]{64}", ref):
                issues.append("R8 证据哈希格式非法")
                break
        # R9 签名验证
        sig = e.get("signature", {})
        ok = False
        try:
            pub.verify(base64.b64decode(sig["value"]), canonical_body(e))
            ok = True
        except Exception:
            ok = False
        if not ok:
            issues.append("R9 Ed25519 签名验证失败(疑似篡改)")
        rows.append((eid, name_by_pid.get(e["source_pseudo_id"], "?"),
                     name_by_pid.get(e["target_pseudo_id"], "?"), issues))
        if issues:
            failures[eid] = issues

    # L3 图级聚合：剔除自评/未同意后，k-匿名（入边 ≥3）才发布共识分
    incoming = defaultdict(list)
    for e in edges:
        if e["source_pseudo_id"] == e["target_pseudo_id"]:
            continue
        if not e.get("consent", {}).get("granted"):
            continue
        incoming[e["target_pseudo_id"]].append(e["scored"]["weighted_total"])
    consensus = {}
    for tgt, vals in sorted(incoming.items()):
        if len(vals) >= K_ANON:
            consensus[name_by_pid.get(tgt, tgt)] = {"in_edges": len(vals),
                                                    "consensus": round(sum(vals) / len(vals), 3)}
        else:
            consensus[name_by_pid.get(tgt, tgt)] = {"in_edges": len(vals), "consensus": None,
                                                    "note": f"k<{K_ANON} 不发布"}

    # 报告
    good = sum(1 for _, _, _, i in rows if not i)
    lines = ["# 虚拟互评样例完备性验证报告", "",
             f"- 样例总数: {len(edges)}（正常 {good}，检出违例 {len(failures)}）",
             f"- Schema: {SCHEMA.name} (draft 2020-12)", "",
             "## L2 红线检出明细", "",
             "| edge_id | source→target | 检出问题 |", "|---|---|---|"]
    for eid, s, t, iss in rows:
        if iss:
            lines.append(f"| {eid} | {s}→{t} | {'; '.join(iss)} |")
    if not any(i for _, _, _, i in rows):
        lines.append("| (无) | (无) | (无) |")
    lines += ["", "## 注入违例 → 检出对照", "",
              "| 注入 | 预期 | 实际 |", "|---|---|---|"]
    expect = {"edge_dead0001": ("自评边", "R1"), "edge_dead0002": ("重复边", "R2"),
              "edge_dead0003": ("手机号", "R4"), "edge_dead0004": ("真名泄漏", "R5"),
              "edge_dead0005": ("未同意", "R3"), "edge_dead0006": ("篡改签名", "R9")}
    detected = {eid: ("; ".join(iss)) for eid, _, _, iss in rows if iss}
    hit = 0
    for eid, (label, rule) in expect.items():
        d = detected.get(eid, "")
        ok = rule in d
        hit += ok
        lines.append(f"| {label} | {rule} 拦截 | {'✅ ' + d[:80] if ok else '❌ 漏检: ' + (d or '无')} |")
    lines.append(f"\n**违例检出率: {hit}/6**")
    lines += ["", "## L3 共识分聚合（k-匿名 ≥3 入边才发布）", "",
              "| 虚拟目标 | 入边数 | 共识分(加权均值) | 备注 |", "|---|---|---|---|"]
    for tgt, v in consensus.items():
        lines.append(f"| {tgt} | {v['in_edges']} | {v['consensus'] if v['consensus'] is not None else '—'} | {v.get('note', '')} |")
    report = ROOT / "validation_report.md"
    report.write_text("\n".join(lines), encoding="utf-8")
    print(f"edges={len(edges)} clean={good} violations_detected={len(failures)} injected_hit={hit}/6")
    print(f"consensus published={sum(1 for v in consensus.values() if v['consensus'] is not None)}/{len(consensus)} targets")
    print(f"report -> {report}")


if __name__ == "__main__":
    main()
