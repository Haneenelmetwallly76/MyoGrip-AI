# Open decisions

The design specification DOCX referenced by `docs/design/README.md` is not
present in this workspace. The items below capture the decisions explicitly
identified in the screen requirements and the unresolved implementation details
visible in the current prototype. This list cannot be verified as a complete
transcription of section 9 until the DOCX is available.

## Explicitly identified decisions

| Decision | Current implementation | Decision needed |
| --- | --- | --- |
| Gesture names | Settings shows `Gesture 0` through `Gesture 9`. | Replace the placeholders with clinician-approved names and translations. |
| Gesture-to-finger mapping | `lib/data/gesture_map.dart` contains the requested placeholder mapping for gestures 0–5; gestures 6–9 have no hardware mapping. | Confirm every gesture and active finger with the hardware team. |
| Sensitivity API values | `lib/features/settings/application/settings_controller.dart` maps Low/Medium/High to 25/50/75. | Confirm threshold scale and values with the arm API. |
| Compact stop on secondary tabs | The widget exists; `AppConfig.showCompactStopOnSecondaryTabs` is `false`. | Decide whether Settings and Profile should expose it in the final product. |
| Today in the usage chart | `FakeUsageRepository.matchMockup` defaults to `true`, highlighting Thursday to match the reference image. | Replace the mockup override with the device's actual local date semantics. |
| Resume behavior | `AppConfig.resumeRestoresPreviousState` is `true`; the fake controller returns to ready after Resume. | Confirm whether Resume restores the previous gesture/state or always starts at rest. |
| Device pairing method | Pairing and permission handling use fake repositories and a `PermissionService` stub. | Specify production discovery, transport, OS permissions, and reconnect behavior for both devices. |

## Additional implementation decisions to confirm

| Decision | Current implementation | Decision needed |
| --- | --- | --- |
| Gesture range | The fake arm cycles through gestures 0–5; Settings exposes ten toggles. | Confirm how gestures 6–9 are represented and delivered by real hardware. |
| Local network permission timing | The explanation is shown before the first Pair action; Continue calls the permission stub. | Confirm the platform-specific permission prompt and behavior after denial. |
| Session restoration while offline | A restore failure routes to Sign in, as required by the screen flow. | Confirm whether an offline cached session may be used instead. |
