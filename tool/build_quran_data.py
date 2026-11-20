#!/usr/bin/env python3
"""Builds assets/quran/juz30.json from published Quran datasets and verifies it.

The Quranic text is NEVER typed or generated here. It is extracted verbatim from:

  PRIMARY   quran-validator@1.3.0   data/quran-verses.json
            (QUL - Quranic Universal Library, Uthmani, Madinah Mushaf)
  CHECK 1   quran-json@3.1.2        dist/quran.json     (QuranEnc Uthmani text)
  CHECK 2   @muslims-community/quran@1.1.0  dist/quran.json (Tanzil Uthmani-min,
            also used for the per-ayah Juz number and ayah counts)

Fetch the three packages with:
    npm pack quran-validator@1.3.0 quran-json@3.1.2 @muslims-community/quran@1.1.0
and unpack each .tgz, then run:

    python3 tool/build_quran_data.py \
        --qul   <dir>/package/data/quran-verses.json \
        --quranenc <dir>/package/dist/quran.json \
        --tanzil   <dir>/package/dist/quran.json

Any failed hard check aborts the build (exit code 1).
"""
import argparse
import hashlib
import json
import sys
import unicodedata
from pathlib import Path

JUZ = 30
FIRST_SURAH = 78
LAST_SURAH = 114
EXPECTED_AYAH_COUNT = 564

# Standard Hafs ayah counts (Kufan numbering) for surahs 78..114, used only as an
# additional hard check against the three datasets.
EXPECTED_COUNTS = {
    78: 40, 79: 46, 80: 42, 81: 29, 82: 19, 83: 36, 84: 25, 85: 22, 86: 17,
    87: 19, 88: 26, 89: 30, 90: 20, 91: 15, 92: 21, 93: 11, 94: 8, 95: 8,
    96: 19, 97: 5, 98: 8, 99: 8, 100: 11, 101: 11, 102: 8, 103: 3, 104: 9,
    105: 5, 106: 4, 107: 7, 108: 3, 109: 6, 110: 3, 111: 5, 112: 4, 113: 5,
    114: 6,
}

# Letter-level normalisation used ONLY for cross-checking (never for output).
_SKELETON_MAP = {
    "ٱ": "ا", "أ": "ا", "إ": "ا", "آ": "ا", "ى": "ي", "ی": "ي",
    "ک": "ك", "ة": "ه", "ؤ": "و", "ئ": "ي", "ء": "", "ـ": "",
}


def skeleton(text: str) -> str:
    text = unicodedata.normalize("NFD", text)
    kept = []
    for ch in text:
        cp = ord(ch)
        if unicodedata.category(ch) in ("Mn", "Cf"):
            continue
        if 0x06D6 <= cp <= 0x06ED:  # Quranic annotation signs
            continue
        kept.append(ch)
    text = "".join(kept)
    for src, dst in _SKELETON_MAP.items():
        text = text.replace(src, dst)
    return text.replace(" ", "")


# Encoding-convention mapping used ONLY to estimate how many ayahs agree
# mark-for-mark between two datasets that encode marks differently.
_CONVENTION_MAP = {
    "ٞ": "ٌ", "ٗ": "ً", "ٖ": "ٍ",
    "ۡ": "ْ", "ى": "ي", "ـ": "", "۞": "",
}


