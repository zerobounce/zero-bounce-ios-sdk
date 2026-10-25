# AGENTS.md

Guidance for AI coding agents working in this repository.

## Project

`zero-bounce-ios-sdk` is the ZeroBounce iOS SDK. Callers construct `ZeroBounceSDK()` or use `ZeroBounceSDK.shared`, call `initialize(apiKey:)`, and receive `ZBResult` values. HTTP uses `URLSession.shared` in `Zero Bounce iOS SDK/ZeroBounceSDK.swift`. Releases go to CocoaPods from the GitHub tag.

## Layout

- `Zero Bounce iOS SDK/`: Swift sources. `ZeroBounceSDK.swift` is the client. `Priority3Api.swift` is bulk finder, domain search, list evaluator, filters, S3/SFTP and the Inbox Placement Tester. `ZeroBounceWarmup.swift` is the Warmup API: a separate product on its own host with its own team-scoped key and an `API-Key` header, so it never touches the validation key.
- `Zero Bounce iOS SDKTests/Zero_Bounce_iOS_SDKTests.swift`: XCTest, including the offline `URLProtocol` suites for the client and for Warmup.
- `Zero Bounce iOS SDKTests/LiveApiTests.swift`: the opt-in live suite. The documented test command and CI exclude it by name, and it does nothing without keys.
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
  -skip-testing:"Zero Bounce iOS SDKTests/LiveApiTests" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  ENABLE_USER_SCRIPT_SANDBOXING=NO
```

The live suite is the one test that is excluded there. To run it:

```bash
export ZEROBOUNCE_API_KEY=... ZEROBOUNCE_WARMUP_API_KEY=...
export ZEROBOUNCE_LIVE_SPEND=1 ZEROBOUNCE_LIVE_CHANGES=1
xcodebuild test \
  -workspace "Zero Bounce iOS SDK.xcworkspace" \
  -scheme "Zero Bounce iOS SDK" \
  -destination 'platform=macOS,variant=Mac Catalyst' \
  -only-testing:"Zero Bounce iOS SDKTests/LiveApiTests" \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO ENABLE_USER_SCRIPT_SANDBOXING=NO
```

xcodebuild does not hand its own environment to the test process, so each variable has to be exported a second time with a `TEST_RUNNER_` prefix, which xcodebuild forwards and the prefix is stripped from:

```bash
export TEST_RUNNER_ZEROBOUNCE_API_KEY="$ZEROBOUNCE_API_KEY"
export TEST_RUNNER_ZEROBOUNCE_WARMUP_API_KEY="$ZEROBOUNCE_WARMUP_API_KEY"
export TEST_RUNNER_ZEROBOUNCE_LIVE_SPEND=1 TEST_RUNNER_ZEROBOUNCE_LIVE_CHANGES=1
```

Pass them as environment variables, not as `xcodebuild` build settings: a build setting is an argument, and arguments are visible to anyone who can run `ps`. Keys come from the environment only: never write one into a file, a commit, a log, a fixture or a message.

That `xcodebuild` compile is the typecheck. There is no separate lint step. CI (`.github/workflows/sdk_ci.yml`) runs the same command. Do not commit `Pods/` changes that you did not intend, or user-specific Xcode state.

## Conventions

- **One `ZeroBounceSDK` per API key.** `shared` is a process-wide singleton. Construct `ZeroBounceSDK()` when two keys are in use. The offline concurrency test does this.
- **Column indexes are 1-based** for optional name, gender, and IP columns. `0` means the field is left out. `emailAddressColumn` on send-file and S3 is sent as given, including `0`, when the caller sets it.
- **Optional `Bool?` and `Int?` are omitted until set.** Explicit `false` is sent as `false`.
- **Booleans are the strings `true` and `false`.** `String(false)` is `false`. Do not send `0` or `1`.
- **`allowPhase2` is validation file send only.** `activityData` on get-file is validation only.
- **`validateBatch` uses `api.zerobounce.net`**, not `bulkapi.zerobounce.net`. An empty `ip_address` is JSON `null`.
- **Failures are `ZBResult.Failure`.** The message must be short: no raw HTML, no megabyte body, and no `Error: Error:` prefix. An account-level batch error (`emailAddress` `all`) is a failure. A per-address error stays on the success value.
- **The live API wins over the docs.** Where they disagree, follow the API and say so in a comment at the call site, prefixed `LIVE:`. The ones found so far: `validateBatch` sends `timeout` as a JSON *string*; the Inbox Placement Tester authenticates with `Authorization: Bearer` and lists tests from `GET /tests` (plural); every S3/SFTP job requires both `fileName` and `returnUrl`, `validateSFTPFile` included, although the docs call its `fileName` optional and call `validateS3File`'s and `scoreS3File`'s `returnUrl` optional (`POST /validateS3file` without one answers HTTP 400 "Provided return URL is not permitted: None"); the Inbox Placement test listing paginates by `page_size` and silently ignores `pageSize`; `sendEvaluatedFile` takes a file id as a form field, not an upload; Warmup's `checkDomainDmarc` takes an *email address*, not a domain; and `testSmtpConfiguration` answers a failed SMTP login with HTTP 500.
- **A `"success": false` field on an HTTP 200 is a failure.** `getFile` and `deleteFile` report an unknown or deleted file id that way. `ZBError.successMeansFailure` catches it in `sendRequest`, and `ZBError.httpError` carries the HTTP status.
- **`exportSFTPFile` sends `export_path`**, not the `export_bucket` that `exportS3File` sends. Both are optional: nil means the path or bucket from the account's settings, and a blank string is a mistake rather than a default.
- **Safety rails.** `initialize` refuses a key with surrounding whitespace or control characters, `ZeroBounceSDK.isAllowedURL` allows https only (loopback aside, for a local stub), `escapePathSegment` keeps a slash encoded, and redirects are never followed. Use them rather than adding a second rail beside them.
- **Requests go through `ZeroBounceSDK.urlSession`**, not `URLSession.shared`, because a shared session cannot refuse a redirect. A test that stubs HTTP puts its `URLProtocol` on that session; `URLProtocol.registerClass` alone reaches only the shared one.
- **Offline tests register their protocol on `ZeroBounceSDK.urlSession`.** Do not call the live API from anything but `LiveApiTests`.
- **Never from the live suite:** creating an Inbox Placement test (it cannot be deleted while running), setting the Inbox Placement webhook (it cannot be cleared), or ZB managed Warmup onboarding (it provisions a mailbox). Everything the `ZEROBOUNCE_LIVE_CHANGES=1` tier creates is removed again in the same run.
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
3. Run the `xcodebuild test` command above, and then the live suite by hand with real keys and both flags set; paste its summary line into the release notes. The offline suite cannot catch an API that has changed shape underneath the SDK.
4. Tag `vx.y.z` on that commit and run the Publish workflow. It publishes the CocoaPod from that tag.

## Build and test

Derived data must live **outside the repository**. With the default in-repo `build/` directory, copying the Mocker test framework into the simulator fails with a wall of `rsync: ... Operation not permitted` errors that look like a build break but are a sandbox problem:

```sh
xcodebuild build-for-testing -workspace "Zero Bounce iOS SDK.xcworkspace" \
  -scheme "Zero Bounce iOS SDK" -sdk iphonesimulator -derivedDataPath /tmp/zb-ios-dd
