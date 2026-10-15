---
description: "Use only for substantial changes where an independent review could find meaningful defects; do not use for trivial edits."
mode: subagent
model: openai/gpt-6.1-sol#reasoning-medium-verbosity-low
permissions:
  - action: edit
    resource: "*"
    effect: deny
  - action: subagent
    resource: "*"
    effect: deny
  - action: question
    resource: "*"
    effect: deny
  - action: skill
    resource: research
    effect: deny
  - action: skill
    resource: code-review
    effect: deny
  - action: skill
    resource: grilling
    effect: deny
  - action: skill
    resource: domain-modeling
    effect: deny
---
