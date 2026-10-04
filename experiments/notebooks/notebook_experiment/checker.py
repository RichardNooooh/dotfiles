"""Compare two notebooks without allowing serialization details to hide data loss."""

from __future__ import annotations

import argparse
import copy
import json
import os
import sys
from pathlib import Path
from typing import Any

import nbformat


def read_notebook(path: Path) -> dict[str, Any]:
    """Load and validate a notebook while preserving every JSON field."""
    with path.open(encoding="utf-8") as notebook_file:
        notebook = json.load(notebook_file)
    if not isinstance(notebook, dict):
        raise ValueError("notebook root must be an object")
    cells = notebook.get("cells")
    if not isinstance(cells, list):
        raise ValueError("notebook cells must be an array")
    cell_ids: set[str] = set()
    for index, cell in enumerate(cells):
        if not isinstance(cell, dict) or not isinstance(cell.get("id"), str) or not cell["id"]:
            raise ValueError(f"cells[{index}].id must be a non-empty string")
        if cell["id"] in cell_ids:
            raise ValueError(f"cells[{index}].id duplicates {cell['id']!r}")
        cell_ids.add(cell["id"])
    # nbformat may normalize legacy fields during validation; retain the raw
    # parsed document for comparison and validate only a disposable copy.
    nbformat.validate(copy.deepcopy(notebook))
    return notebook


def first_difference(expected: Any, actual: Any, path: str = "") -> tuple[str, Any, Any] | None:
    """Return the first JSON-semantic difference, including its notebook path."""
    if type(expected) is not type(actual):
        return path or "<root>", expected, actual
    if isinstance(expected, dict):
        expected_keys = set(expected)
        actual_keys = set(actual)
        for key in sorted(expected_keys | actual_keys):
            child_path = f"{path}.{key}" if path else key
            if key not in expected:
                return child_path, "<missing>", actual[key]
            if key not in actual:
                return child_path, expected[key], "<missing>"
            difference = first_difference(expected[key], actual[key], child_path)
            if difference is not None:
                return difference
        return None
    if isinstance(expected, list):
        if len(expected) != len(actual):
            return f"{path}.length" if path else "<root>.length", len(expected), len(actual)
        for index, (expected_item, actual_item) in enumerate(zip(expected, actual, strict=True)):
            difference = first_difference(expected_item, actual_item, f"{path}[{index}]")
            if difference is not None:
                return difference
        return None
    if expected != actual:
        return path or "<root>", expected, actual
    return None


def validate_execution(expected: dict[str, Any], actual: dict[str, Any], interpreter: Path) -> str | None:
    """Allow only the environment-report execution state to differ from a baseline."""
    try:
        actual_cell = next(cell for cell in actual["cells"] if cell["id"] == "environment-report")
    except (KeyError, StopIteration) as error:
        return f"environment-report cell is missing: {error}"

    execution_count = actual_cell.get("execution_count")
    if not isinstance(execution_count, int) or isinstance(execution_count, bool) or execution_count < 1:
        return f"environment-report.execution_count must be a positive integer; actual {execution_count!r}"
    outputs = actual_cell.get("outputs")
    if not isinstance(outputs, list) or not outputs:
        return "environment-report.outputs must contain the successful execution output"
    if any(output.get("output_type") == "error" for output in outputs):
        return "environment-report execution produced an error output"

    text_parts: list[str] = []
    for output in outputs:
        if output.get("output_type") == "stream" and output.get("name") == "stdout":
            text = output.get("text")
        else:
            text = output.get("data", {}).get("text/plain") if isinstance(output.get("data"), dict) else None
        if isinstance(text, str):
            text_parts.append(text)
        elif isinstance(text, list) and all(isinstance(line, str) for line in text):
            text_parts.extend(text)
    stdout = "".join(text_parts)
    expected_executable = os.path.abspath(interpreter)
    actual_executable = None
    for line in stdout.splitlines():
        if line.startswith("python executable: "):
            actual_executable = line.removeprefix("python executable: ")
            break
    if actual_executable is None:
        return "environment-report output is missing the python executable report"
    if not os.path.isabs(actual_executable) or os.path.abspath(actual_executable) != expected_executable:
        return (
            "environment-report used an unexpected interpreter: "
            f"expected {expected_executable!r}; actual {actual_executable!r}"
        )
    if "pandas version: 2.3.2" not in stdout.splitlines():
        return f"environment-report output is missing the expected pandas output; actual {stdout!r}"

    permitted = copy.deepcopy(expected)
    try:
        permitted_cell = next(cell for cell in permitted["cells"] if cell["id"] == "environment-report")
    except (KeyError, StopIteration):
        return "environment-report cell is missing from expected notebook"
    permitted_cell["execution_count"] = execution_count
    permitted_cell["outputs"] = outputs
    difference = first_difference(permitted, actual)
    if difference is not None:
        path, expected_value, actual_value = difference
        return f"unintended mutation at {path}: expected {expected_value!r}; actual {actual_value!r}"
    return None


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("expected", type=Path, help="known-good .ipynb file (read only)")
    parser.add_argument("actual", type=Path, help="candidate .ipynb file (read only)")
    parser.add_argument(
        "--execution-interpreter",
        type=Path,
        help="validate an environment-report execution against this shared interpreter",
    )
    args = parser.parse_args()
    try:
        expected = read_notebook(args.expected)
        actual = read_notebook(args.actual)
    except (OSError, ValueError, json.JSONDecodeError, nbformat.validator.NotebookValidationError) as error:
        print(f"invalid notebook: {error}", file=sys.stderr)
        return 2

    if args.execution_interpreter is not None:
        error = validate_execution(expected, actual, args.execution_interpreter)
        if error is None:
            print("environment-report execution preserved all other notebook content")
            return 0
        print(error, file=sys.stderr)
        return 1

    difference = first_difference(expected, actual)
    if difference is None:
        print("notebooks are semantically identical")
        return 0

    path, expected_value, actual_value = difference
    print(f"mismatch at {path}: expected {expected_value!r}; actual {actual_value!r}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
