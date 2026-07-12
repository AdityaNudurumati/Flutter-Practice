# Code Hardening & Device Integrity

> Since the binary is inspectable, **raise the reverse-engineer's cost**: build release with **`--obfuscate --split-debug-info`** (renames symbols; keep the mapping to de-obfuscate crashes), strip debug logs, and add **integrity/anti-tamper** signals — **root/jailbreak detection**, **debugger/emulator/hook (Frida) detection**, and **repackaging/signature checks** — to gate or degrade high-risk actions. Crucially, **all of this is bypassable on a device the attacker controls**, so hardening is a **cost-raising, defense-in-depth layer** that must sit atop **server-side enforcement**, never replace it.

## Introduction

This file covers the last layer: making the app harder to reverse-engineer and detecting compromised runtime environments. It explains obfuscation, root/jailbreak/tamper detection, their real (limited) value, and how to use them correctly — without the false confidence that sinks many "secured" apps.

## Why this concept exists

Attackers decompile apps to find logic/secrets, and run them on rooted/jailbroken/instrumented devices to bypass client checks or scrape data. Obfuscation and integrity checks don't make this impossible, but they **increase effort and filter out low-skill attacks** — worthwhile as one layer, dangerous if mistaken for a wall.

## Real-world analogy

Hardening is **removing the labels from your machinery and adding tamper-evident seals**: a casual snoop is stumped and a broken seal tells you something's wrong, but a **determined expert with the machine in their own workshop** can still figure it out and re-seal it. So you don't keep the crown jewels in the machine — you keep them in the **bank** (server) and use the seals to **detect and slow** tampering.

## Problem Statement

Ship a release that's obfuscated (with de-obfuscatable crash reports), logs no sensitive data, detects root/jailbreak and instrumentation to **restrict high-risk actions** (and inform the server), and verifies it hasn't been repackaged — while relying on the server as the real gate. You'll add obfuscation + integrity checks used as signals.

## Internal Working

```mermaid
flowchart TD
    Build[release: --obfuscate --split-debug-info] --> Sym[symbols renamed + mapping kept]
    Sym --> Crash[de-obfuscate crashes with mapping]
    Integrity[integrity signals] --> Root[root/jailbreak detection]
    Integrity --> Hook[debugger/emulator/Frida detection]
    Integrity --> Tamper[signature/repackaging check]
    Root & Hook & Tamper --> Gate[gate/degrade high-risk actions + report to server]
    Gate --> Server[SERVER enforces (bypass-proof backstop)]
```

- **Obfuscation**: `flutter build apk/ipa --obfuscate --split-debug-info=<dir>` renames Dart symbols in the AOT snapshot (harder to read) and writes a **debug-info mapping** you **keep** to **de-obfuscate stack traces** ([21 · startup_and_app_size](../21%20Performance/README.md)). It's not encryption — strings/logic are still recoverable with effort; strip verbose/sensitive **logs** in release.
- **Root/jailbreak detection**: plugins (e.g., root/jailbreak detectors) check for su binaries, known apps, writable system paths, suspicious files. Use the **signal** to **restrict high-risk features** (payments, key display) or warn — not as a hard guarantee (detection is an arms race, bypassable by hiding-root tools).
- **Debugger/emulator/hook detection**: detect attached debuggers, emulators, and **instrumentation frameworks (Frida/Xposed)**; treat as risk signals. Again, bypassable — use to raise cost + inform server-side risk scoring.
- **Tamper/repackaging checks**: verify the app's **signature/package** at runtime and/or via **Play Integrity API / App Attest (iOS)** — device/app attestation that reports to your server whether the app/device looks genuine. Prefer **server-validated attestation** over client-only checks (the client check itself can be patched out).
- **Use signals server-side**: send integrity results to the backend, which **decides** (block, step-up auth, limit) — a patched client can lie, so the server must treat attestation as advisory + apply its own limits/anomaly detection.
- **Anti-patterns to avoid**: relying on client checks alone, hiding secrets via obfuscation (still extractable), or blocking legitimate power users too aggressively (false positives).
- **Limits (say it plainly)**: **every client-side protection is bypassable on an owned device.** Hardening filters casual attackers and raises cost; **server-side enforcement + attestation validation** is the real defense.

