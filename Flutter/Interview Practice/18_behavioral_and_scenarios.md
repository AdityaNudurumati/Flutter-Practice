# Behavioral & Scenario Questions — Interview Questions

> The non-code half of every Flutter/mobile interview: how you work, communicate, decide, and recover. For the seniority lens see [58 Senior Architect Notes](../58%20Senior%20Architect%20Notes/README.md) and for process/craft see [60 Software Engineering Practices](../60%20Software%20Engineering%20Practices/README.md).

Behavioral rounds test whether a strong engineer is also a safe hire: can you own outcomes, collaborate under friction, and make defensible trade-offs. Answers are scored on *specificity and self-awareness*, not eloquence — so every story must be a real situation with a concrete result. Tiers below are by **experience level**, not difficulty: 🟢 common intro/experience questions, 🟡 situational/teamwork, 🔴 senior/leadership.

## How to use the STAR method (read first)

STAR = **S**ituation → **T**ask → **A**ction → **R**esult. It forces a story arc instead of a vague opinion.

- **Situation** (1–2 sentences): set the scene — team size, product, the constraint. Keep it short; it's context, not the point.
- **Task**: what *you* specifically owned. Name your role explicitly so the interviewer can attribute the outcome to you.
- **Action** (the bulk, ~60%): the concrete steps *you* took and *why* you chose them. Use "I", not "we" — the interviewer is scoring you, not your team.
- **Result**: the measurable outcome (numbers > adjectives) plus what you learned or changed afterward.

Golden rules:
- **Quantify the Result.** "Cut cold-start jank" is weak; "cut jank frames from 18% to 3% on the mid-tier Android profile, measured in DevTools" is strong.
- **Pre-load 4–6 stories** that each flex a different muscle (a hard bug, a conflict, a failure, a leadership moment, an ambiguity call) — most questions map onto one of them.
- **Prefer recent, mobile-flavored stories.** A Flutter-specific example (a jank fix, a platform-channel decision, a Bloc-vs-Riverpod call) signals domain depth a generic story can't.
- **End every failure story on the learning + the change you made** so it never landed the same way twice.

## 🟢 Common (intro & experience)

**1. "Tell me about yourself."**
*Assessing:* can you frame your own narrative concisely and steer it toward the role. This is a 60–90 second pitch, not a résumé readthrough.
*Outline (present → past → future):*
- **Present:** "I'm a Flutter engineer focused on production mobile apps — currently owning the {payments / offline-sync} area of a {X}-user app."
- **Past:** one or two proof points that map to this job's needs — "shipped the migration from Provider to Riverpod across 40+ screens," "took app-startup TTI from 3.1s to 1.4s."
- **Future:** why *this* role now — "I want to go deeper on {scale / platform channels / team leadership}, which is exactly what this team does."
*Red flag:* reciting a chronological life story, or going 4+ minutes. Practice it to time.

**2. "Walk me through a project you're proud of."**
*Assessing:* depth of ownership and whether you understand impact, not just tasks.
*STAR outline:*
- **S:** "Our app's checkout was losing users on flaky networks."
- **T:** "I owned making checkout resilient offline." (your scope)
- **A:** "I designed an offline-first queue with a local Drift DB, idempotent retry keys, and optimistic UI; I chose a command-queue pattern over naive caching because payments can't be replayed blindly."
- **R:** "Checkout completion on poor connections rose ~22%; the pattern became the team's template for other mutations." Then the learning.
*Red flag:* can't explain *why* you made the technical choices, or claims sole credit for a team effort.

**3. "Tell me about a difficult bug you fixed."**
*Assessing:* debugging methodology and rigor under pressure — do you guess or do you isolate.
*STAR outline:*
- **S:** "Intermittent crash on Android only, no stack trace in Crashlytics beyond a native frame."
- **T:** "I had to root-cause a heisenbug we couldn't reproduce locally."
- **A:** "I formed hypotheses and eliminated them methodically — added breadcrumb logging, correlated it to a specific device/OS band, found a platform-channel call returning on a background isolate touching a plugin that required the platform thread." Emphasize the *method* (bisect, instrument, reproduce, fix, add a regression test).
- **R:** "Crash-free sessions went from 99.1% to 99.9%; I added a lint/CI check so the same misuse can't ship again."
*Red flag:* "I just kept trying things until it worked" — shows no systematic approach.

