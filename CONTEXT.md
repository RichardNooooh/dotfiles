# OpenCode Workflow

This context defines the vocabulary for OpenCode workflows and their responsibilities.

## Language

**Command**:
An explicitly user-invoked entry point that is not advertised for autonomous model invocation.

**Primary-owned skill**:
A skill that owns direct user interaction, orchestration, or durable artifact creation.

**Execution skill**:
Guidance an implementation role may load while carrying out a bounded brief.

**Execution role**:
A subagent that performs bounded work and returns evidence or changes to its parent without taking ownership of the
parent workflow.

**Artifact workflow**:
A process whose intended result is a durable repository artifact rather than only a chat response.
