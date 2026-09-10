# -*- coding: utf-8 -*-
"""
虚拟互评样例生成器（零真实个人信息）
- 人格来源：dsh-bridle 诗词语料作者（历史诗人，虚拟员工沙盘）
- 结构对齐：docs/evaluation_edge.schema.v0.json + trust.v1 Ed25519 签名格式
- 故意注入 6 类违例样例，用于验证校验器完备性
"""
import json, hashlib, base64, random, datetime
from pathlib import Path
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
from cryptography.hazmat.primitives import serialization

ROOT = Path(__file__).parent
CORPUS = Path("F:/GenzLTD_org_backup_github/dsh-bridle/data/poetry_full_export.json")
SALT = "genzltd-virtual-poetry-sandbox-v0"

# 12 位虚拟员工（诗词语料作者），姓名仅存在于映射表
PERSONAS = ["李白", "杜甫", "元稹", "白居易", "刘禹锡", "柳宗元",
            "苏轼", "黄庭坚", "王维", "孟浩然", "韩愈", "欧阳修"]

WEIGHTS = {"cooperation": 0.20, "creativity": 0.20, "responsibility": 0.30,
           "initiative": 0.15, "discipline": 0.15}
BARS_ANCHORS = {
    "cooperation":   ["主动补位同事缺口", "按分工完成本职", "需督促才配合", "推诿协作事务", "拒绝配合"],
    "creativity":    ["提出可落地的新方案", "有改进建议", "按既定流程执行", "抵触流程变更", "僵化执行"],
    "responsibility": ["主动担责并兜底", "按时保质交付", "需提醒后补交", "多次延期", "失联弃责"],
    "initiative":    ["超前规划主动汇报", "响应迅速", "被动等待指令", "催促后才动", "多次催办无果"],
    "discipline":    ["率先垂范守纪律", "遵守制度", "偶有迟到", "屡次违反", "严重违纪"],
}
FREE_TEXT_POOL = [
    "跨部门协调资源及时，承诺事项均按期兑现。",
    "技术判断准确，但向上同步偏少。",
    "抗压能力强，项目攻坚阶段连续兜底。",
    "文档习惯好，交接成本低。",
    "对本职范围内事务响应快，跨线协作偏保守。",
]


def pseudo_id(name: str) -> str:
    return "psn_" + hashlib.sha256(f"{name}@{SALT}".encode()).hexdigest()[:10]


