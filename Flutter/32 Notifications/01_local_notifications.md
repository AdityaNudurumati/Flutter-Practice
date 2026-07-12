# Local Notifications (`flutter_local_notifications`)

> Local notifications are scheduled/shown **by the app itself** (no server) via `flutter_local_notifications`: initialize per-platform settings, define **Android channels** (importance/sound — mandatory on modern Android), request permission (Android 13+ / iOS), then `show()` immediately or `zonedSchedule()` for the future — attaching a **payload** you read back when the user taps to route them.

## Introduction

Local notifications handle reminders, alarms, timers, and "downloaded/complete" alerts — anything the app can decide on-device without a server. This file covers initialization, channels, permissions, immediate vs scheduled, actions, and the tap payload used for routing ([04_handling_and_deeplinks.md](04_handling_and_deeplinks.md)).

## Why this concept exists

Not every notification needs a server round-trip. Reminders and scheduled alerts are known on-device, so the OS notification system can display them locally. `flutter_local_notifications` wraps the divergent Android/iOS notification APIs (channels, scheduling, timezones) into one Dart API.

## Real-world analogy

A local notification is a **sticky note you set for your future self**: you decide the message and the time, and the OS (your assistant) posts it on the fridge at that moment. No one else is involved — unlike push, where a **courier delivers a note from outside** ([02_fcm_push.md](02_fcm_push.md)).

## Problem Statement

Show a "backup complete" alert now and a "drink water" reminder every day at 9am, with an Android channel, permission handling, and a payload that opens the right screen on tap. You'll initialize the plugin, define a channel, and schedule.

## Internal Working

```mermaid
flowchart TD
    Init[initialize(settings) + onDidReceiveNotificationResponse] --> Channel[create Android channel(s)]
    Channel --> Perm[request permission (Android 13+/iOS)]
    Perm --> Show{immediate or scheduled?}
    Show -->|now| ShowNow[show(id, title, body, payload)]
    Show -->|future| Sched[zonedSchedule(id, ..., tzDateTime, matchDateTimeComponents)]
    Tap[user taps] --> Response[onDidReceiveNotificationResponse(payload) -> route]
```

- **Initialize**: `AndroidInitializationSettings('@mipmap/ic_launcher')` + `DarwinInitializationSettings(...)`; pass `onDidReceiveNotificationResponse` (tap handler with the payload). Call once at startup.
- **Android channels** (mandatory ≥ Android 8): create `AndroidNotificationChannel(id, name, importance: Importance.high, ...)`; importance/sound are set on the **channel**, not per-notification (can't change after creation). Group related notifications by channel.
- **Permissions**: **Android 13+** needs the `POST_NOTIFICATIONS` runtime permission; **iOS** needs `requestPermissions(alert/badge/sound)`. Handle denial gracefully ([27](../27%20Native%20Android/04_permissions_and_manifest.md)/[28](../28%20Native%20iOS/04_infoplist_and_permissions.md)).
- **Immediate**: `show(id, title, body, NotificationDetails(...), payload: 'route:/order/42')`. **Unique id** per notification (reusing an id replaces it — useful for progress).
- **Scheduled**: `zonedSchedule(id, title, body, tz.TZDateTime, details, androidScheduleMode: exactAllowWhileIdle, matchDateTimeComponents: DateTimeComponents.time)` for daily/weekly repeats. Requires the **`timezone`** package (init `tz`); **exact alarms** need a special permission on Android 12+.
- **Actions & styles**: action buttons (`AndroidNotificationAction`), big-text/big-picture/inbox styles, grouping, ongoing/progress notifications.
- **Payload → routing**: the string payload is delivered to the tap handler; parse it to deep-link ([04_handling_and_deeplinks.md](04_handling_and_deeplinks.md)).

## Memory Representation

Notifications live in the OS notification system, not app memory. The plugin keeps init settings + pending scheduled notifications (queryable via `pendingNotificationRequests`).

## Compiler Behavior

Not applicable; channels/permissions are runtime + manifest config.

## Runtime Behavior

Scheduled notifications fire even if the app is killed (OS-driven) — but OEM battery optimizations can delay/drop them; exact timing isn't guaranteed without exact-alarm permission. Reusing an id updates the existing notification.

## Flutter Engine Behavior

Tapping while terminated cold-starts the app; retrieve the launch details (`getNotificationAppLaunchDetails()`) to route on startup ([04_handling_and_deeplinks.md](04_handling_and_deeplinks.md)).

## Dart VM Behavior

Not applicable.

## Examples

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

final _plugin = FlutterLocalNotificationsPlugin();
const _channel = AndroidNotificationChannel(
  'reminders', 'Reminders', importance: Importance.high,
);

Future<void> initLocalNotifications(void Function(String? payload) onTap) async {
  tzdata.initializeTimeZones();
  await _plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
    onDidReceiveNotificationResponse: (r) => onTap(r.payload), // tap -> route
  );
  await _plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_channel);              // mandatory channel
}

Future<void> showNow(int id, String title, String body, String route) =>
    _plugin.show(id, title, body,
        const NotificationDetails(android: AndroidNotificationDetails('reminders', 'Reminders')),
        payload: route);                                  // payload used on tap

Future<void> scheduleDaily9am(int id) => _plugin.zonedSchedule(
      id, 'Drink water', 'Time for a glass 💧',
      _next9am(),
      const NotificationDetails(android: AndroidNotificationDetails('reminders', 'Reminders')),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,   // repeat daily
      payload: 'route:/hydration',
    );

