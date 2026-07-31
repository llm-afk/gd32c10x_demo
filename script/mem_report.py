#!/usr/bin/env python3
"""mem_report.py — GNU ld map file memory usage.

Usage:  python mem_report.py [file.map]
"""

import re, sys


# ── Config ────────────────────────────────────────────────────
# Items to display (one line each).
# ".text", ".bss"  → output sections (size of that section)
# "FLASH", "RAM"   → memory regions  (total used in that region)

SHOW = [
    "FLASH",
    ".text",
    ".rodata",
    "RAM",
    ".data",
    ".bss",
    ".heap_stack",
]


# ── Formatting ────────────────────────────────────────────────

def _human(n):
    """Bytes → compact string: 1024 → '1K', 65536 → '64K', 304 → '304'."""
    for suffix, div in (("M", 1 << 20), ("K", 1 << 10)):
        if n >= div:
            v = n / div
            return f"{v:.1f}{suffix}" if v != int(v) else f"{int(v)}{suffix}"
    return str(n)


def _bar(pct, w=20):
    """Render progress bar (thin line style: ━/─)."""
    f = round(pct / 100 * w)
    f = min(max(1 if pct > 0 else 0, f), w)
    e = w - f
    return "━" * f + "─" * e


# ── Parser ────────────────────────────────────────────────────

def parse_map(path):
    """Extract memory regions and output sections from a GNU ld map file."""
    regions, sections, seen = {}, [], set()
    in_map = False

    with open(path, encoding="utf-8", errors="ignore") as f:
        for line in f:
            m = re.match(
                r"^(\S+)\s+(0x[\da-fA-F]+)\s+(0x[\da-fA-F]+)\s+[xrw!]+", line
            )
            if m and m.group(1) != "*default*":
                regions[m.group(1)] = {
                    "origin": int(m.group(2), 16),
                    "length": int(m.group(3), 16),
                }
                continue

            if "Linker script and memory map" in line:
                in_map = True
                continue
            if not in_map:
                continue

            # Output section (not indented, or minimal indent)
            m = re.match(
                r"^(\.[\w.]+)\s+(0x[\da-fA-F]+)\s+(0x[\da-fA-F]+)\b", line
            )
            if not m or m.group(1) in seen:
                continue
            seen.add(m.group(1))

            addr, size = int(m.group(2), 16), int(m.group(3), 16)
            vma_region = next(
                (r for r, i in regions.items()
                 if i["origin"] <= addr < i["origin"] + i["length"]),
                None,
            )
            lma_m = re.search(r"load address (0x[\da-fA-F]+)", line)
            if lma_m:
                lma_addr = int(lma_m.group(1), 16)
                lma_region = next(
                    (r for r, i in regions.items()
                     if i["origin"] <= lma_addr < i["origin"] + i["length"]),
                    None,
                )
            else:
                lma_region = vma_region

            sections.append({
                "name": m.group(1), "addr": addr, "size": size,
                "region": vma_region, "lma_region": lma_region,
            })

    return sections, regions


# ── Report ────────────────────────────────────────────────────

def report(path):
    """Print one line per entry in SHOW."""
    sections, regions = parse_map(path)
    sys.stdout.reconfigure(encoding="utf-8")

    # Build section lookup
    sec_map = {}
    for s in sections:
        if s["region"] and s["addr"] > 0 and s["name"] not in sec_map:
            sec_map[s["name"]] = s

    # Resolve each SHOW entry to (used, capacity)
    items = []
    for name in SHOW:
        if name.startswith("."):
            # Output section
            if name not in sec_map:
                continue
            s = sec_map[name]
            used = s["size"]
            cap = regions[s["region"]]["length"]
        else:
            # Memory region (Universal VMA/LMA sum, ZERO hardcoding)
            if name not in regions:
                continue
            cap = regions[name]["length"]
            used = sum(
                s["size"] for s in sec_map.values()
                if s["region"] == name or (s["lma_region"] == name and s["lma_region"] != s["region"] and not s["name"].startswith(".bss") and not s["name"].startswith(".stack") and not s["name"].startswith(".heap"))
            )
        items.append((name, used, cap))

    if not items:
        return
    print()  # 在报告输出前加上一个换行符，与上方编译输出优雅分隔
    items_disp = []
    for name, used, cap in items:
        dname = f"  {name}" if name.startswith(".") else name
        items_disp.append((dname, used, cap))

    name_w = max(len(d) for d, _, _ in items_disp)
    used_w = max(len(_human(u)) for _, u, _ in items_disp)
    cap_w  = max(len(_human(c)) for _, _, c in items_disp)

    for dname, used, cap in items_disp:
        pct = used / cap * 100 if cap else 0
        bar = _bar(pct)
        sep = "  " if bar else ""
        u_str = _human(used)
        c_str = _human(cap)
        print(
            f"{dname:<{name_w}s}    {bar}{sep}"
            f"{pct:>5.1f}%   ({u_str:>{used_w}s} / {c_str:<{cap_w}s})"
        )


# ── CLI ───────────────────────────────────────────────────────

if __name__ == "__main__":
    path = next(
        (a for a in sys.argv[1:] if a.endswith(".map")),
        "build/firmware.map",
    )
    report(path)

