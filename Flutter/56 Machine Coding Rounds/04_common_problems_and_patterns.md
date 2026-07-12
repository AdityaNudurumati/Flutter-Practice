# Common Problems & Patterns

> Most machine-coding prompts are variations on a **small set of recurring problems** — **todo/CRUD list**, **searchable/filterable list** (+ **debounce**), **paginated/infinite-scroll list** (API-backed, loading/error), **form with validation**, **timer/stopwatch**, **counter/cart**, **tabs/master-detail** — each with a **known pattern** you can pre-practice: the data model, the state shape (loading/data/empty/error), the interaction logic (debounce, pagination trigger, validation), and the widget breakdown. Recognizing the prompt → applying the practiced pattern is what lets you **start fast and finish clean** instead of designing from scratch under the clock.

## Introduction

This file catalogs the common machine-coding problems + their reusable patterns (state shape, interaction logic, pitfalls), so you can pattern-match a prompt and execute quickly. It applies the right-sized MVVM-lite structure ([03_clean_architecture_under_pressure.md](03_clean_architecture_under_pressure.md)) to concrete features.

## Why this concept exists

Prompts feel varied but reduce to a handful of shapes; **pre-practicing the patterns** means you're not inventing debounce/pagination/validation logic under pressure — you recognize the prompt, reach for the known structure, and spend your time finishing + polishing. It's the machine-coding analog of DSA pattern recognition ([Module 55](../55%20Flutter%20Interview%20Preparation/02_dsa_in_dart.md)).

## Real-world analogy

It's a chef with a repertoire of **base recipes** (a risotto, a reduction, a vinaigrette): a new dish request maps to a known technique they execute smoothly, rather than improvising from nothing. Machine-coding patterns are your **base recipes** — recognize the prompt, apply the practiced method, finish on time.

## Internal Working

```mermaid
flowchart TD
    Prompt[prompt] --> Recognize{recognize the pattern}
    Recognize --> Todo[todo/CRUD list]
    Recognize --> Search[searchable/filterable list (+debounce)]
    Recognize --> Paged[paginated/infinite-scroll (API)]
    Recognize --> Form[form + validation]
    Recognize --> Timer[timer/stopwatch]
    Recognize --> Cart[counter/cart]
    Recognize --> Tabs[tabs/master-detail]
    Todo & Search & Paged & Form & Timer & Cart & Tabs --> Apply[apply practiced pattern: model + state (loading/data/empty/error) + logic + widgets]
```

- **Todo / CRUD list** (the classic):
  - *Model*: `Todo(id, text, done)`. *State*: a list (+ maybe filter: all/active/done). *Logic*: add/toggle/edit/delete (validation: no empty). *Widgets*: input + `ListView.builder` of tiles + filter.
  - *Pitfalls*: no empty-state, no validation, mutating state without notify, no keys on reorderable items.
- **Searchable / filterable list** (+ **debounce**):
  - *State*: full list + query → filtered list (loading if async). *Logic*: filter on query; **debounce** input (~300ms) so you don't filter/fetch per keystroke ([Module 43](../43%20MVVM/README.md)). *Widgets*: search field + results + empty ("no results").
  - *Pitfalls*: no debounce (hammering), no empty-results state, case-sensitivity, not cancelling stale searches.
- **Paginated / infinite-scroll list** (API-backed):
  - *State*: `items + page/cursor + isLoadingMore + hasMore + error`. *Logic*: fetch page 1 (loading), append on scroll-near-bottom (`ScrollController` / `NotificationListener`), stop at `hasMore == false`; **pull-to-refresh**. *Widgets*: `ListView.builder` + a bottom loader/error-retry row.
  - *Pitfalls*: refetching the same page, no loading/error states, no `hasMore` guard, rebuilding the whole list, blocking scroll on error.
- **Form + validation**:
  - *State*: field values + validation errors + submitting. *Logic*: validate (per-field + on submit), disable submit while invalid/submitting, show errors. *Widgets*: `Form`/`TextFormField` (or a VM-driven form) + submit button + error text.
  - *Pitfalls*: no validation, validating only on submit (or never), not disabling submit, losing focus/state, no loading on submit.
