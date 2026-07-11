# DSA in Dart

> Coding rounds test **data structures + algorithms**, and you solve them in **Dart** — so know its collections (`List`, `Map`/`HashMap`, `Set`, `Queue` from `dart:collection`), their **complexity** (`Map`/`Set` O(1) average lookup; `List` O(1) index / O(n) insert-middle), and the **core patterns** (two-pointer, sliding window, hashing, stack/queue, BFS/DFS, binary search, recursion/DP, sorting). The interview meta-skill isn't memorizing solutions — it's **clarify → brute force → optimize (state complexity) → code cleanly → test edge cases → think out loud**. Dart's idioms (spread, collection-if/for, records, pattern matching) make solutions concise.

## Introduction

This file covers DSA for interviews **through Dart**: the collections + their complexity, the common problem patterns, and the interview approach (clarify/optimize/analyze/communicate). It's the coding-round preparation, applying Dart fundamentals ([Module 01](../01%20Dart%20Fundamentals/README.md)/[Module 02](../02%20Advanced%20Dart/README.md)).

## Why this concept exists

Many (esp. big-tech) mobile loops include algorithmic coding rounds. You need **DSA fluency + Dart-specific tooling** (right collection, right complexity) and a **repeatable approach** so you can solve unfamiliar problems under time pressure while communicating. Knowing Dart's collections/complexity avoids the classic mistakes (O(n) `List.contains` in a loop instead of a `Set`).

## Real-world analogy

DSA interviews are like a **timed cooking test**: you're given ingredients (input) and must produce a dish (output) under time. Success isn't a memorized recipe — it's **technique** (patterns), **the right tools** (collections), knowing **prep times** (complexity), **tasting as you go** (test cases), and **explaining your method to the judge** (think aloud). Reaching for a whisk when you need a blender (wrong collection) wastes precious time.

## Internal Working

```mermaid
flowchart TD
    Problem[problem] --> Clarify[1. clarify input/output/constraints/edge cases]
    Clarify --> Brute[2. brute force + state complexity]
    Brute --> Optimize[3. optimize via a pattern (state new complexity)]
    Optimize --> Code[4. code cleanly in Dart (right collections)]
    Code --> Test[5. test edge cases (empty/one/dupes/overflow)]
    Test --> Aloud[think out loud throughout]
```