## Memory Representation

Obfuscation changes symbol names in the snapshot; the debug-info file (kept off-device) maps them back. Integrity results are transient signals sent to the server. No secrets rely on hardening.

## Compiler Behavior

`--obfuscate` renames symbols during AOT compilation; `--split-debug-info` emits the mapping. Without the mapping, crash traces are unreadable — **archive it per release**.

## Runtime Behavior

Integrity checks run at startup/high-risk points, producing signals; results should reach the server. On hooked devices, checks can be patched to always pass — hence server validation.

## Flutter Engine Behavior

AOT snapshot ships in the bundle (obfuscated names). Native attestation (Play Integrity/App Attest) is platform-provided.

## Dart VM Behavior

Not applicable beyond AOT/obfuscation.

## Examples

```bash
# Release build with obfuscation + kept debug-info mapping (de-obfuscate crashes later)
flutter build apk --release --obfuscate --split-debug-info=build/symbols
flutter build ipa --release --obfuscate --split-debug-info=build/symbols
# Archive build/symbols per release/version to symbolicate stack traces.
```

```dart
// Integrity checks used as SIGNALS to gate high-risk actions + inform the server
class IntegrityService {
  Future<Risk> assess() async {
    final rooted = await RootChecker.isRooted();      // best-effort signal
    final hooked = await HookDetector.isInstrumented();// e.g., Frida/emulator
    final attest = await PlayIntegrity.token();        // server-validated attestation
    await api.reportIntegrity(rooted: rooted, hooked: hooked, attestation: attest);
    return (rooted || hooked) ? Risk.high : Risk.normal;
  }
}
// Usage: if ((await integrity.assess()) == Risk.high) restrictSensitiveAction();
// SERVER still validates attestation + enforces limits — client signal can be faked.
```

## Diagrams

```mermaid
flowchart LR
    Client[client checks: root/hook/tamper] -->|signals (spoofable)| Server[server validates attestation]
    Server --> Decide[server decides: allow / step-up / block]
    Obf[obfuscation] --> Cost[raises reverse-engineering cost]
    Cost -. not a wall .-> Determined[determined attacker still can]
```

## Common Mistakes

| Mistake | Why | Fix |
|---------|-----|-----|
| Treating obfuscation as security | Logic/strings still recoverable | Cost-raising layer; secrets stay server-side |
| Losing the debug-info mapping | Can't read crash traces | Archive `split-debug-info` per release |
| Client-only integrity as a gate | Patchable to always pass | Server-validated attestation + enforcement |
| Hard-blocking on root detection alone | False positives, bypassable | Signal → risk scoring; degrade, not brick |
| Leaving debug logs in release | Leaks internals | Strip sensitive/verbose logs |
| Hiding a secret via obfuscation | Extractable | Never ship secrets |
| Over-aggressive checks | Blocks legit users | Tune; prefer step-up over block |

## Best Practices

- Build release with **`--obfuscate --split-debug-info`** and **archive the mapping** to de-obfuscate crashes; **strip sensitive logs**.
- Use **root/jailbreak/hook/emulator + tamper checks as signals** to **gate/degrade high-risk actions** and **report to the server** — don't hard-brick on client checks alone.
- Prefer **server-validated attestation** (Play Integrity / App Attest) over client-only checks; the **server decides** (allow/step-up/block) since client signals are spoofable.
- Remember hardening is **cost-raising defense-in-depth atop server enforcement** — **never** hide secrets or place real authorization in the client.

## Performance

Obfuscation has negligible runtime cost (and slightly aids size). Integrity checks add small startup/high-risk-point latency — keep them off the hot path. The main "cost" is operational (managing mappings, tuning false positives).

## Advantages / Disadvantages

- **+** Raises reverse-engineering cost, filters casual attacks, detects/deters tampered environments, feeds server risk decisions, de-obfuscatable crashes.
- **−** All bypassable on owned devices, false-positive risk, arms-race maintenance, mapping management, no real secrecy for shipped code/secrets.