def mark_canon(text: str):
    text = unicodedata.normalize("NFD", text)
    for src, dst in _CONVENTION_MAP.items():
        text = text.replace(src, dst)
    text = text.replace(" ", "")
    out, cur = [], None
    for ch in text:
        if unicodedata.category(ch) == "Mn":
            if cur is None:
                cur = ["", []]
            cur[1].append(ch)
        else:
            if cur is not None:
                out.append(cur)
            cur = [ch, []]
    if cur is not None:
        out.append(cur)
    res = []
    for base, marks in out:
        marks = ["ْ" if (base in "اىو" and m == "۟") else m for m in marks]
        res.append((base, tuple(sorted(marks))))
    return res


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fail(msg: str):
    print("FAILED CHECK:", msg, file=sys.stderr)
    sys.exit(1)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--qul", required=True)
    ap.add_argument("--quranenc", required=True)
    ap.add_argument("--tanzil", required=True)
    ap.add_argument("--out", default="assets/quran/juz30.json")
    ap.add_argument("--report", default="docs/DATA_VERIFICATION.md")
    args = ap.parse_args()

    qul_p, enc_p, tz_p = Path(args.qul), Path(args.quranenc), Path(args.tanzil)
    qul_raw = json.loads(qul_p.read_text(encoding="utf-8"))
    enc_raw = json.loads(enc_p.read_text(encoding="utf-8"))
    tz_raw = json.loads(tz_p.read_text(encoding="utf-8"))

    qul = {(v["surah"], v["ayah"]): v["text"] for v in qul_raw}
    enc = {(s["id"], v["id"]): v["text"] for s in enc_raw for v in s["verses"]}
    tz = {(s["id"], v["id"]): v["text"] for s in tz_raw["surahs"] for v in s["ayat"]}
    tz_juz = {(s["id"], v["id"]): v["juz"] for s in tz_raw["surahs"] for v in s["ayat"]}
    enc_meta = {s["id"]: s for s in enc_raw}
    tz_meta = {s["id"]: s for s in tz_raw["surahs"]}

    # ---- Hard checks --------------------------------------------------------
    for name, d in (("QUL", qul), ("QuranEnc", enc), ("Tanzil", tz)):
        if len(d) != 6236:
            fail(f"{name} does not contain 6236 ayahs (has {len(d)})")

    juz_keys = sorted(k for k, j in tz_juz.items() if j == JUZ)
    range_keys = sorted(k for k in qul if FIRST_SURAH <= k[0] <= LAST_SURAH)
    if juz_keys != range_keys:
        fail("Tanzil Juz-30 membership differs from surah 78:1 .. 114:6")
    if juz_keys[0] != (78, 1) or juz_keys[-1] != (114, 6):
        fail("Juz 30 does not start at 78:1 and end at 114:6")
    if len(juz_keys) != EXPECTED_AYAH_COUNT:
        fail(f"Juz 30 ayah count is {len(juz_keys)}, expected {EXPECTED_AYAH_COUNT}")

    surahs_out = []
    for n in range(FIRST_SURAH, LAST_SURAH + 1):
        count = EXPECTED_COUNTS[n]
        counts = {
            "expected": count,
            "QUL": sum(1 for k in qul if k[0] == n),
            "QuranEnc": enc_meta[n]["total_verses"],
            "Tanzil": tz_meta[n]["numberOfAyahs"],
        }
        if len(set(counts.values())) != 1:
            fail(f"ayah-count disagreement in surah {n}: {counts}")
        ayahs = []
        for a in range(1, count + 1):
            if (n, a) not in qul:
                fail(f"missing ayah {n}:{a}")
            text = qul[(n, a)]
            if not text or text != text.strip():
                fail(f"empty or untrimmed text at {n}:{a}")
            ayahs.append(text)
        surahs_out.append({
            "number": n,
            "name_ar": enc_meta[n]["name"],
            "name_en": enc_meta[n]["transliteration"],
            "ayah_count": count,
            "ayahs": ayahs,
        })

    # Letter-level agreement between independent sources (hard check for QuranEnc,
    # reported for Tanzil because its "minimal" text spells wasl-alef differently).
    enc_bad = [k for k in juz_keys if skeleton(qul[k]) != skeleton(enc[k])]
    if enc_bad:
        fail(f"QUL vs QuranEnc consonant text differs at {enc_bad[:10]}")
    tz_bad = [k for k in juz_keys if skeleton(qul[k]) != skeleton(tz[k])]

    # Mark-level agreement estimate (informational).
    mark_bad = [k for k in juz_keys if mark_canon(qul[k]) != mark_canon(enc[k])]

    out = {
        "meta": {
            "juz": JUZ,
            "first": "78:1",
            "last": "114:6",
            "ayah_count": EXPECTED_AYAH_COUNT,
            "surah_count": len(surahs_out),
            "text_source": "QUL (Quranic Universal Library, qul.tarteel.ai) Uthmani text, "
                           "Madinah Mushaf, via npm quran-validator@1.3.0",
            "surah_names_source": "quran-json@3.1.2",
            "note": "Text is copied verbatim from the source dataset. "
                    "See docs/DATA_VERIFICATION.md.",
        },
        "surahs": surahs_out,
    }
    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(
        json.dumps(out, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")

    # ---- Report -------------------------------------------------------------
    def fmt(keys):
        return ", ".join(f"{s}:{a}" for s, a in keys) if keys else "none"

    lines = [
        "# Juz 30 data verification report",
        "",
        "Generated by `tool/build_quran_data.py`. All checks below were executed "
        "when `assets/quran/juz30.json` was built.",
        "",
        "## Sources",
        "",
        "| Role | Dataset | sha256 of file used |",
        "|---|---|---|",
        f"| Primary text (shipped) | QUL Uthmani via npm `quran-validator@1.3.0` | `{sha256(qul_p)}` |",
        f"| Cross-check 1 | QuranEnc Uthmani via npm `quran-json@3.1.2` | `{sha256(enc_p)}` |",
        f"| Cross-check 2 | Tanzil Uthmani-min via npm `@muslims-community/quran@1.1.0` | `{sha256(tz_p)}` |",
        f"| Output | `assets/quran/juz30.json` | `{sha256(out_path)}` |",
        "",
        "## Hard checks (build aborts if any fails)",
        "",
        "- All three datasets contain 6,236 ayahs.",
        "- Tanzil's per-ayah Juz field puts exactly 78:1 through 114:6 in Juz 30, identical "
        "to the surah-range selection (surahs 78-114).",
        f"- Juz 30 contains {EXPECTED_AYAH_COUNT} ayahs across {len(surahs_out)} surahs.",
        "- Per-surah ayah counts agree between the standard Hafs count table, QUL, "
        "QuranEnc and Tanzil for all 37 surahs.",
        "- No ayah is missing, empty, or has leading/trailing whitespace.",
        f"- Letter-level (diacritics removed) text of QUL equals QuranEnc for "
        f"{EXPECTED_AYAH_COUNT - len(enc_bad)}/{EXPECTED_AYAH_COUNT} ayahs.",
        "",
        "## Informational results",
        "",
        f"- Letter-level agreement QUL vs Tanzil: "
        f"{EXPECTED_AYAH_COUNT - len(tz_bad)}/{EXPECTED_AYAH_COUNT}. "
        f"Differing ayah(s): {fmt(tz_bad)}. Annotation signs (U+06D6-U+06ED, such as the "
        "rub-el-hizb sign at 100:9, the sajdah sign and waqf signs) are ignored in "
        "letter-level comparisons because Tanzil's minimal text omits some of them.",
        f"- Mark-level agreement QUL vs QuranEnc after mapping known encoding "
        f"conventions (open-tanween forms, silent-alef sign, sukun form, tatweel): "
        f"{EXPECTED_AYAH_COUNT - len(mark_bad)}/{EXPECTED_AYAH_COUNT} ayahs identical.",
        f"- The remaining {len(mark_bad)} ayahs have identical letters but encode a "
        "secondary mark differently (for example small-meem tanween forms or the "
        "hamza/maddah mark on alef). The app uses the QUL text for all of them. "
        "Because there is no authoritative mark-level reference available offline, "
        "**compare these ayahs against a printed Madinah Mushaf if you want "
        "mark-level certainty:**",
        "",
        "  " + fmt(mark_bad),
        "",
        "## What is not covered",
        "",
        "- No dataset here is the physical printed Mushaf; this report shows agreement "
        "between independent digital editions, not a proof of correctness.",
        "- Waqf (pause) signs and other annotation marks are kept exactly as in QUL.",
        "",
    ]
    rpt = Path(args.report)
    rpt.parent.mkdir(parents=True, exist_ok=True)
    rpt.write_text("\n".join(lines), encoding="utf-8")

    print(f"OK: wrote {out_path} ({EXPECTED_AYAH_COUNT} ayahs, {len(surahs_out)} surahs)")
    print(f"QuranEnc consonant mismatches: {len(enc_bad)} | Tanzil: {len(tz_bad)} | "
          f"mark-level residual: {len(mark_bad)}")


if __name__ == "__main__":
    main()