- **Timer / stopwatch**:
  - *State*: elapsed + running. *Logic*: `Timer.periodic` (start/pause/reset), format mm:ss, **dispose the timer** on stop/dispose. *Widgets*: display + controls.
  - *Pitfalls*: not disposing the `Timer` (leak/keeps running), rebuilding whole screen each tick, drift (use elapsed from a start time for accuracy).
- **Counter / cart**:
  - *State*: quantities/items + derived total. *Logic*: increment/decrement (guard ≥0), add/remove, compute total. *Widgets*: item rows + total.
  - *Pitfalls*: recomputing incorrectly, negative quantities, not scoping rebuilds (whole list rebuilds on one change).
- **Tabs / master-detail / navigation**:
  - *State*: selected tab/item. *Logic*: switch content; on desktop/web show master-detail side-by-side (responsive — [Module 24](../24%20Responsive%20UI/README.md)). *Widgets*: `TabBar`/`NavigationRail` + content.
  - *Pitfalls*: losing tab state, not preserving scroll (use `PageStorageKey`/`AutomaticKeepAlive`), no responsive adaptation if asked.
- **Cross-cutting patterns (apply to all)**:
  - **State shape = loading/data/empty/error** (explicit, in the VM — [Module 38](../38%20Error%20Handling/README.md)) — the single most-forgotten scoring win.
  - **MVVM-lite** structure (thin UI + UI-free VM + simple repo — [03_clean_architecture_under_pressure.md](03_clean_architecture_under_pressure.md)).
  - **`ListView.builder`** (virtualized) for any list; **`const`** + scoped rebuilds; **dispose** controllers/timers/subscriptions.
  - **Debounce** for search/typing; **`ScrollController`** for pagination; **validation** for forms.
  - **Mock the data** if no API is given (an in-memory repo with a fake delay) so you can show loading/error states.
- **Recognize → apply**: on hearing the prompt, **name the pattern(s)** (aloud), reach for the practiced model/state/logic/widgets, and adapt — then spend saved time finishing + polishing + edge cases.

## Memory Representation

Not code — a **pattern library**: for each common problem, the (model, state shape, interaction logic, widget breakdown, pitfalls). You pre-build these mentally/by practice so you instantiate them fast under time.

## Compiler / Runtime / Engine / VM Behavior

Not applicable beyond running Flutter. Relevant runtime habits: `ListView.builder` virtualization, `Timer` disposal, debounce timers, `ScrollController` for pagination.

## Examples

```dart
// Searchable list with DEBOUNCE (don't filter/fetch per keystroke) — a recurring pattern
class SearchViewModel extends ChangeNotifier {
  final ProductRepo repo; Timer? _debounce; List<Product> results = [];
  SearchViewModel(this.repo);
  void search(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {   // debounce
      results = await repo.search(q); notifyListeners();
    });
  }
  @override void dispose() { _debounce?.cancel(); super.dispose(); }   // dispose!
}
```

```dart
// Infinite scroll / pagination pattern — state + trigger + guards
class FeedViewModel extends ChangeNotifier {
  final FeedRepo repo; final items = <Post>[]; int _page = 1;
  bool loadingMore = false, hasMore = true; String? error;
  FeedViewModel(this.repo);
  Future<void> loadMore() async {
    if (loadingMore || !hasMore) return;                 // guard
    loadingMore = true; notifyListeners();
    try {
      final page = await repo.page(_page);
      items.addAll(page.items); hasMore = page.hasMore; _page++;
    } catch (e) { error = 'Failed to load'; }
    loadingMore = false; notifyListeners();
  }
}
// UI: ListView.builder + ScrollController -> loadMore() near bottom; bottom loader/error-retry row.
```

