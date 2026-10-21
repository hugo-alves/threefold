# Threefold

**Three fingers. A different conversation.**

An interaction experiment by Hugo Alves, part of [Small Weird Things](https://smallweirdthings.com/).

[Try the browser sketch](https://smallweirdthings.com/threefold/) · [Install on an iPhone](docs/INSTALL.md) · [How it was checked](docs/VERIFICATION.md)

A native iPhone experiment: switch between conversations with **three fingers**, or shrink them into a stack you can browse.

Two standalone UIKit demos share the same interaction:

| Scheme | App on your phone | Interface |
| --- | --- | --- |
| `SessionSwipe` | Threefold Codex | ChatGPT / Codex style |
| `WhatsAppSwipe` | Threefold Chats | WhatsApp iPhone style, based on the 2026 Liquid Glass rollout |

Both use fictional conversations and local storage. No account, backend, analytics, Contacts access or message delivery. This is an independent prototype, unaffiliated with OpenAI or WhatsApp. It does not modify the installed apps.

| WhatsApp-style chat | The same swipe stack |
| --- | --- |
| ![Native conversation](docs/images/whatsapp-conversation.png) | ![Native stack overview](docs/images/whatsapp-overview.png) |

## Try it on an iPhone

**No Terminal setup required:** [download the ZIP](https://github.com/hugo-alves/threefold/archive/refs/heads/main.zip), unzip it on your Mac, and open the included Xcode project. The [full install guide](docs/INSTALL.md) covers signing, Developer Mode and common blockers.

You need a Mac with **Xcode 26 or newer**, an iPhone running **iOS 17 or newer**, and an Apple Account for development signing. The glass material is native on iOS 26+; older versions use a system blur fallback.

1. Open [native/SessionSwipe.xcodeproj](native/SessionSwipe.xcodeproj).
2. Choose **SessionSwipe** or **WhatsAppSwipe** from the scheme menu, then select your connected iPhone.
3. In the chosen target’s **Signing & Capabilities**, select your own development team. If the bundle identifier is unavailable, change it to a unique identifier under your name.
4. Enable **Developer Mode** on the iPhone if requested, then press **Run** in Xcode. If iOS asks you to trust the development app, follow the prompt under **Settings → General → VPN & Device Management**.

You can install both demos side by side. Their drafts, messages, settings and history are separate. There is currently no TestFlight or App Store build; this repository is the source-build route to trying the native gesture.

## Feel the interaction

- **Three fingers down → older chat above.**
- **Three fingers up → newer chat below.**
- A quick flick switches directly. A slower drag shrinks the chat; **release gently while it is shrunk** to leave the stack open.
- **Tap the right-edge indicator** for a reliable way to open the same stack. Browse with **one finger**, tap a card, or use **×** to return.
- **Hold the conversation title** or tap the stack’s sliders for **Prototype controls**. The WhatsApp demo also exposes them through the contact menu and the chat list’s Settings tab.

The first launch starts on the newest chat. Swipe down first. At an end of the history, the surface resists and returns to its place.

Try leaving an unfinished reply, switching away, then returning. Each chat retains its draft, locally entered messages and reading position. Ordinary one-finger scrolling continues to work.

The 17 saved controls include card size, spacing, corners, spring damping, animation speed, swipe distance, flick sensitivity, overview entry/release sensitivity, indicator styles and size, position count, activity, haptics and optional fingertip dots. Changing the open stack’s size and indicator settings applies immediately.

In the ChatGPT-style stack, green means working and blue means a new reply. In the WhatsApp-style stack, green means typing and blue means unread; the chat list uses green unread badges. All activity is fictional and static. Calls, media and unrelated tabs are visual context, with no service connection.

## Simulator

Select an iPhone simulator in Xcode and Run. The right-edge indicator lets you explore and tune the stack with a mouse. The actual three-finger feel and haptics need a physical device.

Debug builds have repeatable capture states. Add `--preview-screen` followed by one of these under **Edit Scheme → Run → Arguments**:

`conversation`, `list`, `settings`, `history`, `overview`, `overview-gesture`, `smoke-overview`

Add `--preview-session` and a sample ID with `conversation` to capture a specific chat. Preview sessions use the isolated preview state file.

The ChatGPT-style demo additionally has `sidebar` and `code`. Preview state is isolated from normal app data. The scripted transition and smoke checks are not physical multitouch evidence.

## Checks

```sh
sh scripts/check-models.sh
npm test
```

The first command checks the native history, swipe decisions, state migration, saved drafts and messages, and WhatsApp sample configuration. The second checks the shared browser interaction model, including direction and overview release parity. Neither needs signing.

Build either native scheme without signing:

```sh
xcodebuild -project native/SessionSwipe.xcodeproj -scheme WhatsAppSwipe -sdk iphonesimulator -configuration Debug -derivedDataPath /tmp/session-swipe-build CODE_SIGNING_ALLOWED=NO build
```

Use `-scheme SessionSwipe` for the other demo. The checked-in Xcode project is ready to open; XcodeGen is only needed when changing the project structure. Regenerate from `native/` with `xcodegen generate --spec project.yml`.

If your Mac’s default developer directory points to Command Line Tools, select full Xcode or prefix a command with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`. Build products outside a cloud-synced Documents folder if file metadata interferes with signing.

## Website and browser sketch

The website explains the idea and lets anyone explore its movement without installing anything. It uses real native prototype screenshots. One finger or a mouse drives this **browser sketch**; the native apps use three fingers. The browser cannot reproduce iOS touch recognition or haptic feel.

```sh
npm start
```

Open `http://localhost:4173`. There are no npm dependencies to install. `npm run build` produces only the static website in `dist/`.

`npm run study` serves the earlier editable browser study in `web/`. Its draft state resets on refresh. Its direction now agrees with the native prototypes.

## Repository map

- `native/` — two standalone UIKit app targets and native model checks.
- `site/` — promotional site and interactive browser sketch.
- `web/` — shared browser gesture/history model and earlier study.
- `scripts/` — native checks and static-site build.
- `docs/` — installation, references, asset notes and verification scope.

See [CONTRIBUTING.md](CONTRIBUTING.md) for feedback and small improvements.

## Design and implementation

UIKit only, with no embedded web view. A three-touch pan recognizer moves the conversation surface; one-touch recognizers scroll its contents. Both apps share the history cursor, interactive movement, overview, settings and persistence code, while owning their conversation and list layouts.

[WhatsApp visual references and rollout notes](docs/WHATSAPP-REFERENCES.md) · [Verification scope](docs/VERIFICATION.md)

With VoiceOver enabled, the custom three-finger recognizer is disabled so system gestures remain available. The stack indicator, menus and accessibility actions provide navigation. System Zoom also uses three-finger gestures.

Local captures, recordings, development profiles, signing credentials and device diagnostics are excluded from Git.