tz.TZDateTime _next9am() {
  final now = tz.TZDateTime.now(tz.local);
  var t = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9);
  if (t.isBefore(now)) t = t.add(const Duration(days: 1));
  return t;
}
```

## Diagrams

```mermaid
flowchart LR
    App[app decides] --> LN[flutter_local_notifications]
    LN -->|now| OS1[OS shows immediately]
    LN -->|zonedSchedule| OS2[OS fires at time (even if app killed)]
    OS2 --> TapR[tap -> payload -> route]
```

## Common Mistakes

| Mistake | Why | Fix |
|---------|-----|-----|
| No Android channel | Notifications silently dropped (≥ O) | Create channel before showing |
| Changing channel importance later | Ignored after creation | Set at creation; new channel to change |
| Not requesting Android 13+/iOS permission | No notifications shown | Request + handle denial |
| Naive `DateTime` scheduling | DST/timezone bugs | Use `timezone` `TZDateTime` |
| Reusing ids unintentionally | Notifications overwrite | Unique ids (reuse only for updates) |
| Expecting exact timing always | OEM battery limits/exact-alarm perm | Use exact-alarm mode/perm; tolerate drift |
| No payload | Can't route on tap | Attach + parse payload |

## Best Practices

- **Initialize once** at startup with a tap handler; **create Android channels** up front (importance/sound are per-channel and immutable).
- **Request permission** (Android 13+ `POST_NOTIFICATIONS`, iOS) and degrade gracefully; use **`timezone` `TZDateTime`** for scheduling (DST-safe).
- Use **unique ids** (reuse only to update/progress); attach a **payload** and route on tap (incl. cold start via launch details).
- For exact/repeating alerts use the right **schedule mode**/exact-alarm permission; tolerate OEM delivery drift.

## Performance

Negligible; the OS handles display/scheduling. Avoid spamming notifications (annoyance + OS throttling). `pendingNotificationRequests` lets you audit/cancel.

## Advantages / Disadvantages

- **+** No server needed, works offline, scheduled/repeating reminders, channels/actions/styles, fires when app killed.
- **−** Per-platform channels/permissions, timezone/exact-alarm gotchas, OEM battery-optimization unreliability, only for on-device-known events.

## Interview Questions

1. **🟢 What are local notifications for?** — App-decided, on-device alerts (reminders/alarms/complete) shown/scheduled without a server.
2. **🟢 Why are Android channels required?** — On Android 8+ every notification needs a channel (which owns importance/sound); without one it's dropped.
3. **🟡 How do you schedule a reliable daily notification?** — `zonedSchedule` with a `timezone` `TZDateTime` + `matchDateTimeComponents: time`, appropriate schedule mode/exact-alarm permission.
4. **🟡 Why use `TZDateTime` instead of `DateTime`?** — To avoid DST/timezone bugs; scheduling must be timezone-aware.
5. **🟡 What permissions do local notifications need?** — Android 13+ `POST_NOTIFICATIONS` runtime permission; iOS alert/badge/sound authorization.
6. **🔴 How do you route when the user taps a notification?** — Attach a payload; handle it in `onDidReceiveNotificationResponse` (and `getNotificationAppLaunchDetails` for cold start) to deep-link.
7. **🔴 Why might scheduled notifications not fire on time?** — OEM battery optimizations/doze and lack of exact-alarm permission can delay/drop them.

## Senior Engineer Tips

- Define channels deliberately (by importance/purpose) at first run; you can't change a channel's importance later, only recreate it.
- Always schedule with the `timezone` package — naive `DateTime` scheduling is a recurring DST/off-by-hours bug.
- Attach a structured payload (a route/deep link) from day one and handle cold-start launch details — retrofitting tap routing is painful.

## Architect Perspective

Local notifications are an on-device scheduling + OS-integration concern. Wrapping init/channels/permissions/scheduling behind a `NotificationService` (with structured payloads feeding deep-link routing) keeps reminders reliable and testable, and unifies cleanly with push (which also renders via the same local plugin in the foreground — [02_fcm_push.md](02_fcm_push.md), [05_notifications_integration.md](05_notifications_integration.md)).

## Summary

- `flutter_local_notifications`: init once (+ tap handler), create Android channels, request permission, `show()`/`zonedSchedule()` with `TZDateTime`.
- Unique ids, structured payloads for tap routing (incl. cold start); tolerate OEM delivery drift; exact-alarm perms for precise timing.
- On-device, offline, no server — for app-known events; wrap behind a service.

## Revision Notes

- Init `FlutterLocalNotificationsPlugin` + `onDidReceiveNotificationResponse`; create `AndroidNotificationChannel` (importance immutable).
- Permissions: Android 13+ `POST_NOTIFICATIONS`, iOS request; `show(id,...,payload)` (unique id), `zonedSchedule(TZDateTime, matchDateTimeComponents)` with `timezone`.
- Tap → payload → route (+ `getNotificationAppLaunchDetails` cold start); OEM battery limits/exact-alarm affect timing.

## Practice Questions

1. Why must you create an Android channel, and what does it own?
2. How do you schedule a DST-safe daily reminder?
3. How do you route the user when they tap a local notification?

## Coding Questions

1. Initialize the plugin with a channel + tap handler and show an immediate notification with a payload.
2. Schedule a daily 9am reminder using `TZDateTime`.
3. Handle a cold-start tap via `getNotificationAppLaunchDetails`.

## Mini Project

**Reminders (Flutter):** Build a `LocalNotificationService` that initializes the plugin (+ channel + permission), shows an immediate "task done" notification, schedules a daily 9am reminder (timezone-aware, repeating), and routes taps via payload (including cold start). Acceptance: channel created; permission requested + handled; immediate + daily-repeating notifications fire; tap deep-links via payload (incl. terminated launch); behind a service; runs on device.
