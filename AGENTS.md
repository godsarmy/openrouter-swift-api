# AGENTS

This repository supports agent-assisted development.

## Purpose
- Provide a single place for agent-facing workflow notes.
- Keep automation guidance close to the codebase.

## Default Expectations
- Keep changes minimal and scoped to the request.
- Prefer small, verifiable edits.
- Run relevant checks/tests for modified areas when possible.
- Avoid unrelated refactors.

## Handoff Notes
- Summarize what changed and why.
- List any follow-up tasks or assumptions.

## Documentation
- `docs/` is the OKF v0.2 bundle; start at `docs/index.md`.
- Follow `docs/development/documentation.md` for frontmatter, links, indexes, and validation.
- Keep one canonical concept per topic; root `APIs.md` is a pointer to `docs/reference/endpoint-coverage.md`.
- Update directory indexes and `docs/log.md` when adding or moving documentation.
- Do not claim human verification unless a human actually reviewed the content.
- Run `python scripts/check_docs.py` and `python -m unittest discover -s scripts -p 'test_*.py'`
  with the documentation dependencies installed (see `scripts/requirements-docs.txt`).

## Planning/Tracking
- Keep long-lived roadmap details in `README.md` and `PLAN.md`.
- If a planning doc is completed, fold essential status into `README.md` before deleting it.
- Note deferred work explicitly (e.g., Responses API parity) so follow-up is discoverable.
