# Run Threefold on your iPhone

Threefold is a standalone interaction experiment. It does not add a gesture to the real ChatGPT or WhatsApp apps.

**Just curious? [Try the browser sketch](https://smallweirdthings.com/threefold/#preview).** No installation is needed. It uses one finger or a mouse to explain the movement; the native builds use three fingers and real iOS haptics.

## What you need

- A Mac with **Xcode 26 or newer** installed from Apple.
- An iPhone with **iOS 17 or newer** and a cable, or an already paired wireless connection.
- Your own Apple Account for Xcode’s development signing. No ChatGPT or WhatsApp account is needed.

The glass treatment is native on iOS 26 and later. Earlier versions use a system blur fallback. There is no TestFlight build or App Store release at present.

## Install without using Terminal

1. [Download the source ZIP](https://github.com/hugo-alves/threefold/archive/refs/heads/main.zip) **on your Mac** and unzip it.
2. Open the `native` folder, then double-click **SessionSwipe.xcodeproj**. The Xcode project is included; you do not need XcodeGen, Node or npm to run either native app.
3. In Xcode’s scheme menu, choose a demo:

   | Scheme | iPhone app | Sample interface |
   | --- | --- | --- |
   | `WhatsAppSwipe` | Threefold Chats | WhatsApp style |
   | `SessionSwipe` | Threefold Codex | ChatGPT / Codex style |

4. Connect and unlock your iPhone. Select it as the run destination. If it asks whether to trust your Mac, complete that pairing on the phone.
5. Select the project in Xcode’s navigator, select the chosen **app target**, and open **Signing & Capabilities**. Keep **Automatically manage signing** enabled and choose your team. Add your Apple Account in Xcode Settings → Accounts if necessary.
6. If Xcode says the bundle identifier cannot be registered, replace that target’s identifier with something unique, such as `com.yourname.threefold.chats`. Use a different identifier for the Codex target.
7. Press **Run**. On the iPhone, enable **Developer Mode** if requested under Settings → Privacy & Security and follow the restart prompt. Unlock the phone again afterward.
8. If iOS reports an untrusted developer, open Settings → General → VPN & Device Management, choose your development account and follow its Trust/Allow prompt. Return to Xcode and press Run again.

You can install both demos side by side. Each keeps its own settings, drafts and messages. Development signing may need renewal; Xcode will tell you when to run it again.

Apple’s [running on simulated or physical devices](https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices) guide covers signing and run destinations. [Developer Mode](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device) is a separate device setting from trusting a development certificate.

## Your first minute

1. The app starts on the newest chat. Put **three fingers** on the conversation and swipe **down** to bring in the older chat above. Swipe **up** to return to the newer one.
2. For the overview, drag about a finger-length, slow down while the conversation is small, then **lift gently**. The stack stays open. A quick flick switches directly.
3. Tap the **right-edge indicator** if the release feels hard to trigger. It always opens the same overview.
4. In the open stack, use **one finger** to browse, then tap a card. The × button returns to your current conversation.
5. Hold the conversation title or use the stack’s sliders to open **Prototype controls**. Start with Card size, Overview release speed, Spring damping and Indicator style.

Leave an unfinished reply, switch away, and come back. The draft and reading position should remain where you left them. Entered messages stay local; nothing is sent to anyone.

## Simulator and accessibility

With no phone connected, select an iPhone simulator and Run. Click the right-edge indicator to browse the stack. A simulator is useful for layout and navigation; it cannot establish physical gesture comfort or haptic feel.

VoiceOver’s own three-finger gestures take priority: Threefold disables its custom recognizer while VoiceOver runs. Use the indicator, menus and accessibility actions instead. iOS Zoom can also consume three-finger gestures.

## If something gets in the way

| What you see | What to do |
| --- | --- |
| No iPhone destination | Unlock the phone, check the cable and pairing, and open Xcode’s Devices and Simulators window. |
| Signing or provisioning error | Select your own team on the chosen app target and use a unique bundle identifier. |
| Developer Mode or trust warning | Follow the relevant phone steps above, then press Run again. |
| Swiping only scrolls messages | Use exactly three fingers. One finger is ordinary scrolling. |
| Quick switches work but the overview does not | Tap the edge indicator, then increase Overview release speed in Prototype controls. |
| Older/newer movement resists | You may be at an end of the visited history. Start with a downward swipe from the newest chat. |

For a reproducible problem, [open an issue](https://github.com/hugo-alves/threefold/issues) with your iPhone model, iOS version and the steps that led to it.