**4. "Why do you want to work here?"**
*Assessing:* genuine research and fit — is this a scattershot application.
*Outline:* tie a specific thing about *their* product/tech/scale to your goals. "You're a Flutter-first team shipping to both stores from one codebase at millions of installs — I want to work on cross-platform consistency at that scale." Reference something concrete (their app, a talk, their tech blog).
*Red flag:* generic answers that fit any company ("great culture, growth"). Interviewers hear these all day.

**5. "What's your biggest strength / weakness?"**
*Assessing:* self-awareness — the weakness is the real question.
*Outline:* pick a **real** weakness plus the concrete system you built to manage it. "I used to over-engineer abstractions early; now I default to the simplest thing that works and only generalize on the second use — I even flag it in my own PRs." A strength should be backed by a one-line example, not just an adjective.
*Red flag:* the humblebrag weakness ("I work too hard," "I'm a perfectionist"). It reads as evasive.

**6. "Why are you leaving your current job / looking to move?"**
*Assessing:* professionalism and motivation — do you speak ill of employers.
*Outline:* frame forward, not away. "I've learned a lot, but the mobile team is small and I want to work on {larger scale / a domain they don't have}." Keep it about growth and opportunity.
*Red flag:* trashing your manager, team, or codebase. It predicts how you'll talk about *them* next.

**7. "Tell me about a time you had to learn a new technology quickly."**
*Assessing:* learning agility — critical because the mobile stack churns fast.
*STAR outline:*
- **S:** "We adopted Riverpod mid-project and I'd only used Provider/Bloc."
- **T:** "I had two weeks before I'd be reviewing others' Riverpod PRs."
- **A:** "I read the official docs end to end, rebuilt one real feature as a spike, and wrote a short team cheat-sheet on our conventions (when to use `ref.watch` vs `ref.read`, provider lifecycles)." Show a *repeatable* learning process.
- **R:** "Shipped the feature on time and the cheat-sheet cut onboarding questions for the next two hires."
*Red flag:* framing learning as painful/reluctant, or no evidence you can self-serve from docs.

**8. "How do you keep your Flutter skills current?"**
*Assessing:* intrinsic motivation and awareness of the ecosystem's pace.
*Outline:* name concrete channels — release notes for each stable Flutter version, pub.dev trends, a side project, reading source of packages you depend on. Mention a *specific* recent change you tracked (e.g. impeller becoming default, a Dart language feature). Specificity proves it's real.
*Red flag:* vague "I read blogs" with nothing concrete to point to.

**9. "Describe your typical development workflow on a feature."**
*Assessing:* engineering discipline — see [60 Software Engineering Practices](../60%20Software%20Engineering%20Practices/README.md).
*Outline:* clarify requirements → break into small PRs → write tests alongside (unit for logic, widget for UI) → self-review the diff → open a tight PR with context → address review → verify on both platforms before merge. The point is you have a *repeatable* process, not heroics.
*Red flag:* "I just start coding" — no design, no tests, giant PRs.

**10. "Tell me about a time you received tough feedback."**
*Assessing:* coachability and ego management.
*STAR outline:*
- **S:** "A senior said my PRs were too large and slow to review."
- **T/A:** "I took it as valid, switched to stacked/small PRs, and asked them to check if it helped."
- **R:** "Review turnaround dropped and I now default to <400-line PRs." Show you acted on it and it stuck.
*Red flag:* being defensive, or an example where you were "given feedback" but disagreed and did nothing.

## 🟡 Situational (teamwork & judgment)

**11. "Tell me about a disagreement with a teammate."**
*Assessing:* can you disagree technically without making it personal, and commit once decided.
*STAR outline:*
- **S:** "A teammate wanted Bloc for a simple settings screen; I thought it was overkill vs. a plain `ChangeNotifier`."
- **A:** "I asked what problem Bloc was solving here, laid out the trade-off (boilerplate vs. testability), and proposed we decide by our actual criterion — testability need and team consistency. We agreed to match the codebase's existing pattern."
- **R:** "We shipped without churn, and I disagreed-and-committed cleanly." Emphasize focusing on *the problem*, shared criteria, and reversible-vs-irreversible framing.
*Red flag:* "I was right and they were wrong," or you won by seniority/volume rather than reasoning.

**12. "Tell me about a time you missed a deadline."**
*Assessing:* accountability and communication under slippage.
*STAR outline:*
- **S:** "A platform-channel integration for a hardware SDK was more complex than scoped."
- **A:** "As soon as I saw the slip coming, I flagged it *early* to the PM with options — cut scope for v1, or push the date two days. I didn't sit on it hoping to catch up."
- **R:** "We shipped a reduced v1 on time and the full version the next sprint." The signal is *early, honest communication + options*, not that you never miss.
*Red flag:* the miss was a surprise to stakeholders, or you blame the estimate/others without owning the communication gap.

