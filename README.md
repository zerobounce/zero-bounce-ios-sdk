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
- Validate an email address
```swift
ZeroBounceSDK.shared.validate(email: "<YOUR_API_KEY>", ipAddress: "<OPTIONAL_IP_ADDRESS>") { (result) in
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
- Check how many credits you have left on your account
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