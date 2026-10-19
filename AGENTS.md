# AGENTS.md

Guidance for AI coding agents working in this repository.

## Project

`zero-bounce-ios-sdk` is the ZeroBounce iOS SDK. Callers construct `ZeroBounceSDK()` or use `ZeroBounceSDK.shared`, call `initialize(apiKey:)`, and receive `ZBResult` values. HTTP uses `URLSession.shared` in `Zero Bounce iOS SDK/ZeroBounceSDK.swift`. Releases go to CocoaPods from the GitHub tag.

## Layout

- `Zero Bounce iOS SDK/`: Swift sources. `ZeroBounceSDK.swift` is the client. `Priority3Api.swift` is bulk finder, domain search, list evaluator, filters, and S3.
- `Zero Bounce iOS SDKTests/Zero_Bounce_iOS_SDKTests.swift`: XCTest, including the offline `URLProtocol` suite.
- `ZeroBounceSDK.podspec`: `s.version`.
- `Zero Bounce iOS SDK.xcodeproj/project.pbxproj`: `MARKETING_VERSION`.
- Both version fields must stay the same. Do not change only one of them.

## Commands

```bash
pod install
xcodebuild test \
  -workspace "Zero Bounce iOS SDK.xcworkspace" \
  -scheme "Zero Bounce iOS SDK" \
  -destination 'platform=macOS,variant=Mac Catalyst' \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  ENABLE_USER_SCRIPT_SANDBOXING=NO
```

That `xcodebuild` compile is the typecheck. There is no separate lint step. CI (`.github/workflows/sdk_ci.yml`) runs the same command. Do not commit `Pods/` changes that you did not intend, or user-specific Xcode state.

## Conventions

- **One `ZeroBounceSDK` per API key.** `shared` is a process-wide singleton. Construct `ZeroBounceSDK()` when two keys are in use. The offline concurrency test does this.
- **Column indexes are 1-based** for optional name, gender, and IP columns. `0` means the field is left out. `emailAddressColumn` on send-file and S3 is sent as given, including `0`, when the caller sets it.
- **Optional `Bool?` and `Int?` are omitted until set.** Explicit `false` is sent as `false`.
- **Booleans are the strings `true` and `false`.** `String(false)` is `false`. Do not send `0` or `1`.
- **`allowPhase2` is validation file send only.** `activityData` on get-file is validation only.
- **`validateBatch` uses `api.zerobounce.net`**, not `bulkapi.zerobounce.net`. An empty `ip_address` is JSON `null`.
- **Failures are `ZBResult.Failure`.** The message must be short: no raw HTML, no megabyte body, and no `Error: Error:` prefix. An account-level batch error (`emailAddress` `all`) is a failure. A per-address error stays on the success value.
- **Offline tests register `OfflineURLProtocol`.** Do not call the live API from the default test run.
- Match the surrounding style. Do not reformat unrelated code.

## Changelog

`CHANGELOG.md` follows [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/), and the project adheres to [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html).

- Add every user-visible change to `## [Unreleased]` in the same commit as the change.
- Group entries under these headings, in this order, omitting empty ones: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`.
- Write for SDK users. Leave out CI-only changes and fixes to code that was never released.
- At 2.y.z, a breaking change bumps the major version, a new method or option bumps the minor version, and fixes alone bump the patch version.

## Releasing

Publishing and pushing tags need a maintainer's explicit approval. Do not bump the version, tag, or publish unless they asked.

1. Move `[Unreleased]` entries under `## [x.y.z] - YYYY-MM-DD`, leave an empty `[Unreleased]` section, and update the compare links.
2. Set the same version in both `s.version` in `ZeroBounceSDK.podspec` and every `MARKETING_VERSION` in `Zero Bounce iOS SDK.xcodeproj/project.pbxproj`. The publish workflow fails if they differ.
3. Run the `xcodebuild test` command above.
4. Tag `vx.y.z` on that commit and run the Publish workflow. It publishes the CocoaPod from that tag.
