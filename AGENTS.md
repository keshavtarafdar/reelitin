# Reel It In collaboration instructions

Before making a plan or implementation change, read `docs/ROADMAP.md` and any relevant architecture decisions.

This is a learning-first project. Explain unfamiliar concepts, configuration, tradeoffs, and verification steps in plain language. Work in deliberate, reviewable stages; do not interpret the roadmap as authorization to execute the entire overhaul autonomously.

## Shared context for parallel work

This repository is the source of truth for Reel It In’s durable project context. Before changing code, read `docs/ROADMAP.md`, this file, and the relevant documents below. Treat the roadmap as staged guidance, not blanket approval to execute later stages.

- Product goals and current user-facing direction: `docs/product/README.md` and the root `README.md`.
- System boundaries and established architecture: `docs/architecture/README.md` and the relevant sections of `docs/ROADMAP.md`.
- Reversible or expensive technical choices: `docs/decisions/README.md` and the applicable ADR.
- Learning-state summaries after explicitly completed tutoring/implementation phases: `docs/learning/README.md` and the relevant phase summary.

Keep phase work small enough to review and coordinate. Record new architectural commitments in an ADR or update an existing ADR rather than silently contradicting the roadmap. Do not infer an unrecorded decision from an old conversation; call out uncertainty and ask for agreement at the stage boundary.
