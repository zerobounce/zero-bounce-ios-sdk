## ZeroBounce iOS SDK
This SDK contains methods for interacting easily with ZeroBounce API.
More information about ZeroBounce you can find in the [official documentation](https://www.zerobounce.net/docs/).


## Security

- Keep API keys on a trusted server. Do not embed them in mobile apps or browser JavaScript that untrusted users can inspect.
- Custom API base URLs (when supported) must use `https://`. Do not pass end-user-controlled hosts into those settings.
- Request URLs include `api_key` as a query parameter (ZeroBounce API contract). Do not log full request URLs or enable payload debug logging in production.

### Installation (CocoaPods)
Add the pod to your Podfile
```pod 'ZeroBounceSDK' ```
and run 
```pod install```

## USAGE
Import the SDK in your file:
```swift
import ZeroBounceSDK
``` 

Initialize the SDK with your api key and preferred api:
```swift 
ZeroBounceSDK.shared.initialize(apiKey: "<YOUR_API_KEY>", apiBaseUrl: .API_DEFAULT_URL)
```

## Examples
Then you can use any of the SDK methods, for example:
* ##### Validate an email address
```swift
let email = "<EMAIL_ADDRESS>"   // The email address you want to validate
let ipAddress = "127.0.0.1"     // The IP Address the email signed up from (Optional)

ZeroBounceSDK.shared.validate(email: email, ipAddress: ipAddress) { result in
    switch result {
    case .Success(let response):
        NSLog("validate success response=\(response)")
    case .Failure(let error):
        NSLog("validate failure error=\(String(describing: error))")
        switch error as? ZBError {
        case ZBError.notInitialized:
            break
        case ZBError.decodeError(let messages):
            /// decodeError is used to extract and decode errors and messages 
            /// when they are not part of the response object
            break
        default:
            break
        }
    }
}
```

* ##### Validate up to 100 email addresses using Batch Email Validator
```swift
// The email addresses you want to validate
let emails = [ 
    ["email_address": "<EMAIL_ADDRESS_1>"], 
    ["email_address": "<EMAIL_ADDRESS_2>", "ip_address": "127.0.0.1"]
] 

ZeroBounceSDK.shared.validateBatch(emails: emails) { result in
    switch result {
    case .Success(let response):
        NSLog("validate success response=\(response)")
    case .Failure(let error):
        NSLog("validate failure error=\(String(describing: error))")
    }
}
```

* ##### Find the email based on a given domain name or company name
```swift
let domain = "<DOMAIN_NAME>" // The domain name for which to find the email format
let companyName = "<COMPANY_NAME>" // The company name for which to find the email format
let firstName = "<FIRST_NAME>" // The first name whose email format is being searched
let middleName = "<MIDDLE_NAME>" // The middle name whose email format is being searched (Optional)
let lastName = "<LAST_NAME>" // The last name whose email format is being searched (Optional)

ZeroBounceSDK.shared.findEmail(
    domain: domain,
    firstName: firstName,
    middleName: middleName,
    lastName: lastName
) { result in
    switch result {
    case .Success(let response):
        NSLog("guessFormat success response=\(response)")
    case .Failure(let error):
        NSLog("guessFormat failure error=\(String(describing: error))")
    }
}

ZeroBounceSDK.shared.findEmail(
    companyName: companyName,
    firstName: firstName,
    middleName: middleName,
    lastName: lastName
) { result in
    switch result {
    case .Success(let response):
        NSLog("guessFormat success response=\(response)")
    case .Failure(let error):
        NSLog("guessFormat failure error=\(String(describing: error))")
    }
}
```

* ##### Find the domain based on a given domain name or company name
```swift
let domain = "<DOMAIN_NAME>" // The domain name for which to find the email format
let companyName = "<COMPANY_NAME>" // The company name for which to find the email format

ZeroBounceSDK.shared.findEmail(
    domain: domain
) { result in
    switch result {
    case .Success(let response):
        NSLog("guessFormat success response=\(response)")
    case .Failure(let error):
        NSLog("guessFormat failure error=\(String(describing: error))")
    }
}

ZeroBounceSDK.shared.findEmail(
    companyName: companyName
) { result in
    switch result {
    case .Success(let response):
        NSLog("guessFormat success response=\(response)")
    case .Failure(let error):
        NSLog("guessFormat failure error=\(String(describing: error))")
    }
}
```

* ##### Check how many credits you have left on your account
```swift
ZeroBounceSDK.shared.getCredits() { result in
    switch result {
    case .Success(let response):
        NSLog("getCredits success response=\(response)")
        let credits = response.credits
    case .Failure(let error):
        NSLog("getCredits failure error=\(String(describing: error))")
    }
}
```

* ##### Check if your email inbox has been active in the past 30, 60, 90, 180, 365, 730 or 1095 days
```swift
let email = "<EMAIL_ADDRESS>"   // The email address you want to check

ZeroBounceSDK.shared.getActivityData(email: email) { result in
    switch result {
    case .Success(let response):
        NSLog("getActivityData success response=\(response)")
    case .Failure(let error):
        NSLog("getActivityData failure error=\(String(describing: error))")
    }
}
```

* ##### Check your API usage for a given period of time
```swift
let startDate = Date();    // The start date of when you want to view API usage
let endDate = Date();      // The end date of when you want to view API usage

ZeroBounceSDK.shared.getApiUsage(startDate: startDate, endDate: endDate) { result in
    switch result {
    case .Success(let response):
        NSLog("getApiUsage success response=\(response)")
    case .Failure(let error):
        NSLog("getApiUsage failure error=\(String(describing: error))")
    }
}
```

* ##### The sendfile API allows user to send a file for bulk email validation
```swift
let filePath = File("<FILE_PATH>"); // The csv or txt file
let emailAddressColumn = 3;         // The index of "email" column in the file. Index starts at 1
let firstNameColumn = 3;            // The index of "first name" column in the file
let lastNameColumn = 3;             // The index of "last name" column in the file
let genderColumn = 3;               // The index of "gender" column in the file
let ipAddressColumn = 3;            // The index of "IP address" column in the file
let hasHeaderRow = true;            // If this is `true` the first row is considered as table headers
let returnUrl = "https://domain.com/called/after/processing/request";
// Optional: request phase 2 (catch-all) after phase 1 when Verify+ rules apply — see [v2 send file](https://www.zerobounce.net/docs/email-validation-api-quickstart/v2-send-file)
let allowPhase2: Bool? = true

ZeroBounceSDK.shared.sendFile(
    filePath: filePath,
    emailAddressColumn: emailAddressColumn,
    returnUrl: returnUrl,
    firstNameColumn: firstNameColumn,
    lastNameColumn: lastNameColumn,
    genderColumn: genderColumn,
    ipAddressColumn: ipAddressColumn,
    hasHeaderRow: hasHeaderRow,
    allowPhase2: allowPhase2
) { result in
    switch result {
    case .Success(let response):
        NSLog("sendFile success response=\(response)")
    case .Failure(let error):
        NSLog("sendFile failure error=\(String(describing: error))")
    }
}
```

Bulk validation uses `https://bulkapi.zerobounce.net/v2`. See [v2 send file](https://www.zerobounce.net/docs/email-validation-api-quickstart/v2-send-file), [v2 file status](https://www.zerobounce.net/docs/email-validation-api-quickstart/v2-file-status), and [v2 get file](https://www.zerobounce.net/docs/email-validation-api-quickstart/v2-get-file). `ZBFileStatusResponse` includes `filePhase2Status` when the API returns it.

* ##### The getfile API allows users to get the validation results file for the file been submitted using sendfile API
```swift
let fileId = "<FILE_ID>";    // The returned file ID when calling sendfile API

ZeroBounceSDK.shared.getFile(fileId: fileId) { result in
    switch result {
    case .Success(let response):
        NSLog("getFile success response=\(response)")
    case .Failure(let error):
        NSLog("getFile failure error=\(String(describing: error))")
    }
}
```

Optional `download_type` and `activity_data` (validation only; JSON errors may still use HTTP 200 and are returned as `.Failure` with `ZBError.decodeError`):

```swift
ZeroBounceSDK.shared.getFile(
    fileId: fileId,
    options: ZBGetFileOptions(downloadType: .combined, activityData: true)
) { result in
    switch result {
    case .Success(let response):
        NSLog("getFile success response=\(response)")
    case .Failure(let error):
        NSLog("getFile failure error=\(String(describing: error))")
    }
}
```

* ##### Check the status of a file uploaded via "sendFile" method
```swift
let fileId = "<FILE_ID>";    // The returned file ID when calling sendfile API

ZeroBounceSDK.shared.fileStatus(fileId: fileId) { result in
    switch result {
    case .Success(let response):
        NSLog("fileStatus success response=\(response)")
    case .Failure(let error):
        NSLog("fileStatus failure error=\(String(describing: error))")
    }
}
```

* ##### Deletes the file that was submitted using scoring sendfile API. File can be deleted only when its status is _`Complete`_
```swift
let fileId = "<FILE_ID>";    // The returned file ID when calling sendfile API

ZeroBounceSDK.shared.deleteFile(fileId: fileId) { result in
    switch result {
    case .Success(let response):
        NSLog("deleteFile success response=\(response)")
    case .Failure(let error):
        NSLog("deleteFile failure error=\(String(describing: error))")
    }
}
```

### AI Scoring API
* ##### The scoringSendFile API allows user to send a file for bulk email validation
```swift
let filePath = File("<FILE_PATH>"); // The csv or txt file
let emailAddressColumn = 3;         // The index of "email" column in the file. Index starts at 1
let hasHeaderRow = true;            // If this is `true` the first row is considered as table headers
let returnUrl = "https://domain.com/called/after/processing/request";

// `allowPhase2` is not used for scoring sendfile (validation bulk only).

ZeroBounceSDK.shared.scoringSendFile(
    filePath: filePath,
    emailAddressColumn: emailAddressColumn,
    returnUrl: returnUrl,
    hasHeaderRow: hasHeaderRow
) { result in
    switch result {
    case .Success(let response):
        NSLog("sendFile success response=\(response)")
    case .Failure(let error):
        NSLog("sendFile failure error=\(String(describing: error))")
    }
}
```

* ##### The scoringGetFile API allows users to get the validation results file for the file been submitted using scoringSendFile API
```swift
let fileId = "<FILE_ID>";    // The returned file ID when calling scoringSendFile API

ZeroBounceSDK.shared.scoringGetFile(fileId: fileId) { result in
    switch result {
    case .Success(let response):
        NSLog("scoringGetFile success response=\(response)")
    case .Failure(let error):
        NSLog("scoringGetFile failure error=\(String(describing: error))")
    }
}
```

```swift
ZeroBounceSDK.shared.scoringGetFile(
    fileId: fileId,
    options: ZBGetFileOptions(downloadType: .phase2, activityData: true) // activityData ignored for scoring
) { result in
    switch result {
    case .Success(let response):
        NSLog("scoringGetFile success response=\(response)")
    case .Failure(let error):
        NSLog("scoringGetFile failure error=\(String(describing: error))")
    }
}
```

* ##### Check the status of a file uploaded via "scoringSendFile" method
```swift
let fileId = "<FILE_ID>";    // The returned file ID when calling scoringSendFile API

ZeroBounceSDK.shared.scoringFileStatus(fileId: fileId) { result in
    switch result {
    case .Success(let response):
        NSLog("fileStatus success response=\(response)")
    case .Failure(let error):
        NSLog("fileStatus failure error=\(String(describing: error))")
    }
}
```

* ##### Deletes the file that was submitted using scoring scoringSendFile API. File can be deleted only when its status is _`Complete`_
```swift
let fileId = "<FILE_ID>";    // The returned file ID when calling scoringSendFile API

ZeroBounceSDK.shared.scoringDeleteFile(fileId: fileId) { result in
    switch result {
    case .Success(let response):
        NSLog("deleteFile success response=\(response)")
    case .Failure(let error):
        NSLog("deleteFile failure error=\(String(describing: error))")
    }
}
```

## Validate options

`validate` takes a `ZBValidateOptions`. An option left `nil` is not sent, and
booleans go on the wire as the strings `"true"`/`"false"`.

```swift
ZeroBounceSDK.shared.validate(
    email: "<EMAIL>",
    options: ZBValidateOptions(
        timeout: 30,                 // 3-60 seconds
        activityData: true,          // fills activeInDays / activeFirstSeen
        verifyPlus: true,
        domainInfo: true,            // fills domainWebsiteExists / domainRegistrantCompanyName
        greylistProcessing: true,
        callbackUrl: "https://example.com/greylist",
        usePost: true                // form-encoded POST /v2/validate instead of GET
    )
) { result in print(result) }
```

`callbackUrl` is where the greylist retry posts its result, so it is rejected
without `greylistProcessing: true` — before any request is sent. While that
retry is still running the API answers with a `Message` and **no** `status` or
`processed_at`, so `ZBValidateResponse.status` and `.processedAt` are optional
and the text lands on `.message`.

## S3 and SFTP/FTP bulk

Queue a job on a file that already sits in your Amazon S3 bucket, or on your
SFTP/FTP server. See the [S3](https://www.zerobounce.net/docs/api-integrations/amazon-s3-bulk-api)
and [SFTP](https://www.zerobounce.net/docs/api-integrations/sftp_bulk_api) docs.
These live on the bulkapi host *without* the `/v2` path.

```swift
let zb = ZeroBounceSDK.shared

// Amazon S3. fileName is the full path, as returned by listS3files.
// Every one of these jobs needs both fileName and returnUrl: the docs call
// validateSFTPFile's fileName optional, but the live API answers
// "Empty parameter: file_name" without it.
let done = "https://example.com/zerobounce-done"
zb.emailFinderS3File(
    options: ZBBulkFileJobOptions(fileName: "lists/leads.csv", returnUrl: done)
) { _ in }
zb.domainSearchS3File(
    options: ZBBulkFileJobOptions(
        fileName: "lists/leads.csv",
        removeDuplicates: true,
        returnUrl: done
    )
) { _ in }

// SFTP/FTP. The server, path and protocol come from your ZeroBounce settings.
let sftp = ZBBulkFileJobOptions(fileName: "my_file.txt", returnUrl: done)
zb.validateSFTPFile(options: sftp) { _ in }
zb.scoreSFTPFile(options: sftp) { _ in }
zb.emailFinderSFTPFile(options: sftp) { _ in }
zb.domainSearchSFTPFile(options: sftp) { _ in }

// Note the field: this one takes export_path, not export_bucket.
// nil uses the export path from your settings.
zb.exportSFTPFile(fileId: "<FILE_ID>", exportPath: "/exports") { _ in }
```

## Inbox Placement Tester

Runs on its own host and sends camelCase JSON bodies. It authenticates with an
`Authorization: Bearer` header rather than the `api_key` parameter the rest of
the API takes, and it spends the account's inbox-test credits.

```swift
let zb = ZeroBounceSDK.shared

zb.getInboxPlacementProviders { _ in }
zb.getInboxPlacementTestTypes { _ in }

zb.createInboxPlacementTest(
    name: "Launch",
    options: ZBCreateInboxPlacementTestOptions(
        testType: 1,
        senderEmail: "news@example.com",
        webhookUrl: "https://example.com/ipt-webhook"
    )
) { _ in }

// Send your campaign to the seeds you got back, then read the results.
zb.getInboxPlacementTest(testId: "<TEST_ID>") { _ in }

zb.listInboxPlacementTests(options: ZBListInboxPlacementTestsOptions(status: "finished", page: 1)) { _ in }
zb.setInboxPlacementWebhook(webhookUrl: "https://example.com/ipt-webhook") { _ in }
zb.getInboxPlacementWebhook { _ in }
zb.deleteInboxPlacementTest(testId: "<TEST_ID>") { _ in }
```

## List evaluator

Upload a list for evaluation, read the result, and hand a finished evaluation
back for bulk validation. The evaluator has its own base URL, and the file id
is one path segment, so a slash in it stays encoded.

```swift
zb.sendListEvaluatorFile(filePath: "emails.csv", emailAddressColumn: 1) { _ in }
zb.getListEvaluatorResult(fileId: "<FILE_ID>") { _ in }

// The id of a finished evaluation, not a path: the live endpoint takes it as
// a form field.
zb.sendEvaluatedFile(fileId: "<FILE_ID>") { _ in }
```

## Warmup API

The [Warmup API](https://www.zerobounce.net/docs/warmup-api) is a separate
product: its own host, its own team-scoped key, and an `API-Key` header instead
of an `api_key` parameter. Use `ZeroBounceWarmup` with a Warmup API key;
`ZeroBounceSDK` stays for the validation key.

The body comes back parsed — a dictionary, an array or a number depending on
the endpoint, and `nil` for the documented empty successes (HTTP 204 and an
empty 200). The two download endpoints hand over CSV text.

```swift
let warmup = ZeroBounceWarmup.shared
warmup.initialize(apiKey: "<YOUR_WARMUP_API_KEY>")

warmup.listSendingAccounts { _ in }
warmup.getEngagementRules { _ in }
warmup.getProgressToday { _ in }

// Add a from-address you run yourself. A standard rule is 0 to 4.
warmup.addSendingAccount(
    fromAddress: "sender@example.com",
    onboardingModel: ZeroBounceWarmup.selfManaged,
    options: ZBWarmupAddSendingAccountOptions(engagementRuleId: 0, ignoreConflict: true)
) { _ in }

// A custom rule: replyPct 5-45, importantPct 5-40, clickPct 0-70 and at most
// importantPct x 1.75. All of it is checked before anything is sent.
warmup.createCustomEngagement(
    cFrom: "sender@example.com", replyPct: 10, importantPct: 20, clickPct: 30
) { _ in }

warmup.downloadSeeds { result in
    if case .Success(let csv) = result { print(csv) }
}

// Pass an email address, not a bare domain: that is what the live API wants.
warmup.checkDomainDmarc(fromAddress: "sender@example.com") { _ in }
```

`testSmtpConfiguration` stores nothing and sends its test message to a
ZeroBounce test recipient, not to `fromAddress`. The live API answers a failed
SMTP login with HTTP 500, which arrives as `ZBError.httpError` with
`statusCode` 500; the password never appears in that message.

## Per-API base URLs

The list evaluator and the Inbox Placement Tester are separate hosts, so
`initialize` alone leaves them pointing at the live API.

```swift
ZeroBounceSDK.shared.setListEvaluatorBaseUrl("https://bulkapi.zerobounce.net/v2/listevaluator")
ZeroBounceSDK.shared.setInboxPlacementBaseUrl("https://bulkapi.zerobounce.net/api/ipt")
```

## Sample App
- You can also clone the repo and access the Sample App inside the project to check out some examples. Just initialize the SDK with your own API key and uncomment the endpoint that you want to test.

## Running Unit Tests

Unit tests are located in `Zero Bounce iOS SDKTests/Zero_Bounce_iOS_SDKTests.swift` and use XCTest with the [Mocker](https://github.com/WeTransfer/Mocker) library for HTTP mocking.

### Option 1: Xcode (Recommended)

1. Open `Zero Bounce iOS SDK.xcworkspace` in Xcode
2. Select the **Zero Bounce iOS SDK** scheme
3. Press **⌘U** (or **Product → Test**)

### Option 2: Command Line (macOS)

**Prerequisites:** macOS with Xcode and CocoaPods installed.

```bash
cd zero-bounce-ios-sdk

# Install dependencies
pod install

# Run tests using Mac Catalyst (no iOS Simulator required)
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

The one test the command above skips is the opt-in live suite, which calls the
real API. To run it, with keys from the environment only:

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

Without `ZEROBOUNCE_LIVE_SPEND` it makes only free calls, and without any key
it does nothing. `ZEROBOUNCE_LIVE_CHANGES=1` makes reversible account changes,
each undone in the same run.

**With iOS Simulator** (requires a simulator runtime from Xcode → Settings → Components). Use a device id that exists on your Mac (`xcrun simctl list devices available`).

Put derived data **outside the repository**. With the default in-repo `build/` directory, copying the **Mocker** test framework into the simulator fails with a wall of `rsync: ... Operation not permitted` errors that look like a build break but are a sandbox problem:

```bash
xcodebuild build-for-testing \
  -workspace "Zero Bounce iOS SDK.xcworkspace" \
  -scheme "Zero Bounce iOS SDK" \
  -sdk iphonesimulator \
  -derivedDataPath /tmp/zb-ios-dd

xcodebuild test-without-building \
  -workspace "Zero Bounce iOS SDK.xcworkspace" \
  -scheme "Zero Bounce iOS SDK" \
  -destination "id=<SIMULATOR_UDID>" \
  -derivedDataPath /tmp/zb-ios-dd
```

If `xcodebuild` reports `CoreSimulator is out of date`, run `xcrun simctl list devices available` once — it reinstalls the matching service — then retry.

### Expected Output

All 25 unit tests should pass:

```
Test Suite 'All tests' passed.
   Executed 25 tests, with 0 failures (0 unexpected) in 0.370 seconds
```

**Any of the following email addresses can be used for testing the API, no credits are charged for these test email addresses:**
* [disposable@example.com](mailto:disposable@example.com)
* [invalid@example.com](mailto:invalid@example.com)
* [valid@example.com](mailto:valid@example.com)
* [toxic@example.com](mailto:toxic@example.com)
* [donotmail@example.com](mailto:donotmail@example.com)
* [spamtrap@example.com](mailto:spamtrap@example.com)
* [abuse@example.com](mailto:abuse@example.com)
* [unknown@example.com](mailto:unknown@example.com)
* [catch_all@example.com](mailto:catch_all@example.com)
* [antispam_system@example.com](mailto:antispam_system@example.com)
* [does_not_accept_mail@example.com](mailto:does_not_accept_mail@example.com)
* [exception_occurred@example.com](mailto:exception_occurred@example.com)
* [failed_smtp_connection@example.com](mailto:failed_smtp_connection@example.com)
* [failed_syntax_check@example.com](mailto:failed_syntax_check@example.com)
* [forcible_disconnect@example.com](mailto:forcible_disconnect@example.com)
* [global_suppression@example.com](mailto:global_suppression@example.com)
* [greylisted@example.com](mailto:greylisted@example.com)
* [leading_period_removed@example.com](mailto:leading_period_removed@example.com)
* [mail_server_did_not_respond@example.com](mailto:mail_server_did_not_respond@example.com)
* [mail_server_temporary_error@example.com](mailto:mail_server_temporary_error@example.com)
* [mailbox_quota_exceeded@example.com](mailto:mailbox_quota_exceeded@example.com)
* [mailbox_not_found@example.com](mailto:mailbox_not_found@example.com)
* [no_dns_entries@example.com](mailto:no_dns_entries@example.com)
* [possible_trap@example.com](mailto:possible_trap@example.com)
* [possible_typo@example.com](mailto:possible_typo@example.com)
* [role_based@example.com](mailto:role_based@example.com)
* [timeout_exceeded@example.com](mailto:timeout_exceeded@example.com)
* [unroutable_ip_address@example.com](mailto:unroutable_ip_address@example.com)
* [free_email@example.com](mailto:free_email@example.com)

## Publish

1. Bump `s.version` in `ZeroBounceSDK.podspec`, commit, tag (`vX.Y.Z`), push tag.
2. **Actions → Publish → Run workflow** with that tag.

Registry: [ZeroBounceSDK on CocoaPods](https://cocoapods.org/pods/ZeroBounceSDK)
