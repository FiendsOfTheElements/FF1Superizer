---
name: scheming
description: "Planning-mode skill. Climb concerns broadest-first down a decision ladder — the big, uncertain stuff before the minutiae. Use during the planning phase of ANY task, before you present a plan or enter plan mode: whenever you're deciding what to clarify, which questions to ask, or how to scope the work. Consult it before you ask the user anything while planning — even a single question."
author: "Polatrite"
version: 4
---

# Scheming — planning mode

You're scoping work before committing to it. A plan built on a misread goal is wasted no matter how good the steps are. Climb the concerns broadest-first, and stop to *ask* only where you hit uncertainty you can't resolve yourself.

## The requirements ladder

Follow the requirements ladder to write the plan: get a high rung wrong and every choice below it is garbage.

1. **Goal.** What does the user actually want, and why? If this is fuzzy, nothing below matters.
2. **Scope.** The right problem — or is there a simpler ask hiding inside it? Whatever's plainly
   out, cut it *now*, before anything downstream reasons about dead scope.
3. **Constraints.** What the solution must get right (business rules, formulas), then what it
   must not break (invariants, conventions, the systems it touches). You **read** these — you don't
   ask them.
4. **Approach.** Only when genuinely different strategies exist *and* the user would notice the
   difference — which one?
5. **Boundaries.** The fine cut, once you know the approach: the exact seam — deferred vs. done,
   which edge cases are in, which tradeoffs you'll accept.
6. **Shape.** Names, exact UX, specific values. **Ask these — don't pick them yourself.**
7. **Minutiae.** The smallest defaults. **Ask these too — don't pick them yourself.** Shape
   and minutiae are interview rungs like every other; you keep asking down through them and
   never quietly fall back to your own choice. The **only** time you fill them yourself is
   after the user opts out (see the **opt-out cadence** below) — that's the fallback, not the
   default.

## The discovery ladder

Before you ask *anything*, work down this ladder to find the answer yourself:

1. **Investigate.** Read the code and the docs (if available). A concern you can look up isn't a question.
2. **Decide.** Pick the obvious default and note the assumption.
3. **Ask.** Only when the answer changes the plan *and* guessing wrong costs more than the round-trip.

## Investigating

Use multiple recon subagents where appropriate, especially when the task spans a large chunk of the codebase.

## Rules

- **Ask at the highest open rung first.** A resolved goal will answer ten downstream questions, a resolved constraint will prohibit an invalid architectural decision.
- **Order a batch broad → narrow, and keep it small.** At maximum, four questions at a time.
- **Lead with the option you'd pick, and why.** A question is a decision you're handing over — not a
  menu to hide behind.
- **Always give an "Other" option** so the user can specify their own answer.
- **If both answers lead to the same plan, it isn't a question.** Pick one and move on.

Ask when it's genuinely unresolvable — an ambiguous goal, or an irreversible / outward-facing
choice. Never ask what the code already answers or permission for the plainly-correct next step.
Shape and minutiae are interview material by default — ask them, don't pick them. You only
start filling them with your own defaults once the user opts out.

## Opt-out cadence

The interview runs all the way through Shape and Minutiae — you keep asking, and you never
fall back to your own defaults on your own initiative. That's comprehensive but long, so the
user needs a way out: opting out is the **only** thing that switches you from asking to
deciding. Hand them that exit on a regular beat:

- **Count your question sets.** Each `AskUserQuestion` batch is one set.
- **Every 2nd set (sets 2, 4, 6, …), include an opt-out** — an explicit way to end questioning
  and let you proceed on your best defaults for everything still open. Either add it as an
  option on that batch's broadest question ("Proceed on your recommended defaults for the
  rest") or as a dedicated final question in the batch ("Keep refining, or lock the rest to
  your defaults?").
- **Until the user opts out, keep asking.** Do not pre-empt the interview by silently
  resolving shape or minutiae yourself — climb the ladder in order and put each open choice to
  the user.
- **When we reach minutiae, alert the user clearly**: `=== [ ASKING MINUTIAE ] ===`
- **When the user opts out, stop asking and decide.** Fill every remaining rung — shape and
  minutiae included — with your recommended defaults, reasoning each one out. Then **print a
  one-line bullet for every decision you made this way**, one decision per bullet, so all of
  them are visible at a glance. After that, move on. Don't re-open the cadence unless the user
  asks something new or reverses course.
- The opt-out is an offer, not a reset: until it's taken, keep climbing the ladder in order
  between offers, and still lead every question with the option you'd pick.

## Progress

Before each round of questions, print these three lines so the user can see how much questioning is
left. Mark each step done/skipped `[x]`, current `[+]`, or pending `[ ]`, and give a rough percent
as a progress bar from the weights below — a step's weight only counts once it's *fully* resolved:

```
Planning: [x] Goal [x] Scope [+] Constraints [ ] Approach [ ] Boundaries [ ] Shape [ ] Minutiae
Progress: [====      ] 5 of 12 questions
```

Following the progress bar is a **rough estimate of how many questions you still expect to ask**
if the user keeps refining — so they can gauge how long the tail is and decide whether to opt out.
Re-estimate it each round as the picture sharpens.

The weights are **question-load, not step count** — most of the asking lives in Approach and
Boundaries. Constraints is read, so it's normally near-free. Shape and Minutiae are now fully
asked (until opt-out), so they carry real question-load rather than being picked silently. And
skew by task: bugfixes and content collapse Approach onto Shape; novel systems spend most of
their questions up in Approach.

| Goal | Scope | Constraints | Approach | Boundaries | Shape | Minutiae |
|---|---|---|---|---|---|---|
| 10 | 15 | 13 | 24 | 18 | 12 | 8 |
