"""Generate the checked-in synthetic notebook fidelity fixture."""

from __future__ import annotations

import argparse
import base64
import os
from io import BytesIO
from pathlib import Path

import nbformat

# Matplotlib may create font and configuration caches during fixture generation.
# Keep them local before importing any Matplotlib module.
os.environ.setdefault("MPLCONFIGDIR", str(Path(__file__).parents[1] / ".local" / "matplotlib"))

from matplotlib.backends.backend_agg import FigureCanvasAgg
from matplotlib.figure import Figure
from nbformat.v4 import new_code_cell, new_markdown_cell, new_notebook, new_output, new_raw_cell


DEFAULT_OUTPUT = Path(__file__).parents[1] / "fixtures" / "notebook-fidelity.ipynb"


def static_plot_png() -> str:
    """Render a stable, metadata-controlled PNG without a GUI backend."""
    figure = Figure(figsize=(4, 2), dpi=100)
    FigureCanvasAgg(figure)
    axes = figure.subplots()
    axes.plot([0, 1, 2], [0, 1, 0], color="#276FBF", marker="o")
    axes.set(xlabel="step", ylabel="value", title="Deterministic plot", xlim=(0, 2), ylim=(0, 1.1))
    axes.grid(True, alpha=0.25)
    figure.tight_layout()
    buffer = BytesIO()
    figure.savefig(buffer, format="png", metadata={"Software": "notebook-fidelity", "Date": None})
    return base64.b64encode(buffer.getvalue()).decode("ascii")


def build_notebook() -> nbformat.NotebookNode:
    """Return a deterministic, non-executed notebook with representative state."""
    png = static_plot_png()
    notebook = new_notebook(
        metadata={
            "kernelspec": {"display_name": "Python 3", "language": "python", "name": "python3"},
            "language_info": {"name": "python", "version": "3.11"},
            "experiment": {
                "purpose": "notebook-fidelity",
                "editing_targets": ["variables", "wide-frame"],
                "unknown_notebook_field": {"preserve": True},
            },
        }
    )
    markdown = new_markdown_cell(
        "# Notebook fidelity\n\nInline math $x^2$ and a [link](https://example.test).\n\n- one\n- two\n\n![Deterministic plot](attachment:tiny-plot.png)",
        id="intro-markdown",
    )
    markdown.attachments = {"tiny-plot.png": {"image/png": png}}
    markdown.metadata = {"tags": ["documentation"], "custom": {"preserve": "markdown"}}
    environment = new_code_cell(
        "import sys\nimport importlib.metadata\nprint(f'python executable: {sys.executable}')\nprint(f\"pandas version: {importlib.metadata.version('pandas')}\")",
        id="environment-report",
        execution_count=None,
        outputs=[],
    )
    variables = new_code_cell(
        "left = 7\nright = 35\ntotal = left + right\nprint(f'total={total}')",
        id="cross-cell-vars",
        execution_count=1,
        outputs=[new_output("stream", name="stdout", text="total=42\n")],
    )
    variables.metadata = {"tags": ["editing-target", "variables"], "custom": {"keep": [1, 2]}}
    wide_frame = new_code_cell(
        "import pandas as pd\nfrom IPython.display import display\nsmall = pd.DataFrame({'label': ['one', 'two']})\nsmall[\"total\"] = total\ndisplay(small)\nwide = pd.DataFrame({'wide_alpha': [10, 20], 'wide_beta': [30, 40], 'wide_gamma': [50, 60], 'wide_delta': [70, 80]})\nwide",
        id="dataframes-and-plot",
        execution_count=2,
        outputs=[
            new_output(
                "display_data",
                data={
                    "text/plain": "  label  total\n0   one     42\n1   two     42",
                    "text/html": "<table><thead><tr><th></th><th>label</th><th>total</th></tr></thead><tbody><tr><th>0</th><td>one</td><td>42</td></tr><tr><th>1</th><td>two</td><td>42</td></tr></tbody></table>",
                },
                metadata={},
            ),
            new_output(
                "execute_result",
                execution_count=2,
                data={
                    "text/plain": "   wide_alpha  wide_beta  wide_gamma  wide_delta\n0          10         30          50          70\n1          20         40          60          80",
                    "text/html": "<table><thead><tr><th></th><th>wide_alpha</th><th>wide_beta</th><th>wide_gamma</th><th>wide_delta</th></tr></thead><tbody><tr><th>0</th><td>10</td><td>30</td><td>50</td><td>70</td></tr><tr><th>1</th><td>20</td><td>40</td><td>60</td><td>80</td></tr></tbody></table>",
                },
                metadata={"isolated": False},
            )
        ],
    )
    wide_frame.metadata = {"tags": ["editing-target", "wide-frame"], "custom": {"frame": "wide"}}
    output_mix = new_code_cell(
        "import sys\nimport matplotlib.pyplot as plt\nprint('plotting')\nprint('warning', file=sys.stderr)\nfigure, axes = plt.subplots(figsize=(4, 2), dpi=100)\naxes.plot([0, 1, 2], [0, 1, 0], color='#276FBF', marker='o')\naxes.set(xlabel='step', ylabel='value', title='Deterministic plot', xlim=(0, 2), ylim=(0, 1.1))\naxes.grid(True, alpha=0.25)\nfigure.tight_layout()",
        id="streams-and-plot",
        execution_count=3,
        outputs=[
            new_output("stream", name="stdout", text="plotting\n"),
            new_output("display_data", data={"image/png": png, "text/plain": "<Figure size 400x200 with 1 Axes>"}, metadata={"image/png": {"width": 400, "height": 200}}),
            new_output("stream", name="stderr", text="warning\n"),
        ],
    )
    exception = new_code_cell(
        "raise ValueError('deliberate notebook exception')",
        id="deliberate-exception",
        execution_count=4,
        outputs=[new_output("error", ename="ValueError", evalue="deliberate notebook exception", traceback=["Traceback (most recent call last):", "ValueError: deliberate notebook exception"])],
    )
    interrupt = new_code_cell(
        "# Manual-only: skip this cell in automated all-cell runs.\nimport time\nfor second in range(12):\n    print(f'waiting second {second + 1}/12; interrupt with the kernel control')\n    time.sleep(1)",
        id="bounded-interrupt",
        execution_count=None,
        outputs=[],
    )
    interrupt.metadata = {"tags": ["manual-only", "skip-in-automated-run"], "custom": {"maximum_seconds": 12}}
    raw = new_raw_cell("Raw cell: preserved without execution.", id="raw-preservation")
    raw.metadata = {"format": "text/plain", "custom": {"preserve": "raw"}}
    notebook.cells = [markdown, environment, variables, wide_frame, output_mix, exception, interrupt, raw]
    return notebook


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    notebook = build_notebook()
    nbformat.validate(notebook)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    nbformat.write(notebook, args.output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
