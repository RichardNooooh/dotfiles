---
description: "Use for implementation, refactoring, tests, validation, and other non-specialized work."
mode: subagent
model: openai/gpt-5.6-terra#reasoning-medium-verbosity-low
permissions:
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
  - action: subagent
    resource: "*"
    effect: deny
---
