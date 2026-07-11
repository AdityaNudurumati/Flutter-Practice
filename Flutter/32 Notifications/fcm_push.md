# Push Notifications with FCM (Foreground / Background / Terminated)

> Firebase Cloud Messaging delivers server-sent push to a device identified by an **FCM registration token** (which rotates — sync it to your backend). The hard part is the **three app-state delivery model**: **foreground** (you receive `onMessage` and must render it yourself, e.g. via a local notification), **background** (the system tray shows it; `onMessageOpenedApp` fires on tap), and **terminated** (a top-level background handler + `getInitialMessage()` on launch) — plus iOS APNs setup.

## Introduction

FCM is the standard push service for Flutter (via `firebase_messaging`). This file covers setup (Firebase + APNs), tokens (get/refresh/sync), permission, and — the crux — how message reception differs across foreground, background, and terminated states. Message *content* (notification vs data) is in [message_types_and_targeting.md](message_types_and_targeting.md); tap routing in [handling_and_deeplinks.md](handling_and_deeplinks.md).

## Why this concept exists

Servers need to reach devices that aren't running. FCM (backed by APNs on iOS) provides OS-level push delivery. Flutter's `firebase_messaging` exposes it, but because the app may be foreground, backgrounded, or killed, the callbacks and responsibilities differ per state — the single biggest source of "push works sometimes" bugs.

## Real-world analogy

FCM is the **postal service**; the **FCM token is your mailing address** (which can change — you must forward it to senders). When you're **home and awake** (foreground) the courier hands you the letter and *you* decide to display it; when you're **out** (background) they drop it in the mailbox (system tray); when the **house is empty** (terminated) it waits in the box and you read it when you get home (on launch).

## Problem Statement

Receive push in all three states: show it while the app is open, let the tray show it while backgrounded, and handle it on cold start after a tap — with tokens synced to your backend and iOS APNs configured. You'll wire `firebase_messaging` handlers.

## Internal Working

```mermaid
flowchart TD
    Setup[Firebase + APNs (iOS)] --> Perm[requestPermission (iOS/Android 13+)]
    Perm --> Token[getToken() + onTokenRefresh -> sync to backend]
    Token --> State{app state on message arrival}
    State -->|foreground| OnMsg[onMessage -> render yourself (local notif)]
    State -->|background| OpenApp[system tray shows; tap -> onMessageOpenedApp]
    State -->|terminated| BgHandler[top-level onBackgroundMessage + getInitialMessage on launch]
```

- **Setup**: FlutterFire ([Module 18](../18%20Firebase/README.md)); **iOS** additionally needs **APNs** — Push Notifications capability + an APNs key/cert in Firebase, and background modes ([28 · ios_integration](../28%20Native%20iOS/ios_integration.md)). Push doesn't work on iOS Simulator.
- **Permission**: `FirebaseMessaging.instance.requestPermission()` (iOS prompt; Android 13+ `POST_NOTIFICATIONS`). Check `authorizationStatus`.
- **Token**: `getToken()` returns the registration token; **`onTokenRefresh`** fires when it rotates. **Send/refresh the token to your backend** (tied to the user) so it can target the device; delete on logout.
- **Three states (crucial)**:
  - **Foreground**: `FirebaseMessaging.onMessage` fires. The OS does **not** show a tray notification for you (on Android, and iOS unless configured) — **you render it**, typically via `flutter_local_notifications` ([local_notifications.md](local_notifications.md)).
  - **Background (app alive, not foreground)**: the system shows the **notification** in the tray automatically (for messages with a `notification` block); tapping fires **`onMessageOpenedApp`**.
  - **Terminated (killed)**: a **top-level `onBackgroundMessage` handler** (a top-level/static function, registered before `runApp`) processes **data** in the background; a tap that launches the app is retrieved via **`getInitialMessage()`** at startup.
- **Background handler rules**: must be a **top-level or static** function annotated `@pragma('vm:entry-point')`, runs in a **separate isolate** (no UI/most singletons) — keep it minimal (e.g., show a local notification, update storage).
- **iOS foreground presentation**: `setForegroundNotificationPresentationOptions` to let iOS show banners in foreground (else you render).

