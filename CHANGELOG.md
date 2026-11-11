# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.0.0] - 2026-11-12

### Breaking

- `getFile`, `scoringGetFile`, `getFileStreaming`, `scoringGetFileStreaming`, `emailFinderGetFile` and `domainSearchGetFile` report a JSON body (a body that is a JSON object, whatever its keys and content type) as `ZBError.httpError(message:statusCode:)` carrying the HTTP status, and save no file. In 2.2.0 `getFile`, `scoringGetFile`, `emailFinderGetFile` and `domainSearchGetFile` reported a body with a `message`, `error` or `error_message` key - such as `{"message": "File is still processing"}` on an HTTP 200 - as `ZBError.decodeError(messages:)`, whose `statusCode` is nil, and saved any other JSON object (`{"Message": ...}`, for example) as the result file; the two streaming downloads saved every JSON body except `"success": false` as the file. Code that matched `.decodeError` for these calls should match `.httpError` (or read `statusCode`).
- `ZeroBounceSDK.initialize(apiKey:apiBaseUrl:)` and `ZeroBounceWarmup.initialize(apiKey:)` return `Bool` (`@discardableResult`): false when the key is refused for surrounding whitespace or control characters. A refused key now also clears a key set by an earlier `initialize`, so every call reports `ZBError.notInitialized` (Warmup: "not initialized") and nothing is sent. In 2.2.0 the refusal was only printed and the client went on sending the previous key. Calls that ignore the result compile unchanged; only code that uses `initialize` as a `Void`-returning function value has to change.

### Changed

- The license file is `LICENSE` (was `LICENSE.md`), the name GitHub and the package tools look for; its text is unchanged. The podspec and the Xcode project point at it.
- `getFileStreaming` and `scoringGetFileStreaming` with a base URL that is not https now fail with `ZBError.decodeError(messages: ["url must be an https:// URL"])`, as every other call does, instead of `ZBError.invalidEndpoint`. No request was sent in either version.

### Fixed

- A trailing slash on a base URL - `ZeroBounceWarmup.baseUrl`, or the list evaluator and Inbox Placement Tester URLs given to `setListEvaluatorBaseUrl` / `setInboxPlacementBaseUrl` - built request paths with `//` (for example `https://warmup-api.zerobounce.net//api/v1/warmup/seeds`). Trailing slashes are now dropped from every base URL when it is set.

### Added

- Offline tests that sweep every public request method (64 on `ZeroBounceSDK`, 26 on `ZeroBounceWarmup`): each refuses a plain `http://` base URL before sending, stops at a redirect with its status, and sets the 120-second request timeout.

## [2.2.0] - 2026-11-11

Compared with 2.1.4. Items marked **Breaking** can stop existing code compiling or change what it receives.

### Upgrading from 2.1.4

- Raise your deployment target to iOS 15.0 (was 9.0); Swift Package Manager users also need Swift tools 5.5 (Xcode 13) or later.
- Update error handling: HTTP failures are now `ZBError.httpError(message:statusCode:)`. `ZBError.invalidResponse` is still declared but no longer produced. An error the API returns in an HTTP 200 body (invalid key, the batch-wide `validateBatch` error) still arrives as `ZBError.decodeError(messages:)`.
- Add `default` (or the new cases) to exhaustive `switch` statements over `ZBError` (`httpError`), `ZBValidateSubStatus` (`aiAgentMailbox`, `unknown`) and `ZBEmailConfidence` (`undetermined`, `unknown`).
- Handle the now optional `ZBValidateResponse.status` and `.processedAt`; they are absent while a greylist retry is still running.
- If you intercept requests with `URLProtocol.registerClass(_:)` (typically in tests), use `ZeroBounceSDK.setSessionConfiguration(_:)` instead; the global registration no longer sees the SDK's traffic.

The **Breaking** entries below give the details.

### Added

