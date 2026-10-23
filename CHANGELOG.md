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
- Inbox Placement Tester on `https://bulkapi.zerobounce.net/api/ipt`: `getInboxPlacementProviders`, `getInboxPlacementTestTypes`, `createInboxPlacementTest`, `getInboxPlacementTest`, `listInboxPlacementTests`, `deleteInboxPlacementTest`, `getInboxPlacementWebhook`, `setInboxPlacementWebhook`. The API key goes on the query string, bodies are camelCase JSON, and unset fields are left out.
- `setListEvaluatorBaseUrl` and `setInboxPlacementBaseUrl`.

### Changed

- **Breaking:** `ZBValidateResponse.status` and `.processedAt` are now optional. While a greylist retry is still running the API answers with a `Message` and neither field, and the previous non-optional declarations made that response fail to decode entirely.
- The list evaluator uses its own base URL instead of building the path from the bulk base, and the file id is encoded as a single path segment. `getListEvaluatorResult` rejects a blank file id before a request is sent.
- `ZeroBounceSDK()` can be constructed directly. `shared` remains available.

### Changed

- The minimum iOS deployment target is 15.0.
- API requests time out after 120 seconds.

### Fixed

- A 403 HTML "Access denied" page is returned as a short error. An HTML page with status 200 is an error as well, including `getFile`, instead of a saved file.
- Empty and non-JSON bodies are a short error. A repeated `Error:` / `[Error]:` prefix is removed.
- `validateBatch` reports an account-level failure (HTTP 200, error for address `all`, such as an invalid API key or no credits) through the failure result. An error for one address stays on the successful result.
- Bulk email finder and domain search send `has_header_row` when it is set to false.
- `validateBatch` sends an empty `ip_address` as JSON `null`.
- An empty API key is rejected before a request is sent.

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
