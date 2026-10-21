# WhatsApp iPhone visual references

Checked on 21 October 2026. The implementation uses the dark appearance, fictional text conversations, generic contact avatars and a plain dark chat wallpaper. It is an interaction study, not a complete WhatsApp client.

| Source | Date | What it grounds |
| --- | --- | --- |
| [Full Liquid Glass chat experience](https://wabetainfo.com/whatsapp-is-widely-rolling-out-the-full-liquid-glass-experience/) | 9 September 2026 | Floating input, separate attachment/camera/voice buttons, glass back and call controls, rounded message bubbles. App Store rollout, version 26.35.72 cited by the report. |
| [Softer chat navigation edge](https://wabetainfo.com/whatsapp-is-rolling-out-a-softer-edge-effect-for-the-chat-interface/) | 13 October 2026 | Gradual blur beneath the conversation header. Version 26.41.10.18 cited by the report; a phased rollout, initially visible to some testers. |
| [WhatsApp Messenger on the App Store](https://apps.apple.com/us/app/whatsapp-messenger/id310633997) | Live listing checked 21 October 2026 | Official product and platform reference. |

The latest specific chat-screen refinement found in this search was the October soft edge update. Availability is gradual; this does not establish that every WhatsApp account has the same interface.

The prototype reproduces the app-owned layout with UIKit, SF Symbols, system typography and native glass on iOS 26+. Older systems use a blur fallback. The screenshot sources are linked here, not bundled into the app. Reference wallpaper, people, logos and message content are not copied. Calls, recording, media and unrelated tabs are visual context; they do not connect to a service.

The added right-edge position control and three-finger interaction are the experiment. Both native targets use the same gesture and overview code.