- `validate` and `validateBatch` take `ZBValidateOptions`: `timeout` (3–60 s for `validate`, 10–120 s for `validateBatch`), `activityData`, `verifyPlus`, `domainInfo`, `greylistProcessing`, `callbackUrl` and `usePost` (form-encoded `POST /validate`). An option left `nil` is not sent. `callbackUrl` needs `greylistProcessing: true` and is rejected without it, and when blank, before a request is sent. `validateBatch` sends `timeout` as a JSON string: sent as a number, the live API rejects the whole batch with "Invalid API Key or your account ran out of credits".
- `ZBValidateResponse` reads `active_in_days`, `active_first_seen`, `domain_website_exists`, `domain_registrant_company_name` and `Message` into `activeInDays`, `activeFirstSeen`, `domainWebsiteExists`, `domainRegistrantCompanyName` and `message`.
- `scoreEmail` (`GET /v2/scoring`) and `scoreEmailPost` (form-encoded `POST /v2/scoring`), returning `ZBScoreEmailResponse`.
- Bulk email finder and bulk domain search: `sendEmailFinderFile` / `sendEmailFinderFileData`, `emailFinderFileStatus`, `emailFinderGetFile`, `emailFinderDeleteFile`, and the matching `sendDomainSearchFile…` / `domainSearch…` methods. `has_header_row` is sent whether true or false. The email finder upload requires `first_name_column` or `full_name_column` as well as `domain_column`, and is rejected before sending without one.
- List evaluator: `sendListEvaluatorFile`, `sendListEvaluatorFileData`, `getListEvaluatorResult` and `sendEvaluatedFile(fileId:)`, which submits a finished evaluation by id as a form field. The evaluator has its own base URL, the file id is encoded as a single path segment, and a blank file id is rejected before a request is sent.
- Filters: `addFilter`, `deleteFilter` and `listFilters`. `/filters/list` answers with a JSON array (`[]` when no filters are set), so `listFilters` completes with the new `ZeroBounceSDK.ZBJsonResult`; cast the success value to `[[String: Any]]`.
- Amazon S3 bulk: `listS3files`, `validateS3File(options: ZBValidateS3FileOptions(fileName:returnUrl:))`, `scoreS3File(options: ZBScoreS3FileOptions(fileName:returnUrl:))`, `emailFinderS3File`, `domainSearchS3File` and `exportS3File(fileId:exportBucket:)`. `exportBucket: nil` uses the export bucket from your ZeroBounce settings; a blank one is rejected.
- SFTP/FTP bulk: `validateSFTPFile`, `scoreSFTPFile`, `emailFinderSFTPFile`, `domainSearchSFTPFile` and `exportSFTPFile(fileId:exportPath:)`, which sends `export_path` rather than `export_bucket`. The server, path and protocol come from your ZeroBounce settings. These and the S3 finder/domain-search jobs share `ZBBulkFileJobOptions`.
- Every S3 and SFTP job requires both `fileName` and `returnUrl`, checked before the request is sent. The docs call `validateSFTPFile`'s `file_name` and the S3 validate/score `return_url` optional; the live API rejects the call without them.
- Inbox Placement Tester on `https://bulkapi.zerobounce.net/api/ipt`: `getInboxPlacementProviders`, `getInboxPlacementTestTypes`, `createInboxPlacementTest`, `getInboxPlacementTest`, `listInboxPlacementTests`, `deleteInboxPlacementTest`, `getInboxPlacementWebhook` and `setInboxPlacementWebhook`, with `ZBCreateInboxPlacementTestOptions` (including per-provider seed caps, `providers: [ZBInboxPlacementTestProvider]`) and `ZBListInboxPlacementTestsOptions` (`status`, `createdAfter`, `createdBefore`, `page`, `pageSize`). It authenticates with an `Authorization: Bearer` header rather than the `api_key` parameter, bodies are camelCase JSON, and unset fields are left out. The listing is `GET /tests` and sends the page size as `page_size`. Before sending, `createInboxPlacementTest` checks `name` (at most 64 characters), `testType` (1, 2 or 3) and `senderEmail` (required for test type 1), and `listInboxPlacementTests` checks `status` (`running` or `finished`) and `pageSize` (1–100). A missing or empty API key is reported as `ZBError.notInitialized` before anything is sent.
- `setListEvaluatorBaseUrl` and `setInboxPlacementBaseUrl`.
- `ZeroBounceWarmup`, a client for the [Warmup API](https://www.zerobounce.net/docs/warmup-api): a separate product with its own host and its own team-scoped key (`initialize(apiKey:)`, sent in an `API-Key` header), with 26 endpoint methods. The body comes back parsed — a dictionary, an array or a number depending on the endpoint, and `nil` for the documented empty successes (HTTP 204 and an empty 200). `downloadSeeds` and `downloadStatistics` hand over CSV text.
- `getFileStreaming` and `scoringGetFileStreaming`, which write a result file straight to `downloadPath` instead of holding it in memory. The first bytes are checked first, so a JSON error still reaches the failure result and no partial file is left behind.
- `ZBError.httpError(message:statusCode:)` and `ZBError.statusCode`, so a caller can tell 429 from 500 without parsing the message. See **Changed** for when it is produced.
- `ZeroBounceSDK()` can be constructed directly (the initializer was `fileprivate`). `shared` remains available.
- `ZeroBounceSDK.setSessionConfiguration(_:)`, the supported way to route the SDK's requests (`ZeroBounceWarmup`'s included) through your own `URLSessionConfiguration` — for example one whose `protocolClasses` holds a test `URLProtocol`. Pass `nil` to return to the default. Redirects are still refused and only `https://` (or loopback) URLs are called.
- A public memberwise initializer on `ZBGetApiUsageResponse`, and its `subStatusLeadingPeriodRemoved` and `subStatusAliasAddress` counters (`sub_status_leading_period_removed`, `sub_status_alias_address`).
- `ZBValidateSubStatus.aiAgentMailbox` (`ai_agent_mailbox`) and `ZBValidateSubStatus.unknown`. See **Changed**.
- `Zero Bounce iOS SDKTests/LiveApiTests.swift`, an opt-in live suite. The documented test command and CI pass `-skip-testing:"Zero Bounce iOS SDKTests/LiveApiTests"`, and it does nothing without keys. Keys come from `TEST_RUNNER_ZEROBOUNCE_API_KEY` and `TEST_RUNNER_ZEROBOUNCE_WARMUP_API_KEY` — xcodebuild strips that prefix on the way into the test process, which does not otherwise inherit its environment. `TEST_RUNNER_ZEROBOUNCE_LIVE_SPEND=1` and `TEST_RUNNER_ZEROBOUNCE_LIVE_CHANGES=1` opt in to calls that spend credits or make reversible account changes.

