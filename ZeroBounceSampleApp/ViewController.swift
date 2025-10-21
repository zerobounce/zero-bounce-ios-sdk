//
//  ViewController.swift
//  ZeroBounceSampleApp
//
//  Created by Andreea Sinescu on 16.03.2023.
//  Copyright © 2023 Mount Software. All rights reserved.
//

import UIKit
import Zero_Bounce_iOS_SDK

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ZeroBounceSDK.shared.initialize(apiKey: "<YOUR_API_KEY>", apiBaseUrl: .API_DEFAULT_URL)
    }
    
    @IBAction func tappedButton(_ sender: Any) {
        getCredits()
//        getApiUsage()
//        validate()
//        validateBatch()
//        findEmail()
//        findDomain()
    }
    
    func getCredits() {
        ZeroBounceSDK.shared.getCredits() { result in
            switch result {
            case .Success(let response):
                NSLog("getCredits success response=\(response)")
                // your implementation
                
            case .Failure(let error):
                NSLog("getCredits failure error=\(String(describing: error))")
                // your implementation
            }
        }
    }
    
    func getApiUsage() {
        /// Get Api Usage for the last 10 days
        let startDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let endDate = Date()
        ZeroBounceSDK.shared.getApiUsage(startDate: startDate, endDate: endDate) { result in
            switch result {
            case .Success(let response):
                NSLog("getApiUsage success response=\(response)")
                // your implementation
                
            case .Failure(let error):
                NSLog("getApiUsage failure error=\(String(describing: error))")
                // your implementation
            }
        }
    }
    
    func validate() {
        let email = "example@example.com"
        ZeroBounceSDK.shared.validate(email: email) { result in
            switch result {
            case .Success(let response):
                NSLog("validate success response=\(response)")
                // your implementation
                
            case .Failure(let error):
                NSLog("validate failure error=\(String(describing: error))")
                // your implementation
            }
        }
    }
    
    func validateBatch() {
        let emails = [
            ["email_address": "example@example.com"],
            ["email_address": "example2@example.com", "ip_address": "1.1.1.1"]
        ]
        ZeroBounceSDK.shared.validateBatch(emails: emails) { result in
            switch result {
            case .Success(let response):
                NSLog("validate success response=\(response)")
                // your implementation
                
            case .Failure(let error):
                NSLog("validate failure error=\(String(describing: error))")
                // your implementation
            }
        }
    }
    
    func findEmail() {
        let domain = "example.com"
        let firstName = "Example"
        ZeroBounceSDK.shared.findEmail(domain: domain, firstName: firstName) { result in
            switch result {
            case .Success(let response):
                NSLog("guessFormat success response=\(response)")
                // your implementation
                
            case .Failure(let error):
                NSLog("guessFormat failure error=\(String(describing: error))")
                // your implementation
            }
        }
    }
    
    func findDomain() {
        let domain = "example.com"
        ZeroBounceSDK.shared.findDomain(domain: domain) { result in
            switch result {
            case .Success(let response):
                NSLog("guessFormat success response=\(response)")
                // your implementation
                
            case .Failure(let error):
                NSLog("guessFormat failure error=\(String(describing: error))")
                // your implementation
            }
        }
    }
}

