# Skill Mechanics

The skill-specific branch of [`writing-for-agents`](SKILL.md): what changes when the document is an OpenCode skill or command. Everything else is in `SKILL.md`.

## Invocation

OpenCode skills are model-invoked. Their `description` makes them available for autonomous loading and for other skills to load. The description is the top-level context pointer, so it imposes permanent context load in exchange for discoverability. Write it for the model, with the trigger branches it needs to recognize.

Put user-only workflows in slash commands. A command is explicitly user-invoked, is not advertised for autonomous model invocation, and should have a concise human-facing `description`.

Choose a skill when the model or another skill must reach the guidance. Choose a command when the workflow begins only through explicit user invocation. A model-invoked skill can still be loaded manually by name.

Shared reference needed by multiple commands belongs in a plain external file, because commands do not invoke one another.

## Splitting By Invocation

Split off a model-invoked skill when it has a distinct leading word that should trigger on its own, or another skill must reach it. The new description adds context load, so independent reach must be worth it.

## Router Commands

When user-only commands multiply past what a user can remember, a router command can name the available commands and when to use them. It points to commands; it does not invoke them.
