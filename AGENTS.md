# Agent Guidelines

Project context: CLAUDE.md

Rules from [Andrej Karpathy](https://x.com/karpathy/status/2015883857489522876): bias toward caution over speed.

## Principles

**Think Before Coding**
- Present material interpretation changes.
- Say when simpler path exists. Explain when approach is wrong or risky.
- Ask only when missing info can't be discovered and assumption is risky.

**Keep It Simple**
- Implement only the request. No single-use abstractions, no unrequested flexibility.
- Handle realistic errors only. Could this be substantially smaller without losing clarity or correctness?

**Surgical Changes**
- Don't improve adjacent code. Match existing style. Remove only unused code introduced by change.

## Workflow

`Understand → Define Success → Plan → Implement → Verify`

- **Define Success:** each change traceable to request. Multi-step work: define step + check.
- **Verify:** run applicable checks, review final diff for scope creep.

## Quality Gates

Before commit:

| Gate | iOS/Swift |
|------|-----------|
| Build | `xcodebuild -scheme Posture build` |
| Tests | `xcodebuild test -scheme Posture -destination 'platform=iOS Simulator,name=iPhone 16'` |
| Lint | N/A |
| Format | N/A |

## Spec-Driven Modes

**Plan Mode** (user asks to plan/design/create specs): inspect, clarify, write specs only when user allows edits. Tree in `.planning/specs/`.

**Build Mode** (user asks to execute): traverse sessions in order, one incomplete leaf at a time. Read spec → implement → verify → mark `completed: true`.

## Design

Find Shallow Modules — wide interface, deep implementation. Apply deletion test. OOP only when it increases depth, locality, or testability.

## Communication

Concise and direct. Report assumptions, material risks, changes, verification results.

## Git

No commit/push/reset/clean/revert unless asked. Never overwrite unrelated user work.