### Changed

- **Breaking:** the minimum deployment target is iOS 15.0, up from iOS 9.0 in both the podspec and `Package.swift`. The Swift package also declares Mac Catalyst 15.0.
- **Breaking:** `Package.swift` needs Swift tools 5.5 (Xcode 13) or later, up from 5.3.
- **Breaking:** an HTTP error status is reported as `ZBError.httpError(message:statusCode:)`, carrying the API's message, instead of `ZBError.invalidResponse(statusCode:)`. `.invalidResponse` is still declared but is no longer produced, so code that matched it to detect a failed request no longer sees one. `.httpError` is also what you now get for an HTTP 200 whose body is empty, an HTML page or `"success": false`, and for a redirect (see below). An error the API reports in the body of an HTTP 200 — such as `{"error": "Invalid API key"}` from `validate` or `getApiUsage`, `{"Message": …}` from `findEmail`, or the batch-wide error of `validateBatch` — still arrives as `ZBError.decodeError(messages:)`, as do a body that cannot be decoded and an argument rejected before a request is sent.
- **Breaking:** `ZBError` has a new case, `httpError`, so a `switch` over it without a `default` no longer compiles.
- **Breaking:** `ZBValidateSubStatus` has two new cases, `aiAgentMailbox` and `unknown`, so a `switch` over it without a `default` no longer compiles. A `sub_status` the SDK does not recognise now decodes as `.unknown` instead of failing the whole response.
- **Breaking:** `ZBValidateResponse.status` and `.processedAt` are now optional. While a greylist retry is still running the API answers with a `Message` and neither field, and the previous non-optional declarations made that response fail to decode.
- **Breaking:** an HTTP 200 whose body has `"success": false` is now always a failure, `ZBError.httpError` with `statusCode` 200. In 2.1.4 it came back as a success value when the rest of the body decoded into the response type, and as `.decodeError` otherwise — which is how an unknown or deleted file id usually surfaced from `getFile` and `deleteFile`.
- **Breaking:** `validateBatch` reports an account-level failure (HTTP 200 with an error for the address `all`, such as an invalid API key or no credits) as a `.decodeError` failure instead of a successful result whose `errors` contains it. An error for one address stays on the successful result.
- **Breaking:** requests go through the SDK's own ephemeral `URLSession` instead of `URLSession.shared`, because a shared session cannot refuse a redirect. A `URLProtocol` registered globally with `URLProtocol.registerClass(_:)` therefore no longer intercepts the SDK's requests; use `ZeroBounceSDK.setSessionConfiguration(_:)` instead.
- `findEmail`'s `firstName` is optional on both overloads, so a person can be looked up by middle or last name alone. At least one of the three names is still needed: with none of them `/guessformat` is the domain search, so `findEmail` says to use `findDomain` instead of sending it.
- Requests time out after 120 seconds, up from `URLRequest`'s default of 60 — uploads and file downloads included.
- `initialize` refuses a key with surrounding whitespace or control characters instead of storing it, and the SDK stays uninitialized.
- `validateBatch` sends an empty `ip_address` as JSON `null`.
- Error messages are short text: an HTTP error carries the API's message (or the title of an HTML error page) rather than only the status code; an empty body, or a non-JSON body over 1,000 characters, is reported as such instead of with an empty message list; and a repeated `Error:` / `[Error]:` prefix is removed.

