import { readFile, mkdir, writeFile } from "node:fs/promises";
import { spawn } from "node:child_process";
import { randomUUID } from "node:crypto";
import { fileURLToPath } from "node:url";
import path from "node:path";
import katex from "katex";
import rehypeKatex from "rehype-katex";
import rehypeStringify from "rehype-stringify";
import remarkGfm from "remark-gfm";
import remarkMath from "remark-math";
import remarkParse from "remark-parse";
import remarkRehype from "remark-rehype";
import { unified } from "unified";

const outputDirectory = "/tmp/opencode/latex";

function usage() {
  return "Usage: render.mjs [--no-open] <markdown-file>";
}

function parseArguments(arguments_) {
  let noOpen = false;
  const files = [];

  for (const argument of arguments_) {
    if (argument === "--no-open") {
      noOpen = true;
    } else {
      files.push(argument);
    }
  }

  if (files.length !== 1) throw new Error(usage());
  return { noOpen, input: path.resolve(process.cwd(), files[0]) };
}

function replaceRawHtmlWithText() {
  return (tree) => walk(tree, (node) => {
    if (node.type === "html") node.type = "text";
  });
}

function reportInvalidMath() {
  return (tree) => walk(tree, (node) => {
    if (node.type !== "element" || node.tagName !== "code") return;
    const classes = node.properties?.className ?? [];
    if (!classes.includes("language-math")) return;

    const source = node.children?.map((child) => child.value ?? "").join("") ?? "";
    try {
      katex.renderToString(source, { displayMode: classes.includes("math-display"), throwOnError: true });
    } catch (error) {
      console.error(`Invalid LaTex (${error.message}): ${source}`);
    }
  });
}

function omitImages() {
  return (tree) => removeMatchingChildren(tree, (node) => node.type === "element" && node.tagName === "img");
}

function walk(node, visitor) {
  visitor(node);
  for (const child of node.children ?? []) walk(child, visitor);
}

function removeMatchingChildren(node, matches) {
  if (!node.children) return;
  node.children = node.children.filter((child) => !matches(child));
  for (const child of node.children) removeMatchingChildren(child, matches);
}

async function embeddedKatexCss() {
  const packageDirectory = path.dirname(fileURLToPath(import.meta.resolve("katex/package.json")));
  const css = (await readFile(path.join(packageDirectory, "dist", "katex.min.css"), "utf8"))
    .replaceAll(/,url\(fonts\/[^)]+\.(?:woff|ttf)\) format\("[^"]+"\)/g, "");
  const fontDirectory = path.join(packageDirectory, "dist", "fonts");
  const urls = [...css.matchAll(/url\(fonts\/([^)]+)\)/g)];

  if (urls.some((match) => !match[1].endsWith(".woff2"))) {
    throw new Error("KaTeX CSS contains a non-WOFF2 font source");
  }

  let embedded = css;
  for (const match of urls) {
    const fontName = match[1];
    const font = await readFile(path.join(fontDirectory, fontName));
    embedded = embedded.replaceAll(match[0], `url(data:font/woff2;base64,${font.toString("base64")})`);
  }

  if (/url\((?!data:)/.test(embedded)) throw new Error("KaTeX CSS contains an unresolved external URL");
  return embedded;
}

function documentFor(content, css) {
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>LaTeX preview</title>
<style>${css}
:root { color-scheme: light dark; }
body { margin: 0; background: light-dark(#f7f7f5, #171716); color: light-dark(#20201e, #e8e7e3); font: 17px/1.65 system-ui, sans-serif; }
main { box-sizing: border-box; max-width: 52rem; margin: 0 auto; padding: 3rem 1.5rem 5rem; overflow-wrap: break-word; }
pre { overflow-x: auto; padding: 1rem; background: light-dark(#ecece8, #282826); border-radius: .4rem; }
code { font-family: ui-monospace, monospace; }
table { display: block; max-width: 100%; overflow-x: auto; border-collapse: collapse; }
th, td { padding: .4rem .7rem; border: 1px solid light-dark(#c8c8c2, #50504b); text-align: left; }
.katex-display { overflow-x: auto; overflow-y: hidden; padding: .2rem 0; }
a { color: light-dark(#0859a5, #8bc4ff); }
</style>
</head>
<body><main>${content}</main></body>
</html>`;
}

async function main() {
  const { noOpen, input } = parseArguments(process.argv.slice(2));
  const markdown = await readFile(input, "utf8");
  const processor = unified()
    .use(remarkParse)
    .use(remarkGfm)
    .use(remarkMath)
    .use(replaceRawHtmlWithText)
    .use(remarkRehype)
    .use(reportInvalidMath)
    .use(rehypeKatex, { throwOnError: false, strict: "ignore" })
    .use(omitImages)
    .use(rehypeStringify);
  const content = String(await processor.process(markdown));
  const css = await embeddedKatexCss();
  const stem = path.basename(input, path.extname(input)).replaceAll(/[^a-zA-Z0-9_-]/g, "-") || "preview";

  await mkdir(outputDirectory, { recursive: true });
  const output = path.join(outputDirectory, `${stem}-${Date.now()}-${process.pid}-${randomUUID()}.html`);
  await writeFile(output, documentFor(content, css));
  console.log(`LaTeX preview: ${output}`);

  if (!noOpen) {
    const opener = spawn("xdg-open", [output], { detached: true, stdio: "ignore" });
    opener.unref();
  }
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
