import { Plugin } from "@opencode/plugin"

const instruction =
  "Write delegation prompts and follow-up messages in clear prose with normal " +
  "word spacing. Use concise sentences or bullets rather than concatenating " +
  "words or removing whitespace to save tokens. Preserve code, identifiers, " +
  "and file paths exactly."

export default Plugin.define({
  id: "local.subagent-prompt-spacing",

  async setup(ctx) {
    await ctx.tool.transform((editor) => {
      editor.update("subagent", (tool) => {
        tool.description += `\n${instruction}`
      })
    })
  },
})
