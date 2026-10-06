---
name: latex-preview
description: Render a local LaTeX math explanation as an offline browser preview. Use whenever you are about to use LaTeX to explain or discuss something with the user.
---

# LaTeX Preview

Use this as a practical aid when math explanation benefits from seeing the rendered result. It is a primary-owned workflow: make the preview yourself and return its output path.

1. Create `/tmp/opencode/latex/` if needed, then write minimal Markdown to a uniquely named file there, such as `/tmp/opencode/latex/explanation-<unique>.md`. Use headings, prose, tables, quotes, code, and `$...$` inline or `$$...$$` display math as needed. Escape currency as `\$`. Raw HTML is literal text and images are omitted, so use Markdown content rather than either.
2. Render it with `mise run latex:preview -- /tmp/opencode/latex/explanation.md`, replacing the example path with the unique input path. Add `--no-open` either before or after the input path when a browser should not open.
3. Choose whether to open the browser preview without further approval; normal tool permissions still apply. Unless `--no-open` is set, the renderer opens the unique snapshot with `xdg-open`. The generated snapshot is a self-contained, offline HTML file under `/tmp/opencode/latex/`, with embedded CSS and WOFF2 fonts, no JavaScript, and light/dark system styling. Wide math can scroll horizontally.
4. If the renderer reports malformed source on stderr, correct the Markdown or math and render again. Its fallback snapshot is only a diagnostic; return the successful snapshot path.

The renderer supports common unified Markdown with `remark-math` and `rehype-katex` conventions. Do not run setup or automatic installation commands for this workflow.