**13. "Describe a code review conflict — as author or reviewer."**
*Assessing:* how you handle friction in the most frequent collaboration surface.
*STAR outline:*
- **A (as reviewer):** "I distinguish blocking issues (a memory leak from an undisposed `StreamController`) from preferences (naming), label nits as nits, and explain the *why* with a link, not just an order."
- **A (as author):** "When I disagreed I moved it to a quick call instead of a comment war, and captured the decision in the PR for the next person."
- **R:** "We merged without resentment and codified the rule so it wasn't re-litigated."
*Red flag:* treating every comment as blocking, or ego battles in the thread. See [60 Software Engineering Practices](../60%20Software%20Engineering%20Practices/README.md).

**14. "How do you handle ambiguous or incomplete requirements?"**
*Assessing:* do you build the wrong thing confidently, or de-risk before coding.
*STAR outline:*
- **S:** "A ticket said 'add offline support' with no detail on conflict handling."
- **A:** "I listed the open questions (which entities, last-write-wins vs. merge, what the user sees when syncing), took them to product with a recommendation, and built a thin prototype of the riskiest path first to make the ambiguity concrete."
- **R:** "We caught a conflict-resolution requirement before it was expensive to change." Show you reduce ambiguity with questions + a spike, not assumptions.
*Red flag:* "I just build what I think is best and adjust later" — expensive rework, and it signals you skip stakeholder alignment.

**15. "Tell me about a time you had to balance speed vs. quality."**
*Assessing:* pragmatism and conscious trade-off — not dogma in either direction.
*STAR outline:*
- **S:** "A launch-critical feature vs. a hard marketing date."
- **A:** "I shipped a scoped, well-tested happy path and *explicitly logged* the deferred edge cases as tracked tech-debt tickets with owners — a deliberate, visible trade-off, not a silent shortcut."
- **R:** "Hit the date, paid the debt down the next sprint before it compounded."
*Red flag:* absolutism ("I never cut corners" or "ship it, fix later always"), or cutting corners *silently*.

**16. "Describe a time you had to give difficult feedback to a peer."**
*Assessing:* directness with empathy — a leadership precursor.
*STAR outline:* private not public → specific behavior + impact ("the last three PRs had no tests, so QA caught regressions late") → ask for their view → agree on a concrete change → follow up. Result: relationship intact, behavior changed.
*Red flag:* avoiding the conversation entirely, or being blunt without care/context.

**17. "Tell me about a time you disagreed with a product/design decision."**
*Assessing:* can you push back constructively across functions and still deliver.
*STAR outline:* "Design wanted an animation I knew would jank on low-end Androids. I didn't just say no — I built a quick profiled demo showing dropped frames on a target device, then proposed an alternative that kept the intent at 60fps." Result: shipped a version that satisfied design *and* performance. Evidence beats opinion.
*Red flag:* "I just did what I was told" (no engineering voice) *or* "I refused" (not a team player).

**18. "Tell me about working with a difficult stakeholder or teammate."**
*Assessing:* emotional maturity and whether you seek to understand.
*STAR outline:* identify their underlying concern (a "difficult" PM often just fears a missed date) → adjust *your* communication (async written updates for someone who felt out of the loop) → find common ground. Result: relationship improved because you changed something you controlled.
*Red flag:* the whole story is about how unreasonable the other person was, with no self-reflection.

**19. "A teammate is blocked on you and getting frustrated — what do you do?"**
*Assessing:* responsiveness and prioritization of team throughput over personal focus.
*Outline:* unblock small/cheap requests fast even if it interrupts you; for larger ones, give a clear ETA and a stopgap (a stub interface, a mock, a branch) so they can proceed in parallel. The signal is that you treat *team velocity* as your job, not just your own tickets.
*Red flag:* "they should wait until I finish my task" — local optimization at the team's expense.

**20. "Tell me about a time you made a mistake in production."**
*Assessing:* ownership and blameless response — do you hide or surface failures.
*STAR outline:*
- **S:** "I shipped a release where a null cast crashed on a locale I didn't test."
- **A:** "I owned it immediately, rolled back / hotfixed via a feature flag, wrote a blameless postmortem, and added a test + a CI matrix for locales."
- **R:** "No repeat; the locale matrix caught two later bugs pre-release."
*Red flag:* minimizing it, blaming QA, or no systemic fix so it could recur.

