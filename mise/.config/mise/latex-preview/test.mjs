import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { spawn, spawnSync } from "node:child_process";
import { createRequire } from "node:module";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const require = createRequire(import.meta.url);
const directory = await mkdtemp(path.join(os.tmpdir(), "latex-preview-test-"));
const source = path.join(directory, "spaced explanation.md");
const renderer = path.join(path.dirname(fileURLToPath(import.meta.url)), "render.mjs");

async function katexVersion(resolver) {
  const katexEntry = resolver.resolve("katex");
  const packageJson = path.join(path.dirname(katexEntry), "..", "package.json");
  return JSON.parse(await readFile(packageJson, "utf8")).version;
}

function run(command, arguments_, options) {
  return spawnSync(command, arguments_, { encoding: "utf8", ...options });
}

function runAsync(command, arguments_, options) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, arguments_, { ...options, stdio: ["ignore", "pipe", "pipe"] });
    let stdout = "";
    let stderr = "";
    child.stdout.on("data", (chunk) => { stdout += chunk; });
    child.stderr.on("data", (chunk) => { stderr += chunk; });
    child.on("error", reject);
    child.on("close", (status) => resolve({ status, stdout, stderr }));
  });
}

try {
  await writeFile(source, `# Preview

Inline $x^2$ and display:

$$\\boxed{\\frac{a}{b}}$$

$x_{y_z}$

Price: \\$5 and \\$10. Code: \`$not_math$\`.

| left | right |
| --- | --- |
| [link](https://example.com) | $y$ |

<mark>literal HTML</mark>

![not fetched](https://example.invalid/image.png)

$\\badcommand$
`);
  const result = run(process.execPath, [renderer, "--no-open", path.basename(source)], { cwd: directory });
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stderr, /Invalid LaTex/);
  const rendererKatex = await katexVersion(createRequire(require.resolve("rehype-katex")));
  const assetProviderKatex = await katexVersion(require);
  assert.equal(rendererKatex, assetProviderKatex, "the renderer and embedded CSS must resolve the same KaTeX version");
  const output = result.stdout.match(/LaTeX preview: (.+\.html)/)?.[1];
  assert.ok(output, result.stdout);
  const html = await readFile(output, "utf8");
  assert.match(html, /class="katex/);
  assert.match(html, /class="stretchy fbox"/);
  assert.match(html, /class="sizing reset-size6 size3/);
  assert.match(html, /\.katex \.stretchy\{[^}]*width:/);
  assert.match(html, /\.katex \.sizing\.reset-size6\.size3\{[^}]*font-size:/);
  assert.match(html, /Price: \$5 and \$10/);
  assert.match(html, /<code>\$not_math\$<\/code>/);
  assert.match(html, /literal HTML/);
  assert.doesNotMatch(html, /<mark>literal HTML<\/mark>/);
  assert.doesNotMatch(html, /<img|example\.invalid/);
  assert.match(html, /\\badcommand/);
  const fonts = [...html.matchAll(/data:font\/woff2;base64,([A-Za-z0-9+/=]+)/g)];
  assert.ok(fonts.length > 0);
  for (const [, encoded] of fonts) {
    assert.equal(Buffer.from(encoded, "base64").subarray(0, 4).toString(), "wOF2");
  }
  assert.doesNotMatch(html, /url\(fonts\/|font\/woff;base64|font\/ttf;base64/);
  assert.doesNotMatch(html, /url\((?!data:)/);
  const concurrent = await Promise.all([
    runAsync(process.execPath, [renderer, "--no-open", path.basename(source)], { cwd: directory }),
    runAsync(process.execPath, [renderer, "--no-open", path.basename(source)], { cwd: directory }),
  ]);
  assert.ok(concurrent.every((run_) => run_.status === 0), concurrent.map((run_) => run_.stderr).join("\n"));
  const outputs = concurrent.map((run_) => run_.stdout.match(/LaTeX preview: (.+\.html)/)?.[1]);
  assert.equal(new Set(outputs).size, 2);
  console.log("latex-preview integration test passed");
} finally {
  await rm(directory, { recursive: true, force: true });
}
