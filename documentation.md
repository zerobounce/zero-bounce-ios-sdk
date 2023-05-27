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

Initialize the SDK with your api key:
```swift 
ZeroBounceSDK.shared.initialize(apiKey: "<YOUR_API_KEY>")
```

#### Examples
Then you can use any of the SDK methods, for example:
* ####### Validate an email address
```swift
let email = "<EMAIL_ADDRESS>"   // The email address you want to validate
let ipAddress = "127.0.0.1"     // The IP Address the email signed up from (Optional)

ZeroBounceSDK.shared.validate(email, ipAddress) { result in
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

* ####### Check if you email inbox has been active in the past 30, 60, 90, 180, 365, 730 or 1095 days
```swift
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

ZeroBounceSDK.shared.getApiUsage(startDate, endDate) { result in
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

ZeroBounceSDK.shared.sendFile(
    filePath,
    emailAddressColumn,
    returnUrl,
    firstNameColumn,
    lastNameColumn,
    genderColumn,
    ipAddressColumn,
    hasHeaderRow) { result in
        switch result {
        case .Success(let response):
            NSLog("sendFile success response=\(response)")
        case .Failure(let error):
            NSLog("sendFile failure error=\(String(describing: error))")
        }
}
```

* ####### The getfile API allows users to get the validation results file for the file been submitted using sendfile API
```swift
let fileId = "<FILE_ID>";    // The returned file ID when calling sendfile API

ZeroBounceSDK.shared.getfile(fileId) { result in
    switch result {
    case .Success(let response):
        NSLog("getfile success response=\(response)")
    case .Failure(let error):
        NSLog("getfile failure error=\(String(describing: error))")
    }
}
```

* ####### Check the status of a file uploaded via "sendFile" method
```swift
let fileId = "<FILE_ID>";    // The returned file ID when calling sendfile API

ZeroBounceSDK.shared.fileStatus(fileId) { result in
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

ZeroBounceSDK.shared.deleteFile(fileId) { result in
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

ZeroBounceSDK.shared.scoringSendFile(
    filePath,
    emailAddressColumn,
    returnUrl,
    hasHeaderRow) { result in
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

ZeroBounceSDK.shared.scoringGetfile(fileId) { result in
    switch result {
    case .Success(let response):
        NSLog("getfile success response=\(response)")
    case .Failure(let error):
        NSLog("getfile failure error=\(String(describing: error))")
    }
}
```

* ####### Check the status of a file uploaded via "scoringSendFile" method
```swift
let fileId = "<FILE_ID>";    // The returned file ID when calling scoringSendFile API

ZeroBounceSDK.shared.scoringFileStatus(fileId) { result in
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

ZeroBounceSDK.shared.scoringDeleteFile(fileId) { result in
    switch result {
    case .Success(let response):
        NSLog("deleteFile success response=\(response)")
    case .Failure(let error):
        NSLog("deleteFile failure error=\(String(describing: error))")
    }
}
```

#### Sample App
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