## Memory Representation

The token is a string synced to your backend. Background messages run in an isolate with its own memory — no access to your app's live state.

## Compiler Behavior

The background handler must be a top-level/static entry point (`@pragma('vm:entry-point')`) so AOT keeps it.

## Runtime Behavior

Foreground → `onMessage`; background → tray + `onMessageOpenedApp` on tap; terminated → background isolate handler + `getInitialMessage()` on launch. Delivery is best-effort (not guaranteed/instant); OEM/doze can delay.

## Flutter Engine Behavior

The background message handler runs in a **dedicated background isolate/engine** — separate from the UI isolate ([02 · isolates](../02%20Advanced%20Dart/isolates_and_concurrency.md)); don't touch UI/providers there.

## Dart VM Behavior

Two isolates: your UI isolate (foreground handlers) and the background isolate (terminated/background data handler). They don't share memory.

## Examples

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';

// TERMINATED/BACKGROUND: top-level, separate isolate — keep minimal
@pragma('vm:entry-point')
Future<void> _bgHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // e.g., show a local notification / update local store. NO UI, NO app singletons.
}

Future<void> initFcm({
  required void Function(RemoteMessage) onForeground,
  required void Function(RemoteMessage) onOpened,
}) async {
  final fm = FirebaseMessaging.instance;
  await fm.requestPermission();                            // iOS/Android 13+
  FirebaseMessaging.onBackgroundMessage(_bgHandler);       // register BEFORE runApp

  // Token: get + keep synced to backend
  final token = await fm.getToken();
  await api.syncFcmToken(token);
  fm.onTokenRefresh.listen(api.syncFcmToken);              // token rotates

  // FOREGROUND: you must render it yourself (e.g., local notification)
  FirebaseMessaging.onMessage.listen(onForeground);

  // BACKGROUND tap: app resumes to this message
  FirebaseMessaging.onMessageOpenedApp.listen(onOpened);

  // TERMINATED tap that launched the app
  final initial = await fm.getInitialMessage();
  if (initial != null) onOpened(initial);
}
```

## Diagrams

```mermaid
sequenceDiagram
    participant Server
    participant FCM
    participant Device
    Server->>FCM: send(token/topic, message)
    FCM->>Device: deliver
    alt foreground
      Device->>Device: onMessage -> render local notification
    else background
      Device->>Device: tray shows; tap -> onMessageOpenedApp
    else terminated
      Device->>Device: bg isolate handler; launch -> getInitialMessage()
    end