## 🔴 Senior & leadership

**21. "Tell me about a time you mentored someone."**
*Assessing:* whether you scale through others, not just your own output.
*STAR outline:*
- **S:** "A junior kept struggling with async/state bugs (setState after dispose, unawaited futures)."
- **A:** "I paired instead of fixing it for them, taught the mental model of the widget lifecycle and `mounted` checks, and set up a lightweight review rhythm. I optimized for *them* learning to fish."
- **R:** "Within a quarter they were reviewing others' async code; that's leverage." See [58 Senior Architect Notes](../58%20Senior%20Architect%20Notes/README.md).
*Red flag:* "mentoring" that's actually just doing the work for them, or measuring your success by your commits instead of their growth.

**22. "Describe a significant technical decision you drove (e.g., a state-management or architecture choice)."**
*Assessing:* structured decision-making, buy-in, and owning the outcome — good and bad.
*STAR outline:*
- **S:** "Team was split on Bloc vs. Riverpod for a new app."
- **A:** "I ran a lightweight trade-off doc with explicit criteria (testability, boilerplate, team familiarity, ecosystem), built parallel spikes of one real feature in each, and made a *recommendation with a rationale*, not a decree. I looped in the seniors and the people who'd maintain it."
- **R:** "We chose Riverpod; I documented the decision + reasons (an ADR) so it wasn't re-litigated. Six months in I revisited whether it held up." Show a repeatable, evidence-based, buy-in-seeking process.
*Red flag:* deciding by ego/hype/novelty, no criteria, or no follow-through to check if it was right.

**23. "Tell me about a time you had to say no to a PM or stakeholder."**
*Assessing:* backbone plus the ability to say no *with* a path, not a wall.
*STAR outline:* "PM wanted a feature in a sprint that required rushing our auth-token refresh logic — a security risk. I said no to *that timeline*, explained the risk in their terms (a token leak = user trust + store review risk), and offered a safe phased plan." Result: they chose the safe plan because you gave them a business-framed trade-off, not just resistance.
*Red flag:* either can't ever say no (pushover) or says no without offering an alternative (blocker). Also: framing risk in jargon they can't act on.

**24. "Walk me through how you owned an incident or outage."**
*Assessing:* calm under fire, coordination, and turning failure into system improvement.
*STAR outline:*
- **S:** "A backend contract change caused a deserialization crash on app launch — users hard-stuck at splash."
- **A:** "I stabilized first (feature-flag kill-switch / forced-update gate), communicated status to stakeholders on a cadence, *then* root-caused. I ran the incident, didn't just fix code."
- **R:** "Restored within the hour; the blameless postmortem produced a contract-test in CI and a schema-version guard so a breaking change can't crash launch again." See [60 Software Engineering Practices](../60%20Software%20Engineering%20Practices/README.md).
*Red flag:* heroics with no communication, or fixing the symptom with no prevention. Mitigate-then-diagnose order matters.

**25. "How do you decide when to take on vs. pay down tech debt?"**
*Assessing:* treating tech debt as a managed trade-off, not a moral failing.
*STAR outline:* "I treat debt like a loan — fine if it's deliberate, documented, and the interest (change-cost, bug-rate) is tracked. I quantify it: this legacy navigation stack cost us N bugs and slowed every feature by ~X. I bundle paydown into adjacent feature work rather than asking for a standalone 'refactor sprint' that PMs will never fund." Result: measurable drop in a metric (crash rate, cycle time).
*Red flag:* "rewrite everything" absolutism, or never addressing debt because "there's no time" — both signal poor judgment. See [58 Senior Architect Notes](../58%20Senior%20Architect%20Notes/README.md).

**26. "Tell me about a time you influenced without authority."**
*Assessing:* can you drive change across a team when you can't simply mandate it.
*STAR outline:* "I wanted the team on a shared CI gate (format, analyze, test, golden diffs). I couldn't mandate it, so I built it, proved it on my own repo, showed the bugs it caught, and made adoption one-line easy. Peers opted in because it made *their* life easier." Result: org-wide adoption via demonstrated value.
*Red flag:* influence via politics or pressure rather than evidence and making the right thing the easy thing.

