# Navigation & Routing — Interview Questions

> How Flutter moves between screens, from `Navigator.push` to declarative routing. For depth see the handbook modules [12 Navigation](../12%20Navigation/README.md) and [13 Routing](../13%20Routing/README.md).

Navigation is where interviewers probe whether you understand the difference between *imperative* screen pushing and *declarative* URL-driven state — the split that Navigator 2.0 and go_router exist to bridge. Expect it to escalate from "how do you pass an argument" to "how do you keep bottom-nav tab state and still support deep links".

## 🟢 Basic

**1. What is the `Navigator` and how does the stack model work?**
`Navigator` is a widget that manages a stack of `Route` objects — one per screen. `push` adds a route on top (the new screen slides in), `pop` removes the top one (revealing the screen beneath and optionally returning a result). It's a LIFO stack, exactly like a browser history or an activity back-stack. The `Navigator` lives above your screens (installed by `MaterialApp`/`WidgetsApp`) and is reached via `Navigator.of(context)` or the static `Navigator.push(context, ...)` helpers.

**2. How do you push and pop a screen?**
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const DetailsPage()),
);
Navigator.pop(context); // back to the previous screen
```
`push` takes a `Route`; `MaterialPageRoute` gives you the platform-correct transition (slide on Android, cupertino swipe on iOS) and a full-screen opaque page. `pop` unwinds one entry.

**3. What is `MaterialPageRoute` and how does it differ from `PageRouteBuilder`?**
`MaterialPageRoute` is a ready-made modal route with Material transitions and a barrier. `PageRouteBuilder` is the low-level escape hatch that lets you define `pageBuilder`, `transitionsBuilder`, and `transitionDuration` yourself — use it for custom transitions (fade, scale, shared-axis). `CupertinoPageRoute` is the iOS-styled equivalent. All extend `PageRoute` → `ModalRoute`.

**4. What are named routes and how do you register them?**
Named routes map a string to a builder, declared once in `MaterialApp`:
```dart
MaterialApp(
  routes: {
    '/': (_) => const HomePage(),
    '/details': (_) => const DetailsPage(),
  },
);
Navigator.pushNamed(context, '/details');
```
They centralize your route table and read like a sitemap. The downside: passing typed arguments is stringly-typed and awkward, which is why teams outgrow them.

**5. How do you pass arguments to a named route, and read them back?**
Pass via the `arguments` parameter and read them with `ModalRoute.of(context)!.settings.arguments`:
```dart
Navigator.pushNamed(context, '/details', arguments: Product(id: 7));
// in DetailsPage:
final product = ModalRoute.of(context)!.settings.arguments as Product;
```
The argument is `Object?`, so you cast it — there's no compile-time safety. This is the classic pain point that `onGenerateRoute` and typed routers fix.

**6. How do you return a result from a screen?**
`push` returns a `Future` that completes when the route is popped, and `pop` can carry a value:
```dart
final picked = await Navigator.push<Color>(
  context,
  MaterialPageRoute(builder: (_) => const ColorPicker()),
);
// in ColorPicker:
Navigator.pop(context, Colors.blue);
```
So navigation is naturally `async`: you `await` the pushed route to get what the user chose. Always guard `context` after the `await` with a `mounted` check.

**7. What is `onGenerateRoute` and when do you use it?**
`onGenerateRoute` is a callback on `MaterialApp` that turns a `RouteSettings` (name + arguments) into a `Route`. It's more powerful than the static `routes` map because you can parse the name, extract path parameters, build typed arguments, and choose the transition — all in one place:
```dart
onGenerateRoute: (settings) {
  if (settings.name == '/details') {
    final id = settings.arguments as int;
    return MaterialPageRoute(builder: (_) => DetailsPage(id: id));
  }
  return null; // falls through to onUnknownRoute
},
```
It's the "one router function" pattern before go_router — useful for validation and centralized argument decoding.

**8. What's the difference between `push`, `pushReplacement`, and `pushNamedAndRemoveUntil`?**
`push` adds on top. `pushReplacement` swaps the current top route for a new one (common for splash → home, so back doesn't return to the splash). `pushNamedAndRemoveUntil` pushes and pops everything until a predicate is true — e.g. after login, clear the whole stack and land on home with `(route) => false`.

**9. What does `Navigator.pop` return to, and how do you go back multiple screens?**
`pop` returns to the route directly beneath. To skip several, use `popUntil((route) => route.isFirst)` or `popUntil(ModalRoute.withName('/home'))`. `maybePop` pops only if there's something to pop (and respects `onWillPop`-style callbacks), which is what the system back button triggers.

**10. What is the difference between imperative and declarative navigation?**
Imperative (Navigator 1.0): you *command* the stack — "push this, pop that" — from event handlers. Declarative (Navigator 2.0 / go_router): you *describe* the stack as a function of app state — the list of pages is rebuilt whenever state changes, and the framework diffs it. Imperative is simpler for linear flows; declarative is necessary when navigation must sync with URLs, deep links, and restorable app state.

**11. Why is the URL / browser address bar relevant to Flutter navigation?**
On Flutter web (and for deep links on mobile), the stack must be reconstructable from a URL string. Imperative pushes don't naturally serialize to a URL, so a user pasting `/products/7` or hitting the browser back button can't be handled cleanly. Declarative routing exists precisely to make "URL ⇄ page stack" a two-way, restorable mapping.

**12. What is a `RouteSettings` object?**
It's the metadata attached to a route: its `name` and `arguments`. `MaterialPageRoute(settings: ...)` carries it, and `ModalRoute.of(context)!.settings` reads it. Named routes and `onGenerateRoute` both work by inspecting `RouteSettings`.

## 🟡 Intermediate

**13. Why was Navigator 2.0 introduced — what could 1.0 not do?**
Navigator 1.0 is imperative and stack-only: the app can push/pop, but the *system* (browser, OS) can't tell the app "the user wants to be at this URL/route now". 1.0 couldn't cleanly handle web URL sync, browser forward/back, or programmatically rewriting the entire stack from app state. Navigator 2.0 adds a declarative **Pages API** and a `Router` widget so the OS/browser can push route information *into* the app, and the app describes its whole stack declaratively.

**14. Explain the core pieces of Navigator 2.0.**
| Piece | Job |
|---|---|
| `Router` | Widget that wires everything together; listens to route info |
| `RouteInformationProvider` | Source of route info (the platform / browser URL) |
| `RouteInformationParser` | Parses a `RouteInformation` (URL) into a typed app state, and back |
| `RouterDelegate` | Builds the `Navigator` with a `pages` list from app state; handles pops |
| `BackButtonDispatcher` | Routes the system back button to the right delegate |

The `RouterDelegate` holds the app's navigation state and calls `notifyListeners()` to rebuild the `Navigator` with a new `pages` list.

**15. What is the Pages API?**
Instead of imperatively pushing routes, you give `Navigator` a declarative `pages: [...]` list of `Page` objects (`MaterialPage`, `CupertinoPage`) plus an `onDidRemovePage` (formerly `onPopPage`) callback. When app state changes, you rebuild the list; Flutter diffs old vs new pages by their `key` and animates the difference. This is the declarative model — the stack is derived from state, not mutated directly.

**16. Why do people find raw Navigator 2.0 painful?**
It's extremely verbose and error-prone: you hand-write a `RouterDelegate` (extending `ChangeNotifier` + `PopNavigatorRouterDelegateMixin`), a `RouteInformationParser`, a state model, and page-diffing logic — dozens of lines of boilerplate for what 1.0 did in one call. Edge cases (nested routers, back dispatch, restoring state) are fiddly. That boilerplate is exactly why `go_router` (and others) were built on top of it.

**17. What is `go_router` and why prefer it?**
`go_router` is the Flutter-team-endorsed declarative router that wraps Navigator 2.0. You declare a route tree with URL-style paths; it gives you deep-link/URL sync, redirects, nested navigation, and error handling without touching `RouterDelegate`. You keep the declarative benefits and lose the boilerplate:
```dart
final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomePage()),
    GoRoute(
      path: '/product/:id',
      builder: (_, state) => ProductPage(id: state.pathParameters['id']!),
    ),
  ],
);
MaterialApp.router(routerConfig: router);
```

**18. `context.go` vs `context.push` in go_router?**
`go` sets the location declaratively — it *replaces* the current navigation state with the stack implied by that path (used for tab switches, post-login redirects). `push` adds a page on top imperatively, keeping the current stack (used for drill-down like list → detail). Mixing them thoughtfully is common; overusing `push` breaks URL/state consistency.

**19. How do you pass data and read path/query params in go_router?**
Path params come from the pattern (`/product/:id` → `state.pathParameters['id']`), query params from `state.uri.queryParameters`, and arbitrary objects via `extra`:
```dart
context.go('/product/7?ref=home');
context.push('/checkout', extra: cart);
// reader: state.extra as Cart
```
`extra` is not serialized into the URL, so it won't survive a deep link or web refresh — use it only for in-app object passing, and use path/query params for anything that must be linkable.

**20. What is a redirect / route guard in go_router?**
`redirect` is a callback (global on `GoRouter` or per-route) that returns a new location string to bounce the user, or `null` to allow. It's how you implement auth gating:
```dart
redirect: (context, state) {
  final loggedIn = auth.isLoggedIn;
  final goingToLogin = state.matchedLocation == '/login';
  if (!loggedIn && !goingToLogin) return '/login';
  if (loggedIn && goingToLogin) return '/';
  return null;
},
```
Combine with `refreshListenable` so the router re-evaluates redirects when auth state changes.

**21. What is `refreshListenable` and why is it needed?**
By itself, a `redirect` only runs on navigation events. If auth state changes *while the user sits on a page* (token expires, logout elsewhere), nothing re-triggers the guard. `refreshListenable: someListenable` makes go_router re-run redirects whenever that `Listenable` notifies — so logging out anywhere immediately bounces to `/login`.

**22. What is `ShellRoute` and when do you use it?**
`ShellRoute` (and `StatefulShellRoute`) wraps a set of child routes in a persistent shell UI — typically a `Scaffold` with a `BottomNavigationBar` — so the shell stays mounted while the body swaps. The shell's `builder` receives the child navigator; child routes render into it. This is the idiomatic way to get a bottom nav where the app bar / nav bar persist across tabs.

**23. How do you handle unknown routes / 404s?**
In Navigator 1.0, `onUnknownRoute` on `MaterialApp` catches names no route matched. In go_router, use `errorBuilder` (or `errorPageBuilder`) to render a not-found screen, and per-route exceptions surface there too. Always have one — otherwise a bad deep link crashes or shows a blank page.

**24. What are typed routes in go_router?**
Typed routes (`go_router_builder`) generate route classes from annotated definitions so you navigate with compile-time-safe objects instead of raw strings:
```dart
@TypedGoRoute<ProductRoute>(path: '/product/:id')
class ProductRoute extends GoRouteData {
  const ProductRoute({required this.id});
  final int id;
  @override
  Widget build(BuildContext c, GoRouterState s) => ProductPage(id: id);
}
// navigate:
const ProductRoute(id: 7).go(context);
```
You get refactor-safe, typo-proof navigation and automatic param parsing — the answer to the "stringly-typed arguments" pain from Navigator 1.0.

## 🔴 Advanced

**25. Explain the full Navigator 2.0 URL round-trip.**
1. The platform reports a new URL via `RouteInformationProvider`.
2. `RouteInformationParser.parseRouteInformation` turns that `RouteInformation` into a typed app state (e.g. `AppRoutePath.details(7)`).
3. `RouterDelegate.setNewRoutePath` receives that state, updates its fields, and `notifyListeners()`.
4. `RouterDelegate.build` returns a `Navigator` whose `pages` list is derived from the state.
5. For the reverse (app → URL), `RouteInformationParser.restoreRouteInformation` serializes current state back into a URL so the address bar / OS stays in sync.

Being able to narrate this both directions is the senior-level Navigator 2.0 answer.

**26. How do nested navigators work, and what breaks with them?**
A nested `Navigator` is a child `Navigator` widget below the root — used for tab-local stacks, wizards, or modal flows so back stays within that subtree. Pitfalls: (a) the system back button targets the root unless you wire a `BackButtonDispatcher`/`Router.of` correctly; (b) `Navigator.of(context)` picks the *nearest* navigator, so you may push onto the wrong one — use `rootNavigator: true` when you need the root; (c) deep links must resolve to the correct inner navigator. `StatefulShellRoute` in go_router manages these nested navigators for you.

**27. How do you preserve independent stack + scroll state per bottom-nav tab?**
Each tab needs its own `Navigator` so its back-stack survives tab switches, and the inactive tab's subtree must stay alive. Options: `IndexedStack` of per-tab navigators (keeps all mounted — simple but builds everything eagerly), or `StatefulShellRoute.indexedStack` in go_router (the modern answer — it manages a branch navigator per tab, preserving each branch's stack and state). Wrap scroll views with `PageStorageKey` so scroll offset is retained. The interviewer is checking you know a naive `body: pages[index]` throws away state on every switch.

**28. How do deep links and app links actually get set up (high level)?**
- **Android:** declare an `intent-filter` in `AndroidManifest.xml` for your scheme/host with `android:autoVerify="true"` for **App Links** (verified `https://` links, no chooser dialog). Verification needs an `assetlinks.json` at `https://yourdomain/.well-known/assetlinks.json` containing your app's SHA-256 fingerprint.
- **iOS:** enable **Associated Domains** (`applinks:yourdomain`) in Xcode capabilities and host an `apple-app-site-association` (AASA) file at `https://yourdomain/.well-known/`.
- **Flutter side:** with go_router, incoming links arrive as route information automatically; otherwise use a package like `app_links`/`uni_links` to receive the initial and streamed URIs. Custom URL schemes (`myapp://`) work without web verification but are less secure and can be hijacked.

