#!/usr/bin/env python3
"""Update the narrowly scoped image identity in a GitOps Helm values file."""

from __future__ import annotations

import argparse
import re
from pathlib import Path

DIGEST_PATTERN = re.compile(r"^sha256:[0-9a-f]{64}$")
REPOSITORY_PATTERN = re.compile(
    r"^[0-9]{12}\.dkr\.ecr\.[a-z0-9-]+\.amazonaws\.com/[a-z0-9][a-z0-9._/-]*$"
)
SHA_PATTERN = re.compile(r"^[0-9a-f]{40}$")


def replace_once(text: str, pattern: str, replacement: str, field: str) -> str:
    updated, count = re.subn(pattern, replacement, text, count=1, flags=re.MULTILINE)
    if count != 1:
        raise ValueError(f"expected exactly one {field} field, found {count}")
    return updated


def update_values(path: Path, repository: str, digest: str, git_sha: str) -> None:
    if not REPOSITORY_PATTERN.fullmatch(repository):
        raise ValueError("repository must be an Amazon ECR repository URL")
    if not DIGEST_PATTERN.fullmatch(digest):
        raise ValueError("digest must be a lowercase sha256 digest")
    if not SHA_PATTERN.fullmatch(git_sha):
        raise ValueError("git SHA must contain 40 lowercase hexadecimal characters")

    text = path.read_text()
    text = replace_once(text, r"^  repository: .+$", f"  repository: {repository}", "repository")
    text = replace_once(text, r'^  digest: ".*"$', f'  digest: "{digest}"', "digest")
    text = replace_once(text, r"^  gitSha: .+$", f"  gitSha: {git_sha}", "gitSha")
    path.write_text(text)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--file", type=Path, required=True)
    parser.add_argument("--repository", required=True)
    parser.add_argument("--digest", required=True)
    parser.add_argument("--git-sha", required=True)
    args = parser.parse_args()
    update_values(args.file, args.repository, args.digest, args.git_sha)


if __name__ == "__main__":
    main()