**27. "Describe leading a project that failed or was cancelled."**
*Assessing:* resilience, honesty, and extracting value from failure at scale.
*STAR outline:* own the call honestly (a Flutter-web bet that didn't meet perf targets on the target hardware), what signals you missed, when you should have killed it sooner, and what the org kept (learnings, reusable components, a clearer bar for "is web viable here"). Result is the *learning* and any salvage.
*Red flag:* no failure to share (unbelievable / low ownership), or blaming everyone but yourself.

**28. "How do you handle a senior engineer whose code you think is wrong?"**
*Assessing:* courage + humility balance, and technical communication upward.
*Outline:* assume you might be missing context → ask questions before asserting ("what happens to this `StreamSubscription` on rebuild — do we leak it?") → bring data/repro if you're confident → escalate on facts, not rank. Result: either you learn the context you missed, or the issue gets fixed — both are wins.
*Red flag:* staying silent out of deference (real bug ships) or steamrolling with certainty (arrogant, no humility).

**29. "How do you set technical direction or standards for a team?"**
*Assessing:* systems thinking — scaling quality through process, not per-PR policing.
*Outline:* codify the important stuff (lint rules, architecture boundaries, ADRs for big calls), automate enforcement in CI so it's not about personalities, and reserve human review for judgment. Lead by writing the first examples. Keep standards *living* — revisit when they cause more friction than value.
*Red flag:* standards-by-decree with no buy-in, or gatekeeping everything manually (doesn't scale, becomes a bottleneck).

**30. "Tell me about balancing individual delivery with team responsibilities as a senior."**
*Assessing:* understanding that senior impact is measured in team output, not personal LOC.
*Outline:* deliberately trade some of your own throughput for reviews, unblocking, mentoring, and design docs when that multiplies the team; protect *some* focus time so you keep technical credibility. Name the trade-off explicitly. Result framed as team velocity/quality, not just your tickets shipped.
*Red flag:* hoarding the "fun" work, or being so heads-down you never lift the team.

## ⚡ Rapid-fire (one-liners)

| Prompt | One-line approach |
| --- | --- |
| Greatest professional achievement? | One story, quantified result, your specific role. |
| Where do you see yourself in 3–5 years? | Growth aligned to *this* role's trajectory; ambitious but plausible. |
| How do you prioritize competing tasks? | Impact × urgency; confirm priorities with the stakeholder, don't guess. |
| How do you handle stress / crunch? | Concrete tactics (scope-cut, communicate early) + sustainable boundaries. |
| Prefer working alone or in a team? | Both, with an example of each; adapt to what the work needs. |
| How do you handle being wrong? | Acknowledge fast, fix, extract the lesson — an example, not a platitude. |
| What motivates you? | Something specific and intrinsic (solving user pain, craft), not "money." |
| Describe your ideal manager. | Autonomy + context + candid feedback; avoid anything that trashes past bosses. |
| A time you went above and beyond? | Real story with impact — not just "worked late." |
| How do you onboard to an unfamiliar codebase? | Run it, trace one flow end-to-end, read tests, ask targeted questions. |
| Do you have questions for us? | Always yes — thoughtful ones about the team's real challenges. |
| How do you handle context-switching between platforms? | Checklists, verify on both iOS/Android, automate the repetitive parts. |
| A time you improved a process? | Named the friction, proposed a fix, measured the before/after. |
| How do you estimate work? | Break down, add uncertainty buffer, communicate ranges + assumptions. |

## Follow-up drills (self-practice — no answers)

1. **Escalating conflict:** "You disagreed and committed to a state-management choice. Six months later it's clearly hurting the team. How do you reopen that decision without undermining the person who won the original call?"
2. **Incident ownership:** "Walk me through an outage where the root cause was *your* code, the fix was non-obvious, and stakeholders were watching live. Separate what you did to mitigate from what you did to diagnose, and to communicate."
3. **Saying no upward:** "A director personally wants a feature you believe is technically unsound for the app's scale. Your PM defers to them. How do you handle it?"
4. **Influence at scale:** "Convince a skeptical team of five to adopt a new architecture pattern (or CI gate) when you have no authority over any of them and two are more senior than you."
5. **Tech-debt tradeoff:** "You've inherited a codebase with no tests and a 4% crash rate under launch pressure. Make the case to product for the investment — in *their* language — and lay out your first 90 days."
6. **Mentoring under-performance:** "A mid-level engineer on your team is plateauing and morale is dipping. Describe how you'd diagnose, intervene, and know whether it's working."

---

See also: [58 Senior Architect Notes](../58%20Senior%20Architect%20Notes/README.md) · [60 Software Engineering Practices](../60%20Software%20Engineering%20Practices/README.md)