**29. Difference between deep links, universal/app links, and custom-scheme links?**
A *deep link* is any URL that opens a specific in-app location. A *custom-scheme* link (`myapp://product/7`) is app-owned but unverified — any app can claim the scheme. *Universal Links (iOS)* / *App Links (Android)* use real `https://` URLs verified against your domain via AASA/assetlinks, so the OS opens your app directly (or the web page if the app isn't installed) with no ambiguity. Interviewers want the verification/security distinction.

**30. `WillPopScope` vs `PopScope` — what changed and why?**
`WillPopScope(onWillPop: () async => bool)` let you *asynchronously veto* a pop (e.g. "discard unsaved changes?"). It's deprecated because it's incompatible with **predictive back** (Android's back-gesture preview): the OS needs to know *up front* whether the pop will be blocked, but an async callback can't answer synchronously. `PopScope` replaces it with a synchronous `canPop` flag plus an `onPopInvokedWithResult(didPop, result)` callback:
```dart
PopScope(
  canPop: !hasUnsavedChanges,
  onPopInvokedWithResult: (didPop, result) {
    if (didPop) return;
    _showDiscardDialog(); // handle the blocked pop
  },
  child: form,
);
```

**31. How do you implement auth-gated navigation robustly?**
Use a global `redirect` keyed on an auth `Listenable` wired via `refreshListenable`. Rules: unauthenticated + not on `/login` → `/login`; authenticated + on `/login` → home. Store the intended destination (`state.uri` in `?from=`) so you can bounce the user back after login. Keep the auth state outside the router (a notifier/BLoC) so both UI and redirects read one source of truth. This avoids flicker and race conditions from doing guarding imperatively inside `build`.

**32. Why must you check `mounted` (or capture objects) after an `await` on navigation?**
`Navigator.push` returns a `Future`; while you `await` the result, the pushing widget may be disposed (user navigated away). Using its `context` afterward (for another push, `ScaffoldMessenger`, etc.) throws or leaks. Guard with `if (!mounted) return;` after the await, or capture `Navigator`/`ScaffoldMessenger` references *before* awaiting. The analyzer's `use_build_context_synchronously` lint flags exactly this.

**33. How does the framework decide which pages to animate when the `pages` list changes?**
`Navigator` diffs the old and new `pages` lists by each `Page`'s `key` (a `LocalKey`/`ValueKey`). New keys → a push-in transition; removed keys → a pop-out; reordering by key reshuffles without recreating state. Forgetting stable keys causes wrong or missing transitions and lost state — so unique, stable page keys are essential in the declarative model.

**34. How do you build a custom page transition and keep it consistent app-wide?**
Subclass `PageRouteBuilder` (or `CustomTransitionPage` in go_router) with your own `transitionsBuilder`, then apply it centrally — a shared factory or a `PageTransitionsTheme` in `ThemeData` so every `MaterialPageRoute` uses it per platform. Centralizing avoids one-off transitions scattered across `push` calls and keeps motion coherent.

**35. What are the risks of using `extra` for navigation data, and the alternatives?**
`extra` is a plain in-memory `Object?` — it is **not** encoded in the URL, so it's `null` after a web refresh, a cold deep link, or state restoration, and it isn't type-safe. Use it only for transient in-app hand-offs. For anything linkable or restorable, encode identity in path/query params and re-fetch the object by id at the destination (single source of truth), or use typed routes for compile-time safety.

## ⚡ Rapid-fire (one-liners)

| Question | Answer |
|---|---|
| What data structure is the Navigator? | A LIFO stack of `Route`s |
| How to get a result from a screen? | `await Navigator.push(...)`; return via `pop(context, value)` |
| Push without keeping current screen? | `pushReplacement` |
| Clear the whole stack after login? | `pushNamedAndRemoveUntil(..., (r) => false)` |
| Read named-route arguments? | `ModalRoute.of(context)!.settings.arguments` |
| Turn a URL into a Route centrally? | `onGenerateRoute` |
| Two halves of Navigator 2.0 parser? | `RouteInformationParser` + `RouterDelegate` |
| Declarative stack list is called? | The Pages API (`pages: [...]`) |
| go_router: replace stack vs add page? | `context.go` vs `context.push` |
| Persistent bottom nav in go_router? | `StatefulShellRoute` / `ShellRoute` |
| Auth guard in go_router? | `redirect` + `refreshListenable` |
| Compile-time-safe routes? | Typed routes via `go_router_builder` |
| Replacement for `WillPopScope`? | `PopScope` (`canPop` + `onPopInvokedWithResult`) |
| Verified https deep links called? | App Links (Android) / Universal Links (iOS) |
| Files that verify app links? | `assetlinks.json` / `apple-app-site-association` |
| Push onto the root navigator? | `Navigator.of(context, rootNavigator: true)` |

## Follow-up drills

1. **Design** a routing layer for a 3-tab app where each tab keeps its own back-stack and scroll position, and a deep link like `/orders/42` opens inside the correct tab — using `StatefulShellRoute`.
2. **Migrate** a legacy app from Navigator 1.0 named routes to go_router without breaking existing `pushNamed` call sites during the transition.
3. **Implement** end-to-end auth gating: unauthenticated users bounced to `/login`, redirected back to their intended destination after sign-in, and instantly ejected on token expiry from any screen.
4. **Set up** verified App Links / Universal Links for `https://shop.example.com/product/:id` and explain what breaks if the `assetlinks.json` fingerprint is wrong.
5. **Debug** a scenario where switching bottom-nav tabs resets each tab to its first screen and loses scroll — identify the cause and fix it.
6. **Optimize** a nested-navigator flow where the system back button closes the whole app instead of popping the inner stack.
