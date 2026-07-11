# File Template (Mandatory Structure)

## Introduction

Every **topic** `.md` file in this handbook uses the exact section order below. This guarantees the promise that *reading a single file gives complete understanding*. Copy this template when authoring a new topic file.

> Module `README.md` files are exempt (they are indexes). All *topic* files follow this template. Sections marked *(if applicable)* are included only when the topic genuinely touches them — and the file states "Not applicable — because …" rather than being dropped silently or padded.

---

## The template (copy below the line)

---

```markdown
# {Title}

> One-sentence definition a senior could quote verbatim.

## Introduction
What this is, in 2–4 sentences. No fluff.

## Why this concept exists
The problem it solves and what the world looked like before it. WHY before HOW.

## Real-world analogy
A concrete, non-code analogy that makes the mental model click.

## Problem Statement
A precise scenario the reader will solve by the end of the file.

## Internal Working
How it actually works under the hood — data structures, algorithms, the flow.
Use a Mermaid diagram here whenever there is structure or a sequence.

## Memory Representation
Stack vs heap, references vs values, what lives where, allocation/retention.

## Compiler Behavior
What the Dart compiler does: inference, canonicalization, tree-shaking, errors.

## Runtime Behavior
What happens while executing: dispatch, exceptions, scheduling, timing.

## Flutter Engine Behavior (if applicable)
Skia/Impeller, compositor, raster thread, platform thread interaction.

## Dart VM Behavior (if applicable)
JIT vs AOT, isolates, GC generational behavior, snapshots.

## Examples
Progressive, runnable, null-safe, lint-clean samples — from minimal to real.

## Diagrams
Mermaid diagrams (flow/sequence/class/state) that visualize the concept.

## Common Mistakes
Real bugs beginners and mids hit, each with the fix.

## Best Practices
Effective-Dart / official-guidance-aligned recommendations.

## Performance
Cost model, hotspots, benchmarks or Big-O where meaningful.

## Advantages
When and why to reach for this.

## Disadvantages
Honest tradeoffs and when NOT to use it.

## Interview Questions
6–12 questions with crisp model answers, tagged by difficulty.

## Senior Engineer Tips
Non-obvious knowledge that separates senior from mid.

## Architect Perspective
System-level implications, tech-selection tradeoffs, scaling impact.

## Summary
Tight recap of the whole file.

## Revision Notes
Bulleted, skimmable, interview-morning-ready.

## Practice Questions
Conceptual questions to self-test (no code required).

## Coding Questions
Hands-on exercises with clear acceptance criteria.

## Mini Project
A small, complete build applying the concept end-to-end.
```

---

## Authoring rules for each section

| Section | Rule |
|---------|------|
| Title + quote | The quote must be a standalone, correct one-liner. |
| Why this concept exists | Always precede HOW. If you can't state the problem, don't write the file. |
| Internal Working | Include a diagram if there is any structure/flow. |
| Compiler/Runtime/Engine/VM | Prefer facts you can cite; mark *Not applicable* explicitly when so. |
| Examples | Must compile against current stable Dart/Flutter and pass `dart analyze`. |
| Interview Questions | Provide the answer, not just the prompt. Tag 🟢/🟡/🔴. |
| Common Mistakes | Show the wrong code and the corrected code. |
| Mini Project | Must be completable in under ~2 hours by a reader at that level. |

---

## Quality bar checklist (per file)

- [ ] WHY stated before HOW.
- [ ] At least one Mermaid diagram (if the topic has structure/flow).
- [ ] At least one comparison table.
- [ ] Code is null-safe and lint-clean.
- [ ] ≥ 6 interview questions with answers.
- [ ] Coding exercise + mini project present.
- [ ] Revision Notes are skimmable in under 60 seconds.
- [ ] Official docs referenced where relevant.

## Summary

- One fixed section order for all topic files.
- *(if applicable)* sections are declared, never silently dropped.
- A per-file checklist enforces the quality bar.