## Interview Questions

1. **🟢 What does `--obfuscate --split-debug-info` do?** — Renames Dart symbols in the AOT build (harder to reverse) and emits a mapping you keep to de-obfuscate crash traces.
2. **🟢 Is obfuscation a form of security/encryption?** — No — it raises cost; logic/strings remain recoverable, so secrets must not rely on it.
3. **🟡 How should root/jailbreak detection be used?** — As a best-effort risk signal to gate/degrade high-risk actions and inform the server — not as an unbreakable gate.
4. **🟡 Why prefer Play Integrity/App Attest over client-only checks?** — They provide server-validated attestation; client-only checks can be patched to always pass.
5. **🟡 Why report integrity signals to the server?** — Because the client can be tampered to lie; the server must validate attestation and make the enforcement decision.
6. **🔴 What's the fundamental limit of code hardening?** — Every client-side protection is bypassable on a device the attacker controls; hardening is cost-raising defense-in-depth atop server enforcement.
7. **🔴 Why archive the debug-info mapping?** — Obfuscated release crash traces are unreadable without it; you need it to symbolicate production crashes.

## Senior Engineer Tips

- Turn on obfuscation for all release builds and store the symbol mapping with the release artifacts — future-you needs it to read prod crashes.
- Use integrity checks to *inform the server and step up auth*, not to brick the app; hard client-side blocks are both bypassable and a false-positive support nightmare.
- Say it out loud in design reviews: client hardening never protects a secret or replaces server authz — it only raises cost and generates signals.

## Architect Perspective

Code hardening is the resilience layer (MASVS "Resilience"): obfuscation + integrity/attestation that raise attacker cost and feed **server-side** risk decisions. Architecturally it must be wired as *signals to the server*, not client gates, and paired with de-obfuscatable observability. Combined with the other layers (storage/network/server authz), it completes defense-in-depth — while the module's core truth holds: the server, not the hardened client, is the real defense ([01_security_model_and_owasp.md](01_security_model_and_owasp.md), [03_network_security_and_pinning.md](03_network_security_and_pinning.md), [05_security_integration.md](05_security_integration.md)).

## Summary

- Release builds: `--obfuscate --split-debug-info` (archive the mapping), strip sensitive logs — cost-raising, not secrecy.
- Root/jailbreak/hook/tamper detection = spoofable **signals** → gate/degrade high-risk actions + report to server; prefer server-validated attestation (Play Integrity/App Attest).
- All client hardening is bypassable on owned devices → defense-in-depth atop **server enforcement**; never hide secrets in the client.

## Revision Notes

- Obfuscation: `flutter build --obfuscate --split-debug-info=<dir>` (renames symbols, keep mapping to symbolicate); not encryption; strip logs.
- Integrity: root/jailbreak, debugger/emulator/Frida, signature/repackaging → risk signals; server-validated attestation (Play Integrity/App Attest) preferred.
- Report signals to server; server decides (allow/step-up/block); all bypassable on owned devices → cost-raising layer atop server authz; no secrets in client.

## Practice Questions

1. Why must you keep the split-debug-info mapping?
2. How should root detection influence app behavior?
3. Why is server-validated attestation better than client checks?

## Coding Questions

1. Produce an obfuscated release build and symbolicate a crash with the mapping.
2. Implement an `IntegrityService` that gathers signals and reports to the server.
3. Gate a high-risk action on a server-decided risk level (not a client block).

## Mini Project

**Hardened release + integrity signals (Flutter + backend):** Configure obfuscated release builds (`--obfuscate --split-debug-info`, archived mapping, stripped sensitive logs) and an `IntegrityService` that gathers root/jailbreak/hook signals + server-validated attestation, reports them, and lets the **server** decide to allow/step-up/block a high-risk action. Acceptance: release obfuscated + crashes symbolicatable via mapping; no sensitive logs; integrity signals gathered + reported (not client-gated); server makes the enforcement decision; documented as cost-raising defense-in-depth atop server authz; no secrets shipped.
