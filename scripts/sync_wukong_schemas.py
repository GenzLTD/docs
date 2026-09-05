#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""同步 GenzLTD/Wukong 的 Layer0/1/2 schema 到 lab-genz-brain-m2，并做一致性校验。

用途（对应 docs/Wukong-lab-Schema同步对接规范.md）：
  1. 真源在 GenzLTD/Wukong/docs/schemas/（layer0_identity / layer1_interest / layer2_profile）
  2. 消费方 lab-genz-brain-m2/schemas/ 维护一份与真源逐字节一致的拷贝
  3. 本工具负责 diff / check / sync 三步，作为「Wukong → lab」promote 流程的唯一入口

用法（任选一个 mode）：
  python sync_wukong_schemas.py --mode diff   --wukong <Wukong本地路径>
  python sync_wukong_schemas.py --mode check  --wukong <Wukong本地路径>
  python sync_wukong_schemas.py --mode sync   --wukong <Wukong本地路径> [--lab <lab本地路径>]

说明：
  - Wukong 需先 `gh repo clone GenzLTD/Wukong` 到本地，或复用已有工作区。
  - 默认 lab 路径 = 本脚本上级的父目录下 lab-genz-brain-m2；可用 --lab 覆盖。
  - 只操作官方命名的 JSON，不搬运 vc_*.json / *.md 等其他资产。
"""

import argparse
import difflib
import hashlib
import shutil
import sys
from pathlib import Path

SCHEMA_NAMES = [
    "layer0_identity.json",
    "layer1_interest.json",
    "layer2_profile.json",
]

WUKONG_SCHEMA_DIR = Path("docs/schemas")   # 相对 Wukong 仓库根
LAB_SCHEMA_DIR = Path("schemas")           # 相对 lab 仓库根


def _sha256(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def _diff_text(a: Path, b: Path) -> str:
    a_lines = a.read_text(encoding="utf-8").splitlines(keepends=True)
    b_lines = b.read_text(encoding="utf-8").splitlines(keepends=True)
    return "".join(difflib.unified_diff(a_lines, b_lines, fromfile=str(a), tofile=str(b)))


def _resolve_lab(args) -> Path:
    if args.lab:
        return Path(args.lab)
    default = Path(__file__).resolve().parent.parent.parent / "lab-genz-brain-m2"
    return default


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--mode", required=True, choices=["diff", "check", "sync"])
    ap.add_argument("--wukong", required=True, help="GenzLTD/Wukong 本地 clone 路径")
    ap.add_argument("--lab", default=None, help="lab-genz-brain-m2 本地路径（默认自动探测）")
    args = ap.parse_args()

    wukong = Path(args.wukong)
    lab = _resolve_lab(args)
    src = wukong / WUKONG_SCHEMA_DIR
    dst = lab / LAB_SCHEMA_DIR

    if not wukong.exists():
        sys.exit(f"ERROR: Wukong 路径不存在: {wukong}")
    if not lab.exists():
        sys.exit(f"ERROR: lab 路径不存在: {lab}")

    diffs = []
    for name in SCHEMA_NAMES:
        s = src / name
        d = dst / name
        if not s.exists():
            diffs.append((name, "MISSING_IN_WUKONG", None))
            continue
        if not d.exists():
            diffs.append((name, "MISSING_IN_LAB", str(s)))
            continue
        if _sha256(s) != _sha256(d):
            diffs.append((name, "DIFFERS", _diff_text(s, d)))

    print(f"[Wukong schema 同步]")
    print(f"  真源: {src}")
    print(f"  目标: {dst}\n")

    if not diffs:
        print("OK: 全部 3 个 schema 与 Wukong 真源逐字节一致。")
        return 0

    print(f"发现 {len(diffs)} 个差异：\n")
    for name, state, detail in diffs:
        print(f"  - {name}: {state}")
        if detail and state == "DIFFERS":
            print("    diff 摘要:")
            for line in detail.splitlines()[:40]:
                print("      " + line)
        elif detail and state == "MISSING_IN_LAB":
            print(f"    （lab 缺少该文件；来源 {detail}）")
    print()

    if args.mode in ("diff", "check"):
        print("结论: DIFFS FOUND（未做任何写入）。")
        print("  - 若状态为 'DIFFERS': 说明 lab 已漂移或 Wukong 已更新，需评审后再 promote。")
        print("  - 若状态为 'MISSING_IN_LAB': 说明 lab 尚未纳入该 schema，需同步。")
        return 2

    # -- mode=sync：写回 lab ----------------------------------------------
    print(">>> 开始 sync（写回 lab）...")
    dst.mkdir(parents=True, exist_ok=True)
    for name, state, _ in diffs:
        s = src / name
        d = dst / name
        if state == "MISSING_IN_WUKONG":
            print(f"  !! {name}: 真源缺失，跳过（忽略）")
            continue
        shutil.copy2(s, d)
        print(f"  copied {name}  (sha256={_sha256(d)[:12]})")
    print("\n完成。请在 lab 仓库执行:")
    print("  .venv/bin/python -m unittest discover -s tests   # 17 用例应全绿")
    print("  python main.py drift    # 或 .venv/bin/python main.py drift，应为 OK")
    print("然后 commit + push lab 仓库。见规范文档的 promote 流程。")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())