# Trying and improving Threefold

This is a small interaction experiment. The useful question is how the movement feels: switching, pausing, browsing and finding your place again.

For feedback, include the demo, iPhone model, iOS version, relevant tuning settings and what happened. A short description of the expected movement helps more than “it feels wrong”. [Open an issue](https://github.com/hugo-alves/threefold/issues).

For code changes:

- Keep the interaction consistent in both native demos. Down reveals older chats above; up reveals newer chats below.
- Preserve saved drafts and settings. New Codable fields need migration defaults.
- Keep demo content fictional and calls or external services disconnected.
- Run `sh scripts/check-models.sh` for native model changes and `npm test` for browser motion/history changes. Build the affected app target for UI changes.
- State whether verification used the simulator, scripted native events or physical fingers. They establish different things.

The website source is in `site/`. `npm run build` creates the publishable `dist/` folder; it does not contain native source, logs or signing files.