def canonical_body(edge: dict) -> bytes:
    body = {k: v for k, v in edge.items() if k != "signature"}
    return json.dumps(body, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode()


def sign_edge(edge: dict, key: Ed25519PrivateKey) -> None:
    sig = key.sign(canonical_body(edge))
    edge["signature"] = {"algorithm": "Ed25519", "format": "looma_sig_v1",
                         "value": base64.b64encode(sig).decode()}


def main():
    rng = random.Random(20260910)
    corpus = json.loads(CORPUS.read_text(encoding="utf-8"))
    by_author = {}
    for meta, doc in zip(corpus["metas"], corpus["docs"]):
        by_author.setdefault(meta["author"], []).append(doc)
    # 繁简混排别名：语料部分作者名为繁体
    ALIAS = {"刘禹锡": "劉禹錫", "王维": "王維"}
    missing = [p for p in PERSONAS if ALIAS.get(p, p) not in by_author]
    if missing:
        raise SystemExit(f"人格缺失于语料: {missing}")
    by_author = {p: by_author[ALIAS.get(p, p)] for p in PERSONAS}

    # 1) 独立身份映射表（模拟物理分离保管）
    identity_map = {p: {"pseudo_id": pseudo_id(p),
                        "note": "虚拟员工，姓名仅存于此映射表，入图数据不得出现"} for p in PERSONAS}
    (ROOT / "identity_map.json").write_text(
        json.dumps(identity_map, ensure_ascii=False, indent=2), encoding="utf-8")

    # 2) 签名密钥（一次性测试密钥，非生产）
    key = Ed25519PrivateKey.generate()
    (ROOT / "demo_ed25519_public.pem").write_bytes(
        key.public_key().public_bytes(serialization.Encoding.PEM,
                                      serialization.PublicFormat.SubjectPublicKeyInfo))

    # 3) 评价计划：每个主目标 ≥3 条入边（peer/superior/subordinate）
    plan = [
        # (cycle, source, target, role)
        ("2026Q3", "杜甫", "李白", "peer"), ("2026Q3", "王维", "李白", "peer"),
        ("2026Q3", "孟浩然", "李白", "peer"), ("2026Q3", "韩愈", "李白", "superior"),
        ("2026Q3", "李白", "杜甫", "peer"), ("2026Q3", "王维", "杜甫", "peer"),
        ("2026Q3", "韩愈", "杜甫", "superior"), ("2026Q3", "孟浩然", "杜甫", "peer"),
        ("2026Q3", "白居易", "元稹", "peer"), ("2026Q3", "刘禹锡", "元稹", "peer"),
        ("2026Q3", "欧阳修", "元稹", "superior"), ("2026Q3", "元稹", "白居易", "peer"),
        ("2026Q3", "刘禹锡", "白居易", "peer"), ("2026Q3", "欧阳修", "白居易", "superior"),
        ("2026Q3", "柳宗元", "刘禹锡", "peer"), ("2026Q3", "白居易", "刘禹锡", "peer"),
        ("2026Q3", "韩愈", "柳宗元", "superior"), ("2026Q3", "刘禹锡", "柳宗元", "peer"),
        ("2026Q3", "苏轼", "黄庭坚", "superior"), ("2026Q3", "欧阳修", "黄庭坚", "superior"),
        ("2026Q3", "王安石自评占位", "黄庭坚", "peer") if False else ("2026Q3", "王维", "黄庭坚", "peer"),
        ("2026Q3", "黄庭坚", "苏轼", "subordinate"), ("2026Q3", "欧阳修", "苏轼", "superior"),
        ("2026Q3", "王维", "苏轼", "peer"),
        ("2026Q3", "孟浩然", "王维", "peer"), ("2026Q3", "李白", "王维", "peer"),
        ("2026Q3", "杜甫", "王维", "peer"),
        ("2026Q4", "白居易", "元稹", "peer"), ("2026Q4", "刘禹锡", "白居易", "peer"),
        ("2026Q4", "苏轼", "黄庭坚", "superior"),
    ]
    persona_ids = {p: pseudo_id(p) for p in PERSONAS}

    def make_items(edge_seed: int, bias: float):
        r = random.Random(edge_seed)
        items = []
        # 25 对强迫选择（mgmt-eval-1.0 第一部分）
        for i in range(25):
            choice = "A" if r.random() < (0.62 + bias) else "B"
            items.append({"dim_id": f"pair_{i+1:02d}", "method": "forced_choice",
                          "choice": choice, "raw_score": 2 if choice == "A" else 1})
        # 5 维加权（第二部分），bars 锚点文本
        per_dim = {}
        for dim, w in WEIGHTS.items():
            level = min(5, max(1, round(3.4 + bias * 3 + r.uniform(-0.7, 0.7))))
            per_dim[dim] = round(level, 2)
            items.append({"dim_id": dim, "method": "bars", "level": level,
                          "raw_score": level, "anchored_text": BARS_ANCHORS[dim][level - 1]})
        weighted_total = round(sum(per_dim[d] * w for d, w in WEIGHTS.items()), 3)
        return items, per_dim, weighted_total

    edges, n = [], 0
    for idx, (cycle, src, tgt, role) in enumerate(plan):
        n += 1
        bias = rng.uniform(-0.12, 0.12)
        items, per_dim, wtotal = make_items(hash(f"{src}->{tgt}@{cycle}") & 0xFFFFFFFF, bias)
        poem = rng.choice(by_author[src])
        edge = {
            "edge_id": f"edge_{hashlib.sha256(f'{src}->{tgt}@{cycle}@{idx}'.encode()).hexdigest()[:8]}",
            "cycle_id": cycle,
            "source_pseudo_id": persona_ids[src],
            "target_pseudo_id": persona_ids[tgt],
            "source_role": role,
            "instrument_version": "mgmt-eval-1.0",
            "items": items,
            "scored": {"per_dim": per_dim, "weighted_total": wtotal},
            "free_text": rng.choice(FREE_TEXT_POOL),
            "evidence_refs": ["sha256:" + hashlib.sha256(poem.encode()).hexdigest()],
            "consent": {"granted": True, "scope": "cycle-2026 共识评价（虚拟沙盘授权）"},
            "created_at": datetime.datetime(2026, 9, rng.randint(1, 9), 10, rng.randint(0, 59)).isoformat() + "+08:00",
        }
        sign_edge(edge, key)
        edges.append(edge)

    # 4) 注入 6 类违例样例（deepcopy 隔离，各自独立 source→target 以便单因检出）
    import copy
    # T1 自评边（source==target，防自证红线）
    t1 = {**copy.deepcopy(edges[0]), "edge_id": "edge_dead0001", "cycle_id": "2026Q3",
          "source_pseudo_id": persona_ids["李白"], "target_pseudo_id": persona_ids["李白"],
          "source_role": "self"}
    sign_edge(t1, key); edges.append(t1)
    # T2 重复边（与 edges[0] 同 cycle+source+target，不同 edge_id）
    t2 = {**copy.deepcopy(edges[0]), "edge_id": "edge_dead0002"}
    sign_edge(t2, key); edges.append(t2)
    # T3 free_text 含手机号（PII 脱敏红线）
    t3 = {**copy.deepcopy(edges[0]), "edge_id": "edge_dead0003",
          "source_pseudo_id": persona_ids["欧阳修"], "target_pseudo_id": persona_ids["孟浩然"],
          "free_text": "沟通很好，随时打 13812345678 找他。"}
    sign_edge(t3, key); edges.append(t3)
    # T4 free_text 含真实姓名（伪匿名脱敏红线）
    t4 = {**copy.deepcopy(edges[0]), "edge_id": "edge_dead0004",
          "source_pseudo_id": persona_ids["苏轼"], "target_pseudo_id": persona_ids["刘禹锡"],
          "free_text": "元稹连轴转三天不带停，值得表扬。"}
    sign_edge(t4, key); edges.append(t4)
    # T5 未获知情同意（consent.granted=false，不入共识）
    t5 = {**copy.deepcopy(edges[0]), "edge_id": "edge_dead0005",
          "source_pseudo_id": persona_ids["黄庭坚"], "target_pseudo_id": persona_ids["柳宗元"],
          "consent": {"granted": False, "scope": "拒绝授权"}}
    sign_edge(t5, key); edges.append(t5)
    # T6 篡改签名（先签名后篡改 items，签名验证必须失败）
    t6 = copy.deepcopy(edges[0])
    t6["edge_id"] = "edge_dead0006"
    t6["source_pseudo_id"] = persona_ids["韩愈"]
    t6["target_pseudo_id"] = persona_ids["王维"]
    sign_edge(t6, key)
    t6["items"][0]["raw_score"] = 1 - t6["items"][0]["raw_score"]  # 篡改后沿用旧签名 → 校验失败
    edges.append(t6)

    out = ROOT / "virtual_edges.jsonl"
    with out.open("w", encoding="utf-8") as f:
        for e in edges:
            f.write(json.dumps(e, ensure_ascii=False) + "\n")
    print(f"generated {len(edges)} edges -> {out}")
    print(f"  normal: 30, injected violations: 6 (T1 self / T2 dup / T3 phone / T4 real-name / T5 no-consent / T6 bad-signature)")


if __name__ == "__main__":
    main()
