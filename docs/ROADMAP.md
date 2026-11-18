# Reel It In Roadmap

## How we will work

This is a learning-first project. Work through one stage at a time: understand the current implementation, discuss the architecture and tradeoffs, agree on a small scope, implement it together, and verify it on a real device. Do not treat this document as authorization to complete every stage autonomously.

Explain new concepts, configuration, dependencies, security implications, and alternatives in plain language before relying on them. Keep an architecture decision record for choices that would be expensive to reverse.

## Product direction

- iPhone is the initial target; iPad support is deferred.
- The app has a portrait native experience for splash, authentication, home/menu, and focus setup; fishing remains landscape.
- The user earns one stamina for each fully completed two-minute focus chunk. A 15-minute session earns 7 stamina. Cancelling early earns none.
- Existing TestFlight accounts will reset when Firebase is removed; this is a fresh beta rather than a password migration.

## Architecture direction

### Native app and focus blocking

- Keep the working Godot 4.5 game and GDScript for the shipping iOS game. Godot C# iOS export is experimental, so do not combine a C# game rewrite with the current release.
- Present a full-screen SwiftUI modal shell over the existing Godot app instead of embedding Godot in a new SwiftUI root. This avoids an unstable Godot toolchain migration.
- Swift owns the FamilyControls picker, Keychain token storage, API client, App Group focus state, and orientation transitions. Godot gets a narrow native bridge for game data.
- Add a Device Activity Monitor extension. It must restore/clear shields independently of the Godot process and read the encoded FamilyActivitySelection from the App Group. Keep FamilyControls tokens on-device; do not send them to the backend.
- Use a durable native iOS host project and repeatable Godot export/sync flow. Do not continue treating regenerated Xcode output as hand-maintained source of truth.

### Backend and data

- Replace Firebase Authentication and Firestore with a public HTTPS ASP.NET Core API on .NET 10 LTS, MySQL, EF Core, and the version-matched Pomelo MySQL provider.
- Use ASP.NET Identity for email/password accounts, short-lived JWT access tokens, and rotated, hashed refresh tokens. Store client tokens only in the iOS Keychain.
- Keep MySQL private behind the API. Deploy API, MySQL, and TLS reverse proxy with Docker; use separate least-privilege runtime and migration database accounts.
- The server is authoritative for focus completion, stamina, money, inventory writes, cast spending, and fish sales. Use database transactions and idempotency so retries or relaunches cannot double-award currency.
- Initial schema: users, refresh tokens, player stats, focus sessions, static item catalog, and inventory slots. Store IDs and gameplay metadata, never texture paths or arbitrary client dictionaries.

## Gameplay and visual direction

- Retain a 1280x720 logical gameplay safe area. Enable responsive expansion for wide iPhones and anchor the game HUD instead of relying on fixed coordinates.
- Make landscape backgrounds as a 1280x720 central safe region plus 256px of horizontal bleed on each side: a 1792x720 master, or equivalent tileable/parallax layers. Do not make device-specific background files for iPhone.
- Use 64x64 transparent fish frames. Common swimming sheets are six horizontal frames (384x64); idle sheets are four to six frames (256-384x64). Draw one direction and mirror it in Godot.
- Replace per-scene fish magic numbers with data-driven fish definitions: spawn weight, depth, speed, behavior rates, catch difficulty, item ID, and animation set. Make random behavior frame-rate independent.
- Polish casting/reeling only after the state model is clear: power preview, release/splash feedback, line tension, bite feedback, aligned animation and sound cues.

## Risks to resolve early

- The repository currently tracks and exports the Firebase `.env`; remove it, rotate credentials as needed, and replace it with non-secret templates.
- The FamilyControls selection is currently kept only in memory, and focus rewards trust a local timestamp. Both must be replaced by App Group persistence and server-backed session state.
- The current project has no CI/test suite, carries generated Xcode and large engine binaries, and tracks SwiftGodot from `main`. Pin dependencies and introduce repeatable build/test automation.
- Existing inventory and economy writes are client-controlled and can lose or diverge money/inventory changes. Move these invariants to server transactions.

## Suggested stage order

1. Establish durable native-host/export workflow, remove secret exposure, and document the current build/run path.
2. Build the ASP.NET Core/MySQL foundation locally with migrations, core accounts, and automated tests.
3. Deploy the backend over HTTPS and replace Firebase data/auth through the Swift client and Godot bridge.
4. Rebuild focus flow with SwiftUI, App Groups, and Device Activity Monitor extension; verify on physical iPhone.
5. Add the native landing/menu transition and responsive iPhone layout.
6. Refactor fish definitions and polish casting/reeling; add art iteratively.
7. Add CI, real-device release checks, and maintenance documentation.