- **Dart collections + complexity (pick the right one)**:
  - **`List<T>`**: ordered, index O(1), `add` amortized O(1), insert/remove-middle O(n), `contains` O(n). Use for sequences/stacks (via `add`/`removeLast`).
  - **`Map<K,V>` / `HashMap`**: key→value, **O(1) average** get/put/contains — the go-to for **hashing/frequency/lookup** patterns. `LinkedHashMap` (default `{}`) preserves insertion order; `SplayTreeMap` is sorted.
  - **`Set<T>` / `HashSet`**: membership **O(1) average**, dedup — use instead of `List.contains` in loops. `SplayTreeSet` sorted.
  - **`Queue` (`dart:collection`)**: `ListQueue`/`DoubleLinkedQueue` — O(1) add/remove both ends → **BFS/deque**. (`List` as a queue via `removeAt(0)` is O(n) — avoid.)
  - No built-in heap → use a package (`package:collection`'s `PriorityQueue`) for heaps.
  - **`package:collection`** helpers (groupBy, `PriorityQueue`, `IterableZip`, binary-search) are handy (know equivalents if not allowed).
- **Core patterns (recognize + apply)**:
  - **Two-pointer** (sorted arrays, pair sums, palindromes), **sliding window** (subarray/substring under a constraint), **hashing/frequency** (`Map`/`Set` — counts, seen, complements), **prefix sums**.
  - **Stack** (matching/parsing, monotonic stack), **queue/deque** (BFS, sliding-window max).
  - **Binary search** (sorted search / answer-space search), **sorting** (`list.sort((a,b)=>...)` — O(n log n)).
  - **Recursion + backtracking** (combinations/permutations/subsets), **DP** (memoization/tabulation — overlapping subproblems).
  - **Trees/graphs**: **DFS/BFS**, traversal, shortest path (BFS/Dijkstra with `PriorityQueue`), Union-Find.
- **Complexity analysis (always state it)**: give **time + space** in Big-O for brute force and optimized; know common ones (O(1)/log n/n/n log n/n²/2ⁿ). Interviewers expect you to reason about it.
- **The interview approach (the real skill)**:
  1. **Clarify** — input/output, constraints (size ranges), edge cases, expected complexity.
  2. **Brute force first** — get a correct baseline + its complexity.
  3. **Optimize** — apply a pattern; state the improved complexity + trade-offs (time vs space).
  4. **Code cleanly** — readable Dart (good names, right collections, small helpers).
  5. **Test** — walk edge cases (empty, single, duplicates, negatives, overflow, already-sorted).
  6. **Communicate** — think aloud throughout; explain choices; respond to hints.
- **Dart idioms (concise solutions)**: `map`/`where`/`fold`/`reduce`, spread `...`, collection-if/for, `Map.putIfAbsent`, records `(a, b)`, pattern matching/`switch`, `??`/`?.`, `int`/`BigInt` (Dart `int` is 64-bit on native, but **web JS ints** differ — mention if relevant). String/list slicing via `substring`/`sublist`.
- **Practice**: solve varied problems in Dart (LeetCode-style), timed, out loud; build **pattern recognition** so unfamiliar problems map to a known technique.

## Memory Representation

The right collection = the right memory/complexity trade-off: `Map`/`Set` (hash tables, O(1) avg) for lookup; `List` (dynamic array) for indexed sequences; `Queue` (linked/list-backed) for O(1) ends; `PriorityQueue` (heap) for min/max extraction. Choosing wrong inflates complexity.

## Compiler / Runtime / VM Behavior

Dart compiles + runs your solution (JIT in dev/tests, AOT in prod) — normal complexity applies. **Web** JS-number semantics differ for large ints (mention when it matters). No special interview runtime.

## Examples

```dart
// Hashing pattern: two-sum in O(n) with a Map (vs O(n^2) brute force)
List<int>? twoSum(List<int> nums, int target) {
  final seen = <int, int>{};                       // value -> index (O(1) avg lookup)
  for (var i = 0; i < nums.length; i++) {
    final need = target - nums[i];
    if (seen.containsKey(need)) return [seen[need]!, i];
    seen[nums[i]] = i;
  }
  return null;                                       // edge: no pair
}
// time O(n), space O(n); state this. Edge cases: empty, no solution, duplicates.
```

```dart
// BFS with a Queue (right collection — O(1) ends, not List.removeAt(0))
import 'dart:collection';
int shortestPath(Map<int, List<int>> graph, int start, int goal) {
  final q = Queue<(int node, int dist)>()..add((start, 0));  // record for node+dist
  final visited = <int>{start};                              // Set membership O(1)
  while (q.isNotEmpty) {
    final (node, dist) = q.removeFirst();                    // pattern match the record
    if (node == goal) return dist;
    for (final n in graph[node] ?? const []) {
      if (visited.add(n)) q.add((n, dist + 1));              // add returns false if present
    }
  }
  return -1;                                                  // unreachable
}
```

```dart
// PriorityQueue (heap) from package:collection — e.g., k largest / Dijkstra
import 'package:collection/collection.dart';
final pq = PriorityQueue<int>((a, b) => b.compareTo(a));      // max-heap
// sorting: list.sort((a, b) => a.compareTo(b));  -> O(n log n)
// idioms: nums.fold(0, (s, x) => s + x); {for (final x in xs) x: freq(x)};
```

## Diagrams

```mermaid
flowchart LR
    Clar[clarify] --> BF[brute force + O()]
    BF --> Opt[optimize (pattern) + new O()]
    Opt --> Code2[clean Dart + right collection]
    Code2 --> Edge[test edge cases]
    Edge --> Talk[think aloud throughout]
```

## Common Mistakes

| Mistake | Why it's wrong | Fix |
|---------|---------------|-----|
| `List.contains`/`removeAt(0)` in loops | O(n) each → O(n²) | Use `Set` (O(1)) / `Queue` (O(1) ends) |
| Jumping to code without clarifying | Solve the wrong problem | Clarify input/output/constraints/edges first |
| No brute force / no complexity stated | Miss baseline + poor signal | Brute force + state O(time/space) |
| Silent solving | Interviewer can't follow | Think aloud; explain choices |
| Skipping edge cases | Bugs on empty/dupes/negatives | Test edge cases explicitly |
| Memorizing solutions | Fails on variations | Learn patterns → recognize + adapt |
| Ignoring web int semantics | Wrong for large numbers on web | Note JS-number caveat when relevant |
| Wrong collection for the pattern | Inflated complexity | Match collection to access pattern |

## Best Practices

- Know Dart's **collections + complexity** and pick the **right one** (`Map`/`Set` O(1) lookup, `Queue` O(1) ends, `PriorityQueue` for heaps) — never O(n) `contains`/`removeAt(0)` in loops.
- Follow the **approach**: **clarify → brute force (+O) → optimize via a pattern (+new O) → clean Dart → test edge cases → think aloud** throughout.
- **Recognize patterns** (two-pointer/sliding-window/hashing/BFS-DFS/binary-search/recursion-DP) so unfamiliar problems map to a known technique; **state complexity** always.
- Use **Dart idioms** for concise code (map/where/fold, spread, collection-if/for, records, pattern matching, `putIfAbsent`); **practice timed + out loud**; note **web int** caveats when relevant.

## Performance

Choosing the right data structure *is* the performance win (O(n²)→O(n) via hashing; O(n) queue vs O(n²) list-as-queue). State time+space complexity for baseline + optimized. Dart runs normally; the interview measures your **algorithmic + communication** performance.

## Advantages / Disadvantages

- **+** (Prepared) solve unfamiliar problems under time, choose optimal collections, analyze complexity, communicate clearly — strong coding-round signal.
- **−** DSA grind is time-intensive + can feel disconnected from mobile work; Dart-specific collection/heap knowledge needed; not all roles weight it equally.

## Interview Questions

1. **🟢 Which Dart collection for O(1) lookup, and for a queue?** — `Map`/`Set` (HashMap/HashSet) for O(1) average lookup; `Queue` (`dart:collection`) for O(1) add/remove at both ends (not `List.removeAt(0)`, which is O(n)).
2. **🟢 What's the interview approach to a coding problem?** — Clarify (input/output/constraints/edges) → brute force + complexity → optimize via a pattern (+ new complexity) → clean code → test edge cases → think aloud.
3. **🟡 Name core DSA patterns and when to use them.** — Two-pointer/sliding-window (arrays/substrings), hashing/frequency (`Map`/`Set`), stack/queue, BFS/DFS (trees/graphs), binary search, recursion/backtracking, DP.
4. **🟡 How do you get a heap/priority queue in Dart?** — `package:collection`'s `PriorityQueue` (no built-in heap) — for k-largest/Dijkstra/scheduling.
5. **🟡 Why state complexity, and which are common?** — Interviewers assess your reasoning; know O(1)/log n/n/n log n/n²/2ⁿ and give time+space for brute force + optimized.
6. **🔴 What's a Dart-specific gotcha for numeric problems?** — Web (JS) integer semantics differ from native 64-bit ints for large values — mention/handle when it matters.
7. **🔴 Why learn patterns instead of memorizing solutions?** — Interviews use variations; pattern recognition lets you adapt to unfamiliar problems, whereas memorized solutions fail when the twist changes.

## Senior Engineer Tips

- Reach for a `Map`/`Set` the moment a problem involves lookups/frequencies/complements, and a `Queue`/`PriorityQueue` for BFS/heaps; the single biggest DSA mistake is O(n) `contains`/`removeAt(0)` inside a loop.
- Always clarify + brute-force + state complexity before optimizing, and narrate your reasoning; a correct-but-silent solution scores worse than a communicated, well-reasoned near-optimal one.
- Drill pattern recognition (timed, out loud) rather than memorizing answers, and test edge cases explicitly — empty/single/duplicate/negative inputs are where interview bugs (and real bugs) hide.

## Architect Perspective

DSA-in-Dart is the coding-round layer of interview prep: real algorithmic problem-solving expressed through Dart's collections/idioms, with the meta-skill being a **repeatable approach** (clarify→brute-force→optimize→analyze→test→communicate) and **pattern recognition** over memorization. Choosing the right data structure is both an interview and an engineering habit (O(1) lookups, O(1) queues). Weighted appropriately for your target level/role, it demonstrates the problem-solving foundation beneath everything else in the handbook ([Module 01](../01%20Dart%20Fundamentals/README.md), [Module 02](../02%20Advanced%20Dart/README.md), [interview_formats_and_prep.md](interview_formats_and_prep.md)).

## Summary

- Solve DSA in Dart: know collections + complexity (`Map`/`Set` O(1) lookup, `List` index O(1)/insert-middle O(n), `Queue` O(1) ends, `PriorityQueue` heap) and pick the right one.
- Apply core patterns (two-pointer/sliding-window/hashing/stack-queue/BFS-DFS/binary-search/recursion-DP) via the approach: clarify → brute force (+O) → optimize (+O) → clean code → edge cases → think aloud.
- Use Dart idioms for concise code; state complexity; practice timed + out loud; note web-int caveats; learn patterns, don't memorize.

## Revision Notes

- Collections: `List` (index O(1), insert-mid O(n), `contains` O(n)); `Map`/`HashMap` + `Set`/`HashSet` (O(1) avg lookup/dedup — hashing pattern); `Queue` (`dart:collection`, O(1) ends → BFS/deque); `PriorityQueue` (`package:collection`, heap). Avoid `List.removeAt(0)`/`contains` in loops.
- Patterns: two-pointer, sliding window, hashing/frequency, prefix sums, stack, queue/deque, binary search, sorting, recursion/backtracking, DP, tree/graph DFS/BFS/Dijkstra/Union-Find.
- Approach: clarify → brute force (+time/space O) → optimize via pattern (+O, trade-offs) → clean Dart (right collections) → test edge cases (empty/one/dupes/negatives/overflow) → think aloud. Idioms: map/where/fold, spread, collection-if/for, records, pattern matching, `putIfAbsent`. Web int semantics differ. Learn patterns > memorize; practice timed/out loud.

## Practice Questions

1. Which collection + complexity for a frequency-count / BFS / k-largest problem?
2. What's the step-by-step approach to an unfamiliar coding problem?
3. Why avoid `List.contains`/`removeAt(0)` in loops?

## Coding Questions

1. Solve two-sum in O(n) with a `Map` (state complexity + edge cases).
2. Implement BFS with a `Queue` + a `Set` for visited.
3. Use `PriorityQueue` for a k-largest / Dijkstra-style problem.

## Mini Project

**DSA-in-Dart drill (prep):** Solve a set of pattern problems in Dart (one each: two-pointer, sliding window, hashing, stack, BFS/DFS, binary search, DP), following the full approach for each (clarify → brute force + O → optimize + O → clean Dart with the right collection → edge cases → written "think-aloud" notes). Acceptance: correct optimized solutions using appropriate collections (Map/Set/Queue/PriorityQueue); complexity stated (brute + optimized) for each; edge cases tested; Dart idioms used; pattern identified per problem; reasoning narrated.
