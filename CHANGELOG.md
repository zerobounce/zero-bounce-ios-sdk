# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `validate` and `validateBatch` take `ZBValidateOptions`: `timeout`, `activityData`, `verifyPlus`, and `usePost` (form-encoded `POST /validate`).
- `ZBValidateResponse` reads `activeInDays` and `activeFirstSeen`.
- `scoreEmail` (`GET /v2/scoring`) and `scoreEmailPost` (form-encoded `POST /v2/scoring`).
- Bulk email finder, bulk domain search, list evaluator, filters, and S3 bulk methods, including `listS3files`, `emailFinderS3File` and `domainSearchS3File`.
- SFTP/FTP bulk: `validateSFTPFile`, `scoreSFTPFile`, `emailFinderSFTPFile`, `domainSearchSFTPFile`, and `exportSFTPFile`, sharing the new `ZBBulkFileJobOptions`. The server, path and protocol come from your ZeroBounce settings. `validateSFTPFile`'s `fileName` is optional; `exportSFTPFile` takes `export_path` rather than the `export_bucket` `exportS3File` sends.
- `ZBValidateOptions` accepts `domainInfo`, `greylistProcessing` and `callbackUrl`. `callbackUrl` needs `greylistProcessing: true` and is rejected without it, and when blank, before a request is sent.
- `ZBValidateResponse` reads `domain_website_exists`, `domain_registrant_company_name` and `Message`.
- Inbox Placement Tester on `https://bulkapi.zerobounce.net/api/ipt`: `getInboxPlacementProviders`, `getInboxPlacementTestTypes`, `createInboxPlacementTest`, `getInboxPlacementTest`, `listInboxPlacementTests`, `deleteInboxPlacementTest`, `getInboxPlacementWebhook`, `setInboxPlacementWebhook`. It authenticates with an `Authorization: Bearer` header, bodies are camelCase JSON, and unset fields are left out.
- `setListEvaluatorBaseUrl` and `setInboxPlacementBaseUrl`.
- `ZeroBounceWarmup`, a client for the [Warmup API](https://www.zerobounce.net/docs/warmup-api): a separate product with its own host, its own team-scoped key (`initialize(apiKey:)`, sent in an `API-Key` header) and all 26 documented endpoints. The body comes back parsed — a dictionary, an array or a number depending on the endpoint, and `nil` for the documented empty successes (HTTP 204 and an empty 200). `downloadSeeds` and `downloadStatistics` hand over CSV text.
- `ZBError.httpError(message:statusCode:)` for an error the API itself reported, and `ZBError.statusCode` to read the status back, so a caller can tell 429 from 500 without parsing the message.
- Safety rails: `initialize` refuses a key with surrounding whitespace or control characters rather than storing it, only `https://` URLs are called (loopback aside, so an offline test can use a local stub), and redirects are not followed.
- `Zero Bounce iOS SDKTests/LiveApiTests.swift`, an opt-in live suite. The documented test command and CI pass `-skip-testing:"Zero Bounce iOS SDKTests/LiveApiTests"`, and it does nothing without keys. Keys come from `TEST_RUNNER_ZEROBOUNCE_API_KEY` and `TEST_RUNNER_ZEROBOUNCE_WARMUP_API_KEY` — xcodebuild strips that prefix on the way into the test process, which does not otherwise inherit its environment. `TEST_RUNNER_ZEROBOUNCE_LIVE_SPEND=1` and `TEST_RUNNER_ZEROBOUNCE_LIVE_CHANGES=1` opt in to calls that spend credits or make reversible account changes.
- `ZBCreateInboxPlacementTestOptions.providers`, the documented per-provider seed caps, sent as `providers: [{"id": …, "maxSeeds": …}]`. They were missing, so a test could ask for a provider but not cap its seeds. The entries are the new `ZBInboxPlacementTestProvider`.
- `ZBListInboxPlacementTestsOptions.createdAfter` and `.createdBefore`, the two documented date filters of the test listing. They were missing entirely.

### Changed

- Verified against the live API. Where it disagrees with the docs, the API wins and the call site says so:
  - `validateBatch` sends `timeout` as a JSON **string**. Sent as a number the API rejects the whole batch with the account-level "Invalid API Key or your account ran out of credits".
  - The Inbox Placement Tester authenticates with `Authorization: Bearer`, not the `api_key` query parameter the rest of the API takes, and its listing is `GET /tests` (plural) — `/test` answers `Method "GET" not allowed`.
  - Every S3/SFTP job requires both `fileName` and `returnUrl`, `validateSFTPFile` included, although the docs call its `fileName` optional. Both are checked before the request is sent.
  - **Breaking:** `sendEvaluatedFile` takes `fileId:` rather than `filePath:`. The live endpoint takes the id of a finished evaluation as a form field, not an upload.
- A `"success": false` field on an HTTP 200 is now a failure instead of a success value. `getFile` and `deleteFile` report an unknown or deleted file id that way.
- **Breaking:** errors the API reported are `ZBError.httpError` rather than `ZBError.decodeError`, which now covers only bodies that could not be read.
- Requests go through `ZeroBounceSDK.urlSession` instead of `URLSession.shared`, because a shared session cannot refuse a redirect. A test that stubs HTTP should put its `URLProtocol` on that session.
- **Breaking:** `ZBValidateResponse.status` and `.processedAt` are now optional. While a greylist retry is still running the API answers with a `Message` and neither field, and the previous non-optional declarations made that response fail to decode entirely.
- The list evaluator uses its own base URL instead of building the path from the bulk base, and the file id is encoded as a single path segment. `getListEvaluatorResult` rejects a blank file id before a request is sent.
- `ZeroBounceSDK()` can be constructed directly. `shared` remains available.
- **Breaking:** `ZBValidateS3FileOptions` and `ZBScoreS3FileOptions` take `returnUrl` in their initializer: `ZBValidateS3FileOptions(fileName:returnUrl:)`. LIVE: `POST /validateS3file` without one answers HTTP 400 "Provided return URL is not permitted: None", so it is required the way it is on every other S3/SFTP job rather than an optional field. `validateS3File` and `scoreS3File` now go through the same `file_name` / `return_url` check those jobs use.
- `exportS3File` takes `exportBucket: String?`. `export_bucket` is optional — pass nil to use the export bucket from your ZeroBounce settings — and a blank one is still rejected, which is how `exportSFTPFile` has always treated `export_path`.
- `findEmail`'s `firstName` is optional on both overloads, so a person can be looked up by middle or last name alone. At least one of the three names is still needed: with none of them `/guessformat` is the domain search, so `findEmail` says to use `findDomain` instead of quietly answering something else.
- `sendEmailFinderFile` and `sendEmailFinderFileData` require `first_name_column` or `full_name_column` as well as `domain_column`. A file with neither has no name for the finder to search with.
- `createInboxPlacementTest` checks the documented limits before sending: `name` at most 64 characters, `testType` 1, 2 or 3, and `senderEmail` when `testType` is 1.
- `listInboxPlacementTests` checks `status` (`running` or `finished`) and `pageSize` (1–100) before sending.

### Changed

- The minimum iOS deployment target is 15.0.
- API requests time out after 120 seconds.

### Removed

- **Breaking:** `removeDuplicate` on `ZBValidateS3FileOptions` and `ZBScoreS3FileOptions`. The singular `remove_duplicate` was sent alongside the documented `remove_duplicates` and is not a parameter the API describes. Use `removeDuplicates`.

### Fixed

- `getApiUsage` no longer fails outright. The live API returns only the counters that apply to the account and date range, and `sub_status_gold` and `sub_status_role_based_accept_all` are absent from an ordinary response; decoding them as required keys threw, so the whole call failed with "ZeroBounce returned a response that is not valid JSON." A missing counter now reads as 0, and a counter the API adds later is ignored rather than fatal. `sub_status_leading_period_removed` and `sub_status_alias_address`, which the API does return, are now read.
- `listFilters` no longer fails outright. `/filters/list` answers with a JSON array — `[]` when no filters are set — which could not be carried by a dictionary-only result. **Breaking:** it now completes with `ZeroBounceSDK.ZBJsonResult`; cast the success value to `[[String: Any]]`.

- A 403 HTML "Access denied" page is returned as a short error. An HTML page with status 200 is an error as well, including `getFile`, instead of a saved file.
- Empty and non-JSON bodies are a short error. A repeated `Error:` / `[Error]:` prefix is removed.
- `validateBatch` reports an account-level failure (HTTP 200, error for address `all`, such as an invalid API key or no credits) through the failure result. An error for one address stays on the successful result.
- Bulk email finder and domain search send `has_header_row` when it is set to false.
- `validateBatch` sends an empty `ip_address` as JSON `null`.
- An empty API key is rejected before a request is sent.
- `scoreS3File` can now succeed. `ZBScoreS3FileOptions` had no `returnUrl` field at all, so the parameter the live API requires was unreachable and every call was rejected. `validateS3File` sent `return_url` only when it happened to be set.
- `listInboxPlacementTests` sends `page_size`. It sent `pageSize`, which the endpoint accepts and then ignores, so every call came back with the whole list however the page size was set.

### Security

- Error results no longer include the raw HTML access-denied page.

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

[Unreleased]: https://github.com/zerobounce/zero-bounce-ios-sdk/compare/v2.1.4...HEAD
[2.1.3]: https://github.com/zerobounce/zero-bounce-ios-sdk/compare/v2.1.2...v2.1.3
[2.1.2]: https://github.com/zerobounce/zero-bounce-ios-sdk/compare/v2.1.0...v2.1.2
[2.1.0]: https://github.com/zerobounce/zero-bounce-ios-sdk/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/zerobounce/zero-bounce-ios-sdk/releases/tag/v2.0.0