```dart
// Timer/stopwatch — periodic + dispose + accurate elapsed
class TimerVm extends ChangeNotifier {
  Timer? _t; Duration elapsed = Duration.zero; DateTime? _start;
  void start() { _start = DateTime.now().subtract(elapsed);
    _t = Timer.periodic(const Duration(milliseconds: 100), (_) {
      elapsed = DateTime.now().difference(_start!); notifyListeners(); }); }
  void pause() { _t?.cancel(); }
  void reset() { _t?.cancel(); elapsed = Duration.zero; notifyListeners(); }
  @override void dispose() { _t?.cancel(); super.dispose(); }   // dispose the timer!
}
```

## Diagrams

```mermaid
flowchart LR
    Hear[hear prompt] --> Name[name the pattern (aloud)]
    Name --> Instantiate[instantiate: model + state (loading/data/empty/error) + logic + widgets]
    Instantiate --> Adapt[adapt specifics]
    Adapt --> Finish[finish + edge cases + polish]
```

## Common Mistakes

| Mistake | Where it bites | Fix |
|---------|---------------|-----|
| No debounce on search | Hammers filter/API | Debounce input (~300ms) + cancel stale |
| No pagination guards | Refetch/overload | `loadingMore`/`hasMore` guards + trigger near bottom |
| Missing loading/empty/error states | Every list/async prompt | Explicit state shape in the VM |
| Not disposing timers/controllers/subs | Timer/search/scroll | `dispose()` everything |
| Building all list items | Any list | `ListView.builder` (virtualized) |
| No form validation / no submit-disable | Form prompt | Validate + disable submit while invalid/submitting |
| Losing tab/scroll state | Tabs/master-detail | `PageStorageKey`/keep-alive |
| Designing from scratch under time | All | Recognize + apply a practiced pattern |

## Best Practices

- **Recognize the prompt as a known pattern** (todo/search/paginated/form/timer/cart/tabs) and **instantiate the practiced structure** (model + loading/data/empty/error state + interaction logic + widget breakdown) rather than designing from scratch.
- Apply the **recurring details**: **debounce** search, **pagination guards** (`loadingMore`/`hasMore`) + scroll trigger, **form validation** + submit-disable, **`Timer` + dispose**, **`ListView.builder`** + scoped rebuilds, **mock data** with fake delay to show states.
- Always include the **loading/empty/error state shape** (the most-forgotten scoring win) and **dispose** timers/controllers/subscriptions.
- Practice each pattern beforehand so you **start fast + finish clean**; name the pattern aloud (communication) and adapt specifics.

## Performance

`ListView.builder` (virtualized), scoped rebuilds, debounce (fewer filter/API calls), and timer disposal keep the built feature efficient — and are also scoring signals. The bigger win is **speed of execution**: practiced patterns let you finish + polish instead of inventing logic under the clock.

## Advantages / Disadvantages

- **+** Fast start (pattern recognition), reliable finish, built-in edge cases + best practices, covers most prompts, communicable ("this is the pagination pattern").
- **−** Requires pre-practice of each pattern; must still adapt to the prompt's specifics; over-reliance without understanding fails on twists.

## Interview Questions

