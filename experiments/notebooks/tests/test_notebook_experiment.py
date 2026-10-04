import base64
from io import BytesIO
import json
from pathlib import Path
import subprocess
import sys
from typing import Any

import nbformat
from PIL import Image


PROJECT_ROOT = Path(__file__).parents[1]
FIXTURE_PATH = PROJECT_ROOT / "fixtures" / "notebook-fidelity.ipynb"


def run_checker(*arguments: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, "-m", "notebook_experiment.checker", *arguments],
        capture_output=True,
        text=True,
        check=False,
    )


def executed_notebook(interpreter: Path) -> dict[str, Any]:
    notebook: dict[str, Any] = json.loads(FIXTURE_PATH.read_text(encoding="utf-8"))
    cell = next(cell for cell in notebook["cells"] if cell["id"] == "environment-report")
    cell["execution_count"] = 5
    cell["outputs"] = [
        {
            "output_type": "stream",
            "name": "stdout",
            "text": f"python executable: {interpreter}\npandas version: 2.3.2\n",
        }
    ]
    return notebook


def write_notebook(path: Path, notebook: dict[str, Any]) -> None:
    path.write_text(json.dumps(notebook), encoding="utf-8")


def test_fixture_is_a_valid_notebook_with_required_cell_kinds() -> None:
    notebook = nbformat.read(FIXTURE_PATH, as_version=4)

    nbformat.validate(notebook)
    assert [cell.cell_type for cell in notebook.cells] == [
        "markdown",
        "code",
        "code",
        "code",
        "code",
        "code",
        "code",
        "raw",
    ]
    assert notebook.metadata["experiment"]["purpose"] == "notebook-fidelity"
    assert notebook.metadata["experiment"]["editing_targets"] == ["variables", "wide-frame"]
    assert notebook.cells[1].id == "environment-report"
    assert notebook.cells[2].metadata["tags"] == ["editing-target", "variables"]
    assert notebook.cells[3].metadata["tags"] == ["editing-target", "wide-frame"]
    assert "small = pd.DataFrame({'label': ['one', 'two']})" in notebook.cells[3].source
    assert "small[\"total\"] = total" in notebook.cells[3].source
    assert notebook.cells[3].source.rstrip().endswith("wide")
    assert notebook.cells[3].source.count("wide_") >= 4
    assert notebook.cells[3].outputs[0].output_type == "display_data"
    assert "one" in notebook.cells[3].outputs[0].data["text/plain"]
    assert "total" in notebook.cells[3].outputs[0].data["text/html"]
    assert notebook.cells[3].outputs[1].output_type == "execute_result"
    assert "wide_delta" in notebook.cells[3].outputs[1].data["text/html"]
    assert "<tr><th>1</th><td>20</td><td>40</td><td>60</td><td>80</td></tr>" in notebook.cells[3].outputs[1].data["text/html"]
    attachment = notebook.cells[0].attachments["tiny-plot.png"]["image/png"]
    assert "attachment:tiny-plot.png" in notebook.cells[0].source
    assert attachment == notebook.cells[4].outputs[1].data["image/png"]
    image = Image.open(BytesIO(base64.b64decode(attachment)))
    assert image.format == "PNG"
    assert image.size == (400, 200)
    assert image.info["Software"] == "notebook-fidelity"
    assert "Date" not in image.info
    image.verify()
    assert notebook.cells[5].outputs[0].ename == "ValueError"
    assert "time.sleep(1)" in notebook.cells[6].source
    assert "skip-in-automated-run" in notebook.cells[6].metadata["tags"]


def test_fixture_generator_cli_is_deterministic(tmp_path: Path) -> None:
    first = tmp_path / "first.ipynb"
    second = tmp_path / "second.ipynb"

    for output in (first, second):
        result = subprocess.run(
            [sys.executable, "-m", "notebook_experiment.generate_fixture", "--output", str(output)],
            capture_output=True,
            text=True,
            check=False,
        )
        assert result.returncode == 0, result.stderr

    assert first.read_bytes() == second.read_bytes()


def test_fixture_generator_matches_checked_in_baseline(tmp_path: Path) -> None:
    generated = tmp_path / "notebook-fidelity.ipynb"

    result = subprocess.run(
        [sys.executable, "-m", "notebook_experiment.generate_fixture", "--output", str(generated)],
        capture_output=True,
        text=True,
        check=False,
    )

    assert result.returncode == 0, result.stderr
    assert json.loads(generated.read_text(encoding="utf-8")) == json.loads(FIXTURE_PATH.read_text(encoding="utf-8"))
    assert generated.read_bytes() == FIXTURE_PATH.read_bytes()