### Fixed

- `ZBValidateResponse.freeEmail`, `.mxFound` and `.catchallDomain` were never read from the response and were always `false`, `false` and `nil`: they were declared as `let` constants with a default value, which synthesized `Decodable` skips. They are now decoded, accepting a JSON boolean or the string `"true"`/`"false"` (the API sends `mx_found` as a string).
- `findEmail` failed to decode any result the finder could not resolve. The API answers those with `"email_confidence": "undetermined"`, which `ZBEmailConfidence` did not have, so the whole response became a decode error. **Breaking:** `ZBEmailConfidence` gains `undetermined` and `unknown`, so a `switch` over it without a `default` needs the two new cases. It and `ZBConfidence` now match their values case-insensitively (the docs write `HIGH`, `MEDIUM`, `LOW`; the API sends lowercase) and decode a value the SDK does not know as `.unknown` instead of failing the response.
- `getApiUsage` no longer fails on an ordinary response. The live API returns only the counters that apply to the account and date range, and `sub_status_gold` and `sub_status_role_based_accept_all` are often absent; decoding them as required keys failed the whole call. A missing counter now reads as 0, and a counter the API adds later is ignored. An invalid key is still reported as `ZBError.decodeError` carrying the API's message.
- `getFile` and `scoringGetFile` saved an HTML page served with HTTP 200 (such as an "Access denied" page) as the result file. It is now a failure.
- An empty API key is rejected with `ZBError.notInitialized` before a request is sent; it used to go out as an empty `api_key`.

### Security

- Version 2.1.4 logged every request URL — which carries the API key as the `api_key` query parameter — and every response body with `NSLog`, and `getFile` printed the whole downloaded result file. These logs are removed; only the saved file's name and an upload's local path are still logged.
- `getFile` keeps only the last path component of the server-suggested file name, so the result is always written inside `Documents/SavedFiles` and a name such as `../x` cannot place it elsewhere.
- Query parameters are built with `URLComponents` instead of string interpolation, so a value containing `&`, `=`, `#` or a space is percent-encoded and can no longer end the value or add a parameter. (`URLComponents` leaves `+` as is.)
- Only `https://` URLs are called (loopback aside, so an offline test can use a local stub), and redirects are not followed, so the API key cannot be sent in the clear or to another host.

## [2.1.3] - 2026-06-18

### Fixed

- `validateBatch` posts to `api.zerobounce.net/v2/validatebatch` instead of `bulkapi.zerobounce.net`.

## [2.1.2] - 2026-06-10

### Added

- `ZBValidateResponse.catchallDomain`, read from `catchall_domain`.

## [2.1.0] - 2026-04-05

### Added

- Optional bulk get-file parameters: download type (`phase_1`, `phase_2`, `combined`) and `activityData` (validation get-file only).
- `allowPhase2` on validation file send.

## [2.0.0] - 2026-03-03

### Changed

- Release 2.0.0 of the SDK.

[Unreleased]: https://github.com/zerobounce/zero-bounce-ios-sdk/compare/v3.0.0...HEAD
[3.0.0]: https://github.com/zerobounce/zero-bounce-ios-sdk/compare/v2.2.0...v3.0.0
[2.2.0]: https://github.com/zerobounce/zero-bounce-ios-sdk/compare/v2.1.4...v2.2.0
[2.1.3]: https://github.com/zerobounce/zero-bounce-ios-sdk/compare/v2.1.2...v2.1.3
[2.1.2]: https://github.com/zerobounce/zero-bounce-ios-sdk/compare/v2.1.0...v2.1.2
[2.1.0]: https://github.com/zerobounce/zero-bounce-ios-sdk/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/zerobounce/zero-bounce-ios-sdk/releases/tag/v2.0.0
