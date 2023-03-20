//
//  Zero_Bounce_iOS_SDKTests.swift
//  Zero Bounce iOS SDKTests
//
//  Created by ZeroBounce on 08/07/2019.
//  Copyright © 2019 ZeroBounce. All rights reserved.
//

import XCTest
import Mocker
@testable import Zero_Bounce_iOS_SDK

class Zero_Bounce_iOS_SDKTests: XCTestCase {
    private let apiKey = "test-api-key"

    override func setUp() {
        ZeroBounceSDK.shared.initialize(apiKey: apiKey)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testGetCredits() {
        let apiEndpoint = URL(
            string: "\(ZeroBounceSDK.shared.apiBaseUrl)/getcredits?api_key=\(ZeroBounceSDK.shared.apiKey!)"
        )!
        let credits = "3000"
        let creditsResponse = ZBCreditsResponse(credits: credits)
        let mockedData = try! JSONEncoder().encode(creditsResponse)
        let mock = Mock(url: apiEndpoint, dataType: .json, statusCode: 200, data: [.get: mockedData])
        mock.register()

        let requestExpectation = expectation(description: "Request should finish")
        ZeroBounceSDK.shared.getCredits() { result in
            defer { requestExpectation.fulfill() }
            switch result {
            case .Success(let response):
                NSLog("getCredits success response=\(response)")
                XCTAssertEqual(response.credits, credits)
            case .Failure(let error):
                NSLog("getCredits failure error=\(String(describing: error))")
                XCTAssertTrue(false)
            }
        }

        wait(for: [requestExpectation], timeout: 60)
    }
}