def test_checker_accepts_identical_notebook_with_different_json_formatting(tmp_path: Path) -> None:
    reformatted = tmp_path / "reformatted.ipynb"
    reformatted.write_text(json.dumps(json.loads(FIXTURE_PATH.read_text()), indent=1, sort_keys=True), encoding="utf-8")
    original_candidate = reformatted.read_text(encoding="utf-8")

    result = subprocess.run(
        [sys.executable, "-m", "notebook_experiment.checker", str(FIXTURE_PATH), str(reformatted)],
        capture_output=True,
        text=True,
        check=False,
    )

    assert result.returncode == 0
    assert result.stdout == "notebooks are semantically identical\n"
    assert reformatted.read_text(encoding="utf-8") == original_candidate


def test_checker_rejects_content_loss_with_a_readable_path(tmp_path: Path) -> None:
    altered = json.loads(FIXTURE_PATH.read_text())
    altered["cells"][2]["source"] = "left = 7\n"
    altered_path = tmp_path / "content-loss.ipynb"
    altered_path.write_text(json.dumps(altered), encoding="utf-8")

    result = subprocess.run(
        [sys.executable, "-m", "notebook_experiment.checker", str(FIXTURE_PATH), str(altered_path)],
        capture_output=True,
        text=True,
        check=False,
    )

    assert result.returncode == 1
    assert "cells[2].source" in result.stderr
    assert "expected" in result.stderr
    assert "actual" in result.stderr


def test_checker_rejects_unknown_metadata_loss(tmp_path: Path) -> None:
    altered = json.loads(FIXTURE_PATH.read_text())
    del altered["metadata"]["experiment"]["unknown_notebook_field"]
    altered_path = tmp_path / "metadata-loss.ipynb"
    altered_path.write_text(json.dumps(altered), encoding="utf-8")

    result = subprocess.run(
        [sys.executable, "-m", "notebook_experiment.checker", str(FIXTURE_PATH), str(altered_path)],
        capture_output=True,
        text=True,
        check=False,
    )

    assert result.returncode == 1
    assert "metadata.experiment.unknown_notebook_field" in result.stderr


def test_checker_rejects_loss_from_every_notebook_content_class(tmp_path: Path) -> None:
    delete = object()
    cases: list[tuple[str, list[str | int], object]] = [
        ("cells[1].id", ["cells", 1, "id"], "environment-report-changed"),
        ("cells[2].metadata.custom.keep", ["cells", 2, "metadata", "custom", "keep"], delete),
        ("cells[0].attachments.tiny-plot.png.image/png", ["cells", 0, "attachments", "tiny-plot.png", "image/png"], "AA=="),
        ("cells[4].outputs[1].data.image/png", ["cells", 4, "outputs", 1, "data", "image/png"], "AA=="),
        ("cells[7].source", ["cells", 7, "source"], ""),
        ("metadata.experiment.unknown_notebook_field.preserve", ["metadata", "experiment", "unknown_notebook_field", "preserve"], 1),
    ]

    for index, (expected_path, path, replacement) in enumerate(cases):
        altered: Any = json.loads(FIXTURE_PATH.read_text())
        target = altered
        for key in path[:-1]:
            target = target[key]
        if replacement is delete:
            del target[path[-1]]
        else:
            target[path[-1]] = replacement
        altered_path = tmp_path / f"loss-{index}.ipynb"
        altered_path.write_text(json.dumps(altered), encoding="utf-8")

        result = subprocess.run(
            [sys.executable, "-m", "notebook_experiment.checker", str(FIXTURE_PATH), str(altered_path)],
            capture_output=True,
            text=True,
            check=False,
        )

        assert result.returncode == 1
        assert expected_path in result.stderr


def test_execution_checker_accepts_only_environment_report_execution_changes(tmp_path: Path) -> None:
    interpreter = tmp_path / "shared" / "bin" / "python"
    actual = tmp_path / "executed.ipynb"
    write_notebook(actual, executed_notebook(interpreter))

    result = run_checker(
        "--execution-interpreter",
        str(interpreter),
        str(FIXTURE_PATH),
        str(actual),
    )

    assert result.returncode == 0, result.stderr
    assert result.stdout == "environment-report execution preserved all other notebook content\n"


