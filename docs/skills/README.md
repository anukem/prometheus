# Skills Docs

## Available Skills
- `plan-mode`
  - Description: Structured planning workflow for ambiguous or multi-step tasks.
  - Use when: the user asks for a plan, asks to brainstorm options, or requests sequencing/tradeoff analysis before implementation.
  - Skill file: `/Users/ezeugo/conductor/workspaces/prometheus/lansing/skills/plan-mode/SKILL.md`

## Usage Rules
- Discovery: Treat this list as the set of skills available in this repo.
- Triggering: If a user names a skill or the request clearly matches a skill description, use that skill for the turn.
- Scope: Do not carry skills across turns unless re-mentioned.
- Loading: Open `SKILL.md` first; load additional referenced files only when needed.
- Missing/blocked: If a skill path cannot be read, state it briefly and continue with best fallback.
