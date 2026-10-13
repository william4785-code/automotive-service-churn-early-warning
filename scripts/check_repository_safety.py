from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MAX_FILE_BYTES = 1 * 1024 * 1024

ALLOWED_EXACT = {
    ".env.example",
    ".gitignore",
    "LICENSE",
    "README.md",
    "data/synthetic_example.csv",
}
ALLOWED_ROOT_SUFFIXES = {
    "R": {".R"},
    "config": {".yml", ".yaml"},
    "docs": {".md"},
    "scripts": {".R", ".py"},
    "tests": {".R"},
}
FORBIDDEN_ROOTS = {
    "cache",
    "checkpoints",
    "logs",
    "models",
    "monitoring",
    "outputs",
    "prospective",
    "tmp",
}
FORBIDDEN_SUFFIXES = {
    ".7z", ".bak", ".csv", ".db", ".dump", ".duckdb", ".feather",
    ".gz", ".log", ".parquet", ".pdf", ".rda", ".rds", ".rdata",
    ".sqlite", ".tar", ".tsv", ".xls", ".xlsx", ".zip",
}


def run_git(*args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *args],
        cwd=ROOT,
        check=check,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )


def candidate_paths() -> list[str]:
    result = run_git("ls-files", "--cached", "--others", "--exclude-standard")
    return sorted(line for line in result.stdout.splitlines() if line.strip())


def staged_paths() -> list[str]:
    result = run_git(
        "diff", "--cached", "--name-only", "--diff-filter=ACMR", check=False
    )
    return sorted(line for line in result.stdout.splitlines() if line.strip())


def history_objects() -> list[tuple[str, str]]:
    result = run_git("rev-list", "--objects", "--all", check=False)
    objects: list[tuple[str, str]] = []
    for line in result.stdout.splitlines():
        object_id, separator, path = line.partition(" ")
        if separator and path:
            objects.append((object_id, path))
    return objects


def is_allowed_path(relative: str) -> bool:
    normalized = Path(relative).as_posix()
    if normalized in ALLOWED_EXACT:
        return True
    parts = Path(normalized).parts
    if not parts:
        return False
    allowed_suffixes = ALLOWED_ROOT_SUFFIXES.get(parts[0])
    return bool(allowed_suffixes and Path(normalized).suffix in allowed_suffixes)


def path_findings(relative: str) -> list[str]:
    normalized = Path(relative).as_posix()
    parts = tuple(part.lower() for part in Path(normalized).parts)
    suffix = Path(normalized).suffix.lower()
    findings: list[str] = []
    if parts and parts[0] in FORBIDDEN_ROOTS:
        findings.append("T0 runtime/model/data directory")
    if suffix in FORBIDDEN_SUFFIXES and normalized != "data/synthetic_example.csv":
        findings.append(f"forbidden artifact suffix {suffix}")
    if not is_allowed_path(normalized):
        findings.append("path is not on the reviewed allowlist")
    return findings


def text_findings(text: str, public_mode: bool) -> list[str]:
    findings: list[str] = []
    if re.search(r"(?i)[a-z]:[\\/]+users[\\/]+[^\s<>'\"]+", text):
        findings.append("personal Windows user path")
    if re.search(r"(?i)/(?:users|home)/[^\s<>'\"]+", text):
        findings.append("personal POSIX user path")
    if "-----BEGIN " + "PRIVATE KEY-----" in text:
        findings.append("private key material")
    if re.search(r"(?i)authorization\s*[:=]\s*bearer\s+\S+", text):
        findings.append("bearer credential")
    if re.search(
        r"(?im)^(?:password|passwd|token|secret|api[_-]?key)\s*=\s*\S+",
        text,
    ):
        findings.append("non-empty credential assignment")
    if re.search(r"(?i)(?:jdbc|mariadb|mysql|postgres(?:ql)?|sqlserver)://", text):
        findings.append("database connection URL")
    if re.search(r"\b[A-Z][12][0-9]{8}\b", text):
        findings.append("identity-number-like value")
    if re.search(r"(?<![0-9])09[0-9]{8}(?![0-9])", text):
        findings.append("mobile-number-like value")
    if re.search(r"(?i)\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b", text):
        findings.append("email-address-like value")
    if re.search(
        r"[\u4e00-\u9fff]{2,}(?:市|縣)[\u4e00-\u9fff0-9之\-]{2,}"
        r"(?:路|街|巷|弄|號)",
        text,
    ):
        findings.append("address-like value")

    internal_tokens = (
        r"\bA5" + r"[2-6]\b|" + "lex" + "us_|" +
        "cs_data" + "_clean|" + "service_record" + "_clean"
    )
    if public_mode and re.search(internal_tokens, text, re.I):
        findings.append("internal schema or site identifier in public candidate")
    return findings


def read_worktree_text(relative: str) -> tuple[str | None, str | None]:
    path = ROOT / relative
    try:
        data = path.read_bytes()
    except OSError as error:
        return None, f"cannot read ({error})"
    if len(data) > MAX_FILE_BYTES:
        return None, "file exceeds 1 MiB allowlist limit"
    if b"\x00" in data:
        return None, "binary content is not allowed"
    try:
        return data.decode("utf-8"), None
    except UnicodeDecodeError:
        return None, "non-UTF-8 content is not allowed"


def scan_worktree(paths: list[str], public_mode: bool) -> list[str]:
    findings: list[str] = []
    for relative in paths:
        findings.extend(f"{relative}: {item}" for item in path_findings(relative))
        text, error = read_worktree_text(relative)
        if error:
            findings.append(f"{relative}: {error}")
            continue
        findings.extend(
            f"{relative}: {item}"
            for item in text_findings(text or "", public_mode)
        )
    return findings


def scan_history(public_mode: bool) -> list[str]:
    findings: list[str] = []
    for object_id, relative in history_objects():
        type_result = run_git("cat-file", "-t", object_id, check=False)
        if type_result.stdout.strip() != "blob":
            continue
        findings.extend(
            f"history:{relative}: {item}" for item in path_findings(relative)
        )
        size_result = run_git("cat-file", "-s", object_id, check=False)
        if size_result.returncode != 0:
            continue
        try:
            size = int(size_result.stdout.strip())
        except ValueError:
            continue
        if size > MAX_FILE_BYTES:
            findings.append(f"history:{relative}: blob exceeds 1 MiB")
            continue
        blob = subprocess.run(
            ["git", "cat-file", "-p", object_id],
            cwd=ROOT,
            check=False,
            capture_output=True,
        ).stdout
        if b"\x00" in blob:
            findings.append(f"history:{relative}: binary blob")
            continue
        try:
            text = blob.decode("utf-8")
        except UnicodeDecodeError:
            findings.append(f"history:{relative}: non-UTF-8 blob")
            continue
        findings.extend(
            f"history:{relative}: {item}"
            for item in text_findings(text, public_mode)
        )
    return findings


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--public", action="store_true")
    args = parser.parse_args()

    candidates = candidate_paths()
    staged = staged_paths()
    findings = scan_worktree(candidates, args.public)
    findings.extend(scan_worktree(staged, args.public))
    findings.extend(scan_history(args.public))

    if findings:
        print("Repository safety scan failed:", file=sys.stderr)
        for finding in sorted(set(findings)):
            print(f"- {finding}", file=sys.stderr)
        return 1

    print("Repository safety scan passed.")
    print("Reviewed allowlist:")
    for relative in candidates:
        print(f"- {relative}")
    print(f"Staged files checked: {len(staged)}")
    print(f"History objects checked: {len(history_objects())}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
