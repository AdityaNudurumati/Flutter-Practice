# MVC in Flutter (Mapping & Friction)

> Mapping MVC onto Flutter is genuinely awkward because **Flutter's widget is both View and (via `build`) a bit of Controller**, and the framework is **declarative/reactive** (UI = f(state)) rather than the imperative "Controller mutates the View" MVC assumes. The pragmatic "Flutter MVC" that emerges — **Model** (data/rules) + **Controller** (holds/mutates state, e.g. a `ChangeNotifier`/GetxController) + **View** (rebuilds reactively from the controller) — is really a **reactive variant that's closer to MVVM/MVC-hybrid**. Knowing this prevents forcing an imperative pattern onto a reactive framework.

## Introduction

This file maps MVC's roles to Flutter's building blocks, explains the friction (widgets blur View/Controller; reactive vs imperative), and describes what "Flutter MVC" actually means in practice (controllers + reactive views), including the GetX flavor. It's the reality-check between classic MVC ([mvc_fundamentals.md](mvc_fundamentals.md)) and the better-fitting MVVM ([Module 43](../43%20MVVM/README.md)).

## Why this concept exists

Teams reach for the familiar MVC label, but Flutter wasn't built around it. The framework rebuilds Views from state (declarative), so there's no persistent imperative View for a Controller to poke. Recognizing this saves you from fighting the framework and clarifies that most "Flutter MVC" is a reactive controller pattern — useful, but not classic MVC.

## Real-world analogy

Classic MVC is like a **stage where a director (Controller) walks on and rearranges the actors (View) directly**. Flutter is like a **screen showing a live render of a script (state)**: you don't move actors on stage — you **change the script and the screen re-renders**. Trying to "grab an actor and move them" (imperatively mutate a widget) doesn't fit; you edit the script (state) and let Flutter redraw.

## Problem Statement

Take the task-list feature and structure it as "Flutter MVC": a Model (data/rules), a Controller holding mutable state + operations, and a View that **rebuilds reactively** from the controller — then articulate exactly where this diverges from classic MVC. You'll wire a reactive controller + view and name the friction.

## Internal Working

```mermaid
flowchart TD
    View[Widget (View): rebuilds from controller state] -->|input| Controller[Controller: ChangeNotifier/GetxController holds+mutates state]
    Controller --> Model[Model: data + rules]
    Controller -->|notifyListeners / reactive| View
    Note[Flutter is declarative: View = f(state); no imperative View to poke]
```

- **The mapping (pragmatic)**:
  - **Model** → plain Dart data + rules (+ optionally repositories) — same as elsewhere.
  - **Controller** → a **state holder** (`ChangeNotifier`, `GetxController`, or similar) that **holds mutable state**, exposes **operations** (called from the View), mutates the Model/state, and **notifies** listeners.
  - **View** → a **widget** that **listens/rebuilds** (via `ListenableBuilder`/`Consumer`/`Obx`) and **forwards input** to the controller.
- **Friction point 1 — the widget blurs View and Controller**: a `StatefulWidget`'s `build` renders (View) but `setState`/event handlers also handle input/logic (Controller-ish). Flutter doesn't hand you a clean 1:1 with MVC's three separate objects.
- **Friction point 2 — declarative/reactive, not imperative**: classic MVC's "Controller updates the View" assumes a **persistent imperative View**. Flutter **rebuilds the View from state** (UI = f(state)) — there's nothing to imperatively poke; you **change state and rebuild**. This inverts the classic flow.
- **What "Flutter MVC" really is**: a **reactive controller pattern** — controller holds state, view observes it. That's essentially **MVVM** (controller ≈ view model) or a hybrid; the "MVC" label is loose. **GetX** popularized this style (`GetxController` + `Obx`), often called MVC but structurally MVVM-ish.
- **Keeping it honest**: if the "controller" exposes observable state the view binds to, you've built MVVM; true classic MVC (passive view, controller pushing updates) doesn't map cleanly. Use the reactive variant deliberately, not by mislabeling.
- **Where the Model/repo fits**: for anything beyond trivial, the "Model" becomes domain + data (repositories) as in Clean Architecture; the controller orchestrates use cases ([Module 40](../40%20Clean%20Architecture/README.md)).

