# First public experiment review

21 October 2026. Scope: making the interaction understandable and straightforward to try, with a public source repository and a Small Weird Things website.

## Improvements made before publication

- Named the experiment **Threefold** and added an original icon and distinct iPhone app names. Kept bundle identifiers stable so existing local app state remains compatible.
- Replaced project-specific sample labels with generic fictional ones.
- Added a browser sketch that requires no install. It is explicitly distinguished from the native touch and haptic experience.
- Found and corrected the older browser study’s reversed direction. Shared browser checks now cover the same spatial order and overview release rules as the native model.
- Added a ZIP-first installation guide with no Terminal dependency, signing steps, Developer Mode, trust prompts, first-use instructions and troubleshooting.
- Included the ready-to-open Xcode project. Node and XcodeGen are not prerequisites for running the native apps.
- Added build and model-check automation for both native variants, plus browser model and website build checks.
- Kept real accounts, service connections, signing material, device logs, raw reference images and recordings out of the repository.
- Used a separate catalogue checkout so adding Threefold does not publish unrelated work in the existing Small Weird Things checkout.

## Explicit limits

This is an independent prototype with fictional conversations. The native apps currently need a Mac and Xcode for installation; there is no TestFlight build. The browser sketch uses prototype screenshots and a one-finger/mouse interaction to demonstrate the idea. It does not establish iOS gesture recognition, accessibility compatibility or haptic comfort.

See [verification](VERIFICATION.md), [installation](INSTALL.md) and [asset notes](ASSETS.md) for the evidence and boundaries.
