## ZeroBounce iOS SDK
This SDK contains methods for interacting easily with ZeroBounce API.
More information about ZeroBounce you can find in the [official documentation](https://www.zerobounce.net/docs/).

### Installation
Add the pod to your Podfile
```pod 'ZeroBounceSDK' ```
and run 
```pod install```

## USAGE
Import the sdk in your file:
```swift
import ZeroBounceSDK
``` 

Initialize the sdk with your api key:
```swift 
ZeroBounceSDK.shared.initialize(apiKey: "<YOUR_API_KEY>")
```

## Examples
Then you can use any of the SDK methods, for example:
* ##### Validate an email address
```swift
let email = "<EMAIL_ADDRESS>"   // The email address you want to validate
let ipAddress = "127.0.0.1"     // The IP Address the email signed up from (Optional)

ZeroBounceSDK.shared.validate(email, ipAddress) { (result) in
    switch (result) {
    case .Success(let response):
        NSLog("validate success response=\(response)")
        break;
    case .Failure(let error):
        NSLog("validate failure error=\(String(describing: error))")
        switch (error) {
        case ZBError.notInitialized:

            break;
        default:
            break;
        }
        break;
    }
}
```

* ##### Check how many credits you have left on your account
```swift
ZeroBounceSDK.shared.getCredits() { (result) in
    switch (result) {
    case .Success(let response):
        NSLog("getCredits success response=\(response)")
        break;
    case .Failure(let error):
        NSLog("getCredits failure error=\(String(describing: error))")
        break;
    }
}
```

* ##### Check your API usage for a given period of time
```swift
let startDate = Date();    // The start date of when you want to view API usage
let endDate = Date();      // The end date of when you want to view API usage

ZeroBounceSDK.shared.getApiUsage(startDate, endDate) { (result) in
    switch (result) {
    case .Success(let response):
        NSLog("getApiUsage success response=\(response)")
        break;
    case .Failure(let error):
        NSLog("getApiUsage failure error=\(String(describing: error))")
        break;
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

ZeroBounceSDK.shared.sendFile(
    filePath,
    emailAddressColumn,
    returnUrl,
    firstNameColumn,
    lastNameColumn,
    genderColumn,
    ipAddressColumn,
    hasHeaderRow,
    ) { (result) in
        switch (result) {
        case .Success(let response):
            NSLog("sendFile success response=\(response)")
            break;
        case .Failure(let error):
            NSLog("sendFile failure error=\(String(describing: error))")
            break;
        }
}
```

* ##### The getfile API allows users to get the validation results file for the file been submitted using sendfile API
```swift
let fileId = "<FILE_ID>";    // The returned file ID when calling sendfile API

ZeroBounceSDK.shared.getfile(fileId) { (result) in
    switch (result) {
    case .Success(let response):
        NSLog("getfile success response=\(response)")
        break;
    case .Failure(let error):
        NSLog("getfile failure error=\(String(describing: error))")
        break;
    }
}
```

* ##### Check the status of a file uploaded via "sendFile" method
```swift
let fileId = "<FILE_ID>";    // The returned file ID when calling sendfile API

ZeroBounceSDK.shared.fileStatus(fileId) { (result) in
    switch (result) {
    case .Success(let response):
        NSLog("fileStatus success response=\(response)")
        break;
    case .Failure(let error):
        NSLog("fileStatus failure error=\(String(describing: error))")
        break;
    }
}
```

* ##### Deletes the file that was submitted using scoring sendfile API. File can be deleted only when its status is _`Complete`_
```swift
let fileId = "<FILE_ID>";    // The returned file ID when calling sendfile API

ZeroBounceSDK.shared.deleteFile(fileId) { (result) in
    switch (result) {
    case .Success(let response):
        NSLog("deleteFile success response=\(response)")
        break;
    case .Failure(let error):
        NSLog("deleteFile failure error=\(String(describing: error))")
        break;
    }
}
```