## Memory Representation

The controller (a `Listenable`/`GetxController`) holds current state + a listener list; widgets subscribe and rebuild on notify. No persistent imperative View object — widgets are rebuilt descriptions.

## Compiler Behavior

Not applicable; it's structural. The controller is plain Dart (testable without widgets).

## Runtime Behavior

Input → controller mutates state → `notifyListeners`/reactive trigger → listening widgets rebuild (View = f(state)). This is reactive propagation, not the controller mutating a live view.

## Flutter Engine Behavior

The framework diffs the rebuilt widget tree against the element tree and repaints changed render objects ([Module 09](../09%20Rendering%20Pipeline/README.md)) — reactivity is native; there's no imperative view mutation to hook.

## Dart VM Behavior

Controller logic is plain Dart (fast unit tests); widget rebuilds run on the UI isolate.

## Examples

```dart
import 'package:flutter/material.dart';

// MODEL — data + rules (UI-agnostic)
class TaskModel {
  final List<String> tasks;
  const TaskModel(this.tasks);
  TaskModel add(String t) => t.trim().isEmpty ? this : TaskModel([...tasks, t.trim()]);
}

// "CONTROLLER" — holds state + operations + notifies (this is really MVVM-ish)
class TaskController extends ChangeNotifier {
  TaskModel _model = const TaskModel([]);
  TaskModel get model => _model;
  void add(String text) { _model = _model.add(text); notifyListeners(); } // mutate + notify
}

// VIEW — rebuilds reactively from the controller, forwards input (no logic)
class TaskView extends StatelessWidget {
  final TaskController controller; final TextEditingController input;
  const TaskView({super.key, required this.controller, required this.input});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,                              // reactive: View = f(state)
    builder: (_, __) => Column(children: [
      for (final t in controller.model.tasks) Text(t),
      ElevatedButton(onPressed: () => controller.add(input.text), child: const Text('Add')),
    ]),
  );
}
// This "MVC" is structurally MVVM (controller = view model exposing observable state).
```

## Diagrams

```mermaid
flowchart LR
    Classic[Classic MVC: Controller imperatively updates View] -->|doesn't fit| Flutter
    Flutter[Flutter: View = f(state), rebuilds] --> Reactive[reactive controller (ChangeNotifier/Getx)]
    Reactive -->|≈| MVVM[really MVVM/hybrid]
```

## Common Mistakes

| Mistake | Why | Fix |
|---------|-----|-----|
| Forcing imperative "controller updates view" | Fights declarative Flutter | Change state; let View rebuild |
| Calling a reactive-controller app "classic MVC" | Mislabels MVVM | Acknowledge it's MVVM-ish |
| Logic/state in the widget | Blurs View/Controller | Move state to the controller |
| Controller with UI imports | Not testable/reusable | Keep controller plain Dart |
| God controllers | Catch-all logic | Split per feature; use repos/use cases |
| Ignoring rebuild scope | Whole-tree rebuilds | Scope listeners (`ListenableBuilder`/`Obx`) |

## Best Practices

- Accept Flutter's **declarative model**: don't imperatively "update the view" — **mutate state in the controller and let the View rebuild** (UI = f(state)).
- Keep the **controller plain Dart** (state + operations + notify), **no UI imports**, so it's testable; keep **widgets thin** (rebuild + forward input).
- **Scope rebuilds** (`ListenableBuilder`/`Consumer`/`Obx`) to what changed; split controllers per feature; delegate real logic to **Model/repositories/use cases** ([Module 40](../40%20Clean%20Architecture/README.md)).
- Be **honest about the label**: a controller exposing observable state the view binds to is **MVVM** — use the reactive variant deliberately ([Module 43](../43%20MVVM/README.md)).

## Performance

Reactivity is native + efficient if rebuilds are **scoped** (listen narrowly). Whole-tree rebuilds on every notify are the main pitfall — use granular builders/selectors ([Module 21](../21%20Performance/README.md)). Controller logic in plain Dart is cheap.

## Advantages / Disadvantages

