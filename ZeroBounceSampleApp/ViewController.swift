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
        ZeroBounceSDK.shared.initialize(apiKey: "<YOUR_API_KEY>")
    }

    @IBAction func tappedButton(_ sender: Any) {
        getCredits()
        // TODO: Create methods for all the other requests
    }

    func getCredits() {
        ZeroBounceSDK.shared.getCredits() { result in
            switch result {
            case .Success(let response):
                NSLog("getCredits success response=\(response)")
            case .Failure(let error):
                NSLog("getCredits failure error=\(String(describing: error))")
            }
        }
    }
}

