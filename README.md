# Repaste

A macOS menubar app that cleans clipboard text — strips ANSI escapes and terminal
artifacts, normalizes whitespace, and reflows wrapped paragraphs. Swift / AppKit,
minimum target macOS 15.0 (Sequoia). Distributed as a notarized Developer ID build
(outside the Mac App Store).

## Links

- **Download:** [Latest Release](https://github.com/carlos-andres/repaste/releases/latest)
- **Website:** [repaste.carlos-andres.pro](https://repaste.carlos-andres.pro/)

## Install

1. Download `Repaste-0.1.0.dmg` from the [latest release](https://github.com/carlos-andres/repaste/releases/latest).
2. Mount it and drag **Repaste** to Applications.
3. Launch it — a menubar icon appears. No Gatekeeper warnings (signed + notarized).

Requires macOS 15.0+ (Sequoia).

## Build

The `.xcodeproj` is **not versioned**: it's generated from `project.yml` with [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
xcodegen generate
xcodebuild -scheme Repaste -configuration Debug build
open build/Build/Products/Debug/Repaste.app   # a menubar icon appears
```

Edit project settings in `project.yml` (not in Xcode). Debug builds sign ad-hoc, so no
Apple account or certificate is needed to build and run the tests.

## Architecture (clean architecture)

`Domain/` pure engine · `Application/` use cases + ports · `Infrastructure/` adapters
(AppKit/Carbon/CGEvent) · `Presentation/` menubar + settings + HUD · `RepasteTests/` golden tests.

## License

[MIT](LICENSE) © 2026 Carlos A Loaiza O