- **+** Familiar vocabulary, clean state-in-controller separation, testable controllers, works with Flutter's reactivity (as a variant).
- **−** Classic MVC doesn't map (friction/mislabeling), widget blurs View/Controller, controller-god risk, essentially reinvents MVVM.

## Interview Questions

1. **🟢 Why does classic MVC fit Flutter awkwardly?** — Flutter is declarative (View = f(state)) with no persistent imperative View for a Controller to update; the classic imperative flow doesn't apply.
2. **🟢 How does "Flutter MVC" typically work?** — A controller (`ChangeNotifier`/`GetxController`) holds state + operations and notifies; widgets rebuild reactively and forward input.
3. **🟡 Why is "Flutter MVC" often really MVVM?** — Because the controller exposes observable state the view binds to — that's a view model, i.e., MVVM.
4. **🟡 How does the widget blur MVC roles?** — A widget both renders (View) and, via handlers/`setState`, handles input/logic (Controller) — no clean 1:1 with three objects.
5. **🟡 Where should state and logic live?** — State/operations in the controller (plain Dart), business rules in the Model/domain — not in widgets.
6. **🔴 What's the main performance pitfall of this pattern?** — Unscoped rebuilds on every notify; fix with granular listeners/selectors.
7. **🔴 How does GetX relate to MVC here?** — It popularized the reactive-controller style (`GetxController`+`Obx`) often called MVC but structurally MVVM-ish.

## Senior Engineer Tips

- Stop trying to imperatively update views; the moment you "change state and let Flutter rebuild," the friction disappears — and you've built MVVM, which is fine.
- Keep controllers UI-free and per-feature; a `ChangeNotifier`/`GetxController` with `dio` or `BuildContext` baked in is untestable and god-prone.
- Scope your reactive rebuilds; "MVC in Flutter" apps most often jank because the whole page rebuilds on every notify.

## Architect Perspective

Mapping MVC to Flutter exposes a truth: the framework's reactivity naturally yields MVVM, so "Flutter MVC" is best understood as a reactive controller (≈ view model) pattern. Recognizing this lets you use the familiar structure without fighting the framework, and points you to MVVM as the cleaner articulation and Clean Architecture for the Model side. The label matters less than respecting UI = f(state) and keeping controllers testable ([Module 43](../43%20MVVM/README.md), [Module 40](../40%20Clean%20Architecture/README.md)).

## Summary

- Classic MVC (imperative "Controller updates View") fits Flutter awkwardly; the widget blurs View/Controller and the framework is declarative.
- "Flutter MVC" = Model (data/rules) + reactive controller (state+ops+notify) + View (rebuilds from state) — structurally MVVM/hybrid (as in GetX).
- Mutate state and let the View rebuild; keep controllers plain-Dart + per-feature; scope rebuilds; be honest about the label.

## Revision Notes

- Flutter = declarative (View = f(state)); no imperative View → classic MVC flow inverts; widget = View + some Controller.
- "Flutter MVC" = Model + controller (`ChangeNotifier`/`GetxController`, state+ops+notify) + reactive View (`ListenableBuilder`/`Obx`) → really MVVM/hybrid (GetX).
- Controller plain Dart (no UI), per-feature; rules in Model/domain; scope rebuilds; mutate state, don't poke the view.

## Practice Questions

1. Why is there no imperative View for a Controller to update in Flutter?
2. In what sense is "Flutter MVC" actually MVVM?
3. What's the main pitfall of reactive controllers, and the fix?

## Coding Questions

1. Build a reactive controller (`ChangeNotifier`) + a View that rebuilds from it.
2. Move logic/state out of a widget into the controller.
3. Scope the rebuild so only the changed part updates.

## Mini Project

**Reactive "MVC" feature (Flutter):** Implement the task list as Model (data + rule), a plain-Dart controller (`ChangeNotifier`: state + `add`/`remove` + notify), and a thin View that rebuilds reactively (`ListenableBuilder`) and forwards input — with scoped rebuilds and a UI-free, unit-testable controller. Document how this differs from classic MVC and why it's MVVM-ish. Acceptance: controller holds state/ops + notifies (no UI imports); View rebuilds from state + only forwards input; rebuilds scoped; controller unit-tested; classic-MVC-vs-reality difference documented.
