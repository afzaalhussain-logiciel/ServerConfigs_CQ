#!/usr/bin/env python3
"""
Turn diff-cover's JSON report into a Cobertura XML containing ONLY the changed
lines, so Jenkins' Coverage plugin can show modified-code coverage as its own
report - with no reference build and no dependency on a baseline Jenkins job.

Filenames are emitted relative to <strip-prefix> so they match the paths gcovr
writes, letting both reports share one sourceDirectories setting in Jenkins.

Usage: mk-newcode-cobertura.py <diff-cover.json> <out.xml> [strip-prefix]
"""
import json
import sys
import time
import xml.etree.ElementTree as ET


def main(src, dst, strip=""):
    d = json.load(open(src))
    stats = d.get("src_stats", {}) or {}

    total_cov = sum(len(v.get("covered_lines", [])) for v in stats.values())
    total_all = total_cov + sum(len(v.get("violation_lines", [])) for v in stats.values())
    rate = (total_cov / total_all) if total_all else 0.0

    cov = ET.Element("coverage", {
        "line-rate": f"{rate:.4f}",
        "branch-rate": "0",
        "lines-covered": str(total_cov),
        "lines-valid": str(total_all),
        "branches-covered": "0",
        "branches-valid": "0",
        "complexity": "0",
        "version": "diff-cover",
        "timestamp": str(int(time.time())),
    })
    ET.SubElement(ET.SubElement(cov, "sources"), "source").text = "."
    packages = ET.SubElement(cov, "packages")
    pkg = ET.SubElement(packages, "package", {
        "name": "changed-lines", "line-rate": f"{rate:.4f}",
        "branch-rate": "0", "complexity": "0",
    })
    classes = ET.SubElement(pkg, "classes")

    for path, v in sorted(stats.items()):
        if strip and path.startswith(strip):
            path = path[len(strip):]
        covered = set(v.get("covered_lines", []))
        missed = set(v.get("violation_lines", []))
        if not covered and not missed:
            continue
        n = len(covered) + len(missed)
        cls = ET.SubElement(classes, "class", {
            "name": path.replace("/", ".").rsplit(".", 1)[0],
            "filename": path,
            "line-rate": f"{(len(covered) / n) if n else 0:.4f}",
            "branch-rate": "0", "complexity": "0",
        })
        ET.SubElement(cls, "methods")
        lines = ET.SubElement(cls, "lines")
        for ln in sorted(covered | missed):
            ET.SubElement(lines, "line", {
                "number": str(ln),
                "hits": "1" if ln in covered else "0",
                "branch": "false",
            })

    ET.ElementTree(cov).write(dst, encoding="utf-8", xml_declaration=True)
    print(f"changed lines: {total_all}  covered: {total_cov}  "
          f"rate: {rate * 100:.2f}%  -> {dst}")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else "")