```

## Common Mistakes

| Mistake | Why | Fix |
|---------|-----|-----|
| Expecting a tray notification in foreground | OS doesn't auto-show | Render yourself (local notification) |
| Background handler not top-level/`vm:entry-point` | Not invoked / stripped | Top-level/static + `@pragma('vm:entry-point')` |
| Touching UI/singletons in bg handler | Separate isolate, no access | Keep minimal; use storage/local notif |
| Not syncing/refreshing token | Can't target device; breaks on rotation | Sync `getToken` + `onTokenRefresh` |
| Ignoring `getInitialMessage` | Terminated taps lost | Handle on startup |
| Missing iOS APNs setup | No push on iOS | Configure APNs key + capability |
| Testing push on iOS Simulator | Unsupported | Use a real device |

## Best Practices

- **Register `onBackgroundMessage` before `runApp`** with a top-level `@pragma('vm:entry-point')` handler; keep it minimal (no UI/singletons).
- Handle **all three states**: `onMessage` (render yourself in foreground), tray+`onMessageOpenedApp` (background tap), `getInitialMessage` (terminated launch).
- **Sync the token** (`getToken` + `onTokenRefresh`) to your backend tied to the user; **delete on logout**; request permission + handle denial.
- Configure **iOS APNs** (key + capability + background modes — [28 · ios_integration](../28%20Native%20iOS/ios_integration.md)); test on **real devices**; wrap behind a service.

## Performance

Push is event-driven (no polling — battery-friendly). The background isolate spins up briefly per message — keep the handler fast. Delivery is best-effort; don't rely on instant/guaranteed timing.

## Advantages / Disadvantages

- **+** Reach devices when not running, battery-efficient (OS push), topic/token targeting, cross-platform via FCM/APNs.
- **−** Complex three-state model, background-isolate constraints, iOS APNs setup, best-effort delivery, token lifecycle management.

## Interview Questions

1. **🟢 What identifies a device for push?** — Its FCM registration token (which rotates — sync `getToken`/`onTokenRefresh` to your backend).
2. **🟢 What happens to a push while the app is in the foreground?** — `onMessage` fires; the OS doesn't show a tray notification, so you render it yourself (e.g., local notification).
3. **🟡 How is a terminated-state message handled?** — A top-level `@pragma('vm:entry-point')` background handler (separate isolate) processes data; a launching tap is read via `getInitialMessage()`.
4. **🟡 Why can't the background handler touch app state?** — It runs in a separate background isolate with no shared memory/UI; keep it minimal (storage/local notification).
5. **🟡 What's needed for iOS push?** — APNs key/cert in Firebase + Push Notifications capability/background modes; a real device (not Simulator).
6. **🔴 Differentiate `onMessageOpenedApp` vs `getInitialMessage`.** — Both handle taps that open the app: `onMessageOpenedApp` when resuming from background; `getInitialMessage` for the tap that cold-started a terminated app.
7. **🔴 Why sync and delete tokens?** — The backend needs the current token to target the device; tokens rotate (refresh) and should be removed on logout to stop delivery to that user.

## Senior Engineer Tips

- Wire all three states on day one and test each explicitly (foreground, backgrounded, force-killed) — "push works" usually means only one state was tested.
- Treat the token as user-scoped mutable state: sync on login/refresh, delete on logout; stale tokens cause misrouted or lost notifications.
- Keep the background isolate handler tiny and self-contained (init Firebase, show a local notification, write storage) — it can't reach your DI/UI.

## Architect Perspective

FCM is an event-driven, multi-isolate delivery system with a state-dependent contract. A `PushService` that centralizes permission, token sync, the three-state handlers, and foreground rendering (delegating to the local-notifications service) turns a notoriously flaky area into a testable, reliable one — with the backend owning who/when to send ([message_types_and_targeting.md](message_types_and_targeting.md), [notifications_integration.md](notifications_integration.md), [Module 18](../18%20Firebase/README.md)).

## Summary

- FCM push targets a rotating **token** (sync to backend); iOS needs APNs; test on real devices.
- Handle three states: **foreground** (`onMessage`, render yourself), **background** (tray + `onMessageOpenedApp`), **terminated** (top-level bg isolate handler + `getInitialMessage`).
- Background handler must be top-level `@pragma('vm:entry-point')`, minimal, no UI/singletons; wrap behind a service.

## Revision Notes

- `firebase_messaging`: `requestPermission`, `getToken`/`onTokenRefresh` (sync + delete on logout), APNs for iOS, real device.
- Foreground `onMessage` (render via local notif); background tray + `onMessageOpenedApp`; terminated `onBackgroundMessage` (top-level `@pragma('vm:entry-point')`, isolate) + `getInitialMessage`.
- Best-effort delivery; bg handler minimal (no UI/singletons); register `onBackgroundMessage` before `runApp`.

## Practice Questions

1. What happens to a push in each of the three app states?
2. Why must the background handler be top-level and minimal?
3. How do you keep the device targetable over time?

## Coding Questions

1. Initialize FCM with permission, token sync, and all three state handlers.
2. Write a compliant top-level background message handler.
3. Handle a terminated-state launch via `getInitialMessage`.

## Mini Project

**Push receiver (Flutter + Firebase):** Build a `PushService` that requests permission, syncs the FCM token (+ refresh) to a backend, and handles push in foreground (rendered via the local-notifications service), background (tray + open handler), and terminated (top-level isolate handler + `getInitialMessage`). Configure iOS APNs. Acceptance: token synced + refreshed; all three states handled + tested on a real device; foreground push rendered locally; background handler minimal + compliant; behind a service.