def test_execution_checker_rejects_unrelated_notebook_mutations(tmp_path: Path) -> None:
    interpreter = tmp_path / "shared" / "bin" / "python"
    cases: list[tuple[str, list[str | int], object]] = [
        ("metadata.experiment.purpose", ["metadata", "experiment", "purpose"], "changed"),
        ("cells[7].source", ["cells", 7, "source"], "changed raw cell"),
        ("cells[0].attachments.tiny-plot.png.image/png", ["cells", 0, "attachments", "tiny-plot.png", "image/png"], "AA=="),
    ]

    for index, (expected_path, path, replacement) in enumerate(cases):
        notebook = executed_notebook(interpreter)
        target: Any = notebook
        for key in path[:-1]:
            target = target[key]
        target[path[-1]] = replacement
        actual = tmp_path / f"mutation-{index}.ipynb"
        write_notebook(actual, notebook)

        result = run_checker(
            "--execution-interpreter",
            str(interpreter),
            str(FIXTURE_PATH),
            str(actual),
        )

        assert result.returncode == 1
        assert f"unintended mutation at {expected_path}" in result.stderr


def test_execution_checker_rejects_expected_notebook_without_environment_report(tmp_path: Path) -> None:
    interpreter = tmp_path / "shared" / "bin" / "python"
    expected = json.loads(FIXTURE_PATH.read_text(encoding="utf-8"))
    expected["cells"] = [cell for cell in expected["cells"] if cell["id"] != "environment-report"]
    expected_path = tmp_path / "missing-environment-report.ipynb"
    write_notebook(expected_path, expected)
    actual = tmp_path / "executed.ipynb"
    write_notebook(actual, executed_notebook(interpreter))

    result = run_checker(
        "--execution-interpreter",
        str(interpreter),
        str(expected_path),
        str(actual),
    )

    assert result.returncode == 1
    assert result.stderr == "environment-report cell is missing from expected notebook\n"


def test_execution_checker_rejects_an_alias_to_the_shared_python_binary(tmp_path: Path) -> None:
    binary = tmp_path / "python"
    binary.touch()
    interpreter = tmp_path / "shared" / "bin" / "python"
    interpreter.parent.mkdir(parents=True)
    interpreter.symlink_to(binary)
    alias = tmp_path / "other" / "bin" / "python"
    alias.parent.mkdir(parents=True)
    alias.symlink_to(binary)
    actual = tmp_path / "alias.ipynb"
    write_notebook(actual, executed_notebook(alias))

    result = run_checker(
        "--execution-interpreter",
        str(interpreter),
        str(FIXTURE_PATH),
        str(actual),
    )

    assert result.returncode == 1
    assert "unexpected interpreter" in result.stderr


def test_execution_checker_rejects_inexact_pandas_version_and_error_outputs(tmp_path: Path) -> None:
    interpreter = tmp_path / "shared" / "bin" / "python"
    cases = [
        ("pandas", "python executable: {interpreter}\npandas version: 2.3.20\n", []),
        ("error", "python executable: {interpreter}\npandas version: 2.3.2\n", [{"output_type": "error", "ename": "ValueError", "evalue": "bad", "traceback": ["bad"]}]),
    ]

    for name, output, extra_outputs in cases:
        notebook = executed_notebook(interpreter)
        notebook["cells"][1]["outputs"][0]["text"] = output.format(interpreter=interpreter)
        notebook["cells"][1]["outputs"].extend(extra_outputs)
        actual = tmp_path / f"{name}.ipynb"
        write_notebook(actual, notebook)

        result = run_checker(
            "--execution-interpreter",
            str(interpreter),
            str(FIXTURE_PATH),
            str(actual),
        )

        assert result.returncode == 1


def test_checker_rejects_missing_or_duplicate_cell_ids_as_invalid_notebooks(tmp_path: Path) -> None:
    cases = [("missing", lambda notebook: notebook["cells"][0].pop("id")), ("duplicate", lambda notebook: notebook["cells"][1].__setitem__("id", notebook["cells"][2]["id"]))]

    for name, alter in cases:
        notebook: dict[str, Any] = json.loads(FIXTURE_PATH.read_text(encoding="utf-8"))
        alter(notebook)
        actual = tmp_path / f"{name}.ipynb"
        write_notebook(actual, notebook)

        result = run_checker(str(FIXTURE_PATH), str(actual))

        assert result.returncode == 2
        assert "invalid notebook" in result.stderr


def test_checker_rejects_invalid_json_with_exit_two(tmp_path: Path) -> None:
    invalid = tmp_path / "invalid.ipynb"
    invalid.write_text("{not json", encoding="utf-8")

    result = run_checker(str(FIXTURE_PATH), str(invalid))

    assert result.returncode == 2
    assert "invalid notebook" in result.stderr