xcodebuild test-without-building -workspace "Zero Bounce iOS SDK.xcworkspace" \
  -scheme "Zero Bounce iOS SDK" -destination "id=<SIMULATOR_UDID>" -derivedDataPath /tmp/zb-ios-dd
```

If `xcodebuild` reports `CoreSimulator is out of date`, run `xcrun simctl list devices available` once — it reinstalls the matching service — then retry. `swift build` does **not** work: the package imports UIKit, so it must be built for an iOS SDK, not macOS.

## Rules

- **Only endpoints documented at https://www.zerobounce.net/docs/.** Do not add a method for an endpoint the public docs do not describe. Check before concluding something is undocumented: the S3 and SFTP bulk endpoints live under https://www.zerobounce.net/docs/api-integrations, not the main API reference.
- **Four base URLs.** `apiBaseUrl`, `bulkApiBaseUrl` (ends in `/v2`), `bulkApiRootUrl` (the S3/SFTP jobs, **no** `/v2`), and `listEvaluatorBaseUrl` / `inboxPlacementBaseUrl`. The last two are separate hosts rather than paths built from the bulk base, so `initialize` alone leaves them on the live API — use `setListEvaluatorBaseUrl` / `setInboxPlacementBaseUrl`.
- **Two bulk shapes are easy to get wrong.** `validateSFTPFile`'s `fileName` is optional — leaving it nil uses the input bucket from the account's settings, and every other job requires it. `exportSFTPFile` sends `export_path`, not the `export_bucket` that `exportS3File` sends; both are optional. Every job, `validateS3File` and `scoreS3File` included, needs a `returnUrl`: those two take it in their initializer.
- **A greylist-pending response has no `status` and no `processed_at`.** Both are optional on `ZBValidateResponse` for that reason; making either non-optional again makes the whole response fail to decode.
- **Two test harnesses live in one file.** `Zero_Bounce_iOS_SDKTests` uses Mocker; `OfflineApiTests` uses `OfflineURLProtocol`, which records every request. Prefer `OfflineApiTests` for new work — Mocker's registry is global and a mock registered with `ignoreQuery: true` will swallow requests from the other class's tests.
- **`URL.path` is percent-decoded and drops a trailing slash.** Assert on `OfflineRecord.rawPath` for anything about encoding.
- **Offline tests only.** Never call the live API from a test.
