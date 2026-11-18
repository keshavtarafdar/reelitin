# Codex work session guide

Use this page as a quick routing guide. The global and ReelItIn `AGENTS.md` files already set the tutoring style, project boundaries, and learning-summary rule. Skills add focused workflows when you invoke them or when their descriptions let Codex choose them.

## Start every session

Give Codex a small, outcome-based request:

```text
Goal: [observable result]
Scope: [included work; excluded work]
Expected behavior: [examples, rules, edge cases]
My current knowledge: [what to explain or skip]
Done when: [verification and stopping point]
```

For ReelItIn, work from the repository root or a subdirectory so the project `AGENTS.md` is in scope. Ask Codex to consult `docs/ROADMAP.md` and relevant ADRs for project work. One implementation unit per session keeps decisions reviewable.

## Brainstorm and align

```text
Idea / unclear behavior
  → /grill-me
  → answer questions until scope and behavior are explicit
  → /grill-with-docs when terminology, glossary, or an ADR should be captured
  → agree on a small first unit
```

- `grill-me`: interview you about intent and edge cases. Best for feature behavior, UX expectations, and boundaries.
- `grill-with-docs`: same alignment, while building shared domain language and recording durable glossary/ADR decisions.
- `domain-modeling`: clarify domain terms and relationships; useful alongside an ADR or glossary change.
- `codebase-design`: choose module boundaries, interfaces, and test seams before a cross-cutting change.
- `prototype`: explore uncertain UI or state behavior with a throwaway proof of concept.
- `research`: gather current, high-trust sources and save cited findings when the task needs investigation.
- `ask-matt`: ask which Matt Pocock workflow fits when the choice is unclear.

Alignment checkpoint: restate the user problem, expected behavior, scope, constraints, open decisions, and what is explicitly out of scope. Only then implement.

## Implement and test

```text
Agreed behavior
  → /to-spec for a durable feature spec, or /to-tickets for several independent slices
  → /implement for one bounded unit (or /implement-spec for an agreed multi-ticket plan)
  → /tdd at agreed behavior seams: failing test → minimal implementation → passing test
  → focused verification and explanation
  → /code-review against the spec and repo standards
  → explicitly mark phase complete to update docs/learning/
```

- `to-spec`: turn settled conversation into a spec; it does not interview you for missing decisions.
- `to-tickets`: split a plan into small tracer-bullet tasks and dependencies.
- `implement`: execute a spec or tickets, using TDD at agreed seams; the upstream skill also asks for code review and a commit. State if you want a different stopping point.
- `implement-spec`: coordinate implementation of an agreed spec across its ready tickets. Use only when the work is genuinely divisible and shared-file conflicts are controlled.
- `tdd`: one behavior seam at a time. Agree on the public interface to test; avoid tests coupled to internals.
- `code-review`: review a non-empty diff from a named fixed point and the originating spec. It reports standards and spec alignment separately.
- `codebase-design`: consult when the right interface or seam is uncertain.

The tutoring workflow applies throughout: ask for explanations at the level you need, flag concepts you already know, and request a 5–10 question diagnostic quiz when useful. Prefer small explanations next to the code change; ask for a deeper dive when you want one.

## Diagnose a bug

```text
Exact symptom + reproduction details
  → /diagnosing-bugs
  → build a fast, deterministic check that fails on this symptom
  → reproduce and minimise
  → rank testable hypotheses
  → instrument one variable at a time
  → regression test at the real behavior seam → fix → rerun original check
```

Use `diagnosing-bugs` for reported failures, wrong behavior, or performance regressions. Give it the exact observed result, expected result, steps to reproduce, and relevant logs (redact secrets). It deliberately establishes a red-capable feedback loop before settling on a cause.

## Close the session

Ask for a concise handoff: changed files, behavior delivered, verification run and result, unresolved questions, and next boundary. When the tutoring/implementation phase is complete, say so explicitly and ask Codex to update the relevant cumulative summary under `docs/learning/`. A session ending alone does not mean the phase is complete.

Useful closeout skills: `handoff` creates a continuation note; `retro` suggests improvements to the agent workflow; `code-review` checks the finished diff. Use `pr` only when preparing a pull request.

## Skill quick map

| Need | Skill |
|---|---|
| Clarify intent before building | `grill-me`, `grill-with-docs` |
| Shape domain terms or architecture | `domain-modeling`, `codebase-design` |
| Investigate current technical facts | `research` |
| Write spec / split scope | `to-spec`, `to-tickets` |
| Implement a small agreed slice | `implement`, `tdd` |
| Implement an agreed ticket set | `implement-spec` |
| Find and fix a hard bug | `diagnosing-bugs` |
| Review completed changes | `code-review` |
| Explore a design cheaply | `prototype` |
| Carry context to another session | `handoff` |
| Improve workflow after a session | `retro` |
| Unsure which workflow fits | `ask-matt` |

Other installed skills cover specific needs: `wayfinder` for multi-session roadmaps; `triage` for issue intake; `improve-codebase-architecture` for an architecture survey; `wizard` for steps only a human can perform; `wait-what` when an explanation did not land; `teach` for a multi-session learning workspace; `to-questionnaire` for async decisions; `pr` for PR text; and `setup-matt-pocock-skills` for repo-specific tracker and documentation conventions. The `chief-of-staff`, `claude-handoff`, `loop-me`, `setup-ts-deep-modules`, writing skills, and misc setup/migration skills are narrower or in-progress; invoke them only for their stated use.

Global/non-Matt skills include `codex-auto-model-router` (routing advice for coding work), `hatch-pet` (Codex pets), and installed tool skills such as `openai-docs`, `skill-creator`, and `skill-installer`. Use these only when their task applies. Skills do not replace project instructions or user approval of product behavior.

## Example prompt

```text
Use /grill-me first. I want to improve focus-session recovery after an app relaunch.
Help me define expected behavior and edge cases before changing code. Keep this to
one small ReelItIn unit. I understand the general idea of persistence; explain any
new iOS or backend concepts as we reach them. Once we agree on behavior, propose
the first implementation slice and its test seam. Don't start coding until the
scope and expected behavior are clear.
```