1. **🟢 What are the common machine-coding problem types?** — Todo/CRUD list, searchable/filterable list (+debounce), paginated/infinite-scroll (API), form + validation, timer/stopwatch, counter/cart, tabs/master-detail.
2. **🟢 What state shape should most list/async prompts have?** — Explicit loading/data/empty/error in the view model — the most-forgotten scoring win.
3. **🟡 How do you implement search correctly?** — Debounce input (~300ms), cancel stale searches, filter/fetch on the debounced query, and show a "no results" empty state.
4. **🟡 What does the pagination pattern require?** — `items + page/cursor + loadingMore + hasMore + error`, a scroll-near-bottom trigger, guards (don't refetch / stop at `hasMore == false`), pull-to-refresh, and a bottom loader/error-retry row.
5. **🟡 What must a timer/stopwatch handle?** — `Timer.periodic` for ticks, accurate elapsed from a start time (avoid drift), start/pause/reset, and **disposing the timer** (leak otherwise).
6. **🔴 Why practice patterns rather than design from scratch?** — Recognition lets you instantiate a known model/state/logic/widget structure fast and spend saved time finishing + polishing + edge cases.
7. **🔴 What cross-cutting best practices apply to all patterns?** — Loading/empty/error state, MVVM-lite structure, `ListView.builder`, scoped rebuilds, dispose timers/controllers/subs, debounce/validation/mock-data as relevant.

## Senior Engineer Tips

- Pre-build the top patterns (todo, search+debounce, pagination, form, timer) until you can produce each in minutes; recognizing the prompt and reaching for the practiced structure is what turns a 90-minute scramble into a finished, polished feature.
- Always add the loading/empty/error state shape and dispose your timers/controllers/subscriptions — those two are the most common cheap points left on the table (and the most common real bugs).
- Mock the data with a fake delay when no API is given, so you can actually demonstrate loading/error states + pagination — a static list hides exactly the behaviors being scored.

## Architect Perspective

The pattern library is machine-coding's execution accelerator: recurring problems (list/search/pagination/form/timer) with known model+state+logic+widget structures, all built on right-sized MVVM-lite with explicit edge-case states. Recognizing the prompt and instantiating the practiced pattern is the analog of DSA pattern recognition — it frees your limited time to finish, polish, and communicate, converting knowledge into a consistent, strong submission ([03_clean_architecture_under_pressure.md](03_clean_architecture_under_pressure.md), [02_approach_and_time_management.md](02_approach_and_time_management.md), [Module 43](../43%20MVVM/README.md)).

## Summary

- Most prompts are variations of: todo/CRUD, searchable list (+debounce), paginated/infinite-scroll, form+validation, timer/stopwatch, counter/cart, tabs/master-detail.
- Each has a practiced pattern (model + loading/data/empty/error state + interaction logic + widget breakdown); recognize → instantiate → adapt → finish.
- Apply recurring details (debounce, pagination guards, validation, `Timer`+dispose, `ListView.builder`, mock data) + always the edge-case state shape.

## Revision Notes

- Problems + patterns: todo/CRUD (add/toggle/delete + filter + empty/validation); search (debounce ~300ms + cancel stale + no-results); pagination/infinite-scroll (items+page/cursor+loadingMore+hasMore+error, scroll trigger, guards, pull-to-refresh, bottom loader/error); form (per-field + submit validation, disable submit, loading); timer/stopwatch (`Timer.periodic`, accurate elapsed, start/pause/reset, DISPOSE); counter/cart (guard ≥0 + derived total + scoped rebuild); tabs/master-detail (selected state, keep-alive/PageStorageKey, responsive).
- Cross-cutting: loading/data/empty/error state shape (most-forgotten), MVVM-lite, `ListView.builder` + `const` + scoped rebuilds, dispose timers/controllers/subs, mock data + fake delay to show states. Recognize→apply (name aloud)→adapt→finish.

## Practice Questions

1. What's the state + logic for the pagination pattern?
2. How do you implement search correctly (debounce/edge cases)?
3. What must you always dispose, and what state shape must lists have?

## Coding Questions

1. Build a searchable list with debounce + empty-results state.
2. Build an infinite-scroll list with loading/error + `hasMore` guards + pull-to-refresh.
3. Build a stopwatch with start/pause/reset that disposes its timer + avoids drift.

## Mini Project

**Pattern drill (prep):** Pre-build three common patterns (e.g., searchable list with debounce, paginated/infinite-scroll list with loading/error + guards, and a form with validation) using MVVM-lite (UI-free VM + simple mock repo with fake delay), each with the loading/data/empty/error state shape, proper disposal, `ListView.builder`, and the recurring logic (debounce/pagination-guards/validation). Time each build. Acceptance: each pattern implemented with correct state shape + interaction logic + edge cases + disposal; virtualized lists; mock data shows loading/error; built quickly (practiced); pattern named per prompt.
