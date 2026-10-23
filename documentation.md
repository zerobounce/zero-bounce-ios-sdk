##### Installation (CocoaPods)
Add the pod to your Podfile
```pod 'ZeroBounceSDK' ```
and run 
```pod install```

#### USAGE
Import the SDK in your file:
```swift
import ZeroBounceSDK
``` 

Initialize the SDK with your api key and preferred api:
```swift 
ZeroBounceSDK.shared.initialize(apiKey: "<YOUR_API_KEY>", apiBaseUrl: .API_DEFAULT_URL)
```

#### Examples
Then you can use any of the SDK methods, for example:
* ####### Validate an email address
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
        case .notInitialized:
            break
        case .decodeError(let messages):
            /// decodeError is used to extract and decode errors and messages 
            /// when they are not part of the response object
            break
        default:
            break
        }
    }
}
```

* ####### Validate up to 100 email addresses using Batch Email Validator
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

* ####### Check how many credits you have left on your account
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

* ####### Check if your email inbox has been active in the past 30, 60, 90, 180, 365, 730 or 1095 days
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

* ####### Check your API usage for a given period of time
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

* ####### The sendfile API allows user to send a file for bulk email validation
```swift
let filePath = File("<FILE_PATH>"); // The csv or txt file
let emailAddressColumn = 3;         // The index of "email" column in the file. Index starts at 1
let firstNameColumn = 3;            // The index of "first name" column in the file
let lastNameColumn = 3;             // The index of "last name" column in the file
let genderColumn = 3;               // The index of "gender" column in the file
let ipAddressColumn = 3;            // The index of "IP address" column in the file
let hasHeaderRow = true;            // If this is `true` the first row is considered as table headers
let returnUrl = "https://domain.com/called/after/processing/request";
let allowPhase2: Bool? = true // optional; [v2 send file](https://www.zerobounce.net/docs/email-validation-api-quickstart/v2-send-file)

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

Bulk base URL is `https://bulkapi.zerobounce.net/v2`. See [v2 send file](https://www.zerobounce.net/docs/email-validation-api-quickstart/v2-send-file), [v2 file status](https://www.zerobounce.net/docs/email-validation-api-quickstart/v2-file-status), [v2 get file](https://www.zerobounce.net/docs/email-validation-api-quickstart/v2-get-file).

* ####### The getfile API allows users to get the validation results file for the file been submitted using sendfile API
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

* ####### Check the status of a file uploaded via "sendFile" method
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

* ####### Deletes the file that was submitted using scoring sendfile API. File can be deleted only when its status is _`Complete`_
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

##### AI Scoring API
* ####### The scoringSendFile API allows user to send a file for bulk email validation
```swift
let filePath = File("<FILE_PATH>"); // The csv or txt file
let emailAddressColumn = 3;         // The index of "email" column in the file. Index starts at 1
let hasHeaderRow = true;            // If this is `true` the first row is considered as table headers
let returnUrl = "https://domain.com/called/after/processing/request";
// allowPhase2 is validation bulk only.

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

* ####### The scoringGetFile API allows users to get the validation results file for the file been submitted using scoringSendFile API
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
    options: ZBGetFileOptions(downloadType: .phase2)
) { result in /* ... */ }
```

* ####### Check the status of a file uploaded via "scoringSendFile" method
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

* ####### Deletes the file that was submitted using scoring scoringSendFile API. File can be deleted only when its status is _`Complete`_
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

#### Running unit tests

Tests live in `Zero Bounce iOS SDKTests/Zero_Bounce_iOS_SDKTests.swift` and use [Mocker](https://github.com/WeTransfer/Mocker) for HTTP mocking.

**From Xcode (recommended)**

1. Run `pod install` in the repo root (CocoaPods).
2. Open **`Zero Bounce iOS SDK.xcworkspace`** (not the `.xcodeproj` alone).
3. Select the **Zero Bounce iOS SDK** scheme and press **⌘U** (Product → Test).

**From the command line**

```bash
cd zero-bounce-ios-sdk
pod install

# iOS Simulator — use a device that exists on your Mac: xcrun simctl list devices available
xcodebuild test \
  -workspace "Zero Bounce iOS SDK.xcworkspace" \
  -scheme "Zero Bounce iOS SDK" \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4' \
  ENABLE_USER_SCRIPT_SANDBOXING=NO

# Mac Catalyst (no iOS Simulator required)
xcodebuild test \
  -workspace "Zero Bounce iOS SDK.xcworkspace" \
  -scheme "Zero Bounce iOS SDK" \
  -destination 'platform=macOS,variant=Mac Catalyst' \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  ENABLE_USER_SCRIPT_SANDBOXING=NO
```

`ENABLE_USER_SCRIPT_SANDBOXING=NO` avoids build failures when embedding **Mocker.framework** into the test bundle under strict Xcode sandboxing. There are **25** unit tests; you should see **TEST SUCCEEDED** and **Executed 25 tests, with 0 failures**.

#### Validate options

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
zb.emailFinderS3File(options: ZBBulkFileJobOptions(fileName: "lists/leads.csv")) { _ in }
zb.domainSearchS3File(
    options: ZBBulkFileJobOptions(
        fileName: "lists/leads.csv",
        removeDuplicates: true,
        returnUrl: "https://example.com/zerobounce-done"
    )
) { _ in }

// SFTP/FTP. The server, path and protocol come from your ZeroBounce settings.
// fileName may be left nil for validateSFTPFile alone, which then uses the
// input bucket from those settings.
zb.validateSFTPFile(options: ZBBulkFileJobOptions()) { _ in }
zb.scoreSFTPFile(options: ZBBulkFileJobOptions(fileName: "my_file.txt")) { _ in }
zb.emailFinderSFTPFile(options: ZBBulkFileJobOptions(fileName: "my_file.txt")) { _ in }
zb.domainSearchSFTPFile(options: ZBBulkFileJobOptions(fileName: "my_file.txt")) { _ in }

// Note the field: this one takes export_path, not export_bucket.
// nil uses the export path from your settings.
zb.exportSFTPFile(fileId: "<FILE_ID>", exportPath: "/exports") { _ in }
```

## Inbox Placement Tester

Runs on its own host, takes the API key on the query string, and sends camelCase
JSON bodies. It spends the account's inbox-test credits.

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

## Per-API base URLs

The list evaluator and the Inbox Placement Tester are separate hosts, so
`initialize` alone leaves them pointing at the live API.

```swift
ZeroBounceSDK.shared.setListEvaluatorBaseUrl("https://bulkapi.zerobounce.net/v2/listevaluator")
ZeroBounceSDK.shared.setInboxPlacementBaseUrl("https://bulkapi.zerobounce.net/api/ipt")
```

## Sample App
- You can also clone the repo and access the Sample App inside the project to check out some examples. Just initialize the SDK with your own API key and uncomment the endpoint that you want to test.

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
