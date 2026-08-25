from pathlib import Path
import importlib.util

import pytest

SCRIPT = Path(__file__).parents[1] / "update-image-digest.py"
spec = importlib.util.spec_from_file_location("update_image_digest", SCRIPT)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)


def test_updates_only_release_identity(tmp_path: Path) -> None:
    values = tmp_path / "values.yaml"
    values.write_text(
        'image:\n  repository: pending\n  tag: ""\n  digest: ""\nconfiguration:\n  gitSha: pending\n'
    )
    repository = "123456789012.dkr.ecr.us-east-1.amazonaws.com/platform-reference-service"
    digest = "sha256:" + "a" * 64
    git_sha = "b" * 40

    module.update_values(values, repository, digest, git_sha)

    rendered = values.read_text()
    assert f"  repository: {repository}" in rendered
    assert f'  digest: "{digest}"' in rendered
    assert f"  gitSha: {git_sha}" in rendered
    assert '  tag: ""' in rendered


@pytest.mark.parametrize(
    ("repository", "digest", "git_sha"),
    [
        ("docker.io/example/app", "sha256:" + "a" * 64, "b" * 40),
        ("123456789012.dkr.ecr.us-east-1.amazonaws.com/app", "latest", "b" * 40),
        ("123456789012.dkr.ecr.us-east-1.amazonaws.com/app", "sha256:" + "a" * 64, "main"),
    ],
)
def test_rejects_mutable_or_untrusted_identity(
    tmp_path: Path, repository: str, digest: str, git_sha: str
) -> None:
    values = tmp_path / "values.yaml"
    values.write_text('image:\n  repository: pending\n  digest: ""\nconfiguration:\n  gitSha: pending\n')

    with pytest.raises(ValueError):
        module.update_values(values, repository, digest, git_sha)
