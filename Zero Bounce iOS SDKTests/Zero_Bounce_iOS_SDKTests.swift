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
    private var liveSession: URLSession!

    override func setUp() {
        ZeroBounceSDK.shared.initialize(apiKey: apiKey)
        // The SDK no longer uses URLSession.shared, because a shared session
        // cannot refuse a redirect, and URLProtocol.registerClass reaches only
        // that one. Mocker's protocol goes on the SDK's session instead.
        liveSession = ZeroBounceSDK.urlSession
        ZeroBounceSDK.urlSession = ZeroBounceSDK.makeSession(protocolClasses: [MockingURLProtocol.self])
    }

    override func tearDown() {
        ZeroBounceSDK.urlSession = liveSession
        Mocker.removeAll()
    }

    // MARK: Get Credits
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
    
    func testGetCreditsStatusError() {
        let apiEndpoint = URL(
            string: "\(ZeroBounceSDK.shared.apiBaseUrl)/getcredits?api_key=\(ZeroBounceSDK.shared.apiKey!)"
        )!
        let credits = "3000"
        let creditsResponse = ZBCreditsResponse(credits: credits)
        let mockedData = try! JSONEncoder().encode(creditsResponse)
        let mock = Mock(url: apiEndpoint, dataType: .json, statusCode: 400, data: [.get: mockedData])
        mock.register()

        let requestExpectation = expectation(description: "Request should finish")
        ZeroBounceSDK.shared.getCredits() { result in
            defer { requestExpectation.fulfill() }
            switch result {
            case .Success(let response):
                NSLog("getCredits success response=\(response)")
                XCTAssertTrue(false)
                
            case .Failure(let error):
                NSLog("getCredits failure error=\(String(describing: error))")
                let text = (error as? LocalizedError)?.errorDescription ?? ""
                XCTAssertLessThan(text.count, 500)
                XCTAssertNil(text.range(of: "<html"))
            }
        }

        wait(for: [requestExpectation], timeout: 60)
    }
    
    // MARK: Get API Usage
    func testGetApiUsage() {
        let startDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let endDate = Date()
        let startString = ZeroBounceSDK.shared.dateFormatter.string(from: startDate)
        let endString = ZeroBounceSDK.shared.dateFormatter.string(from: endDate)
        
        let apiEndpoint = URL(
            string: "\(ZeroBounceSDK.shared.apiBaseUrl)/getapiusage?api_key=\(ZeroBounceSDK.shared.apiKey!)&start_date=\(startString)&end_date=\(endString)"
        )!
        
        let apiUsageResponse = ZBGetApiUsageResponse(
            total: 1, statusValid: 1, statusInvalid: 0, statusCatchAll: 0,
            statusDoNotMail: 0, statusSpamtrap: 0, statusUnknown: 0, subStatusToxic: 0,
            subStatusDisposable: 0, subStatusRoleBased: 0,
            subStatusPossibleTrap: 0, subStatusGlobalSuppression: 0,
            subStatusTimeoutExceeded: 0, subStatusMailServerTemporaryError: 0,
            subStatusMailServerDidNotResponse: 0, subStatusGreyListed: 0,
            subStatusAntiSpamSystem: 0, subStatusDoesNotAcceptMail: 0,
            subStatusExceptionOccurred: 0, subStatusFailedSyntaxCheck: 0,
            subStatusMailboxNotFound: 0, subStatusUnRoutableIpAddress: 0,
            subStatusPossibleTypo: 0, subStatusNoDnsEntries: 0,
            subStatusRoleBasedCatchAll: 0, subStatusMailboxQuotaExceeded: 0,
            subStatusForcibleDisconnect: 0, subStatusFailedSmtpConnection: 0,
            subStatusAcceptAll: 0, subStatusMxForward: 0, subStatusAlternate: 0,
            subStatusAllowed: 0, subStatusBlocked: 0, subStatusGold: 0,
            subStatusRoleBasedAcceptAll: 0, startDate: startString, endDate: endString
        )
        
        let mockedData = try! JSONEncoder().encode(apiUsageResponse)
        let mock = Mock(url: apiEndpoint, dataType: .json, statusCode: 200, data: [.get: mockedData])
        mock.register()

        let requestExpectation = expectation(description: "Request should finish")
        ZeroBounceSDK.shared.getApiUsage(startDate: startDate, endDate: endDate) { result in
            defer { requestExpectation.fulfill() }
            switch result {
            case .Success(let response):
                NSLog("getApiUsage success response=\(response)")
                XCTAssertEqual(response, apiUsageResponse)
                
            case .Failure(let error):
                NSLog("getApiUsage failure error=\(String(describing: error))")
                XCTAssertTrue(false)
            }
        }

        wait(for: [requestExpectation], timeout: 60)
    }
    
    // MARK: Get Activity Data
    func testGetActivityData() {
        let email = "example@gmail.com"
        let apiEndpoint = URL(
            string: "\(ZeroBounceSDK.shared.apiBaseUrl)/activity?api_key=\(ZeroBounceSDK.shared.apiKey!)&email=\(email)"
        )!
        let activityResponse = ZBActivityDataResponse(found: true, activeInDays: "20")
        
        let mockedData = try! JSONEncoder().encode(activityResponse)
        let mock = Mock(url: apiEndpoint, dataType: .json, statusCode: 200, data: [.get: mockedData])
        mock.register()

        let requestExpectation = expectation(description: "Request should finish")
        ZeroBounceSDK.shared.getActivityData(email: email) { result in
            defer { requestExpectation.fulfill() }
            switch result {
            case .Success(let response):
                NSLog("getActivityData success response=\(response)")
                XCTAssertEqual(response, activityResponse)
                
            case .Failure(let error):
                NSLog("getActivityData failure error=\(String(describing: error))")
                XCTAssertTrue(false)
            }
        }

        wait(for: [requestExpectation], timeout: 60)
    }

    // MARK: Priority 3
    func testSendEmailFinderFile() {
        let apiEndpoint = URL(string: "\(ZeroBounceSDK.shared.bulkApiRootUrl)/email-finder/sendfile")!
        let sendResponse = ZBSendFileResponse(success: true, message: "", fileName: "out.csv", fileId: "f1")
        let mockedData = try! JSONEncoder().encode(sendResponse)
        let mock = Mock(url: apiEndpoint, dataType: .json, statusCode: 200, data: [.post: mockedData])
        mock.register()

        let csvPath = NSTemporaryDirectory() + "finder-p3.csv"
        try! "domain,name\nacme.com,Jane\n".write(toFile: csvPath, atomically: true, encoding: .utf8)

        // The bulk email finder needs first_name_column or full_name_column.
        var options = ZBEmailFinderSendFileOptions()
        options.firstNameColumn = 2

        let requestExpectation = expectation(description: "Request should finish")
        ZeroBounceSDK.shared.sendEmailFinderFile(filePath: csvPath, domainColumn: 1, options: options) { result in
            defer { requestExpectation.fulfill() }
            switch result {
            case .Success(let response):
                XCTAssertEqual(response.fileId, "f1")
            case .Failure:
                XCTFail("sendEmailFinderFile should succeed")
            }
        }
        wait(for: [requestExpectation], timeout: 60)
    }

    func testValidateS3File() {
        let apiEndpoint = URL(string: "\(ZeroBounceSDK.shared.bulkApiRootUrl)/validateS3file")!
        let sendResponse = ZBSendFileResponse(success: true, message: "", fileName: "", fileId: "s3-1")
        let mockedData = try! JSONEncoder().encode(sendResponse)
        let mock = Mock(url: apiEndpoint, dataType: .json, statusCode: 200, data: [.post: mockedData])
        mock.register()

        let requestExpectation = expectation(description: "Request should finish")
        let options = ZBValidateS3FileOptions(
            fileName: "bucket/key.csv",
            returnUrl: "https://example.com/done"
        )
        ZeroBounceSDK.shared.validateS3File(options: options) { result in
            defer { requestExpectation.fulfill() }
            switch result {
            case .Success(let response):
                XCTAssertEqual(response.fileId, "s3-1")
            case .Failure:
                XCTFail("validateS3File should succeed")
            }
        }
        wait(for: [requestExpectation], timeout: 60)
    }

    func testListS3files() {
        let apiEndpoint = URL(string: "\(ZeroBounceSDK.shared.bulkApiRootUrl)/listS3files")!
        let payload = """
        [{"name":"uploads/list.csv","size":100,"last_modified":"2024-01-01T00:00:00Z"}]
        """.data(using: .utf8)!
        let mock = Mock(url: apiEndpoint, ignoreQuery: true, dataType: .json, statusCode: 200, data: [.get: payload])
        mock.register()

        let requestExpectation = expectation(description: "Request should finish")
        ZeroBounceSDK.shared.listS3files(bucket: "my-bucket", search: "list") { result in
            defer { requestExpectation.fulfill() }
            switch result {
            case .Success(let entries):
                XCTAssertEqual(entries.count, 1)
                XCTAssertEqual(entries[0].name, "uploads/list.csv")
                XCTAssertEqual(entries[0].size, 100)
            case .Failure:
                XCTFail("listS3files should succeed")
            }
        }
        wait(for: [requestExpectation], timeout: 60)
    }

    func testAddFilter() {
        let apiEndpoint = URL(string: "\(ZeroBounceSDK.shared.apiBaseUrl)/filters/add")!
        let mockedData = "{\"success\":true}".data(using: .utf8)!
        let mock = Mock(url: apiEndpoint, dataType: .json, statusCode: 200, data: [.post: mockedData])
        mock.register()

        let requestExpectation = expectation(description: "Request should finish")
        ZeroBounceSDK.shared.addFilter(rule: "allow", target: "email", value: "user@example.com") { result in
            defer { requestExpectation.fulfill() }
            switch result {
            case .Success(let dict):
                XCTAssertEqual(dict["success"] as? Bool, true)
            case .Failure:
                XCTFail("addFilter should succeed")
            }
        }
        wait(for: [requestExpectation], timeout: 60)
    }

    // MARK: Score Email
    func testScoreEmail() {
        let email = "mark@gmail.com"
        let apiEndpoint = URL(
            string: "\(ZeroBounceSDK.shared.apiBaseUrl)/scoring?api_key=\(ZeroBounceSDK.shared.apiKey!)&email=\(email)"
        )!
        let scoreResponse = ZBScoreEmailResponse(email: email, score: 10)

        let mockedData = try! JSONEncoder().encode(scoreResponse)
        let mock = Mock(url: apiEndpoint, dataType: .json, statusCode: 200, data: [.get: mockedData])
        mock.register()

        let requestExpectation = expectation(description: "Request should finish")
        ZeroBounceSDK.shared.scoreEmail(email: email) { result in
            defer { requestExpectation.fulfill() }
            switch result {
            case .Success(let response):
                XCTAssertEqual(response, scoreResponse)
            case .Failure:
                XCTFail("scoreEmail should succeed")
            }
        }

        wait(for: [requestExpectation], timeout: 60)
    }

    func testScoreEmailPost() {
        let email = "mark@gmail.com"
        let apiEndpoint = URL(string: "\(ZeroBounceSDK.shared.apiBaseUrl)/scoring")!
        let scoreResponse = ZBScoreEmailResponse(email: email, score: 10)

        let mockedData = try! JSONEncoder().encode(scoreResponse)
        let mock = Mock(url: apiEndpoint, dataType: .json, statusCode: 200, data: [.post: mockedData])
        mock.register()

        let requestExpectation = expectation(description: "Request should finish")
        ZeroBounceSDK.shared.scoreEmailPost(email: email) { result in
            defer { requestExpectation.fulfill() }
            switch result {
            case .Success(let response):
                XCTAssertEqual(response, scoreResponse)
            case .Failure:
                XCTFail("scoreEmailPost should succeed")
            }
        }

        wait(for: [requestExpectation], timeout: 60)
    }
    
    // MARK: Validate
    // MARK: - sub_status decoding (RD-66)

    private func decodeValidateResponse(status: String, subStatus: String) throws -> ZBValidateResponse {
        let json = """
        {"address":"agent@example.com","status":"\(status)","sub_status":"\(subStatus)"}
        """.data(using: .utf8)!
        return try JSONDecoder().decode(ZBValidateResponse.self, from: json)
    }

    func testSubStatusAiAgentMailboxWithValidStatus() throws {
        let response = try decodeValidateResponse(status: "valid", subStatus: "ai_agent_mailbox")
        XCTAssertEqual(response.status, .valid)
        XCTAssertEqual(response.subStatus, .aiAgentMailbox)
    }

    func testSubStatusAiAgentMailboxWithCatchAllStatus() throws {
        let response = try decodeValidateResponse(status: "catch-all", subStatus: "ai_agent_mailbox")
        XCTAssertEqual(response.status, .catchAll)
        XCTAssertEqual(response.subStatus, .aiAgentMailbox)
    }

    func testUnknownSubStatusDecodesToUnknownInsteadOfThrowing() throws {
        // Before RD-66 this threw DecodingError.dataCorrupted and failed the
        // entire validate response, because synthesised Codable rejects an
        // unrecognised raw value and Optional only covers a missing/null key.
        let response = try decodeValidateResponse(status: "valid", subStatus: "some_future_sub_status")
        XCTAssertEqual(response.status, .valid)
        XCTAssertEqual(response.subStatus, .unknown)
    }

    func testValidate() {
        let email = "example@gmail.com"
        let ipAddress = "1.1.1.1"
        let apiEndpoint = URL(
            string: "\(ZeroBounceSDK.shared.apiBaseUrl)/validate?api_key=\(ZeroBounceSDK.shared.apiKey!)&email=\(email)&ip_address=\(ipAddress)"
        )!
        let validateResponse = ZBValidateResponse(
            address: email, status: .valid, subStatus: nil, account: "",
            domain: "", didYouMean: "", domainAgeDays: "",
            activeInDays: "30", activeFirstSeen: "2024-01-15",
            freeEmail: true, mxFound: true, mxRecord: "",
            smtpProvider: "", catchallDomain: false,
            firstName: nil, lastName: nil, gender: nil,
            city: nil, region: nil, zipCode: nil, country: nil, processedAt: "date",
            domainWebsiteExists: nil, domainRegistrantCompanyName: nil, message: nil
        )
        
        let mockedData = try! JSONEncoder().encode(validateResponse)
        let mock = Mock(url: apiEndpoint, dataType: .json, statusCode: 200, data: [.get: mockedData])
        mock.register()

        let requestExpectation = expectation(description: "Request should finish")
        ZeroBounceSDK.shared.validate(email: email, ipAddress: ipAddress) { result in
            defer { requestExpectation.fulfill() }
            switch result {
            case .Success(let response):
                NSLog("validate success response=\(response)")
                XCTAssertEqual(response, validateResponse)
                
            case .Failure(let error):
                NSLog("validate failure error=\(String(describing: error))")
                XCTAssertTrue(false)
            }
        }

        wait(for: [requestExpectation], timeout: 60)
    }
    
    func testValidateWithError() {
        let email = "example@gmail.com"
        let ipAddress = "1.1.1.1"
        let apiEndpoint = URL(
            string: "\(ZeroBounceSDK.shared.apiBaseUrl)/validate?api_key=\(ZeroBounceSDK.shared.apiKey!)&email=\(email)&ip_address=\(ipAddress)"
        )!
        let validateResponse = ["error": "Error test"]
        
        let mockedData = try! JSONEncoder().encode(validateResponse)
        let mock = Mock(url: apiEndpoint, dataType: .json, statusCode: 200, data: [.get: mockedData])
        mock.register()

        let requestExpectation = expectation(description: "Request should finish")
        ZeroBounceSDK.shared.validate(email: email, ipAddress: ipAddress) { result in
            defer { requestExpectation.fulfill() }
            switch result {
            case .Success(let response):
                NSLog("validate success response=\(response)")
                XCTAssertTrue(false)
                
            case .Failure(let error):
                NSLog("validate failure error=\(String(describing: error))")
                switch error as? ZBError {
                case .httpError(let message, let statusCode):
                    XCTAssertEqual(message, "Error test")
                    XCTAssertEqual(statusCode, 200)

                default:
                    XCTAssertTrue(false)
                }
            }
        }

        wait(for: [requestExpectation], timeout: 60)
    }
    
    func testValidateWithMessage() {
        let email = "example@gmail.com"
        let ipAddress = "1.1.1.1"
        let apiEndpoint = URL(
            string: "\(ZeroBounceSDK.shared.apiBaseUrl)/validate?api_key=\(ZeroBounceSDK.shared.apiKey!)&email=\(email)&ip_address=\(ipAddress)"
        )!
        let validateResponse = ["unexpected_message": "Message"]
        
        let mockedData = try! JSONEncoder().encode(validateResponse)
        let mock = Mock(url: apiEndpoint, dataType: .json, statusCode: 200, data: [.get: mockedData])
        mock.register()

        let requestExpectation = expectation(description: "Request should finish")
        ZeroBounceSDK.shared.validate(email: email, ipAddress: ipAddress) { result in
            defer { requestExpectation.fulfill() }
            switch result {
            case .Success(let response):
                NSLog("validate success response=\(response)")
                XCTAssertTrue(false)
                
            case .Failure(let error):
                NSLog("validate failure error=\(String(describing: error))")
                switch error as? ZBError {
                case .decodeError(let messages):
                    XCTAssertTrue(messages[0] == "Message")
                    
                default:
                    XCTAssertTrue(false)
                }
            }
        }

        wait(for: [requestExpectation], timeout: 60)
    }
    
    // MARK: Validate Batch
    func testValidateBatch() {
        let emails = [["email_address": "example@gmail.com"], ["email_address": "example2@gmail.com", "ip_address": "1.1.1.1"]]
        let apiEndpoint = URL(string: "\(ZeroBounceSDK.shared.apiBaseUrl)/validatebatch")!
        let validateResponse = ZBValidateResponse(
            address: "example@gmail.com", status: .valid, subStatus: nil, account: "",
            domain: "", didYouMean: "", domainAgeDays: "",
            activeInDays: "30", activeFirstSeen: "2024-01-15",
            freeEmail: true, mxFound: true, mxRecord: "",
            smtpProvider: "", catchallDomain: false,
            firstName: nil, lastName: nil, gender: nil,
            city: nil, region: nil, zipCode: nil, country: nil, processedAt: "date",
            domainWebsiteExists: nil, domainRegistrantCompanyName: nil, message: nil
        )
        let validateBatchResponse = ZBValidateBatchResponse(emailBatch: [validateResponse], errors: [])
        
        let mockedData = try! JSONEncoder().encode(validateBatchResponse)
        let mock = Mock(url: apiEndpoint, dataType: .json, statusCode: 200, data: [.post: mockedData])
        mock.register()

        let requestExpectation = expectation(description: "Request should finish")
        ZeroBounceSDK.shared.validateBatch(emails: emails) { result in
            defer { requestExpectation.fulfill() }
            switch result {
            case .Success(let response):
                NSLog("validate success response=\(response)")
                XCTAssertEqual(response , validateBatchResponse)
                
            case .Failure(let error):
                NSLog("validate failure error=\(String(describing: error))")
                XCTAssertTrue(false)
            }
        }

        wait(for: [requestExpectation], timeout: 60)
    }
    
    func testValidateBatchDecodeError() {
        let emails = [["email_address": "example@gmail.com"], ["email_address": "example2@gmail.com", "ip_address": "1.1.1.1"]]
        let apiEndpoint = URL(string: "\(ZeroBounceSDK.shared.apiBaseUrl)/validatebatch")!
        
        let mock = Mock(url: apiEndpoint, dataType: .json, statusCode: 200, data: [.post: Data()])
        mock.register()

        let requestExpectation = expectation(description: "Request should finish")
        ZeroBounceSDK.shared.validateBatch(emails: emails) { result in
            defer { requestExpectation.fulfill() }
            switch result {
            case .Success(let response):
                NSLog("validate success response=\(response)")
                XCTAssertTrue(false)
                
            case .Failure(let error):
                NSLog("validate failure error=\(String(describing: error))")
                // An empty 200 body is an error, and the status is kept.
                switch error as? ZBError {
                case .httpError(_, let statusCode):
                    XCTAssertEqual(statusCode, 200)

                default:
                    XCTAssertTrue(false)
                }
            }
        }

        wait(for: [requestExpectation], timeout: 60)
    }
    
    func testValidateBatchNotInitializedError() {
        let emails = [["email_address": "example@gmail.com"], ["email_address": "example2@gmail.com", "ip_address": "1.1.1.1"]]
        ZeroBounceSDK.shared.apiKey = nil
        let apiEndpoint = URL(string: "\(ZeroBounceSDK.shared.apiBaseUrl)/validatebatch")!
        
        let validateBatchResponse = ZBValidateBatchResponse(emailBatch: [], errors: [])
        let mockedData = try! JSONEncoder().encode(validateBatchResponse)
        let mock = Mock(url: apiEndpoint, dataType: .json, statusCode: 200, data: [.post: mockedData])
        mock.register()

        let requestExpectation = expectation(description: "Request should finish")
        ZeroBounceSDK.shared.validateBatch(emails: emails) { result in
            defer { requestExpectation.fulfill() }
            switch result {
            case .Success(let response):
                NSLog("validate success response=\(response)")
                XCTAssertTrue(false)
                
            case .Failure(let error):
                NSLog("validate failure error=\(String(describing: error))")
                switch error as? ZBError {
                case .notInitialized:
                    XCTAssertTrue(true)
                    
                default:
                    XCTAssertTrue(false)
                }
            }
        }

        wait(for: [requestExpectation], timeout: 60)
    }
    
    // MARK: Email finder
    func testFindEmail() {
        let domain = "example.com"
        let firstName = "Example"
        
        let apiEndpointDomain = URL(
            string: "\(ZeroBounceSDK.shared.apiBaseUrl)/guessformat?api_key=\(apiKey)&domain=\(domain)&first_name=\(firstName)"
        )!
        let emailFinderDomainResponse = ZBEmailFinderResponse(
            email: "example@example.com", emailConfidence: .medium, domain: domain,
            companyName: "", didYouMean: "", failureReason: ""
        )
        
        let mockedDataDomain = try! JSONEncoder().encode(emailFinderDomainResponse)
        let mockDomain = Mock(url: apiEndpointDomain, dataType: .json, statusCode: 200, data: [.get: mockedDataDomain])
        mockDomain.register()

        let domainRequestExpectation = expectation(description: "Request should finish")
        ZeroBounceSDK.shared.findEmail(domain: domain, firstName: firstName) { result in
            defer { domainRequestExpectation.fulfill() }
            switch result {
            case .Success(let response):
                NSLog("guessFormat success response=\(response)")
                XCTAssertEqual(response, emailFinderDomainResponse)
                
            case .Failure(let error):
                NSLog("guessFormat failure error=\(String(describing: error))")
                XCTAssertTrue(false)
            }
        }

        wait(for: [domainRequestExpectation], timeout: 60)
    }
    
    /// first_name is optional on /guessformat, so a last name alone is a
    /// valid email finder search and parses the same response.
    func testFindEmailWithoutAFirstName() {
        let domain = "example.com"

        let apiEndpointDomain = URL(
            string: "\(ZeroBounceSDK.shared.apiBaseUrl)/guessformat?api_key=\(apiKey)&domain=\(domain)&last_name=Doe"
        )!
        let expected = ZBEmailFinderResponse(
            email: "jdoe@example.com", emailConfidence: .high, domain: domain,
            companyName: "", didYouMean: "", failureReason: ""
        )
        let mockedData = try! JSONEncoder().encode(expected)
        Mock(url: apiEndpointDomain, dataType: .json, statusCode: 200, data: [.get: mockedData]).register()

        let requestExpectation = expectation(description: "Request should finish")
        ZeroBounceSDK.shared.findEmail(domain: domain, lastName: "Doe") { result in
            defer { requestExpectation.fulfill() }
            switch result {
            case .Success(let response):
                XCTAssertEqual(response, expected)
            case .Failure(let error):
                XCTFail("findEmail without a first name should succeed: \(error)")
            }
        }

        wait(for: [requestExpectation], timeout: 60)
    }

    // MARK: Domain search
    func testFindDomain() {
        let domain = "example.com"
        
        let apiEndpointDomain = URL(
            string: "\(ZeroBounceSDK.shared.apiBaseUrl)/guessformat?api_key=\(apiKey)&domain=\(domain)"
        )!
        let domainSearchDomainResponse = ZBDomainSearchResponse(
            domain: domain, companyName: "", format: "first",
            confidence: .medium, didYouMean: "", failureReason: "",
            otherDomainFormats: [
                ZBDomainFormat(format: "first.last", confidence: .medium),
                ZBDomainFormat(format: "firstl", confidence: .low),
                ZBDomainFormat(format: "last_first", confidence: .unknown)
            ]
        )

        let mockedDataDomain = try! JSONEncoder().encode(domainSearchDomainResponse)
        let mockDomain = Mock(url: apiEndpointDomain, dataType: .json, statusCode: 200, data: [.get: mockedDataDomain])
        mockDomain.register()

        let domainRequestExpectation = expectation(description: "Request should finish")
        ZeroBounceSDK.shared.findDomain(domain: domain) { result in
            defer { domainRequestExpectation.fulfill() }
            switch result {
            case .Success(let response):
                NSLog("guessFormat success response=\(response)")
                XCTAssertEqual(response, domainSearchDomainResponse)
                
            case .Failure(let error):
                NSLog("guessFormat failure error=\(String(describing: error))")
                XCTAssertTrue(false)
            }
        }

        wait(for: [domainRequestExpectation], timeout: 60)
    }
    
    // MARK: File Status
    func testFileStatus() {
        let fileId = "file_id"
        let apiEndpoint = URL(
            string: "\(ZeroBounceSDK.shared.bulkApiBaseUrl)/filestatus?api_key=\(ZeroBounceSDK.shared.apiKey!)&file_id=\(fileId)"
        )!
        
        let fileStatusResponse = ZBFileStatusResponse(
            success: true, message: nil, fileId: "fileId", fileName: "fileName",
            uploadDate: "date", fileStatus: "Completed",
            filePhase2Status: "N/A",
            completePercentage: "100%", errorReason: nil, returnUrl: nil
        )

        let mockedData = try! JSONEncoder().encode(fileStatusResponse)
        let mock = Mock(url: apiEndpoint, dataType: .json, statusCode: 200, data: [.get: mockedData])
        mock.register()

        let requestExpectation = expectation(description: "Request should finish")
        ZeroBounceSDK.shared.fileStatus(fileId: fileId) { result in
            defer { requestExpectation.fulfill() }
            switch result {
            case .Success(let response):
                NSLog("validate success response=\(response)")
                XCTAssertEqual(response, fileStatusResponse)
                
            case .Failure(let error):
                NSLog("validate failure error=\(String(describing: error))")
                XCTAssertTrue(false)
            }
        }

        wait(for: [requestExpectation], timeout: 60)
    }
    
    func testScoringFileStatus() {
        let fileId = "file_id"
        let apiEndpoint = URL(
            string: "\(ZeroBounceSDK.shared.bulkApiScoringBaseUrl)/filestatus?api_key=\(ZeroBounceSDK.shared.apiKey!)&file_id=\(fileId)"
        )!
        
        let fileStatusResponse = ZBFileStatusResponse(
            success: true, message: nil, fileId: "fileId", fileName: "fileName",
            uploadDate: "date", fileStatus: "Completed",
            filePhase2Status: nil,
            completePercentage: "100%", errorReason: nil, returnUrl: nil
        )

        let mockedData = try! JSONEncoder().encode(fileStatusResponse)
        let mock = Mock(url: apiEndpoint, dataType: .json, statusCode: 200, data: [.get: mockedData])
        mock.register()

        let requestExpectation = expectation(description: "Request should finish")
        ZeroBounceSDK.shared.scoringFileStatus(fileId: fileId) { result in
            defer { requestExpectation.fulfill() }
            switch result {
            case .Success(let response):
                NSLog("validate success response=\(response)")
                XCTAssertEqual(response, fileStatusResponse)
                
            case .Failure(let error):
                NSLog("validate failure error=\(String(describing: error))")
                XCTAssertTrue(false)
            }
        }

        wait(for: [requestExpectation], timeout: 60)
    }
    
    // MARK: Delete File
    func testDeleteFile() {
        let fileId = "file_id"
        let apiEndpoint = URL(
            string: "\(ZeroBounceSDK.shared.bulkApiBaseUrl)/deletefile?api_key=\(ZeroBounceSDK.shared.apiKey!)&file_id=\(fileId)"
        )!
        
        let fileDeleteResponse = ZBDeleteFileResponse(success: true, message: nil, fileName: fileId, fileId: fileId)
        let mockedData = try! JSONEncoder().encode(fileDeleteResponse)
        let mock = Mock(url: apiEndpoint, dataType: .json, statusCode: 200, data: [.get: mockedData])
        mock.register()

        let requestExpectation = expectation(description: "Request should finish")
        ZeroBounceSDK.shared.deleteFile(fileId: fileId) { result in
            defer { requestExpectation.fulfill() }
            switch result {
            case .Success(let response):
                NSLog("validate success response=\(response)")
                XCTAssertEqual(response, fileDeleteResponse)
                
            case .Failure(let error):
                NSLog("validate failure error=\(String(describing: error))")
                XCTAssertTrue(false)
            }
        }

        wait(for: [requestExpectation], timeout: 60)
    }
    
    func testScoringDeleteFile() {
        let fileId = "file_id"
        let apiEndpoint = URL(
            string: "\(ZeroBounceSDK.shared.bulkApiScoringBaseUrl)/deletefile?api_key=\(ZeroBounceSDK.shared.apiKey!)&file_id=\(fileId)"
        )!
        
        let fileDeleteResponse = ZBDeleteFileResponse(success: true, message: nil, fileName: fileId, fileId: fileId)
        let mockedData = try! JSONEncoder().encode(fileDeleteResponse)
        let mock = Mock(url: apiEndpoint, dataType: .json, statusCode: 200, data: [.get: mockedData])
        mock.register()

        let requestExpectation = expectation(description: "Request should finish")
        ZeroBounceSDK.shared.scoringDeleteFile(fileId: fileId) { result in
            defer { requestExpectation.fulfill() }
            switch result {
            case .Success(let response):
                NSLog("validate success response=\(response)")
                XCTAssertEqual(response, fileDeleteResponse)
                
            case .Failure(let error):
                NSLog("validate failure error=\(String(describing: error))")
                XCTAssertTrue(false)
            }
        }

        wait(for: [requestExpectation], timeout: 60)
    }
    
    // MARK: Get File
    func testGetFile() {
        let fileId = "fileId"
        let apiEndpoint = URL(
            string: "\(ZeroBounceSDK.shared.bulkApiBaseUrl)/getfile?api_key=\(ZeroBounceSDK.shared.apiKey!)&file_id=\(fileId)"
        )!
        
        // getfile answers with the file itself; a JSON body or content type
        // would be an error. Mocker has no text/csv, so a download type.
        let mockedData = Data("email,status\nexample@gmail.com,valid\n".utf8)
        let mock = Mock(url: apiEndpoint, dataType: .zip, statusCode: 200, data: [.get: mockedData])
        mock.register()

        let requestExpectation = expectation(description: "Request should finish")
        ZeroBounceSDK.shared.getFile(fileId: fileId) { result in
            defer { requestExpectation.fulfill() }
            switch result {
            case .Success(let response):
                NSLog("validate success response=\(response)")
                XCTAssertTrue(response.localFilePath != nil)
                
            case .Failure(let error):
                NSLog("validate failure error=\(String(describing: error))")
                XCTAssertTrue(false)
            }
        }

        wait(for: [requestExpectation], timeout: 60)
    }
    
    func testScoringGetFile() {
        let fileId = "fileId"
        let apiEndpoint = URL(
            string: "\(ZeroBounceSDK.shared.bulkApiScoringBaseUrl)/getfile?api_key=\(ZeroBounceSDK.shared.apiKey!)&file_id=\(fileId)"
        )!
        
        // getfile answers with the file itself; a JSON body or content type
        // would be an error. Mocker has no text/csv, so a download type.
        let mockedData = Data("email,status\nexample@gmail.com,valid\n".utf8)
        let mock = Mock(url: apiEndpoint, dataType: .zip, statusCode: 200, data: [.get: mockedData])
        mock.register()

        let requestExpectation = expectation(description: "Request should finish")
        ZeroBounceSDK.shared.scoringGetFile(fileId: fileId) { result in
            defer { requestExpectation.fulfill() }
            switch result {
            case .Success(let response):
                NSLog("validate success response=\(response)")
                XCTAssertTrue(response.localFilePath != nil)
                
            case .Failure(let error):
                NSLog("validate failure error=\(String(describing: error))")
                XCTAssertTrue(false)
            }
        }

        wait(for: [requestExpectation], timeout: 60)
    }
    
    // MARK: Send File
    func testSendFile() {
        let bundle = Bundle(for: type(of: self))
        let filePath = bundle.path(forResource: "test", ofType: "txt")!
        let apiEndpoint = URL(string: "\(ZeroBounceSDK.shared.bulkApiBaseUrl)/sendfile")!
        
        let sendFileResponse = ZBSendFileResponse(success: true, message: nil, fileName: "fileName", fileId: "fileId")
        let mockedData = try! JSONEncoder().encode(sendFileResponse)
        let mock = Mock(url: apiEndpoint, dataType: .json, statusCode: 200, data: [.post: mockedData])
        mock.register()

        let requestExpectation = expectation(description: "Request should finish")
        ZeroBounceSDK.shared.sendFile(filePath: filePath, emailAddressColumn: 1) { result in
            defer { requestExpectation.fulfill() }
            switch result {
            case .Success(let response):
                NSLog("validate success response=\(response)")
                XCTAssertEqual(response, sendFileResponse)
                
            case .Failure(let error):
                NSLog("validate failure error=\(String(describing: error))")
                XCTAssertTrue(false)
            }
        }

        wait(for: [requestExpectation], timeout: 60)
    }
    
    func testSendFileNotInitializedError() {
        ZeroBounceSDK.shared.apiKey = nil
        let bundle = Bundle(for: type(of: self))
        let filePath = bundle.path(forResource: "test", ofType: "txt")!
        let apiEndpoint = URL(string: "\(ZeroBounceSDK.shared.bulkApiBaseUrl)/sendfile")!
        
        let sendFileResponse = ZBSendFileResponse(success: false, message: nil, fileName: "fileName", fileId: "fileId")
        let mockedData = try! JSONEncoder().encode(sendFileResponse)
        let mock = Mock(url: apiEndpoint, dataType: .json, statusCode: 200, data: [.post: mockedData])
        mock.register()

        let requestExpectation = expectation(description: "Request should finish")
        ZeroBounceSDK.shared.sendFile(filePath: filePath, emailAddressColumn: 1) { result in
            defer { requestExpectation.fulfill() }
            switch result {
            case .Success(let response):
                NSLog("validate success response=\(response)")
                XCTAssertTrue(false)
                
            case .Failure(let error):
                NSLog("validate failure error=\(String(describing: error))")
                switch error as? ZBError {
                case .notInitialized:
                    XCTAssertTrue(true)
                    
                default:
                    XCTAssertTrue(false)
                }
            }
        }

        wait(for: [requestExpectation], timeout: 60)
    }
    
    func testScoringSendFile() {
        let bundle = Bundle(for: type(of: self))
        let filePath = bundle.path(forResource: "test", ofType: "txt")!
        let apiEndpoint = URL(string: "\(ZeroBounceSDK.shared.bulkApiScoringBaseUrl)/sendfile")!
        
        let sendFileResponse = ZBSendFileResponse(success: true, message: nil, fileName: "fileName", fileId: "fileId")
        let mockedData = try! JSONEncoder().encode(sendFileResponse)
        let mock = Mock(url: apiEndpoint, dataType: .json, statusCode: 200, data: [.post: mockedData])
        mock.register()

        let requestExpectation = expectation(description: "Request should finish")
        ZeroBounceSDK.shared.scoringSendFile(filePath: filePath, emailAddressColumn: 1) { result in
            defer { requestExpectation.fulfill() }
            switch result {
            case .Success(let response):
                NSLog("validate success response=\(response)")
                XCTAssertEqual(response, sendFileResponse)
                
            case .Failure(let error):
                NSLog("validate failure error=\(String(describing: error))")
                XCTAssertTrue(false)
            }
        }

        wait(for: [requestExpectation], timeout: 60)
    }
    
    func testScoringSendFileNotInitializedError() {
        ZeroBounceSDK.shared.apiKey = nil
        let bundle = Bundle(for: type(of: self))
        let filePath = bundle.path(forResource: "test", ofType: "txt")!
        let apiEndpoint = URL(string: "\(ZeroBounceSDK.shared.bulkApiScoringBaseUrl)/sendfile")!
        
        let sendFileResponse = ZBSendFileResponse(success: false, message: nil, fileName: "fileName", fileId: "fileId")
        let mockedData = try! JSONEncoder().encode(sendFileResponse)
        let mock = Mock(url: apiEndpoint, dataType: .json, statusCode: 200, data: [.post: mockedData])
        mock.register()

        let requestExpectation = expectation(description: "Request should finish")
        ZeroBounceSDK.shared.scoringSendFile(filePath: filePath, emailAddressColumn: 1) { result in
            defer { requestExpectation.fulfill() }
            switch result {
            case .Success(let response):
                NSLog("validate success response=\(response)")
                XCTAssertTrue(false)
                
            case .Failure(let error):
                NSLog("validate failure error=\(String(describing: error))")
                switch error as? ZBError {
                case .notInitialized:
                    XCTAssertTrue(true)
                    
                default:
                    XCTAssertTrue(false)
                }
            }
        }

        wait(for: [requestExpectation], timeout: 60)
    }
    
    func testGetFileJsonErrorWithHttp200() {
        let fileId = "fileId"
        let apiKey = ZeroBounceSDK.shared.apiKey!
        var comp = URLComponents(string: "\(ZeroBounceSDK.shared.bulkApiBaseUrl)/getfile")
        comp?.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "file_id", value: fileId)
        ]
        let apiEndpoint = comp!.url!
        let errJson = "{\"success\":false,\"message\":\"Phase 2 download types are only available when phase 2 is enabled for this file.\"}".data(using: .utf8)!
        let mock = Mock(url: apiEndpoint, dataType: .json, statusCode: 200, data: [.get: errJson])
        mock.register()

        let requestExpectation = expectation(description: "Request should finish")
        ZeroBounceSDK.shared.getFile(fileId: fileId) { result in
            defer { requestExpectation.fulfill() }
            switch result {
            case .Success:
                XCTFail("expected failure")
            case .Failure(let error):
                guard let zbe = error as? ZBError else {
                    XCTFail("wrong error type")
                    return
                }
                // LIVE: a "success": false field on an HTTP 200 is a
                // failure, and the status it came back with is kept.
                guard case .httpError(let message, let statusCode) = zbe else {
                    XCTFail("expected httpError")
                    return
                }
                XCTAssertTrue(message.contains("Phase 2"), message)
                XCTAssertEqual(statusCode, 200)
            }
        }
        wait(for: [requestExpectation], timeout: 60)
    }
    
    func testGetFileWithOptions_IncludesDownloadTypeAndActivityData() {
        let fileId = "abc-id"
        let apiKey = ZeroBounceSDK.shared.apiKey!
        var comp = URLComponents(string: "\(ZeroBounceSDK.shared.bulkApiBaseUrl)/getfile")
        comp?.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "file_id", value: fileId),
            URLQueryItem(name: "download_type", value: "combined"),
            URLQueryItem(name: "activity_data", value: "true")
        ]
        let apiEndpoint = comp!.url!
        // getfile answers with the file itself; a JSON body or content type
        // would be an error. Mocker has no text/csv, so a download type.
        let mockedData = Data("email,status\nexample@gmail.com,valid\n".utf8)
        let mock = Mock(url: apiEndpoint, dataType: .zip, statusCode: 200, data: [.get: mockedData])
        mock.register()

        let requestExpectation = expectation(description: "Request should finish")
        let opts = ZBGetFileOptions(downloadType: .combined, activityData: true)
        ZeroBounceSDK.shared.getFile(fileId: fileId, options: opts) { result in
            defer { requestExpectation.fulfill() }
            switch result {
            case .Success(let response):
                XCTAssertNotNil(response.localFilePath)
            case .Failure:
                XCTFail("unexpected failure")
            }
        }
        wait(for: [requestExpectation], timeout: 60)
    }
    
    func testScoringGetFileWithOptions_DoesNotAppendActivityData() {
        let fileId = "id-1"
        let apiKey = ZeroBounceSDK.shared.apiKey!
        var comp = URLComponents(string: "\(ZeroBounceSDK.shared.bulkApiScoringBaseUrl)/getfile")
        comp?.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "file_id", value: fileId),
            URLQueryItem(name: "download_type", value: "phase_2")
        ]
        let apiEndpoint = comp!.url!
        // getfile answers with the file itself; a JSON body or content type
        // would be an error. Mocker has no text/csv, so a download type.
        let mockedData = Data("email,status\nexample@gmail.com,valid\n".utf8)
        let mock = Mock(url: apiEndpoint, dataType: .zip, statusCode: 200, data: [.get: mockedData])
        mock.register()

        let requestExpectation = expectation(description: "Request should finish")
        let opts = ZBGetFileOptions(downloadType: .phase2, activityData: true)
        ZeroBounceSDK.shared.scoringGetFile(fileId: fileId, options: opts) { result in
            defer { requestExpectation.fulfill() }
            switch result {
            case .Success(let response):
                XCTAssertNotNil(response.localFilePath)
            case .Failure:
                XCTFail("unexpected failure")
            }
        }
        wait(for: [requestExpectation], timeout: 60)
    }
}

struct OfflineRecord {
    let method: String
    let host: String
    /// `URL.path` is percent-decoded, so a %2F in a segment reads as a slash.
    let path: String
    /// The percent-encoded path, which is what goes on the wire.
    let rawPath: String
    let apiKey: String
    let query: String
    let body: String
    /// The Authorization or API-Key header the request carried, or "".
    let authHeader: String
    /// The timeout the request was built with.
    let timeout: TimeInterval
}

/// A secret as JSON serializers write it inside a string, worked out
/// apart from the SDK's own list: Foundation's (`\"` and `\/`), the same
/// without `\/`, and .NET's System.Text.Json (`"`, `+`, `<`, `>`, `&`, `'`
/// and non-ASCII as `\uXXXX`) in upper and lower case hex.
func jsonEscapedEchoes(_ secret: String) -> [String] {
    var forms: [String] = []
    if let data = try? JSONSerialization.data(withJSONObject: [secret]),
       let text = String(data: data, encoding: .utf8) {
        let inner = String(text.dropFirst(2).dropLast(2))
        forms.append(inner)
        forms.append(inner.replacingOccurrences(of: "\\/", with: "/"))
    }
    for format in ["\\u%04X", "\\u%04x"] {
        var dotnet = ""
        for unit in secret.utf16 {
            if unit == 0x5C {
                dotnet += "\\\\"
            } else if unit < 0x20 || unit > 0x7E || "\"+<>&'`".utf16.contains(unit) {
                dotnet += String(format: format, UInt32(unit))
            } else {
                dotnet += String(UnicodeScalar(UInt8(unit)))
            }
        }
        forms.append(dotnet)
    }
    return forms
}

final class OfflineURLProtocol: URLProtocol {
    static var enabled = false
    static var records: [OfflineRecord] = []
    static let lock = NSLock()

    override class func canInit(with request: URLRequest) -> Bool { enabled }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let url = request.url!
        let method = request.httpMethod ?? "GET"
        let bodyData = OfflineURLProtocol.bodyData(from: request)
        let body = String(data: bodyData, encoding: .utf8) ?? ""
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        func query(_ name: String) -> String {
            items.first { $0.name == name }?.value ?? ""
        }
        var apiKey = query("api_key")
        if apiKey.isEmpty, let range = body.range(of: "api_key=") {
            let rest = body[range.upperBound...]
            apiKey = String(rest.prefix { $0 != "&" }).removingPercentEncoding ?? ""
        }
        if apiKey.isEmpty, let data = body.data(using: .utf8),
           let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let key = object["api_key"] as? String {
            apiKey = key
        }
        if apiKey.isEmpty, let range = body.range(of: "name=\"api_key\"") {
            let rest = body[range.upperBound...]
            // A multipart value ends at the CRLF before the next boundary.
            // Swift reads "\r\n" as one Character, so the terminator has to be
            // searched for rather than scanned past one scalar at a time.
            if let blank = rest.range(of: "\r\n\r\n"),
               let end = rest[blank.upperBound...].range(of: "\r\n") {
                apiKey = String(rest[blank.upperBound..<end.lowerBound])
            }
        }
        // The Inbox Placement Tester and the Warmup API carry the key in a
        // header instead of a parameter.
        var authHeader = ""
        if let bearer = request.value(forHTTPHeaderField: "Authorization") {
            authHeader = bearer
            if apiKey.isEmpty, bearer.hasPrefix("Bearer ") {
                apiKey = String(bearer.dropFirst(7))
            }
        } else if let warmup = request.value(forHTTPHeaderField: "API-Key") {
            authHeader = "API-Key: " + warmup
            if apiKey.isEmpty { apiKey = warmup }
        }
        let record = OfflineRecord(
            method: method,
            host: url.host ?? "",
            path: url.path,
            rawPath: URLComponents(url: url, resolvingAgainstBaseURL: false)?.percentEncodedPath ?? url.path,
            apiKey: apiKey,
            query: url.query ?? "",
            body: body,
            authHeader: authHeader,
            timeout: request.timeoutInterval
        )
        OfflineURLProtocol.lock.lock()
        OfflineURLProtocol.records.append(record)
        OfflineURLProtocol.lock.unlock()
        usleep(UInt32(Int.random(in: 0...20) * 1000))

        // A redirect to another host. Handed to the session the way a real
        // HTTP loader would, so a session that follows it sends a second
        // request, to /followed, which is recorded like any other.
        if apiKey.hasPrefix("redirect-") && !url.path.hasPrefix("/followed") {
            let target = URL(string: "https://elsewhere.example/followed?api_key=\(apiKey)")!
            let redirect = HTTPURLResponse(url: url, statusCode: 302, httpVersion: "HTTP/1.1", headerFields: [
                "Location": target.absoluteString
            ])!
            client?.urlProtocol(self, wasRedirectedTo: URLRequest(url: target), redirectResponse: redirect)
            client?.urlProtocol(self, didReceive: redirect, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data())
            client?.urlProtocolDidFinishLoading(self)
            return
        }

        let (status, type, payload) = OfflineURLProtocol.answer(record)
        let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: [
            "Content-Type": type
        ])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: payload)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    private static func bodyData(from request: URLRequest) -> Data {
        if let body = request.httpBody { return body }
        guard let stream = request.httpBodyStream else { return Data() }
        stream.open()
        defer { stream.close() }
        var data = Data()
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 4096)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
            let count = stream.read(buffer, maxLength: 4096)
            if count <= 0 { break }
            data.append(buffer, count: count)
        }
        return data
    }

    private static func htmlPage() -> Data {
        var page = "<!DOCTYPE html><html><head><title>Access denied | zerobounce.net | Zero Bounce</title></head><body>"
        for _ in 0..<20000 { page += "<p>blocked</p>" }
        page += "</body></html>"
        return Data(page.utf8)
    }

    private static func answer(_ request: OfflineRecord) -> (Int, String, Data) {
        let key = request.apiKey
        // A server or proxy that quotes the key back in its error body: as
        // JSON on a 200, as "success": false on a 200, as plain text quoting
        // the request URL (key percent-encoded) on a 400, and as JSON on a 400.
        if key.hasPrefix("echo-") {
            let quotedUrl = "https://\(request.host)\(request.rawPath)?api_key="
                + (key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key)
            func json(_ object: [String: Any]) -> Data {
                (try? JSONSerialization.data(withJSONObject: object)) ?? Data()
            }
            if key.hasPrefix("echo-200-error-") {
                return (200, "application/json", json(["error": "Invalid API key \(key)"]))
            }
            if key.hasPrefix("echo-200-success-false-") {
                return (200, "application/json", json(["success": false, "message": "No file for key \(key)"]))
            }
            if key.hasPrefix("echo-400-text-") {
                return (400, "text/plain", Data("Bad request: \(quotedUrl)".utf8))
            }
            if key.hasPrefix("echo-400-json-") {
                return (400, "application/json", json(["error": "Invalid API key \(key)"]))
            }
            // A plain-text 400 quoting the key, and any SMTP password sent,
            // only in their JSON-escaped forms, as a proxy echoing a JSON
            // request or a serialized error would.
            if key.hasPrefix("echo-400-escaped-") {
                var secrets = [key]
                if let object = try? JSONSerialization.jsonObject(with: Data(request.body.utf8)) as? [String: Any],
                   let password = object["password"] as? String {
                    secrets.append(password)
                }
                let echoes = secrets.flatMap(jsonEscapedEchoes).joined(separator: " ; ")
                return (400, "text/plain", Data("Bad request: \(echoes)".utf8))
            }
        }
        if key.hasPrefix("html-403-") || key.hasPrefix("html-200-") {
            return (key.hasPrefix("html-403-") ? 403 : 200, "text/html", htmlPage())
        }
        if key.hasPrefix("empty-") { return (200, "application/json", Data()) }
        if key.hasPrefix("malformed-") {
            return (200, "application/json", Data(("<<<not-json>>>" + String(repeating: "x", count: 5000)).utf8))
        }
        // LIVE (2026-11-11): what an invalid or drained key gets back, each
        // with an HTTP 200 and no "success" field.
        if key.hasPrefix("dead-key-") {
            let path = request.path
            var body = #"{"error":"Invalid API key or your account ran out of credits"}"#
            if path.contains("guessformat") {
                body = #"{"Message":"Invalid API key or your account ran out of credits"}"#
            } else if path.contains("filters") {
                body = #"{  "Error": "Invalid API key or your account ran out of credits"}"#
            } else if path.contains("getapiusage") {
                body = #"{"error":"Invalid API key"}"#
            } else if path.contains("getcredits") {
                body = #"{"Credits":"-1"}"#
            }
            return (200, "application/json", Data(body.utf8))
        }
        // LIVE: a repeated greylisted validate answers a bare Message while
        // the retry runs. It is a result, not an error.
        if key.hasPrefix("greylist-") && request.path.hasSuffix("/validate") {
            return (200, "application/json",
                    Data(#"{"Message":"Greylist validation still in progress, please try again later."}"#.utf8))
        }
        if key.hasPrefix("filter-message-") && request.path.contains("filters") {
            return (200, "application/json", Data(#"{"Message":"Filter has been added."}"#.utf8))
        }
        if key.hasPrefix("getfile-message-") && request.path.contains("getfile") {
            // What getfile answers while the file is still being processed:
            // a JSON message on an HTTP 200, with a download content type.
            return (200, "application/octet-stream", Data(#"{"message":"File is still processing"}"#.utf8))
        }
        if key.hasPrefix("getfile-Message-") && request.path.contains("getfile") {
            return (200, "application/json", Data(#"{"Message":"File is still processing"}"#.utf8))
        }
        if key.hasPrefix("success-false") {
            return (200, "application/json", Data(#"{"success":false,"message":"File cannot be found."}"#.utf8))
        }
        if key.hasPrefix("cf-json-") {
            let json = #"{"type":"https://developers.cloudflare.com/support/error-1020/","title":"Error 1020: Access denied","status":403,"error_code":1020,"cloudflare_error":true}"#
            return (403, "application/json", Data(json.utf8))
        }
        // A 200 to a download that is not a file but does not look like the
        // usual error: an HTML page whose body has no tags a body check
        // would see, JSON that is not an object, and each kind under the
        // other's content type.
        if key.hasPrefix("dl-html-bare-") {
            return (200, "text/html; charset=UTF-8", Data("<p>Access denied by proxy</p>".utf8))
        }
        if key.hasPrefix("dl-html-plain-") {
            return (200, "text/html", Data("Access denied by proxy".utf8))
        }
        if key.hasPrefix("dl-json-array-") {
            return (200, "application/json", Data(#"["error"]"#.utf8))
        }
        if key.hasPrefix("dl-json-type-") {
            return (200, "application/json; charset=utf-8", Data("email,status\na@example.com,valid\n".utf8))
        }
        if key.hasPrefix("dl-json-csv-") {
            return (200, "text/csv", Data(#"["File is still processing"]"#.utf8))
        }
        if request.path.contains("/api/v1/warmup/") {
            // The Warmup endpoints answer with different shapes: an object, a
            // bare number, and CSV for the two downloads.
            if key.hasPrefix("warm-empty") { return (204, "application/json", Data()) }
            // "warm-echo-<shape>-...": a 200 that is not the JSON or CSV the
            // call expects, quoting the key (as sent, percent-encoded in a
            // URL, JSON-escaped) and the request body with any SMTP password
            // in it, both as sent and as it reads in JSON.
            if key.hasPrefix("warm-echo-") {
                var password = ""
                if let object = try? JSONSerialization.jsonObject(with: Data(request.body.utf8)) as? [String: Any],
                   let value = object["password"] as? String {
                    password = value
                }
                let encoded = key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key
                let echo = "key \(key) url https://\(request.host)\(request.rawPath)?api_key=\(encoded) "
                    + "json \(jsonEscapedEchoes(key).joined(separator: " ")) password \(password) "
                    + "\(jsonEscapedEchoes(password).joined(separator: " ")) body \(request.body)"
                if key.hasPrefix("warm-echo-text-") {
                    return (200, "text/plain", Data("Unexpected request: \(echo)".utf8))
                }
                let page = "<!DOCTYPE html><html><head><title>Denied: \(echo)</title></head><body>\(echo)</body></html>"
                // An HTML page by content type, and one served as CSV.
                return (200, key.hasPrefix("warm-echo-htmlcsv-") ? "text/csv" : "text/html", Data(page.utf8))
            }
            if key.hasPrefix("warm-json-download") {
                return (200, "application/json", Data(#"{"detail":"nothing here"}"#.utf8))
            }
            if key.hasPrefix("warm-500") {
                return (500, "application/json", Data(#"{"detail":"login failed for sekrit"}"#.utf8))
            }
            if key.hasPrefix("warm-404") {
                return (404, "application/json", Data(#"{"detail":"Not found."}"#.utf8))
            }
            if request.path.hasSuffix("/seeds/download") {
                return (200, "text/csv", Data("seed,provider\na@example.com,gmail\n".utf8))
            }
            if request.path.hasSuffix("/statistics/download") {
                return (200, "text/csv", Data("date,sent\n2026-10-01,10\n".utf8))
            }
            if request.path.hasSuffix("/seed-count") {
                return (200, "application/json", Data("42".utf8))
            }
            return (200, "application/json", Data(#"{"ok":true}"#.utf8))
        }
        if key.hasPrefix("ipt-detail") {
            // The Inbox Placement Tester is a Django REST framework app and
            // reports errors under "detail".
            return (404, "application/json", Data(#"{"detail":"Inbox placement test not found."}"#.utf8))
        }
        if key.hasPrefix("ipt-empty-") && request.path.contains("/api/ipt") {
            // "ipt-empty-<status>-...": that status with no body at all, the
            // way a DELETE can answer.
            let status = Int(key.split(separator: "-")[2]) ?? 200
            return (status, "application/json", Data())
        }
        if key.hasPrefix("double-error-") {
            return (400, "text/plain", Data("Error: Error: api_key is invalid".utf8))
        }
        if request.path.contains("validatebatch") && key.hasPrefix("batch-account-") {
            let json = #"{"email_batch":[],"errors":[{"error":"Invalid API Key or your account ran out of credits","email_address":"all"}]}"#
            return (200, "application/json", Data(json.utf8))
        }
        if request.path.contains("validatebatch") && key.hasPrefix("batch-partial-") {
            let json = #"{"email_batch":[{"address":"good@example.com","status":"valid","processed_at":"2010-01-01"}],"errors":[{"error":"Invalid email address","email_address":"bad@"}]}"#
            return (200, "application/json", Data(json.utf8))
        }
        if request.path.contains("getfile") {
            return (200, "application/octet-stream", Data("email\n\(key)@example.com\n".utf8))
        }
        if request.path.contains("getcredits") {
            return (200, "application/json", Data("{\"Credits\":\"7\"}".utf8))
        }
        if request.path.hasSuffix("/validate") {
            let json = "{\"address\":\"\(key)\",\"status\":\"valid\",\"processed_at\":\"2010-01-01\"}"
            return (200, "application/json", Data(json.utf8))
        }
        if request.path.contains("validatebatch") {
            let json = "{\"email_batch\":[{\"address\":\"\(key)\",\"status\":\"valid\",\"processed_at\":\"2010-01-01\"}],\"errors\":[]}"
            return (200, "application/json", Data(json.utf8))
        }
        if request.path.contains("/scoring") && !request.path.contains("sendfile") && !request.path.contains("getfile") {
            let json = "{\"email\":\"\(key)\",\"score\":10}"
            return (200, "application/json", Data(json.utf8))
        }
        let json = "{\"success\":true,\"message\":\"ok\",\"file_id\":\"\(key)\",\"file_name\":\"f.csv\",\"email\":\"\(key)\",\"domain\":\"\(key)\"}"
        return (200, "application/json", Data(json.utf8))
    }
}

final class OfflineApiTests: XCTestCase {
    private var liveSession: URLSession!

    override func setUp() {
        super.setUp()
        OfflineURLProtocol.enabled = true
        OfflineURLProtocol.records = []
        URLProtocol.registerClass(OfflineURLProtocol.self)
        // The SDK no longer uses URLSession.shared, because a shared session
        // cannot refuse a redirect; the stub goes on its session instead.
        liveSession = ZeroBounceSDK.urlSession
        ZeroBounceSDK.urlSession = ZeroBounceSDK.makeSession(protocolClasses: [OfflineURLProtocol.self])
    }

    override func tearDown() {
        OfflineURLProtocol.enabled = false
        URLProtocol.unregisterClass(OfflineURLProtocol.self)
        ZeroBounceSDK.urlSession = liveSession
        super.tearDown()
    }

    private func onlyRequest() -> OfflineRecord {
        XCTAssertEqual(OfflineURLProtocol.records.count, 1)
        return OfflineURLProtocol.records[0]
    }

    private func shortMessage(_ error: Error) -> String {
        let text = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        XCTAssertLessThan(text.count, 500, text)
        XCTAssertNil(text.range(of: "<html"))
        XCTAssertNil(text.range(of: "Error: Error:"))
        return text
    }

    func testOfflineCreditsValidateAndBatch() {
        let sdk = ZeroBounceSDK()
        sdk.initialize(apiKey: "credits-key")
        let exp = expectation(description: "credits")
        sdk.getCredits { result in
            if case .Success(let response) = result {
                XCTAssertEqual(response.credits, "7")
            } else { XCTFail("credits") }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5)
        let credits = onlyRequest()
        XCTAssertEqual(credits.method, "GET")
        XCTAssertEqual(credits.host, "api.zerobounce.net")
        XCTAssertEqual(credits.path, "/v2/getcredits")
        XCTAssertEqual(credits.apiKey, "credits-key")

        OfflineURLProtocol.records = []
        sdk.initialize(apiKey: "validate-key")
        let options = ZBValidateOptions(activityData: false, verifyPlus: true)
        let validate = expectation(description: "validate")
        sdk.validate(email: "person@example.com", ipAddress: "", options: options) { result in
            if case .Success(let response) = result {
                XCTAssertEqual(response.address, "validate-key")
            } else { XCTFail("validate") }
            validate.fulfill()
        }
        wait(for: [validate], timeout: 5)
        let validated = onlyRequest()
        XCTAssertEqual(validated.path, "/v2/validate")
        XCTAssertTrue(validated.query.contains("activity_data=false"))
        XCTAssertTrue(validated.query.contains("verify_plus=true"))
        XCTAssertFalse(validated.query.contains("timeout="))

        OfflineURLProtocol.records = []
        let posted = expectation(description: "post")
        sdk.validate(email: "person@example.com", ipAddress: "203.0.113.5", options: ZBValidateOptions(timeout: 15, usePost: true)) { _ in
            posted.fulfill()
        }
        wait(for: [posted], timeout: 5)
        let post = onlyRequest()
        XCTAssertEqual(post.method, "POST")
        XCTAssertTrue(post.body.contains("timeout=15"))
        XCTAssertFalse(post.body.contains("activity_data"))

        OfflineURLProtocol.records = []
        sdk.initialize(apiKey: "batch-key")
        let batch = expectation(description: "batch")
        sdk.validateBatch(emails: [
            ["email_address": "a@example.com", "ip_address": ""],
            ["email_address": "b@example.com", "ip_address": "203.0.113.9"]
        ]) { result in
            if case .Success(let response) = result {
                XCTAssertEqual(response.emailBatch.first?.address, "batch-key")
            } else { XCTFail("batch") }
            batch.fulfill()
        }
        wait(for: [batch], timeout: 5)
        let batched = onlyRequest()
        XCTAssertEqual(batched.host, "api.zerobounce.net")
        XCTAssertEqual(batched.path, "/v2/validatebatch")
        XCTAssertTrue(batched.body.contains("null"))
        XCTAssertTrue(batched.body.contains("203.0.113.9"))
    }

    func testOfflineErrorsAndSeparateClients() {
        let html = ZeroBounceSDK()
        html.initialize(apiKey: "html-403-user")
        let denied = expectation(description: "403")
        html.getCredits { result in
            if case .Failure(let error) = result {
                let text = self.shortMessage(error)
                XCTAssertTrue(text.contains("Access denied"), text)
            } else { XCTFail("html succeeded") }
            denied.fulfill()
        }
        wait(for: [denied], timeout: 5)

        let page = ZeroBounceSDK()
        page.initialize(apiKey: "html-200-user")
        let html200 = expectation(description: "200")
        page.validate(email: "a@example.com", ipAddress: "") { result in
            if case .Failure(let error) = result {
                XCTAssertTrue(self.shortMessage(error).contains("Access denied"))
            } else { XCTFail("html 200 succeeded") }
            html200.fulfill()
        }
        wait(for: [html200], timeout: 5)

        let empty = ZeroBounceSDK()
        empty.initialize(apiKey: "empty-user")
        let emptyExp = expectation(description: "empty")
        empty.validate(email: "a@example.com", ipAddress: "") { result in
            if case .Failure(let error) = result {
                XCTAssertTrue(self.shortMessage(error).contains("Empty response"))
            } else { XCTFail("empty succeeded") }
            emptyExp.fulfill()
        }
        wait(for: [emptyExp], timeout: 5)

        let bad = ZeroBounceSDK()
        bad.initialize(apiKey: "malformed-user")
        let badExp = expectation(description: "malformed")
        bad.validate(email: "a@example.com", ipAddress: "") { result in
            if case .Failure(let error) = result {
                let text = self.shortMessage(error)
                XCTAssertTrue(text.contains("not valid JSON"), text)
                XCTAssertNil(text.range(of: "<<<not-json>>>"))
            } else { XCTFail("malformed succeeded") }
            badExp.fulfill()
        }
        wait(for: [badExp], timeout: 5)

        let doubled = ZeroBounceSDK()
        doubled.initialize(apiKey: "double-error-user")
        let doubleExp = expectation(description: "double")
        doubled.getActivityData(email: "a@example.com") { result in
            if case .Failure(let error) = result {
                let text = self.shortMessage(error)
                XCTAssertTrue(text.contains("api_key is invalid"), text)
            } else { XCTFail("double succeeded") }
            doubleExp.fulfill()
        }
        wait(for: [doubleExp], timeout: 5)

        let cloud = ZeroBounceSDK()
        cloud.initialize(apiKey: "cf-json-user")
        let cloudExp = expectation(description: "cf")
        cloud.getCredits { result in
            if case .Failure(let error) = result {
                let text = self.shortMessage(error)
                XCTAssertNil(text.range(of: "developers.cloudflare.com"))
                XCTAssertTrue(text.contains("Access denied"), text)
            } else { XCTFail("cloudflare succeeded") }
            cloudExp.fulfill()
        }
        wait(for: [cloudExp], timeout: 5)

        let account = ZeroBounceSDK()
        account.initialize(apiKey: "batch-account-user")
        let accountExp = expectation(description: "account")
        account.validateBatch(emails: [["email_address": "a@example.com", "ip_address": ""]]) { result in
            if case .Failure(let error) = result {
                let text = self.shortMessage(error)
                XCTAssertTrue(text.contains("Invalid API Key"))
                XCTAssertTrue(text.contains("ran out of credits"))
            } else { XCTFail("account error succeeded") }
            accountExp.fulfill()
        }
        wait(for: [accountExp], timeout: 5)

        let partial = ZeroBounceSDK()
        partial.initialize(apiKey: "batch-partial-user")
        let partialExp = expectation(description: "partial")
        partial.validateBatch(emails: [
            ["email_address": "good@example.com", "ip_address": ""],
            ["email_address": "bad@", "ip_address": ""]
        ]) { result in
            if case .Success(let response) = result {
                XCTAssertEqual(response.emailBatch.first?.address, "good@example.com")
                XCTAssertEqual(response.errors.first?.emailAddress, "bad@")
            } else { XCTFail("partial failed") }
            partialExp.fulfill()
        }
        wait(for: [partialExp], timeout: 5)

        let missing = ZeroBounceSDK()
        missing.initialize(apiKey: "")
        OfflineURLProtocol.records = []
        let missingExp = expectation(description: "missing")
        missing.getCredits { result in
            if case .Failure(let error) = result {
                XCTAssertTrue(self.shortMessage(error).contains("not initialized"))
            } else { XCTFail("empty key succeeded") }
            missingExp.fulfill()
        }
        wait(for: [missingExp], timeout: 5)
        XCTAssertEqual(OfflineURLProtocol.records.count, 0)
    }

    func testOfflineFinderFileAndConcurrency() {
        let sdk = ZeroBounceSDK()
        sdk.initialize(apiKey: "file-key")
        var finder = ZBEmailFinderSendFileOptions()
        finder.hasHeaderRow = false
        finder.firstNameColumn = 2
        let finderExp = expectation(description: "finder file")
        let csv = FileManager.default.temporaryDirectory.appendingPathComponent("offline.csv")
        try? Data("domain\nexample.com\n".utf8).write(to: csv)
        sdk.sendEmailFinderFile(filePath: csv.path, domainColumn: 1, options: finder) { _ in
            finderExp.fulfill()
        }
        wait(for: [finderExp], timeout: 5)
        let sent = onlyRequest()
        XCTAssertEqual(sent.path, "/email-finder/sendfile")
        XCTAssertEqual(sent.host, "bulkapi.zerobounce.net")
        XCTAssertTrue(sent.body.contains("has_header_row"))
        XCTAssertTrue(sent.body.contains("false"))

        let group = DispatchGroup()
        let concurrent = NSLock()
        var echoes: [Int: String] = [:]
        for index in 0..<8 {
            group.enter()
            DispatchQueue.global().async {
                let client = ZeroBounceSDK()
                client.initialize(apiKey: "conc-\(index)")
                client.validate(email: "person@example.com", ipAddress: "") { result in
                    if case .Success(let response) = result {
                        concurrent.lock()
                        echoes[index] = response.address
                        concurrent.unlock()
                    }
                    group.leave()
                }
            }
        }
        XCTAssertEqual(group.wait(timeout: .now() + 8), .success)
        let keys = OfflineURLProtocol.records.filter { $0.apiKey.hasPrefix("conc-") }
        XCTAssertEqual(keys.count, 8)
        for index in 0..<8 {
            XCTAssertEqual(echoes[index], "conc-\(index)")
        }
    }


    // MARK: Validate options, S3 / SFTP bulk, Inbox Placement Tester
    //
    // Ported from the Python SDK (407f0a8 and b0444f8). Every request is
    // answered by OfflineURLProtocol; nothing here reaches the live API.

    /// Runs one SDK call and returns the single request it sent.
    private func send(_ block: (@escaping () -> ()) -> ()) -> OfflineRecord {
        OfflineURLProtocol.records = []
        let done = expectation(description: "request finished")
        block { done.fulfill() }
        wait(for: [done], timeout: 5)
        return onlyRequest()
    }

    /// Runs one SDK call that must be rejected before any request is sent.
    private func expectRejected(
        _ fragment: String,
        file: StaticString = #file,
        line: UInt = #line,
        _ block: (@escaping (String?) -> ()) -> ()
    ) {
        OfflineURLProtocol.records = []
        var message: String?
        let done = expectation(description: "rejected: \(fragment)")
        block { text in
            message = text
            done.fulfill()
        }
        wait(for: [done], timeout: 5)
        XCTAssertNotNil(message, "expected a failure mentioning \(fragment)", file: file, line: line)
        XCTAssertTrue(message?.contains(fragment) == true, message ?? "", file: file, line: line)
        XCTAssertEqual(OfflineURLProtocol.records.count, 0, "no request should have been sent", file: file, line: line)
    }

    private func failureText<T>(_ result: ZeroBounceSDK.ZBResult<T>) -> String? {
        if case .Failure(let error) = result { return "\(error)" }
        return nil
    }

    private func dictFailureText(_ result: ZeroBounceSDK.ZBDictionaryResult) -> String? {
        if case .Failure(let error) = result { return "\(error)" }
        return nil
    }

    /// Splits a form-encoded request body into its decoded fields.
    private func formFields(_ record: OfflineRecord) -> [String: String] {
        var fields: [String: String] = [:]
        for pair in record.body.split(separator: "&") {
            let parts = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2 else { continue }
            let name = String(parts[0]).removingPercentEncoding ?? String(parts[0])
            fields[name] = String(parts[1]).removingPercentEncoding ?? String(parts[1])
        }
        return fields
    }

    /// The plain (non-file) fields of a multipart/form-data request body.
    private func multipartFields(_ record: OfflineRecord) -> [String: String] {
        var fields: [String: String] = [:]
        let marker = "Content-Disposition: form-data; name=\""
        var rest = Substring(record.body)
        while let start = rest.range(of: marker) {
            rest = rest[start.upperBound...]
            guard let quote = rest.range(of: "\"") else { break }
            let name = String(rest[..<quote.lowerBound])
            let after = rest[quote.upperBound...]
            // A file part goes on with `; filename=...`; a plain field ends
            // its headers right after the name. Swift reads "\r\n" as one
            // Character, so the separators are searched for, not scanned.
            guard after.hasPrefix("\r\n\r\n"),
                  let blank = after.range(of: "\r\n\r\n"),
                  let end = after[blank.upperBound...].range(of: "\r\n") else { continue }
            fields[name] = String(after[blank.upperBound..<end.lowerBound])
        }
        return fields
    }

    /// `remove_duplicate` (API default true; a 400 when more than half the
    /// rows would be dropped) is sent on all four sendfile entry points only
    /// when the caller sets it, as "true" or "false".
    func testOfflineSendFileSendsRemoveDuplicateOnlyWhenSet() {
        let sdk = ZeroBounceSDK()
        sdk.initialize(apiKey: "file-key")
        let csv = FileManager.default.temporaryDirectory.appendingPathComponent("remove-duplicate.csv")
        try? Data("email\nperson@example.com\n".utf8).write(to: csv)
        let data = Data("email\nperson@example.com\n".utf8)

        typealias Call = (Bool?, @escaping () -> ()) -> ()
        let calls: [(String, String, Call)] = [
            ("sendFile(filePath:)", "/v2/sendfile", { flag, finish in
                sdk.sendFile(filePath: csv.path, emailAddressColumn: 1, hasHeaderRow: true,
                             removeDuplicate: flag) { _ in finish() }
            }),
            ("sendFile(fileData:)", "/v2/sendfile", { flag, finish in
                sdk.sendFile(fileData: data, fileName: "list.csv", emailAddressColumn: 1, hasHeaderRow: true,
                             removeDuplicate: flag) { _ in finish() }
            }),
            ("scoringSendFile(filePath:)", "/v2/scoring/sendfile", { flag, finish in
                sdk.scoringSendFile(filePath: csv.path, emailAddressColumn: 1, hasHeaderRow: true,
                                    removeDuplicate: flag) { _ in finish() }
            }),
            ("scoringSendFile(fileData:)", "/v2/scoring/sendfile", { flag, finish in
                sdk.scoringSendFile(fileData: data, fileName: "list.csv", emailAddressColumn: 1, hasHeaderRow: true,
                                    removeDuplicate: flag) { _ in finish() }
            }),
        ]
        for (name, path, call) in calls {
            for flag in [true, false, nil] as [Bool?] {
                let sent = send { finish in call(flag, finish) }
                XCTAssertEqual(sent.path, path, name)
                let fields = multipartFields(sent)
                XCTAssertEqual(fields["api_key"], "file-key", name)
                XCTAssertEqual(fields["email_address_column"], "1", name)
                XCTAssertEqual(fields["has_header_row"], "true", name)
                XCTAssertEqual(fields["remove_duplicate"], flag.map { $0 ? "true" : "false" },
                               "\(name) remove_duplicate=\(String(describing: flag))")
                // The bulk root's S3/SFTP spelling is not the sendfile one.
                XCTAssertNil(fields["remove_duplicates"], name)
            }
        }
    }

    /// Runs one SDK call and returns the error message it failed with.
    private func failureMessage(_ block: (@escaping (String?) -> ()) -> ()) -> String {
        var message: String?
        let done = expectation(description: "failed")
        block { text in
            message = text
            done.fulfill()
        }
        wait(for: [done], timeout: 5)
        XCTAssertNotNil(message, "expected a failure")
        return message ?? ""
    }

    /// An invalid or drained key answers with an HTTP 200 and an error-only
    /// body. Every call must fail with the API's own message.
    func testOfflineADeadKeyIsAFailureOnEveryCall() {
        let sdk = ZeroBounceSDK()
        sdk.initialize(apiKey: "dead-key-user")
        let drained = "Invalid API key or your account ran out of credits"
        func dictText(_ result: ZeroBounceSDK.ZBDictionaryResult) -> String? {
            if case .Failure(let error) = result { return shortMessage(error) }
            return nil
        }
        func jsonText(_ result: ZeroBounceSDK.ZBJsonResult) -> String? {
            if case .Failure(let error) = result { return shortMessage(error) }
            return nil
        }
        func typedText<T>(_ result: ZeroBounceSDK.ZBResult<T>) -> String? {
            if case .Failure(let error) = result { return shortMessage(error) }
            return nil
        }
        let calls: [(String, String, (@escaping (String?) -> ()) -> ())] = [
            ("validate", drained, { report in sdk.validate(email: "a@example.com") { report(typedText($0)) } }),
            ("activity", drained, { report in sdk.getActivityData(email: "a@example.com") { report(typedText($0)) } }),
            ("apiUsage", "Invalid API key", { report in
                sdk.getApiUsage(startDate: Date(timeIntervalSince1970: 0), endDate: Date(timeIntervalSince1970: 86_400)) { report(typedText($0)) }
            }),
            ("findEmail", drained, { report in sdk.findEmail(domain: "example.com", firstName: "john") { report(typedText($0)) } }),
            ("findDomain", drained, { report in sdk.findDomain(domain: "example.com") { report(typedText($0)) } }),
            ("addFilter", drained, { report in sdk.addFilter(rule: "allow", target: "email", value: "x@example.com") { report(dictText($0)) } }),
            ("deleteFilter", drained, { report in sdk.deleteFilter(rule: "allow", target: "email", value: "x@example.com") { report(dictText($0)) } }),
            ("listFilters", drained, { report in sdk.listFilters { report(jsonText($0)) } }),
            ("listFilters POST", drained, { report in sdk.listFilters(usePost: true) { report(jsonText($0)) } }),
        ]
        for (name, expected, call) in calls {
            let message = failureMessage(call)
            XCTAssertTrue(message.contains(expected), "\(name): \(message)")
            XCTAssertFalse(message.contains("{"), "\(name) carries raw JSON: \(message)")
        }
    }

    func testOfflineAFilterMessageIsStillAResult() {
        let sdk = ZeroBounceSDK()
        sdk.initialize(apiKey: "filter-message-user")
        var added: [String: Any]?
        let done = expectation(description: "added")
        sdk.addFilter(rule: "allow", target: "email", value: "x@example.com") { result in
            if case .Success(let dict) = result { added = dict }
            done.fulfill()
        }
        wait(for: [done], timeout: 5)
        XCTAssertEqual(added?["Message"] as? String, "Filter has been added.")
    }

    /// LIVE (2026-11-11): the finder answers a search it could not resolve
    /// with email_confidence "undetermined", which the enum did not have, so
    /// the whole response failed to decode. The docs spell the values in
    /// capitals (HIGH, MEDIUM, LOW); a value the SDK does not know yet must
    /// not fail the response either.
    func testOfflineEmailConfidenceDecodesEveryValueTheApiSends() throws {
        func finder(_ confidence: String) throws -> ZBEmailFinderResponse {
            let json = #"{"email":"","email_confidence":"\#(confidence)","domain":"example.com","company_name":"","did_you_mean":"","failure_reason":""}"#
            return try JSONDecoder().decode(ZBEmailFinderResponse.self, from: Data(json.utf8))
        }
        XCTAssertEqual(try finder("undetermined").emailConfidence, .undetermined)
        XCTAssertEqual(try finder("high").emailConfidence, .high)
        XCTAssertEqual(try finder("HIGH").emailConfidence, .high)
        XCTAssertEqual(try finder("Medium").emailConfidence, .medium)
        XCTAssertEqual(try finder("").emailConfidence, .none)
        XCTAssertEqual(try finder("something-new").emailConfidence, .unknown)

        func domain(_ confidence: String) throws -> ZBDomainSearchResponse {
            let json = #"{"domain":"example.com","company_name":"","format":"unknown","confidence":"\#(confidence)","did_you_mean":"","failure_reason":"","other_domain_formats":[]}"#
            return try JSONDecoder().decode(ZBDomainSearchResponse.self, from: Data(json.utf8))
        }
        XCTAssertEqual(try domain("undetermined").confidence, .undetermined)
        XCTAssertEqual(try domain("LOW").confidence, .low)
        XCTAssertEqual(try domain("something-new").confidence, .unknown)
    }

    func testOfflineValidateSendsTheNewOptionsOnlyWhenSet() {
        let sdk = ZeroBounceSDK()
        sdk.initialize(apiKey: "validate-key")

        let plain = send { finish in
            sdk.validate(email: "a@example.com", ipAddress: "", options: ZBValidateOptions()) { _ in finish() }
        }
        for absent in ["domain_info", "greylist_processing", "callback_url"] {
            XCTAssertFalse(plain.query.contains("\(absent)="), "\(absent) should not be sent: \(plain.query)")
        }

        let full = send { finish in
            sdk.validate(
                email: "a@example.com",
                ipAddress: "",
                options: ZBValidateOptions(
                    domainInfo: true,
                    greylistProcessing: true,
                    callbackUrl: "https://example.com/greylist"
                )
            ) { _ in finish() }
        }
        // Booleans go on the wire as the strings "true"/"false".
        XCTAssertTrue(full.query.contains("domain_info=true"), full.query)
        XCTAssertTrue(full.query.contains("greylist_processing=true"), full.query)
        XCTAssertTrue(full.query.contains("callback_url="), full.query)

        let posted = send { finish in
            sdk.validate(
                email: "a@example.com",
                ipAddress: "",
                options: ZBValidateOptions(
                    domainInfo: false,
                    greylistProcessing: true,
                    callbackUrl: "https://example.com/greylist",
                    usePost: true
                )
            ) { _ in finish() }
        }
        XCTAssertEqual(posted.method, "POST")
        XCTAssertTrue(posted.body.contains("domain_info=false"), posted.body)
        XCTAssertTrue(posted.body.contains("callback_url="), posted.body)
    }

    func testOfflineGreylistMessageDecodesWithoutProcessedAt() {
        // While a greylist retry is still running the API answers with
        // "Message" and no processed_at.
        let json = Data(#"""
        {"address":"a@example.com","Message":"Greylisted email, we will retry",
         "domain_website_exists":"true","domain_registrant_company_name":"Example Inc"}
        """#.utf8)

        let response = try? JSONDecoder().decode(ZBValidateResponse.self, from: json)

        XCTAssertEqual(response?.message, "Greylisted email, we will retry")
        XCTAssertEqual(response?.domainWebsiteExists, "true")
        XCTAssertEqual(response?.domainRegistrantCompanyName, "Example Inc")
        XCTAssertNil(response?.processedAt)
    }

    func testOfflineCallbackUrlWithoutGreylistProcessingSendsNoRequest() {
        let sdk = ZeroBounceSDK()
        sdk.initialize(apiKey: "validate-key")

        expectRejected("greylist_processing") { report in
            sdk.validate(
                email: "a@example.com", ipAddress: "",
                options: ZBValidateOptions(callbackUrl: "https://example.com/cb")
            ) { report(self.failureText($0)) }
        }
        expectRejected("greylist_processing") { report in
            sdk.validate(
                email: "a@example.com", ipAddress: "",
                options: ZBValidateOptions(greylistProcessing: false, callbackUrl: "https://example.com/cb")
            ) { report(self.failureText($0)) }
        }
        expectRejected("callback_url") { report in
            sdk.validate(
                email: "a@example.com", ipAddress: "",
                options: ZBValidateOptions(greylistProcessing: true, callbackUrl: "   ")
            ) { report(self.failureText($0)) }
        }
    }

    func testOfflineS3AndSftpFileJobsSendTheDocumentedFieldsOnly() {
        let sdk = ZeroBounceSDK()
        sdk.initialize(apiKey: "bulk-key")

        let finder = send { finish in
            sdk.emailFinderS3File(
                options: ZBBulkFileJobOptions(
                    fileName: "lists/leads.csv",
                    returnUrl: "https://example.com/done"
                )
            ) { _ in finish() }
        }
        XCTAssertEqual(finder.method, "POST")
        XCTAssertEqual(finder.host, "bulkapi.zerobounce.net")
        // The S3 and SFTP jobs live on the bulkapi root, WITHOUT /v2.
        XCTAssertEqual(finder.path, "/emailFinderS3file")
        XCTAssertTrue(finder.body.contains("file_name=lists/leads.csv")
            || finder.body.contains("file_name=lists%2Fleads.csv"), finder.body)
        XCTAssertTrue(finder.body.contains("return_url="), finder.body)
        XCTAssertTrue(finder.body.contains("has_header_row=true"), finder.body)
        // Options that were never set stay off the request entirely.
        XCTAssertFalse(finder.body.contains("remove_duplicates"), finder.body)

        let domains = send { finish in
            sdk.domainSearchS3File(
                options: ZBBulkFileJobOptions(
                    fileName: "lists/leads.csv",
                    hasHeaderRow: false,
                    removeDuplicates: true,
                    returnUrl: "https://example.com/done"
                )
            ) { _ in finish() }
        }
        XCTAssertEqual(domains.path, "/domainSearchS3file")
        XCTAssertTrue(domains.body.contains("has_header_row=false"), domains.body)
        XCTAssertTrue(domains.body.contains("remove_duplicates=true"), domains.body)
        XCTAssertTrue(domains.body.contains("return_url="), domains.body)

        // LIVE: the docs call file_name optional for validateSFTPfile, but the
        // API answers "Empty parameter: file_name" without it, and every job
        // needs a return_url as well.
        let named = ZBBulkFileJobOptions(
            fileName: "my_file.txt",
            returnUrl: "https://example.com/done"
        )
        let sftp = send { finish in
            sdk.validateSFTPFile(options: named) { _ in finish() }
        }
        XCTAssertEqual(sftp.path, "/validateSFTPfile")
        XCTAssertTrue(sftp.body.contains("file_name=my_file.txt"), sftp.body)
        XCTAssertTrue(sftp.body.contains("return_url="), sftp.body)

        XCTAssertEqual(send { finish in sdk.scoreSFTPFile(options: named) { _ in finish() } }.path, "/scoreSFTPfile")
        XCTAssertEqual(send { finish in sdk.emailFinderSFTPFile(options: named) { _ in finish() } }.path, "/emailFinderSFTPfile")
        XCTAssertEqual(send { finish in sdk.domainSearchSFTPFile(options: named) { _ in finish() } }.path, "/domainSearchSFTPfile")

        // exportSFTPfile takes export_path, not the export_bucket exportS3file uses.
        let exported = send { finish in
            sdk.exportSFTPFile(fileId: "fid", exportPath: "/exports") { _ in finish() }
        }
        XCTAssertEqual(exported.path, "/exportSFTPfile")
        XCTAssertTrue(exported.body.contains("file_id=fid"), exported.body)
        XCTAssertTrue(exported.body.contains("export_path="), exported.body)
        XCTAssertFalse(exported.body.contains("export_bucket"), exported.body)

        let exportedDefault = send { finish in
            sdk.exportSFTPFile(fileId: "fid", exportPath: nil) { _ in finish() }
        }
        XCTAssertFalse(exportedDefault.body.contains("export_path"), exportedDefault.body)
    }

    func testOfflineBulkJobsRejectInvalidArgumentsBeforeARequest() {
        let sdk = ZeroBounceSDK()
        sdk.initialize(apiKey: "bulk-key")
        let blank = ZBBulkFileJobOptions(fileName: "   ")

        expectRejected("file_name") { report in
            sdk.emailFinderS3File(options: ZBBulkFileJobOptions()) { report(self.failureText($0)) }
        }
        expectRejected("file_name") { report in
            sdk.domainSearchS3File(options: blank) { report(self.failureText($0)) }
        }
        expectRejected("file_name") { report in
            sdk.scoreSFTPFile(options: blank) { report(self.failureText($0)) }
        }
        expectRejected("file_name") { report in
            sdk.emailFinderSFTPFile(options: blank) { report(self.failureText($0)) }
        }
        expectRejected("file_name") { report in
            sdk.domainSearchSFTPFile(options: blank) { report(self.failureText($0)) }
        }
        // A blank name is rejected just like a missing one, here too.
        expectRejected("file_name") { report in
            sdk.validateSFTPFile(options: blank) { report(self.failureText($0)) }
        }
        expectRejected("file_name") { report in
            sdk.validateSFTPFile(options: ZBBulkFileJobOptions()) { report(self.failureText($0)) }
        }
        // LIVE: return_url is required on every one of these jobs as well.
        expectRejected("return_url") { report in
            sdk.validateSFTPFile(options: ZBBulkFileJobOptions(fileName: "my_file.txt")) {
                report(self.failureText($0))
            }
        }
        expectRejected("return_url") { report in
            sdk.emailFinderS3File(options: ZBBulkFileJobOptions(fileName: "f.csv")) {
                report(self.failureText($0))
            }
        }
        expectRejected("file_id") { report in
            sdk.sendEvaluatedFile(fileId: "  ") { report(self.failureText($0)) }
        }
        expectRejected("file_id") { report in
            sdk.exportSFTPFile(fileId: "  ", exportPath: nil) { report(self.failureText($0)) }
        }
        expectRejected("export_path") { report in
            sdk.exportSFTPFile(fileId: "fid", exportPath: " ") { report(self.failureText($0)) }
        }
    }

    func testOfflineS3ValidateAndScoreCarryAReturnUrlAndNothingUndocumented() {
        let sdk = ZeroBounceSDK()
        sdk.initialize(apiKey: "s3-key")

        var validate = ZBValidateS3FileOptions(
            fileName: "bucket/key.csv",
            returnUrl: "https://example.com/done"
        )
        validate.hasHeaderRow = true
        validate.removeDuplicates = true
        validate.emailAddressColumn = 1
        validate.firstNameColumn = 2
        validate.lastNameColumn = 3
        validate.genderColumn = 4
        validate.ipAddressColumn = 5
        validate.allowPhase2 = false

        let sent = send { finish in sdk.validateS3File(options: validate) { _ in finish() } }
        XCTAssertEqual(sent.method, "POST")
        XCTAssertEqual(sent.host, "bulkapi.zerobounce.net")
        // The S3 jobs live on the bulkapi root, WITHOUT /v2.
        XCTAssertEqual(sent.path, "/validateS3file")
        // The key travels in the form body here, not on the query string.
        XCTAssertEqual(sent.apiKey, "s3-key")
        XCTAssertFalse(sent.query.contains("api_key="), sent.query)

        let fields = formFields(sent)
        XCTAssertEqual(fields["api_key"], "s3-key")
        XCTAssertEqual(fields["file_name"], "bucket/key.csv")
        // LIVE: without this the API answers HTTP 400 "Provided return URL is
        // not permitted: None", so it is always sent.
        XCTAssertEqual(fields["return_url"], "https://example.com/done")
        XCTAssertEqual(fields["has_header_row"], "true")
        XCTAssertEqual(fields["remove_duplicates"], "true")
        XCTAssertEqual(fields["email_address_column"], "1")
        XCTAssertEqual(fields["first_name_column"], "2")
        XCTAssertEqual(fields["last_name_column"], "3")
        XCTAssertEqual(fields["gender_column"], "4")
        XCTAssertEqual(fields["ip_address_column"], "5")
        XCTAssertEqual(fields["allow_phase_2"], "false")
        // The undocumented singular spelling is no longer sent beside it.
        XCTAssertNil(fields["remove_duplicate"])

        var score = ZBScoreS3FileOptions(
            fileName: "bucket/key.csv",
            returnUrl: "https://example.com/done"
        )
        score.hasHeaderRow = false
        score.emailAddressColumn = 2

        let scored = send { finish in sdk.scoreS3File(options: score) { _ in finish() } }
        XCTAssertEqual(scored.method, "POST")
        XCTAssertEqual(scored.path, "/scoreS3file")
        let scoreFields = formFields(scored)
        XCTAssertEqual(scoreFields["file_name"], "bucket/key.csv")
        XCTAssertEqual(scoreFields["return_url"], "https://example.com/done")
        XCTAssertEqual(scoreFields["has_header_row"], "false")
        XCTAssertEqual(scoreFields["email_address_column"], "2")
        XCTAssertNil(scoreFields["remove_duplicate"])
        // Unset options stay off the request entirely.
        XCTAssertNil(scoreFields["remove_duplicates"])

        // A blank value is rejected the same way a missing one would be, and
        // the type system takes care of a missing one.
        expectRejected("file_name") { report in
            sdk.validateS3File(options: ZBValidateS3FileOptions(fileName: " ", returnUrl: "https://e.test/d")) {
                report(self.failureText($0))
            }
        }
        expectRejected("return_url") { report in
            sdk.validateS3File(options: ZBValidateS3FileOptions(fileName: "f.csv", returnUrl: "  ")) {
                report(self.failureText($0))
            }
        }
        expectRejected("file_name") { report in
            sdk.scoreS3File(options: ZBScoreS3FileOptions(fileName: "", returnUrl: "https://e.test/d")) {
                report(self.failureText($0))
            }
        }
        expectRejected("return_url") { report in
            sdk.scoreS3File(options: ZBScoreS3FileOptions(fileName: "f.csv", returnUrl: "")) {
                report(self.failureText($0))
            }
        }
    }

    func testOfflineS3JobsParseTheirResponses() {
        let ok = ZeroBounceSDK()
        ok.initialize(apiKey: "s3-ok")
        var response: ZBSendFileResponse?
        let done = expectation(description: "parsed")
        ok.scoreS3File(options: ZBScoreS3FileOptions(fileName: "f.csv", returnUrl: "https://e.test/d")) { result in
            if case .Success(let value) = result { response = value }
            done.fulfill()
        }
        wait(for: [done], timeout: 5)
        XCTAssertEqual(response?.fileId, "s3-ok")
        XCTAssertEqual(response?.success, true)

        // An HTTP 200 carrying "success": false is a failure, here too.
        let failing = ZeroBounceSDK()
        failing.initialize(apiKey: "success-false-s3")
        let message = failureMessage { report in
            failing.validateS3File(options: ZBValidateS3FileOptions(fileName: "f.csv", returnUrl: "https://e.test/d")) {
                report(self.failureText($0))
            }
        }
        XCTAssertTrue(message.contains("File cannot be found."), message)

        // And an access-denied HTML page stays a short message.
        let blocked = ZeroBounceSDK()
        blocked.initialize(apiKey: "html-403-s3")
        var short = ""
        let denied = expectation(description: "denied")
        blocked.exportS3File(fileId: "fid", exportBucket: nil) { result in
            if case .Failure(let error) = result { short = self.shortMessage(error) }
            denied.fulfill()
        }
        wait(for: [denied], timeout: 5)
        XCTAssertFalse(short.isEmpty, short)
    }

    func testOfflineExportS3FileCanLeaveTheBucketToTheAccountSettings() {
        let sdk = ZeroBounceSDK()
        sdk.initialize(apiKey: "export-key")

        let named = send { finish in
            sdk.exportS3File(fileId: "fid", exportBucket: "my-bucket") { _ in finish() }
        }
        XCTAssertEqual(named.method, "POST")
        XCTAssertEqual(named.path, "/exportS3file")
        XCTAssertEqual(formFields(named)["file_id"], "fid")
        // exportS3file takes export_bucket, not the export_path exportSFTPfile uses.
        XCTAssertEqual(formFields(named)["export_bucket"], "my-bucket")
        XCTAssertNil(formFields(named)["export_path"])

        // export_bucket is optional: without one the account's settings decide.
        let defaulted = send { finish in
            sdk.exportS3File(fileId: "fid", exportBucket: nil) { _ in finish() }
        }
        XCTAssertNil(formFields(defaulted)["export_bucket"])
        XCTAssertEqual(formFields(defaulted)["file_id"], "fid")

        expectRejected("file_id") { report in
            sdk.exportS3File(fileId: "  ", exportBucket: nil) { report(self.failureText($0)) }
        }
        // A blank bucket is a mistake rather than "use the default".
        expectRejected("export_bucket") { report in
            sdk.exportS3File(fileId: "fid", exportBucket: " ") { report(self.failureText($0)) }
        }
    }

    func testOfflineEmailFinderFileNeedsAFirstNameOrFullNameColumn() {
        let sdk = ZeroBounceSDK()
        sdk.initialize(apiKey: "finder-key")
        let csv = FileManager.default.temporaryDirectory.appendingPathComponent("finder-columns.csv")
        try? Data("domain,first,full\nexample.com,Jane,Jane Doe\n".utf8).write(to: csv)

        var full = ZBEmailFinderSendFileOptions()
        full.fullNameColumn = 3
        let sent = send { finish in
            sdk.sendEmailFinderFile(filePath: csv.path, domainColumn: 1, options: full) { _ in finish() }
        }
        XCTAssertEqual(sent.method, "POST")
        XCTAssertEqual(sent.host, "bulkapi.zerobounce.net")
        XCTAssertEqual(sent.path, "/email-finder/sendfile")
        XCTAssertEqual(sent.apiKey, "finder-key")
        XCTAssertTrue(sent.body.contains("full_name_column"), sent.body)

        var first = ZBEmailFinderSendFileOptions()
        first.firstNameColumn = 2
        let data = send { finish in
            sdk.sendEmailFinderFileData(
                fileData: Data("domain,first\nexample.com,Jane\n".utf8),
                fileName: "finder.csv",
                domainColumn: 1,
                options: first
            ) { _ in finish() }
        }
        XCTAssertEqual(data.path, "/email-finder/sendfile")
        XCTAssertTrue(data.body.contains("first_name_column"), data.body)

        // Neither name column: the file has nothing to search with.
        expectRejected("first_name_column or full_name_column") { report in
            sdk.sendEmailFinderFile(filePath: csv.path, domainColumn: 1, options: nil) {
                report(self.failureText($0))
            }
        }
        expectRejected("first_name_column or full_name_column") { report in
            sdk.sendEmailFinderFile(
                filePath: csv.path,
                domainColumn: 1,
                options: ZBEmailFinderSendFileOptions()
            ) { report(self.failureText($0)) }
        }
        expectRejected("first_name_column or full_name_column") { report in
            sdk.sendEmailFinderFileData(
                fileData: Data("domain\nexample.com\n".utf8),
                fileName: "finder.csv",
                domainColumn: 1,
                options: ZBEmailFinderSendFileOptions()
            ) { report(self.failureText($0)) }
        }
        expectRejected("domain_column") { report in
            sdk.sendEmailFinderFile(filePath: csv.path, domainColumn: 0, options: full) {
                report(self.failureText($0))
            }
        }
    }

    func testOfflineFindEmailWorksWithoutAFirstName() {
        let sdk = ZeroBounceSDK()
        sdk.initialize(apiKey: "guess-key")

        // first_name is optional: a last name alone is a valid search.
        let byLastName = send { finish in
            sdk.findEmail(domain: "example.com", lastName: "Doe") { _ in finish() }
        }
        XCTAssertEqual(byLastName.method, "GET")
        XCTAssertEqual(byLastName.path, "/v2/guessformat")
        XCTAssertTrue(byLastName.query.contains("domain=example.com"), byLastName.query)
        XCTAssertTrue(byLastName.query.contains("last_name=Doe"), byLastName.query)
        XCTAssertFalse(byLastName.query.contains("first_name="), byLastName.query)
        XCTAssertTrue(byLastName.query.contains("api_key=guess-key"), byLastName.query)

        let byMiddleName = send { finish in
            sdk.findEmail(companyName: "Acme", middleName: "Q") { _ in finish() }
        }
        XCTAssertTrue(byMiddleName.query.contains("company_name=Acme"), byMiddleName.query)
        XCTAssertTrue(byMiddleName.query.contains("middle_name=Q"), byMiddleName.query)
        XCTAssertFalse(byMiddleName.query.contains("first_name="), byMiddleName.query)

        // A first name still goes out, and a blank one is left off.
        let full = send { finish in
            sdk.findEmail(domain: "example.com", firstName: "Jane", middleName: nil, lastName: "Doe") { _ in finish() }
        }
        XCTAssertTrue(full.query.contains("first_name=Jane"), full.query)
        XCTAssertFalse(full.query.contains("middle_name="), full.query)

        let blankFirst = send { finish in
            sdk.findEmail(domain: "example.com", firstName: "  ", lastName: "Doe") { _ in finish() }
        }
        XCTAssertFalse(blankFirst.query.contains("first_name="), blankFirst.query)

        // With no name at all /guessformat is the domain search, which
        // findDomain covers, so findEmail says so instead of sending it.
        expectRejected("first_name, middle_name or last_name") { report in
            sdk.findEmail(domain: "example.com") { report(self.failureText($0)) }
        }
        expectRejected("first_name, middle_name or last_name") { report in
            sdk.findEmail(companyName: "Acme") { report(self.failureText($0)) }
        }

        // Domain search is untouched: same endpoint, no name parameters.
        let domainOnly = send { finish in
            sdk.findDomain(domain: "example.com") { _ in finish() }
        }
        XCTAssertEqual(domainOnly.path, "/v2/guessformat")
        XCTAssertTrue(domainOnly.query.contains("domain=example.com"), domainOnly.query)
        XCTAssertFalse(domainOnly.query.contains("last_name="), domainOnly.query)
    }

    func testOfflineInboxPlacementTestTakesPerProviderSeatsAndChecksItsFields() {
        let sdk = ZeroBounceSDK()
        sdk.initialize(apiKey: "ipt-key")

        let created = send { finish in
            sdk.createInboxPlacementTest(
                name: "Launch",
                options: ZBCreateInboxPlacementTestOptions(
                    testType: 2,
                    providerIds: [3],
                    seedIds: [7],
                    providers: [
                        ZBInboxPlacementTestProvider(id: 1, maxSeeds: 5),
                        ZBInboxPlacementTestProvider(id: 2, maxSeeds: 10)
                    ]
                )
            ) { _ in finish() }
        }
        XCTAssertEqual(created.method, "POST")
        XCTAssertEqual(created.path, "/api/ipt/test")
        XCTAssertEqual(created.authHeader, "Bearer ipt-key")
        XCTAssertEqual(
            created.body,
            #"{"name":"Launch","providerIds":[3],"providers":[{"id":1,"maxSeeds":5},{"id":2,"maxSeeds":10}],"seedIds":[7],"testType":2}"#
        )

        // Not set, not sent.
        let bare = send { finish in
            sdk.createInboxPlacementTest(name: "Bare", options: nil) { _ in finish() }
        }
        XCTAssertEqual(bare.body, #"{"name":"Bare"}"#)

        expectRejected("name") { report in
            sdk.createInboxPlacementTest(name: String(repeating: "x", count: 65)) {
                report(self.dictFailureText($0))
            }
        }
        // 64 is the limit, not one less.
        let atTheLimit = send { finish in
            sdk.createInboxPlacementTest(name: String(repeating: "x", count: 64)) { _ in finish() }
        }
        XCTAssertEqual(atTheLimit.path, "/api/ipt/test")

        expectRejected("testType") { report in
            sdk.createInboxPlacementTest(
                name: "Launch",
                options: ZBCreateInboxPlacementTestOptions(testType: 4)
            ) { report(self.dictFailureText($0)) }
        }
        expectRejected("testType") { report in
            sdk.createInboxPlacementTest(
                name: "Launch",
                options: ZBCreateInboxPlacementTestOptions(testType: 0)
            ) { report(self.dictFailureText($0)) }
        }
        // Test type 1 is the one you send the email for, so the address it
        // will come from has to be known up front.
        expectRejected("senderEmail") { report in
            sdk.createInboxPlacementTest(
                name: "Launch",
                options: ZBCreateInboxPlacementTestOptions(testType: 1)
            ) { report(self.dictFailureText($0)) }
        }
        expectRejected("senderEmail") { report in
            sdk.createInboxPlacementTest(
                name: "Launch",
                options: ZBCreateInboxPlacementTestOptions(testType: 1, senderEmail: " ")
            ) { report(self.dictFailureText($0)) }
        }
        // Test types 2 and 3 do not need one.
        let noSender = send { finish in
            sdk.createInboxPlacementTest(
                name: "Launch",
                options: ZBCreateInboxPlacementTestOptions(testType: 3)
            ) { _ in finish() }
        }
        XCTAssertEqual(noSender.body, #"{"name":"Launch","testType":3}"#)
    }

    func testOfflineInboxPlacementListSendsPageSizeAndTheDateFilters() {
        let sdk = ZeroBounceSDK()
        sdk.initialize(apiKey: "ipt-key")

        let listed = send { finish in
            sdk.listInboxPlacementTests(
                options: ZBListInboxPlacementTestsOptions(
                    status: "running",
                    createdAfter: "2026-01-01",
                    createdBefore: "2026-02-01",
                    page: 2,
                    pageSize: 100
                )
            ) { _ in finish() }
        }
        XCTAssertEqual(listed.path, "/api/ipt/tests")
        XCTAssertEqual(listed.authHeader, "Bearer ipt-key")
        XCTAssertTrue(listed.query.contains("status=running"), listed.query)
        XCTAssertTrue(listed.query.contains("createdAfter=2026-01-01"), listed.query)
        XCTAssertTrue(listed.query.contains("createdBefore=2026-02-01"), listed.query)
        XCTAssertTrue(listed.query.contains("page=2"), listed.query)
        // LIVE: page_size paginates; pageSize is accepted and ignored.
        XCTAssertTrue(listed.query.contains("page_size=100"), listed.query)
        XCTAssertFalse(listed.query.contains("pageSize="), listed.query)

        expectRejected("status") { report in
            sdk.listInboxPlacementTests(
                options: ZBListInboxPlacementTestsOptions(status: "done")
            ) { report(self.dictFailureText($0)) }
        }
        expectRejected("page_size") { report in
            sdk.listInboxPlacementTests(
                options: ZBListInboxPlacementTestsOptions(pageSize: 0)
            ) { report(self.dictFailureText($0)) }
        }
        expectRejected("page_size") { report in
            sdk.listInboxPlacementTests(
                options: ZBListInboxPlacementTestsOptions(pageSize: 101)
            ) { report(self.dictFailureText($0)) }
        }
        // 1 and 100 are both inside the bound.
        let smallest = send { finish in
            sdk.listInboxPlacementTests(
                options: ZBListInboxPlacementTestsOptions(pageSize: 1)
            ) { _ in finish() }
        }
        XCTAssertTrue(smallest.query.contains("page_size=1"), smallest.query)
    }

    func testOfflineListEvaluatorUsesItsOwnBaseUrlAndEncodesTheFileId() {
        let sdk = ZeroBounceSDK()
        sdk.initialize(apiKey: "eval-key")

        let sent = send { finish in
            sdk.getListEvaluatorResult(fileId: "a b/c") { _ in finish() }
        }
        XCTAssertEqual(sent.host, "bulkapi.zerobounce.net")
        // The file id is one path segment, so a slash in it must stay encoded
        // and a space must not become a plus.
        // URL.path drops the trailing slash and decodes %2F, so assert on the
        // encoded path, which is what goes on the wire.
        XCTAssertTrue(sent.rawPath.contains("/v2/listevaluator/a%20b%2Fc/"), sent.rawPath)

        expectRejected("file_id") { report in
            sdk.getListEvaluatorResult(fileId: "   ") { report(self.dictFailureText($0)) }
        }

        // It is a separate host, not a path built from the bulk base.
        sdk.setListEvaluatorBaseUrl("https://bulk.example.test/v2/listevaluator")
        let overridden = send { finish in
            sdk.getListEvaluatorResult(fileId: "fid") { _ in finish() }
        }
        XCTAssertEqual(overridden.host, "bulk.example.test")
    }

    func testOfflineInboxPlacementUsesItsOwnHostAndCamelCaseJson() {
        let sdk = ZeroBounceSDK()
        sdk.initialize(apiKey: "ipt-key")

        let providers = send { finish in sdk.getInboxPlacementProviders { _ in finish() } }
        XCTAssertEqual(providers.path, "/api/ipt/providers")
        // LIVE: the key travels in an Authorization: Bearer header. Sent as an
        // api_key query parameter the request is rejected as unauthorized, and
        // the key would end up in whatever logs the query string.
        XCTAssertEqual(providers.authHeader, "Bearer ipt-key")
        XCTAssertFalse(providers.query.contains("api_key="), providers.query)

        XCTAssertEqual(send { finish in sdk.getInboxPlacementTestTypes { _ in finish() } }.path, "/api/ipt/test-types")

        let created = send { finish in
            sdk.createInboxPlacementTest(
                name: "Launch",
                options: ZBCreateInboxPlacementTestOptions(
                    testType: 1,
                    senderEmail: "news@example.com",
                    webhookUrl: "https://example.com/ipt"
                )
            ) { _ in finish() }
        }
        XCTAssertEqual(created.method, "POST")
        XCTAssertEqual(created.path, "/api/ipt/test")
        // Bodies are camelCase JSON, and unset fields are left out.
        XCTAssertEqual(
            created.body,
            #"{"name":"Launch","senderEmail":"news@example.com","testType":1,"webhookUrl":"https:\/\/example.com\/ipt"}"#
        )
        XCTAssertFalse(created.body.contains("providerIds"), created.body)
        XCTAssertFalse(created.body.contains("seedIds"), created.body)

        let listed = send { finish in
            sdk.listInboxPlacementTests(
                options: ZBListInboxPlacementTestsOptions(status: "finished", page: 1, pageSize: 25)
            ) { _ in finish() }
        }
        // LIVE: the listing is GET /tests (plural). /test is the single-test
        // path and answers 'Method "GET" not allowed'.
        XCTAssertEqual(listed.path, "/api/ipt/tests")
        XCTAssertTrue(listed.query.contains("status=finished"), listed.query)
        XCTAssertTrue(listed.query.contains("page=1"), listed.query)
        // LIVE: the page size is page_size. Sent as pageSize it is accepted
        // and then ignored, and the whole list comes back unpaginated.
        XCTAssertTrue(listed.query.contains("page_size=25"), listed.query)
        XCTAssertFalse(listed.query.contains("pageSize="), listed.query)

        let bare = send { finish in sdk.listInboxPlacementTests { _ in finish() } }
        XCTAssertFalse(bare.query.contains("status="), bare.query)
        XCTAssertFalse(bare.query.contains("page="), bare.query)

        let deleted = send { finish in
            sdk.deleteInboxPlacementTest(testId: "a b/c") { _ in finish() }
        }
        XCTAssertEqual(deleted.method, "DELETE")
        XCTAssertTrue(deleted.rawPath.contains("/api/ipt/test/a%20b%2Fc"), deleted.rawPath)

        let webhook = send { finish in
            sdk.setInboxPlacementWebhook(webhookUrl: "https://example.com/ipt") { _ in finish() }
        }
        XCTAssertEqual(webhook.method, "PUT")
        XCTAssertEqual(webhook.path, "/api/ipt/webhook")
        XCTAssertTrue(webhook.body.contains("webhookUrl"), webhook.body)

        XCTAssertEqual(send { finish in sdk.getInboxPlacementWebhook { _ in finish() } }.path, "/api/ipt/webhook")

        expectRejected("test_id") { report in
            sdk.getInboxPlacementTest(testId: "   ") { report(self.dictFailureText($0)) }
        }
        expectRejected("name") { report in
            sdk.createInboxPlacementTest(name: " ") { report(self.dictFailureText($0)) }
        }
        expectRejected("webhook_url") { report in
            sdk.setInboxPlacementWebhook(webhookUrl: "") { report(self.dictFailureText($0)) }
        }
    }

    func testOfflineInboxPlacementDetailErrorBecomesTheMessage() {
        let sdk = ZeroBounceSDK()
        sdk.initialize(apiKey: "ipt-detail")

        OfflineURLProtocol.records = []
        var message = ""
        let done = expectation(description: "detail error")
        sdk.getInboxPlacementTest(testId: "123") { result in
            if case .Failure(let error) = result { message = self.shortMessage(error) }
            done.fulfill()
        }
        wait(for: [done], timeout: 5)

        XCTAssertTrue(message.contains("Inbox placement test not found."), message)
    }

    /// Every Inbox Placement method, with arguments that pass the local
    /// checks.
    private func inboxPlacementCalls(
        _ sdk: ZeroBounceSDK
    ) -> [(String, (@escaping (ZeroBounceSDK.ZBDictionaryResult) -> ()) -> ())] {
        [
            ("getInboxPlacementProviders", { sdk.getInboxPlacementProviders(completion: $0) }),
            ("getInboxPlacementTestTypes", { sdk.getInboxPlacementTestTypes(completion: $0) }),
            ("createInboxPlacementTest", { sdk.createInboxPlacementTest(name: "Launch", completion: $0) }),
            ("getInboxPlacementTest", { sdk.getInboxPlacementTest(testId: "123", completion: $0) }),
            ("listInboxPlacementTests", { sdk.listInboxPlacementTests(completion: $0) }),
            ("deleteInboxPlacementTest", { sdk.deleteInboxPlacementTest(testId: "123", completion: $0) }),
            ("getInboxPlacementWebhook", { sdk.getInboxPlacementWebhook(completion: $0) }),
            ("setInboxPlacementWebhook", { sdk.setInboxPlacementWebhook(webhookUrl: "https://example.com/hook", completion: $0) }),
        ]
    }

    private func dictionaryOutcome(
        _ name: String,
        _ call: (@escaping (ZeroBounceSDK.ZBDictionaryResult) -> ()) -> ()
    ) -> ZeroBounceSDK.ZBDictionaryResult? {
        OfflineURLProtocol.records = []
        var outcome: ZeroBounceSDK.ZBDictionaryResult?
        let done = expectation(description: name)
        call { result in
            outcome = result
            done.fulfill()
        }
        wait(for: [done], timeout: 5)
        return outcome
    }

    /// LIVE: a dead or drained key gets an HTTP 200 whose body is only
    /// {"error": ...}. On the Inbox Placement Tester that came back as a
    /// result holding the error; like every other JSON call it is an
    /// `.httpError` with status 200.
    func testOfflineADeadKeyIsAFailureOnEveryInboxPlacementCall() throws {
        let sdk = ZeroBounceSDK()
        sdk.initialize(apiKey: "dead-key-ipt")
        let calls = inboxPlacementCalls(sdk)
        let declared = try publicRequestMethodsInSources().keys.filter { $0.contains("InboxPlacement") }
        XCTAssertEqual(Set(calls.map { $0.0 }), Set(declared), "every Inbox Placement method must be checked")
        for (name, call) in calls {
            let outcome = dictionaryOutcome(name, call)
            guard case .Failure(let error)? = outcome else {
                XCTFail("\(name) returned \(String(describing: outcome))")
                continue
            }
            guard case .httpError(let message, let statusCode)? = error as? ZBError else {
                XCTFail("\(name): \(error)")
                continue
            }
            XCTAssertEqual(statusCode, 200, name)
            XCTAssertEqual(message, "Invalid API key or your account ran out of credits", name)
        }
    }

    /// A DELETE may answer a 2xx with no body at all; that is a success. Any
    /// other status with no body is still an error with that status, and so
    /// is an empty 2xx to any other method, which has lost its result.
    func testOfflineInboxPlacementEmptyBodyIsASuccessOnlyForA2xxDelete() {
        for status in [200, 204] {
            let sdk = ZeroBounceSDK()
            sdk.initialize(apiKey: "ipt-empty-\(status)-delete")
            let outcome = dictionaryOutcome("DELETE \(status)") { sdk.deleteInboxPlacementTest(testId: "123", completion: $0) }
            XCTAssertEqual(OfflineURLProtocol.records.first?.method, "DELETE")
            guard case .Success(let body)? = outcome else {
                XCTFail("an empty \(status) DELETE should succeed: \(String(describing: outcome))")
                continue
            }
            XCTAssertTrue(body.isEmpty, "\(body)")
        }
        for status in [401, 404, 500] {
            let sdk = ZeroBounceSDK()
            sdk.initialize(apiKey: "ipt-empty-\(status)-delete")
            let outcome = dictionaryOutcome("DELETE \(status)") { sdk.deleteInboxPlacementTest(testId: "123", completion: $0) }
            guard case .Failure(let error)? = outcome else {
                XCTFail("an empty \(status) DELETE should fail: \(String(describing: outcome))")
                continue
            }
            XCTAssertEqual((error as? ZBError)?.statusCode, status, "\(error)")
        }
        for status in [200, 204] {
            let sdk = ZeroBounceSDK()
            sdk.initialize(apiKey: "ipt-empty-\(status)-other")
            for (name, call) in inboxPlacementCalls(sdk) where name != "deleteInboxPlacementTest" {
                let outcome = dictionaryOutcome(name, call)
                XCTAssertNotEqual(OfflineURLProtocol.records.first?.method, "DELETE", name)
                guard case .Failure(let error)? = outcome else {
                    XCTFail("\(name): an empty \(status) should fail: \(String(describing: outcome))")
                    continue
                }
                XCTAssertEqual((error as? ZBError)?.statusCode, status, "\(name): \(error)")
            }
        }
    }

    func testOfflineStreamingDownloadWritesStraightToDisk() {
        let sdk = ZeroBounceSDK()
        sdk.initialize(apiKey: "stream-key")
        let path = NSTemporaryDirectory() + "zb-offline-stream.csv"
        try? FileManager.default.removeItem(atPath: path)

        var saved: String?
        var done = expectation(description: "streamed")
        sdk.getFileStreaming(fileId: "fid", downloadPath: path) { result in
            if case .Success(let response) = result { saved = response.localFilePath }
            done.fulfill()
        }
        wait(for: [done], timeout: 5)
        XCTAssertEqual(saved, path)
        XCTAssertTrue((try? String(contentsOfFile: path, encoding: .utf8))?.hasPrefix("email") == true)
        try? FileManager.default.removeItem(atPath: path)

        // getfile answers an unknown or deleted id with a JSON error rather
        // than a file, so the probe must catch it and leave nothing behind.
        let failing = ZeroBounceSDK()
        failing.initialize(apiKey: "success-false")
        var message = ""
        done = expectation(description: "streamed error")
        failing.getFileStreaming(fileId: "fid", downloadPath: path) { result in
            if case .Failure(let error) = result {
                message = (error as? LocalizedError)?.errorDescription ?? "\(error)"
            }
            done.fulfill()
        }
        wait(for: [done], timeout: 5)
        XCTAssertTrue(message.contains("File cannot be found"), message)
        XCTAssertFalse(FileManager.default.fileExists(atPath: path))

        done = expectation(description: "blank path")
        sdk.getFileStreaming(fileId: "fid", downloadPath: " ") { result in
            if case .Failure(let error) = result {
                message = (error as? LocalizedError)?.errorDescription ?? "\(error)"
            }
            done.fulfill()
        }
        wait(for: [done], timeout: 5)
        XCTAssertTrue(message.contains("downloadPath"), message)
    }

    // MARK: Release fixes (2.2.0)

    /// Synthesized `Decodable` skips a `let` that already has a value, so
    /// `activeInDays`, `activeFirstSeen`, `freeEmail`, `mxFound` and
    /// `catchallDomain` were never read: `active_in_days: "30"` came back nil
    /// and `free_email: true` came back false.
    func testValidateResponseReadsActivityAndTheBooleanFields() throws {
        func decode(_ fields: String) throws -> ZBValidateResponse {
            let json = #"{"address":"a@example.com","status":"valid","processed_at":"2010-01-01"\#(fields)}"#
            return try JSONDecoder().decode(ZBValidateResponse.self, from: Data(json.utf8))
        }
        let full = try decode(#","active_in_days":"30","active_first_seen":"2024-01-15","free_email":true,"mx_found":"true","catchall_domain":true"#)
        XCTAssertEqual(full.activeInDays, "30")
        XCTAssertEqual(full.activeFirstSeen, "2024-01-15")
        XCTAssertTrue(full.freeEmail)
        // The API sends mx_found as the string "true" rather than a boolean.
        XCTAssertTrue(full.mxFound)
        XCTAssertEqual(full.catchallDomain, true)

        let strings = try decode(#","free_email":"True","mx_found":"false","catchall_domain":"false","active_in_days":180"#)
        XCTAssertTrue(strings.freeEmail)
        XCTAssertFalse(strings.mxFound)
        XCTAssertEqual(strings.catchallDomain, false)
        XCTAssertEqual(strings.activeInDays, "180")

        // Absent, null or of an unexpected type: the default, and the rest of
        // the response still decodes.
        let absent = try decode("")
        XCTAssertNil(absent.activeInDays)
        XCTAssertNil(absent.activeFirstSeen)
        XCTAssertFalse(absent.freeEmail)
        XCTAssertFalse(absent.mxFound)
        XCTAssertNil(absent.catchallDomain)
        let odd = try decode(#","free_email":null,"mx_found":"maybe","catchall_domain":[],"active_in_days":{}"#)
        XCTAssertFalse(odd.freeEmail)
        XCTAssertFalse(odd.mxFound)
        XCTAssertNil(odd.catchallDomain)
        XCTAssertNil(odd.activeInDays)
        XCTAssertEqual(odd.status, .valid)

        // Through validate, and through a batch.
        let encoded = try JSONEncoder().encode(full)
        XCTAssertEqual(try JSONDecoder().decode(ZBValidateResponse.self, from: encoded), full)
        let batch = #"{"email_batch":[{"address":"a@example.com","status":"valid","processed_at":"2010-01-01","active_in_days":"30","free_email":true}],"errors":[]}"#
        let decodedBatch = try JSONDecoder().decode(ZBValidateBatchResponse.self, from: Data(batch.utf8))
        XCTAssertEqual(decodedBatch.emailBatch.first?.activeInDays, "30")
        XCTAssertEqual(decodedBatch.emailBatch.first?.freeEmail, true)
    }

    /// The release notes promise a 120 s timeout on API requests, but the
    /// downloads, the GETs built from a bare URL and every upload were left at
    /// URLRequest's default of 60.
    func testEveryRequestTimesOutAfter120Seconds() throws {
        let csv = Data("email\na@example.com\n".utf8)
        let byPath = try ZBMultiPartRequest.createFileRequest(
            url: "https://bulkapi.zerobounce.net/v2/sendfile", parameters: ["api_key": "k"],
            filePathKey: "file", paths: [writeTemporaryCsv("zb-timeout-path.csv")]
        )
        XCTAssertEqual(byPath.timeoutInterval, 120)
        let byData = try ZBMultiPartRequest.createFileRequestWithData(
            url: "https://bulkapi.zerobounce.net/v2/sendfile", parameters: ["api_key": "k"],
            filePathKey: "file", fileData: csv, fileName: "list.csv"
        )
        XCTAssertEqual(byData.timeoutInterval, 120)

        let sdk = ZeroBounceSDK()
        sdk.initialize(apiKey: "timeout-key")
        let csvPath = writeTemporaryCsv("zb-timeout-upload.csv")
        let download = NSTemporaryDirectory() + "zb-timeout-download.csv"
        var finderOptions = ZBEmailFinderSendFileOptions()
        finderOptions.firstNameColumn = 2
        let calls: [(String, (@escaping () -> ()) -> ())] = [
            ("getFile", { done in sdk.getFile(fileId: "f") { _ in done() } }),
            ("scoringGetFile", { done in sdk.scoringGetFile(fileId: "f") { _ in done() } }),
            ("emailFinderGetFile", { done in sdk.emailFinderGetFile(fileId: "f", downloadPath: download) { _ in done() } }),
            ("domainSearchGetFile", { done in sdk.domainSearchGetFile(fileId: "f", downloadPath: download) { _ in done() } }),
            ("listFilters", { done in sdk.listFilters { _ in done() } }),
            ("getListEvaluatorResult", { done in sdk.getListEvaluatorResult(fileId: "f") { _ in done() } }),
            ("sendFile path", { done in sdk.sendFile(filePath: csvPath, emailAddressColumn: 1) { _ in done() } }),
            ("sendFile data", { done in
                sdk.sendFile(fileData: csv, fileName: "list.csv", emailAddressColumn: 1) { _ in done() }
            }),
            ("scoringSendFile", { done in sdk.scoringSendFile(filePath: csvPath, emailAddressColumn: 1) { _ in done() } }),
            ("sendEmailFinderFile", { done in
                sdk.sendEmailFinderFile(filePath: csvPath, domainColumn: 1, options: finderOptions) { _ in done() }
            }),
            ("sendListEvaluatorFileData", { done in
                sdk.sendListEvaluatorFileData(fileData: csv, fileName: "list.csv", emailAddressColumn: 1) { _ in done() }
            }),
            ("getCredits", { done in sdk.getCredits { _ in done() } }),
            ("getFileStreaming", { done in sdk.getFileStreaming(fileId: "f", downloadPath: download) { _ in done() } }),
        ]
        for (name, call) in calls {
            XCTAssertEqual(send(call).timeout, 120, name)
        }
        try? FileManager.default.removeItem(atPath: download)
    }

    /// The Inbox Placement Tester sent "Authorization: Bearer " with an empty
    /// key instead of reporting notInitialized like every other call.
    func testInboxPlacementRejectsAMissingOrEmptyKeyBeforeSending() {
        let empty = ZeroBounceSDK()
        empty.initialize(apiKey: "")
        let uninitialized = ZeroBounceSDK()
        for sdk in [empty, uninitialized] {
            let calls: [(@escaping (String?) -> ()) -> ()] = [
                { report in sdk.getInboxPlacementProviders { report(self.dictFailureText($0)) } },
                { report in sdk.getInboxPlacementTestTypes { report(self.dictFailureText($0)) } },
                { report in sdk.createInboxPlacementTest(name: "Launch") { report(self.dictFailureText($0)) } },
                { report in sdk.getInboxPlacementTest(testId: "123") { report(self.dictFailureText($0)) } },
                { report in sdk.listInboxPlacementTests { report(self.dictFailureText($0)) } },
                { report in sdk.deleteInboxPlacementTest(testId: "123") { report(self.dictFailureText($0)) } },
                { report in sdk.getInboxPlacementWebhook { report(self.dictFailureText($0)) } },
                { report in
                    sdk.setInboxPlacementWebhook(webhookUrl: "https://example.com/hook") { report(self.dictFailureText($0)) }
                },
            ]
            for call in calls {
                expectRejected("notInitialized", call)
            }
        }
    }

    /// A URLProtocol registered globally does not reach the SDK's own session,
    /// so apps need a supported way to put one on it.
    func testSessionConfigurationIsTheWayToStubRequests() {
        // A session with no stub on it, as an app starts with.
        ZeroBounceSDK.urlSession = ZeroBounceSDK.makeSession()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [OfflineURLProtocol.self]
        ZeroBounceSDK.setSessionConfiguration(configuration)
        // The caller's configuration object is left as it was given.
        XCTAssertEqual(configuration.protocolClasses?.count, 1)

        let sdk = ZeroBounceSDK()
        sdk.initialize(apiKey: "hooked-key")
        let record = send { done in sdk.getCredits { _ in done() } }
        XCTAssertEqual(record.apiKey, "hooked-key")
        XCTAssertEqual(record.timeout, 120)

        // nil goes back to the default session, which carries no stub.
        ZeroBounceSDK.setSessionConfiguration(nil)
        let restored = ZeroBounceSDK.urlSession.configuration.protocolClasses ?? []
        XCTAssertFalse(restored.contains { ObjectIdentifier($0) == ObjectIdentifier(OfflineURLProtocol.self) })
        XCTAssertEqual(ZeroBounceSDK.urlSession.configuration.timeoutIntervalForRequest, 120)
    }

    private func writeTemporaryCsv(_ name: String) -> String {
        let path = NSTemporaryDirectory() + name
        try? "email\na@example.com\n".write(toFile: path, atomically: true, encoding: .utf8)
        return path
    }
}

/// Offline tests for the Warmup API client.
///
/// Every request is answered by `OfflineURLProtocol`; nothing here reaches the
/// live API. The assertions are on the url, the method, the body and the one
/// header that actually went out.
final class OfflineWarmupTests: XCTestCase {
    private var liveSession: URLSession!
    private let root = "/api/v1/warmup"

    override func setUp() {
        super.setUp()
        OfflineURLProtocol.enabled = true
        OfflineURLProtocol.records = []
        liveSession = ZeroBounceSDK.urlSession
        ZeroBounceSDK.urlSession = ZeroBounceSDK.makeSession(protocolClasses: [OfflineURLProtocol.self])
    }

    override func tearDown() {
        OfflineURLProtocol.enabled = false
        ZeroBounceSDK.urlSession = liveSession
        super.tearDown()
    }

    private func client(_ key: String = "warm-key") -> ZeroBounceWarmup {
        let warmup = ZeroBounceWarmup()
        warmup.initialize(apiKey: key)
        return warmup
    }

    /// Runs one call and hands back the single request it sent.
    private func send(_ block: (@escaping () -> ()) -> ()) -> OfflineRecord {
        OfflineURLProtocol.records = []
        let done = expectation(description: "request finished")
        block { done.fulfill() }
        wait(for: [done], timeout: 5)
        XCTAssertEqual(OfflineURLProtocol.records.count, 1)
        return OfflineURLProtocol.records[0]
    }

    /// Runs one call that must be rejected before any request is sent.
    private func expectRejected(
        _ fragment: String,
        file: StaticString = #file,
        line: UInt = #line,
        _ block: (@escaping (String?) -> ()) -> ()
    ) {
        OfflineURLProtocol.records = []
        var message: String?
        let done = expectation(description: "rejected: \(fragment)")
        block { text in
            message = text
            done.fulfill()
        }
        wait(for: [done], timeout: 5)
        XCTAssertNotNil(message, "expected a failure mentioning \(fragment)", file: file, line: line)
        XCTAssertTrue(message?.contains(fragment) == true, message ?? "", file: file, line: line)
        XCTAssertEqual(OfflineURLProtocol.records.count, 0, "no request should have been sent", file: file, line: line)
    }

    private func failureText(_ result: ZeroBounceWarmup.ZBWarmupResult) -> String? {
        if case .Failure(let error) = result {
            return (error as? LocalizedError)?.errorDescription ?? "\(error)"
        }
        return nil
    }

    func testEveryCallCarriesTheApiKeyHeaderAndItsOwnHost() {
        let warmup = client()
        let sent = send { finish in warmup.listSendingAccounts { _ in finish() } }

        XCTAssertEqual(sent.method, "GET")
        // Its own host and base path, not the validation API's.
        XCTAssertEqual(sent.host, "warmup-api.zerobounce.net")
        XCTAssertEqual(sent.path, "\(root)/sending-accounts")
        // The Warmup API authenticates with an API-Key header; the validation
        // api_key never appears.
        XCTAssertEqual(sent.authHeader, "API-Key: warm-key")
        XCTAssertFalse(sent.query.contains("api_key="), sent.query)
    }

    func testAnUninitializedClientSendsNothing() {
        let warmup = ZeroBounceWarmup()
        expectRejected("ZeroBounceWarmup.shared.initialize") { report in
            warmup.getSeeds { report(self.failureText($0)) }
        }

        // A key with surrounding whitespace or control characters would be
        // quoted, unredacted, in a transport error.
        warmup.initialize(apiKey: " warm-key")
        XCTAssertNil(warmup.apiKey)
        warmup.initialize(apiKey: "warm-key")
        XCTAssertEqual(warmup.apiKey, "warm-key")
    }

    func testReadsUseTheDocumentedPaths() {
        let warmup = client()

        XCTAssertEqual(
            send { finish in warmup.getSendingAccount(fromAddress: "sender@example.com") { _ in finish() } }.path,
            "\(root)/sending-account"
        )
        XCTAssertEqual(send { finish in warmup.getEngagementRules { _ in finish() } }.path, "\(root)/engagement-rules")
        XCTAssertEqual(send { finish in warmup.getSeeds { _ in finish() } }.path, "\(root)/seeds")
        XCTAssertEqual(send { finish in warmup.getProgressToday { _ in finish() } }.path, "\(root)/progress-today")
        XCTAssertEqual(send { finish in warmup.getSentToday { _ in finish() } }.path, "\(root)/sent-today")
        XCTAssertEqual(send { finish in warmup.getEmailsPerDay { _ in finish() } }.path, "\(root)/emails-per-day")
        XCTAssertEqual(
            send { finish in warmup.getStatistics(fromAddress: "sender@example.com") { _ in finish() } }.path,
            "\(root)/statistics"
        )
        XCTAssertEqual(
            send { finish in warmup.getStatisticsDetailed(cFrom: "sender@example.com") { _ in finish() } }.path,
            "\(root)/statistics-detailed"
        )
        XCTAssertEqual(
            send { finish in warmup.getFromAddressStatistics(fromAddress: "sender@example.com") { _ in finish() } }.path,
            "\(root)/from-address-statistics"
        )

        let account = send { finish in
            warmup.getSendingAccount(fromAddress: "sender@example.com") { _ in finish() }
        }
        XCTAssertTrue(account.query.contains("from_address=sender@example.com")
            || account.query.contains("from_address=sender%40example.com"), account.query)

        // c_from is one path segment here, so a slash must stay encoded.
        let custom = send { finish in warmup.getCustomEngagement(cFrom: "a b/c") { _ in finish() } }
        XCTAssertTrue(custom.rawPath.contains("\(root)/custom-engagement/a%20b%2Fc"), custom.rawPath)
    }

    func testSeedCountAnswersABareNumber() {
        let warmup = client()
        var value: Any??
        let done = expectation(description: "seed count")
        warmup.getSeedCount { result in
            if case .Success(let object) = result { value = object }
            done.fulfill()
        }
        wait(for: [done], timeout: 5)
        XCTAssertEqual((value ?? nil) as? Int, 42)
    }

    func testEmptySuccessesComeBackAsNil() {
        // 204 and an empty 200 are the documented empty successes.
        let warmup = client("warm-empty")
        var wasSuccess = false
        var value: Any??
        let done = expectation(description: "empty success")
        warmup.getSentToday { result in
            if case .Success(let object) = result {
                wasSuccess = true
                value = object
            }
            done.fulfill()
        }
        wait(for: [done], timeout: 5)
        XCTAssertTrue(wasSuccess)
        XCTAssertNil(value ?? nil)
    }

    func testAddSendingAccount() {
        let warmup = client()

        let selfManaged = send { finish in
            warmup.addSendingAccount(
                fromAddress: "sender@example.com",
                onboardingModel: ZeroBounceWarmup.selfManaged,
                options: ZBWarmupAddSendingAccountOptions(engagementRuleId: 2, ignoreConflict: true)
            ) { _ in finish() }
        }
        XCTAssertEqual(selfManaged.method, "POST")
        XCTAssertEqual(selfManaged.path, "\(root)/sending-accounts")
        XCTAssertTrue(selfManaged.body.contains("\"onboarding_model\":\"self_managed\""), selfManaged.body)
        XCTAssertTrue(selfManaged.body.contains("\"engagement_rule_id\":2"), selfManaged.body)
        XCTAssertTrue(selfManaged.body.contains("\"ignore_conflict\":true"), selfManaged.body)

        // A self-managed account needs an engagement rule, and the ZB managed
        // extras belong to the other model.
        expectRejected("engagement_rule_id") { report in
            warmup.addSendingAccount(
                fromAddress: "sender@example.com",
                onboardingModel: ZeroBounceWarmup.selfManaged
            ) { report(self.failureText($0)) }
        }
        expectRejected("zb_managed") { report in
            warmup.addSendingAccount(
                fromAddress: "sender@example.com",
                onboardingModel: ZeroBounceWarmup.selfManaged,
                options: ZBWarmupAddSendingAccountOptions(
                    engagementRuleId: 0,
                    emailContent: ZBWarmupEmailContent(companyName: "Example")
                )
            ) { report(self.failureText($0)) }
        }
        expectRejected("onboarding_model") { report in
            warmup.addSendingAccount(fromAddress: "sender@example.com", onboardingModel: "whatever") {
                report(self.failureText($0))
            }
        }

        let managed = send { finish in
            warmup.addSendingAccount(
                fromAddress: "sender@example.com",
                onboardingModel: ZeroBounceWarmup.zbManaged,
                options: ZBWarmupAddSendingAccountOptions(
                    emailContent: ZBWarmupEmailContent(
                        companyName: "Example",
                        typesOfEmails: ["newsletter", "marketing"]
                    ),
                    managedSending: ZBWarmupManagedSending(
                        weekdaysOnly: true,
                        timezoneOffsetHours: 3,
                        warmupStartDate: "2026-11-02"
                    )
                )
            ) { _ in finish() }
        }
        XCTAssertTrue(managed.body.contains("\"company_name\":\"Example\""), managed.body)
        XCTAssertTrue(managed.body.contains("\"types_of_emails\":[\"newsletter\",\"marketing\"]"), managed.body)
        XCTAssertTrue(managed.body.contains("\"timezone_offset\":3"), managed.body)
        XCTAssertTrue(managed.body.contains("\"warmup_start_date\":\"2026-11-02\""), managed.body)
        XCTAssertFalse(managed.body.contains("engagement_rule_id"), managed.body)

        expectRejected("types_of_emails") { report in
            warmup.addSendingAccount(
                fromAddress: "sender@example.com",
                onboardingModel: ZeroBounceWarmup.zbManaged,
                options: ZBWarmupAddSendingAccountOptions(
                    emailContent: ZBWarmupEmailContent(typesOfEmails: ["postcards"])
                )
            ) { report(self.failureText($0)) }
        }
        expectRejected("timezone_offset") { report in
            warmup.addSendingAccount(
                fromAddress: "sender@example.com",
                onboardingModel: ZeroBounceWarmup.zbManaged,
                options: ZBWarmupAddSendingAccountOptions(
                    managedSending: ZBWarmupManagedSending(timezoneOffsetHours: 15)
                )
            ) { report(self.failureText($0)) }
        }
        expectRejected("warmup_start_date") { report in
            warmup.addSendingAccount(
                fromAddress: "sender@example.com",
                onboardingModel: ZeroBounceWarmup.zbManaged,
                options: ZBWarmupAddSendingAccountOptions(
                    managedSending: ZBWarmupManagedSending(warmupStartDate: "02/11/2026")
                )
            ) { report(self.failureText($0)) }
        }
    }

    /// The documented zb_managed payload (warmup-api/adding-a-sending-account),
    /// with every field set, and a fractional timezone_offset of -11.0 to 14.0.
    func testAddSendingAccountZbManagedSendsTheDocumentedPayload() {
        let warmup = client()

        func managed(_ offset: Double?) -> ZBWarmupAddSendingAccountOptions {
            ZBWarmupAddSendingAccountOptions(
                emailContent: ZBWarmupEmailContent(
                    companyName: "Example",
                    companyWebsite: "https://example.com",
                    companyDescription: "We make examples.",
                    typesOfEmails: ["transactional", "newsletter", "marketing"],
                    exampleEmail: "Hello from Example."
                ),
                managedSending: ZBWarmupManagedSending(
                    weekdaysOnly: false,
                    timezone: "Asia/Kolkata",
                    timezoneOffsetHours: offset,
                    warmupStartDate: "2026-11-02"
                )
            )
        }
        func body(_ record: OfflineRecord) -> NSDictionary {
            let object = try? JSONSerialization.jsonObject(with: Data(record.body.utf8))
            return (object as? NSDictionary) ?? [:]
        }

        let sent = send { finish in
            warmup.addSendingAccount(
                fromAddress: "sender@example.com",
                onboardingModel: ZeroBounceWarmup.zbManaged,
                options: managed(5.5)
            ) { _ in finish() }
        }
        XCTAssertEqual(sent.method, "POST")
        XCTAssertEqual(body(sent), [
            "from_address": "sender@example.com",
            "onboarding_model": "zb_managed",
            "email_content": [
                "company_name": "Example",
                "company_website": "https://example.com",
                "company_description": "We make examples.",
                "types_of_emails": ["transactional", "newsletter", "marketing"],
                "example_email": "Hello from Example."
            ],
            "managed_sending": [
                "weekdays_only": false,
                "timezone": "Asia/Kolkata",
                "timezone_offset": 5.5,
                "warmup_start_date": "2026-11-02"
            ]
        ] as NSDictionary, sent.body)
        // A strict JSON boolean and number, not strings.
        XCTAssertTrue(sent.body.contains("\"weekdays_only\":false"), sent.body)
        XCTAssertTrue(sent.body.contains("\"timezone_offset\":5.5"), sent.body)

        for offset in [3.0, -11.0, 14.0, -3.5, 5.75] {
            let accepted = send { finish in
                warmup.addSendingAccount(
                    fromAddress: "sender@example.com",
                    onboardingModel: ZeroBounceWarmup.zbManaged,
                    options: managed(offset)
                ) { _ in finish() }
            }
            let sending = body(accepted)["managed_sending"] as? NSDictionary
            XCTAssertEqual((sending?["timezone_offset"] as? NSNumber)?.doubleValue, offset, accepted.body)
        }
        for offset in [-11.5, 14.5, -12.0, 15.0, .nan, .infinity] {
            expectRejected("timezone_offset") { report in
                warmup.addSendingAccount(
                    fromAddress: "sender@example.com",
                    onboardingModel: ZeroBounceWarmup.zbManaged,
                    options: managed(offset)
                ) { report(self.failureText($0)) }
            }
        }

        // Unset fields stay off the request.
        let bare = send { finish in
            warmup.addSendingAccount(
                fromAddress: "sender@example.com",
                onboardingModel: ZeroBounceWarmup.zbManaged,
                options: managed(nil)
            ) { _ in finish() }
        }
        XCTAssertNil((body(bare)["managed_sending"] as? NSDictionary)?["timezone_offset"], bare.body)
    }

    /// 3.x code built `ZBWarmupManagedSending` with an `Int` offset and read
    /// `timezoneOffset` back; both still compile and behave as before.
    @available(*, deprecated)
    func testAddSendingAccountKeepsTheIntTimezoneOffset() {
        let warmup = client()
        let hours: Int = -5
        var sending = ZBWarmupManagedSending(weekdaysOnly: true, timezoneOffset: hours)
        XCTAssertEqual(sending.timezoneOffset, -5)
        XCTAssertEqual(sending.timezoneOffsetHours, -5.0)
        sending.timezoneOffset = 14
        XCTAssertEqual(sending.timezoneOffsetHours, 14.0)
        sending.timezoneOffsetHours = 5.5
        // A fractional offset has no Int form.
        XCTAssertNil(sending.timezoneOffset)
        sending.timezoneOffset = 7

        let sent = send { finish in
            warmup.addSendingAccount(
                fromAddress: "sender@example.com",
                onboardingModel: ZeroBounceWarmup.zbManaged,
                options: ZBWarmupAddSendingAccountOptions(managedSending: sending)
            ) { _ in finish() }
        }
        XCTAssertTrue(sent.body.contains("\"timezone_offset\":7"), sent.body)
        XCTAssertTrue(sent.body.contains("\"weekdays_only\":true"), sent.body)
    }

    func testUpdateAndDeleteSendingAccount() {
        let warmup = client()

        let updated = send { finish in
            warmup.updateSendingAccount(
                fromAddress: "sender@example.com", engagementRuleId: 1, statusId: 4, autoEnable: true
            ) { _ in finish() }
        }
        XCTAssertEqual(updated.method, "PUT")
        XCTAssertEqual(updated.path, "\(root)/sending-accounts")
        XCTAssertTrue(updated.body.contains("\"team_id\":1"), updated.body)
        XCTAssertTrue(updated.body.contains("\"status_id\":4"), updated.body)
        XCTAssertTrue(updated.body.contains("\"auto_enable\":true"), updated.body)

        let deleted = send { finish in
            warmup.deleteSendingAccount(fromAddress: "sender@example.com") { _ in finish() }
        }
        XCTAssertEqual(deleted.method, "DELETE")
        XCTAssertEqual(deleted.path, "\(root)/sending-accounts")

        // Despite the path, nothing about SMTP credentials is stored.
        let moved = send { finish in
            warmup.changeFromAddress(oldFromAddress: "old@example.com", newFromAddress: "new@example.com") { _ in finish() }
        }
        XCTAssertEqual(moved.method, "PUT")
        XCTAssertEqual(moved.path, "\(root)/smtp-credentials")
        XCTAssertTrue(moved.body.contains("\"old_from_address\":\"old@example.com\""), moved.body)

        expectRejected("engagement_rule_id") { report in
            warmup.updateSendingAccount(
                fromAddress: "sender@example.com", engagementRuleId: 9, statusId: 4, autoEnable: false
            ) { report(self.failureText($0)) }
        }
        expectRejected("status_id") { report in
            warmup.updateSendingAccount(
                fromAddress: "sender@example.com", engagementRuleId: 1, statusId: 9, autoEnable: false
            ) { report(self.failureText($0)) }
        }
        expectRejected("new_from_address") { report in
            warmup.changeFromAddress(oldFromAddress: "old@example.com", newFromAddress: " ") {
                report(self.failureText($0))
            }
        }
    }

    func testListFromAddresses() {
        let warmup = client()

        let bare = send { finish in warmup.listFromAddresses { _ in finish() } }
        XCTAssertEqual(bare.path, "\(root)/from-addresses")
        XCTAssertEqual(bare.query, "")

        let filtered = send { finish in
            warmup.listFromAddresses(
                options: ZBWarmupListFromAddressesOptions(searchFrom: "sender@example.com", offset: 20, limit: 50)
            ) { _ in finish() }
        }
        XCTAssertTrue(filtered.query.contains("offset=20"), filtered.query)
        XCTAssertTrue(filtered.query.contains("limit=50"), filtered.query)

        expectRejected("search_from") { report in
            warmup.listFromAddresses(options: ZBWarmupListFromAddressesOptions(searchFrom: "a b")) {
                report(self.failureText($0))
            }
        }
    }

    func testEngagementRules() {
        let warmup = client()

        let standard = send { finish in
            warmup.setEngagementRule(cFrom: "sender@example.com", ruleId: 3) { _ in finish() }
        }
        XCTAssertEqual(standard.method, "PUT")
        XCTAssertEqual(standard.path, "\(root)/engagement-rule")
        XCTAssertTrue(standard.body.contains("\"rule_id\":3"), standard.body)

        let created = send { finish in
            warmup.createCustomEngagement(
                cFrom: "sender@example.com", replyPct: 10, importantPct: 20, clickPct: 30
            ) { _ in finish() }
        }
        XCTAssertEqual(created.method, "POST")
        XCTAssertEqual(created.path, "\(root)/custom-engagement")
        XCTAssertTrue(created.body.contains("\"reply_pct\":10"), created.body)

        let updated = send { finish in
            warmup.updateCustomEngagement(
                cFrom: "sender@example.com", replyPct: 10, importantPct: 20, clickPct: 30
            ) { _ in finish() }
        }
        XCTAssertEqual(updated.method, "PUT")

        let removed = send { finish in
            warmup.deleteCustomEngagement(cFrom: "sender@example.com", engagementRuleId: 2) { _ in finish() }
        }
        XCTAssertEqual(removed.method, "DELETE")
        XCTAssertTrue(removed.body.contains("\"engagement_rule_id\":2"), removed.body)

        // The ranges are checked before anything is sent.
        expectRejected("reply_pct") { report in
            warmup.createCustomEngagement(cFrom: "sender@example.com", replyPct: 4, importantPct: 20, clickPct: 10) {
                report(self.failureText($0))
            }
        }
        expectRejected("important_pct") { report in
            warmup.createCustomEngagement(cFrom: "sender@example.com", replyPct: 10, importantPct: 41, clickPct: 10) {
                report(self.failureText($0))
            }
        }
        // click_pct is capped at important_pct x 1.75 as well as at 70.
        expectRejected("click_pct") { report in
            warmup.createCustomEngagement(cFrom: "sender@example.com", replyPct: 10, importantPct: 20, clickPct: 36) {
                report(self.failureText($0))
            }
        }
        // and exactly 1.75 x is still allowed.
        XCTAssertEqual(
            send { finish in
                warmup.createCustomEngagement(cFrom: "sender@example.com", replyPct: 10, importantPct: 20, clickPct: 35) { _ in finish() }
            }.path,
            "\(root)/custom-engagement"
        )
        // Falling back to the custom rule itself is not a standard rule.
        expectRejected("engagement_rule_id") { report in
            warmup.deleteCustomEngagement(cFrom: "sender@example.com", engagementRuleId: 0) {
                report(self.failureText($0))
            }
        }
    }

    func testStatisticsPerDayChecksItsDates() {
        let warmup = client()

        let ranged = send { finish in
            warmup.getStatisticsPerDay(
                fromAddress: "sender@example.com", startDate: "2026-10-01", endDate: "2026-10-07"
            ) { _ in finish() }
        }
        XCTAssertEqual(ranged.path, "\(root)/statistics-per-day")
        XCTAssertTrue(ranged.query.contains("start_date=2026-10-01"), ranged.query)
        XCTAssertTrue(ranged.query.contains("end_date=2026-10-07"), ranged.query)

        expectRejected("start_date") { report in
            warmup.getStatisticsPerDay(
                fromAddress: "sender@example.com", startDate: "10/01/2026", endDate: "2026-10-07"
            ) { report(self.failureText($0)) }
        }
        expectRejected("later than") { report in
            warmup.getStatisticsPerDay(
                fromAddress: "sender@example.com", startDate: "2026-10-08", endDate: "2026-10-07"
            ) { report(self.failureText($0)) }
        }
    }

    func testCheckDomainDmarcNeedsAnEmailAddress() {
        let warmup = client()

        let checked = send { finish in
            warmup.checkDomainDmarc(fromAddress: "sender@example.com", dkimSelector: "selector1") { _ in finish() }
        }
        XCTAssertEqual(checked.path, "\(root)/check-domain-dmarc")
        XCTAssertTrue(checked.query.contains("dkim_selector=selector1"), checked.query)

        let bare = send { finish in
            warmup.checkDomainDmarc(fromAddress: "sender@example.com") { _ in finish() }
        }
        XCTAssertFalse(bare.query.contains("dkim_selector"), bare.query)

        // LIVE: the docs describe a domain, but a bare domain is answered with
        // "Please provide a valid email address".
        expectRejected("email address") { report in
            warmup.checkDomainDmarc(fromAddress: "example.com") { report(self.failureText($0)) }
        }
    }

    func testTestSmtpConfigurationKeepsCredentialsOutOfTheError() {
        let warmup = client()

        let sent = send { finish in
            warmup.testSmtpConfiguration(
                fromAddress: "sender@example.com", username: "sender@example.com",
                password: "sekrit", server: "smtp.example.com", port: 587
            ) { _ in finish() }
        }
        XCTAssertEqual(sent.method, "POST")
        XCTAssertEqual(sent.path, "\(root)/test-smtp-configuration")
        XCTAssertTrue(sent.body.contains("\"port\":587"), sent.body)

        expectRejected("port") { report in
            warmup.testSmtpConfiguration(
                fromAddress: "sender@example.com", username: "sender@example.com",
                password: "sekrit", server: "smtp.example.com", port: 0
            ) { report(self.failureText($0)) }
        }

        // LIVE: a failed SMTP login is answered with HTTP 500, and the
        // password must not travel out in the error.
        let failing = client("warm-500")
        var message = ""
        var status: Int?
        let done = expectation(description: "smtp failure")
        failing.testSmtpConfiguration(
            fromAddress: "sender@example.com", username: "sender@example.com",
            password: "sekrit", server: "smtp.example.com", port: 587
        ) { result in
            if case .Failure(let error) = result {
                message = (error as? LocalizedError)?.errorDescription ?? "\(error)"
                status = (error as? ZBError)?.statusCode
            }
            done.fulfill()
        }
        wait(for: [done], timeout: 5)
        XCTAssertEqual(status, 500)
        XCTAssertFalse(message.contains("sekrit"), message)
        XCTAssertTrue(message.contains("***"), message)
    }

    func testCsvDownloads() {
        let warmup = client()

        var seeds = ""
        var done = expectation(description: "seeds csv")
        warmup.downloadSeeds { result in
            if case .Success(let text) = result { seeds = text }
            done.fulfill()
        }
        wait(for: [done], timeout: 5)
        XCTAssertTrue(seeds.hasPrefix("seed,provider"), seeds)

        var stats = ""
        done = expectation(description: "statistics csv")
        warmup.downloadStatistics(cFrom: "sender@example.com") { result in
            if case .Success(let text) = result { stats = text }
            done.fulfill()
        }
        wait(for: [done], timeout: 5)
        XCTAssertTrue(stats.hasPrefix("date,sent"), stats)

        // An error comes back as JSON, so it is not a file.
        let failing = client("warm-json-download")
        var message = ""
        done = expectation(description: "json instead of csv")
        failing.downloadSeeds { result in
            if case .Failure(let error) = result {
                message = (error as? LocalizedError)?.errorDescription ?? "\(error)"
            }
            done.fulfill()
        }
        wait(for: [done], timeout: 5)
        XCTAssertTrue(message.contains("nothing here"), message)
    }

    func testAnUnknownResourceKeepsItsStatusAndHidesTheKey() {
        let warmup = client("warm-404")
        var status: Int?
        var message = ""
        let done = expectation(description: "unknown resource")
        warmup.getCustomEngagement(cFrom: "no-such-address@example.com") { result in
            if case .Failure(let error) = result {
                status = (error as? ZBError)?.statusCode
                message = (error as? LocalizedError)?.errorDescription ?? "\(error)"
            }
            done.fulfill()
        }
        wait(for: [done], timeout: 5)
        XCTAssertEqual(status, 404)
        XCTAssertFalse(message.contains("warm-404"), message)
    }

    func testBlankArgumentsAreRejectedBeforeSending() {
        let warmup = client()

        expectRejected("from_address") { report in
            warmup.getSendingAccount(fromAddress: "  ") { report(self.failureText($0)) }
        }
        expectRejected("c_from") { report in
            warmup.getStatisticsDetailed(cFrom: "  ") { report(self.failureText($0)) }
        }
        // A path segment of "." or ".." would walk the request out of the
        // endpoint it was meant for.
        expectRejected("c_from") { report in
            warmup.getCustomEngagement(cFrom: "..") { report(self.failureText($0)) }
        }
    }
}


/// Transport rules that hold for every public request method: HTTPS only, no
/// redirects, an explicit timeout, base URLs without a trailing slash.
///
/// Every request is answered by `OfflineURLProtocol`; nothing here reaches the
/// live API.
/// The public request methods the SDK declares, read from its sources when
/// the test runs: every `public func` in "Zero Bounce iOS SDK/*.swift" that
/// takes a `completion` handler, by name, with how many overloads it has.
/// Sweeps that must reach every request method check themselves against
/// this, so a method added later cannot be left out of them.
func publicRequestMethodsInSources(testFile: String = #filePath) throws -> [String: Int] {
    let sources = URL(fileURLWithPath: testFile)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Zero Bounce iOS SDK")
    let files = try FileManager.default.contentsOfDirectory(at: sources, includingPropertiesForKeys: nil)
        .filter { $0.pathExtension == "swift" }
    let declaration = try NSRegularExpression(pattern: #"\bpublic\s+(?:(?:static|final|class)\s+)*func\s+(\w+)\s*\("#)
    var methods: [String: Int] = [:]
    for file in files {
        // Comment lines are left out, so a doc example is not a declaration.
        let text = try String(contentsOf: file, encoding: .utf8)
            .components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n") as NSString
        for match in declaration.matches(in: text as String, range: NSRange(location: 0, length: text.length)) {
            // The parameter list runs up to the body's opening brace.
            let signature = text.substring(from: match.range.upperBound).prefix { $0 != "{" }
            if signature.range(of: #"\bcompletion\s*:"#, options: .regularExpression) != nil {
                methods[text.substring(with: match.range(at: 1)), default: 0] += 1
            }
        }
    }
    return methods
}

final class TransportSafetyTests: XCTestCase {
    private var liveSession: URLSession!
    private var csvPath = ""
    private let download = NSTemporaryDirectory() + "zb-transport-download.csv"
    /// The SMTP password the sweep sends; "|", "/", '"', "+" and "%" give
    /// it distinct percent-encoded and JSON-escaped forms.
    static let smtpPassword = "smtp-pa|ss/wo\"r%d+"

    override func setUp() {
        super.setUp()
        OfflineURLProtocol.enabled = true
        OfflineURLProtocol.records = []
        liveSession = ZeroBounceSDK.urlSession
        ZeroBounceSDK.urlSession = ZeroBounceSDK.makeSession(protocolClasses: [OfflineURLProtocol.self])
        csvPath = NSTemporaryDirectory() + "zb-transport-upload.csv"
        try? "email\na@example.com\n".write(toFile: csvPath, atomically: true, encoding: .utf8)
    }

    override func tearDown() {
        OfflineURLProtocol.enabled = false
        ZeroBounceSDK.urlSession = liveSession
        try? FileManager.default.removeItem(atPath: download)
        super.tearDown()
    }

    private typealias Report = (Error?) -> ()

    private func err<T>(_ r: ZeroBounceSDK.ZBResult<T>) -> Error? {
        if case .Failure(let e) = r { return e }
        return nil
    }
    private func err(_ r: ZeroBounceSDK.ZBDictionaryResult) -> Error? {
        if case .Failure(let e) = r { return e }
        return nil
    }
    private func err(_ r: ZeroBounceSDK.ZBJsonResult) -> Error? {
        if case .Failure(let e) = r { return e }
        return nil
    }
    private func err(_ r: ZeroBounceWarmup.ZBWarmupResult) -> Error? {
        if case .Failure(let e) = r { return e }
        return nil
    }
    private func err(_ r: ZeroBounceWarmup.ZBWarmupCsvResult) -> Error? {
        if case .Failure(let e) = r { return e }
        return nil
    }

    /// Every public method that sends a request, with arguments that pass the
    /// local checks, so each one reaches the transport.
    private func everyCall(_ sdk: ZeroBounceSDK, _ warmup: ZeroBounceWarmup) -> [(String, (@escaping Report) -> ())] {
        let csv = Data("email\na@example.com\n".utf8)
        let path = csvPath
        let download = self.download
        var finder = ZBEmailFinderSendFileOptions()
        finder.firstNameColumn = 2
        let job = ZBBulkFileJobOptions(fileName: "f.csv", returnUrl: "https://example.com/done")
        let s3 = ZBValidateS3FileOptions(fileName: "f.csv", returnUrl: "https://example.com/done")
        let score = ZBScoreS3FileOptions(fileName: "f.csv", returnUrl: "https://example.com/done")
        var post = ZBValidateOptions()
        post.usePost = true
        var selfManaged = ZBWarmupAddSendingAccountOptions()
        selfManaged.engagementRuleId = 2
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        return [
            ("validate", { r in sdk.validate(email: "a@example.com") { r(self.err($0)) } }),
            ("validate POST", { r in sdk.validate(email: "a@example.com", options: post) { r(self.err($0)) } }),
            ("validateBatch", { r in sdk.validateBatch(emails: [["email_address": "a@example.com"]]) { r(self.err($0)) } }),
            ("validateBatch options", { r in
                sdk.validateBatch(emails: [["email_address": "a@example.com"]], options: ZBValidateOptions()) { r(self.err($0)) }
            }),
            ("findEmail domain", { r in sdk.findEmail(domain: "example.com", firstName: "Ada") { r(self.err($0)) } }),
            ("findEmail company", { r in sdk.findEmail(companyName: "Example", firstName: "Ada") { r(self.err($0)) } }),
            ("findDomain domain", { r in sdk.findDomain(domain: "example.com") { r(self.err($0)) } }),
            ("findDomain company", { r in sdk.findDomain(companyName: "Example") { r(self.err($0)) } }),
            ("guessFormat", { r in sdk.guessFormat(domain: "example.com") { r(self.err($0)) } }),
            ("getCredits", { r in sdk.getCredits { r(self.err($0)) } }),
            ("getApiUsage", { r in sdk.getApiUsage(startDate: start, endDate: start) { r(self.err($0)) } }),
            ("getActivityData", { r in sdk.getActivityData(email: "a@example.com") { r(self.err($0)) } }),
            ("scoreEmail", { r in sdk.scoreEmail(email: "a@example.com") { r(self.err($0)) } }),
            ("scoreEmailPost", { r in sdk.scoreEmailPost(email: "a@example.com") { r(self.err($0)) } }),
            ("sendEmailFinderFile", { r in sdk.sendEmailFinderFile(filePath: path, domainColumn: 1, options: finder) { r(self.err($0)) } }),
            ("sendEmailFinderFileData", { r in
                sdk.sendEmailFinderFileData(fileData: csv, fileName: "f.csv", domainColumn: 1, options: finder) { r(self.err($0)) }
            }),
            ("emailFinderFileStatus", { r in sdk.emailFinderFileStatus(fileId: "f") { r(self.err($0)) } }),
            ("emailFinderGetFile", { r in sdk.emailFinderGetFile(fileId: "f", downloadPath: download) { r(self.err($0)) } }),
            ("emailFinderDeleteFile", { r in sdk.emailFinderDeleteFile(fileId: "f") { r(self.err($0)) } }),
            ("sendDomainSearchFile", { r in sdk.sendDomainSearchFile(filePath: path, domainColumn: 1) { r(self.err($0)) } }),
            ("sendDomainSearchFileData", { r in
                sdk.sendDomainSearchFileData(fileData: csv, fileName: "f.csv", domainColumn: 1) { r(self.err($0)) }
            }),
            ("domainSearchFileStatus", { r in sdk.domainSearchFileStatus(fileId: "f") { r(self.err($0)) } }),
            ("domainSearchGetFile", { r in sdk.domainSearchGetFile(fileId: "f", downloadPath: download) { r(self.err($0)) } }),
            ("domainSearchDeleteFile", { r in sdk.domainSearchDeleteFile(fileId: "f") { r(self.err($0)) } }),
            ("sendListEvaluatorFile", { r in sdk.sendListEvaluatorFile(filePath: path, emailAddressColumn: 1) { r(self.err($0)) } }),
            ("sendListEvaluatorFileData", { r in
                sdk.sendListEvaluatorFileData(fileData: csv, fileName: "f.csv", emailAddressColumn: 1) { r(self.err($0)) }
            }),
            ("getListEvaluatorResult", { r in sdk.getListEvaluatorResult(fileId: "f") { r(self.err($0)) } }),
            ("sendEvaluatedFile", { r in sdk.sendEvaluatedFile(fileId: "f") { r(self.err($0)) } }),
            ("addFilter", { r in sdk.addFilter(rule: "allow", target: "email", value: "a@example.com") { r(self.err($0)) } }),
            ("listFilters GET", { r in sdk.listFilters { r(self.err($0)) } }),
            ("listFilters POST", { r in sdk.listFilters(usePost: true) { r(self.err($0)) } }),
            ("deleteFilter", { r in sdk.deleteFilter(rule: "allow", target: "email", value: "a@example.com") { r(self.err($0)) } }),
            ("validateS3File", { r in sdk.validateS3File(options: s3) { r(self.err($0)) } }),
            ("scoreS3File", { r in sdk.scoreS3File(options: score) { r(self.err($0)) } }),
            ("exportS3File", { r in sdk.exportS3File(fileId: "f", exportBucket: nil) { r(self.err($0)) } }),
            ("emailFinderS3File", { r in sdk.emailFinderS3File(options: job) { r(self.err($0)) } }),
            ("domainSearchS3File", { r in sdk.domainSearchS3File(options: job) { r(self.err($0)) } }),
            ("validateSFTPFile", { r in sdk.validateSFTPFile(options: job) { r(self.err($0)) } }),
            ("scoreSFTPFile", { r in sdk.scoreSFTPFile(options: job) { r(self.err($0)) } }),
            ("emailFinderSFTPFile", { r in sdk.emailFinderSFTPFile(options: job) { r(self.err($0)) } }),
            ("domainSearchSFTPFile", { r in sdk.domainSearchSFTPFile(options: job) { r(self.err($0)) } }),
            ("exportSFTPFile", { r in sdk.exportSFTPFile(fileId: "f", exportPath: nil) { r(self.err($0)) } }),
            ("getInboxPlacementProviders", { r in sdk.getInboxPlacementProviders { r(self.err($0)) } }),
            ("getInboxPlacementTestTypes", { r in sdk.getInboxPlacementTestTypes { r(self.err($0)) } }),
            ("createInboxPlacementTest", { r in sdk.createInboxPlacementTest(name: "Launch") { r(self.err($0)) } }),
            ("getInboxPlacementTest", { r in sdk.getInboxPlacementTest(testId: "1") { r(self.err($0)) } }),
            ("listInboxPlacementTests", { r in sdk.listInboxPlacementTests { r(self.err($0)) } }),
            ("deleteInboxPlacementTest", { r in sdk.deleteInboxPlacementTest(testId: "1") { r(self.err($0)) } }),
            ("getInboxPlacementWebhook", { r in sdk.getInboxPlacementWebhook { r(self.err($0)) } }),
            ("setInboxPlacementWebhook", { r in sdk.setInboxPlacementWebhook(webhookUrl: "https://example.com/hook") { r(self.err($0)) } }),
            ("listS3files", { r in sdk.listS3files { r(self.err($0)) } }),
            ("fileStatus", { r in sdk.fileStatus(fileId: "f") { r(self.err($0)) } }),
            ("scoringFileStatus", { r in sdk.scoringFileStatus(fileId: "f") { r(self.err($0)) } }),
            ("deleteFile", { r in sdk.deleteFile(fileId: "f") { r(self.err($0)) } }),
            ("scoringDeleteFile", { r in sdk.scoringDeleteFile(fileId: "f") { r(self.err($0)) } }),
            ("sendFile path", { r in sdk.sendFile(filePath: path, emailAddressColumn: 1) { r(self.err($0)) } }),
            ("sendFile data", { r in sdk.sendFile(fileData: csv, fileName: "f.csv", emailAddressColumn: 1) { r(self.err($0)) } }),
            ("scoringSendFile path", { r in sdk.scoringSendFile(filePath: path, emailAddressColumn: 1) { r(self.err($0)) } }),
            ("scoringSendFile data", { r in
                sdk.scoringSendFile(fileData: csv, fileName: "f.csv", emailAddressColumn: 1) { r(self.err($0)) }
            }),
            ("getFile", { r in sdk.getFile(fileId: "f") { r(self.err($0)) } }),
            ("getFile options", { r in sdk.getFile(fileId: "f", options: ZBGetFileOptions()) { r(self.err($0)) } }),
            ("getFileStreaming", { r in sdk.getFileStreaming(fileId: "f", downloadPath: download) { r(self.err($0)) } }),
            ("scoringGetFileStreaming", { r in sdk.scoringGetFileStreaming(fileId: "f", downloadPath: download) { r(self.err($0)) } }),
            ("scoringGetFile", { r in sdk.scoringGetFile(fileId: "f") { r(self.err($0)) } }),
            ("scoringGetFile options", { r in sdk.scoringGetFile(fileId: "f", options: ZBGetFileOptions()) { r(self.err($0)) } }),
            ("warmup listSendingAccounts", { r in warmup.listSendingAccounts { r(self.err($0)) } }),
            ("warmup getSendingAccount", { r in warmup.getSendingAccount(fromAddress: "s@example.com") { r(self.err($0)) } }),
            ("warmup addSendingAccount", { r in
                warmup.addSendingAccount(fromAddress: "s@example.com", onboardingModel: ZeroBounceWarmup.selfManaged, options: selfManaged) { r(self.err($0)) }
            }),
            ("warmup updateSendingAccount", { r in
                warmup.updateSendingAccount(fromAddress: "s@example.com", engagementRuleId: 1, statusId: 4, autoEnable: true) { r(self.err($0)) }
            }),
            ("warmup deleteSendingAccount", { r in warmup.deleteSendingAccount(fromAddress: "s@example.com") { r(self.err($0)) } }),
            ("warmup changeFromAddress", { r in
                warmup.changeFromAddress(oldFromAddress: "old@example.com", newFromAddress: "new@example.com") { r(self.err($0)) }
            }),
            ("warmup listFromAddresses", { r in warmup.listFromAddresses { r(self.err($0)) } }),
            ("warmup getEngagementRules", { r in warmup.getEngagementRules { r(self.err($0)) } }),
            ("warmup setEngagementRule", { r in warmup.setEngagementRule(cFrom: "s@example.com", ruleId: 3) { r(self.err($0)) } }),
            ("warmup getCustomEngagement", { r in warmup.getCustomEngagement(cFrom: "s@example.com") { r(self.err($0)) } }),
            ("warmup createCustomEngagement", { r in
                warmup.createCustomEngagement(cFrom: "s@example.com", replyPct: 10, importantPct: 20, clickPct: 30) { r(self.err($0)) }
            }),
            ("warmup updateCustomEngagement", { r in
                warmup.updateCustomEngagement(cFrom: "s@example.com", replyPct: 10, importantPct: 20, clickPct: 30) { r(self.err($0)) }
            }),
            ("warmup deleteCustomEngagement", { r in
                warmup.deleteCustomEngagement(cFrom: "s@example.com", engagementRuleId: 2) { r(self.err($0)) }
            }),
            ("warmup getSeeds", { r in warmup.getSeeds { r(self.err($0)) } }),
            ("warmup downloadSeeds", { r in warmup.downloadSeeds { r(self.err($0)) } }),
            ("warmup getSeedCount", { r in warmup.getSeedCount { r(self.err($0)) } }),
            ("warmup getProgressToday", { r in warmup.getProgressToday { r(self.err($0)) } }),
            ("warmup getSentToday", { r in warmup.getSentToday { r(self.err($0)) } }),
            ("warmup getEmailsPerDay", { r in warmup.getEmailsPerDay { r(self.err($0)) } }),
            ("warmup getStatistics", { r in warmup.getStatistics(fromAddress: "s@example.com") { r(self.err($0)) } }),
            ("warmup getStatisticsPerDay", { r in
                warmup.getStatisticsPerDay(fromAddress: "s@example.com", startDate: "2026-10-01", endDate: "2026-10-07") { r(self.err($0)) }
            }),
            ("warmup getStatisticsDetailed", { r in warmup.getStatisticsDetailed(cFrom: "s@example.com") { r(self.err($0)) } }),
            ("warmup downloadStatistics", { r in warmup.downloadStatistics(cFrom: "s@example.com") { r(self.err($0)) } }),
            ("warmup getFromAddressStatistics", { r in warmup.getFromAddressStatistics(fromAddress: "s@example.com") { r(self.err($0)) } }),
            ("warmup checkDomainDmarc", { r in warmup.checkDomainDmarc(fromAddress: "s@example.com") { r(self.err($0)) } }),
            ("warmup testSmtpConfiguration", { r in
                warmup.testSmtpConfiguration(fromAddress: "s@example.com", username: "s@example.com", password: TransportSafetyTests.smtpPassword, server: "smtp.example.com", port: 587) { r(self.err($0)) }
            }),
        ]
    }

    private func clients(_ key: String) -> (ZeroBounceSDK, ZeroBounceWarmup) {
        let sdk = ZeroBounceSDK()
        sdk.initialize(apiKey: key)
        let warmup = ZeroBounceWarmup()
        warmup.initialize(apiKey: key)
        return (sdk, warmup)
    }

    /// Runs one call, waits for its completion and returns the error it
    /// reported (nil on success) and the requests it sent.
    private func run(_ name: String, _ call: (@escaping Report) -> ()) -> (Error?, [OfflineRecord]) {
        OfflineURLProtocol.lock.lock()
        OfflineURLProtocol.records = []
        OfflineURLProtocol.lock.unlock()
        var reported: Error?
        let done = expectation(description: name)
        call { error in
            reported = error
            done.fulfill()
        }
        wait(for: [done], timeout: 10)
        OfflineURLProtocol.lock.lock()
        defer { OfflineURLProtocol.lock.unlock() }
        return (reported, OfflineURLProtocol.records)
    }

    private func describe(_ error: Error?) -> String {
        guard let error = error else { return "succeeded" }
        return (error as? LocalizedError)?.errorDescription ?? "\(error)"
    }

    /// A request that gets no answer fails with URLSession's own error, which
    /// quotes the request URL, api_key included, in its user info
    /// (NSErrorFailingURLStringKey, NSErrorFailingURLKey and the underlying
    /// error). No method may hand the key back to the caller that way.
    func testATransportErrorNeverCarriesTheApiKey() {
        // The real transport, not the stub.
        ZeroBounceSDK.urlSession = ZeroBounceSDK.makeSession()
        let key = "transport-secret-key"
        let (sdk, warmup) = clients(key)
        // Nothing listens on port 1, so every connection is refused at once.
        sdk.apiBaseUrl = "http://127.0.0.1:1/v2"
        sdk.bulkApiRootUrl = "http://127.0.0.1:1"
        sdk.bulkApiBaseUrl = "http://127.0.0.1:1/v2"
        sdk.setListEvaluatorBaseUrl("http://127.0.0.1:1/v2/listevaluator")
        sdk.setInboxPlacementBaseUrl("http://127.0.0.1:1/api/ipt")
        warmup.baseUrl = "http://127.0.0.1:1"
        for (name, call) in everyCall(sdk, warmup) {
            let (error, _) = run(name, call)
            guard let error = error else {
                XCTFail("\(name) succeeded without a server")
                continue
            }
            XCTAssertFalse(mentions(error, key), "\(name): \(error)")
        }
        // Still the URLError a caller can switch on, with the URL it failed on.
        let (credits, _) = run("getCredits") { r in sdk.getCredits { r(self.err($0)) } }
        XCTAssertEqual((credits as? URLError)?.code, .cannotConnectToHost)
        XCTAssertEqual((credits as? URLError)?.failingURL?.path, "/v2/getcredits")
    }

    private func mentions(_ value: Any, _ key: String) -> Bool {
        if let error = value as? NSError {
            return "\(error)".contains(key) || error.localizedDescription.contains(key)
                || error.userInfo.values.contains { mentions($0, key) }
        }
        if let list = value as? [Any] {
            return list.contains { mentions($0, key) }
        }
        return "\(value)".contains(key)
    }

    /// The sweep covers every public request method. The methods are read
    /// from the SDK's sources, so one added later without an entry in
    /// `everyCall` (or a new overload of one already there) fails here.
    /// An entry is named after the method it calls ("warmup " in front for
    /// `ZeroBounceWarmup`), with a word after it to tell overloads apart.
    func testTheSweepCoversEveryPublicRequestMethod() throws {
        let (sdk, warmup) = clients("count-key")
        let declared = try publicRequestMethodsInSources()
        // A scan that finds nothing must not pass: there are 64 + 26 today.
        XCTAssertGreaterThanOrEqual(declared.values.reduce(0, +), 64 + 26, "\(declared)")
        var swept: [String: Int] = [:]
        for (label, _) in everyCall(sdk, warmup) {
            let words = label.split(separator: " ")
            let name = words.first == "warmup" && words.count > 1 ? words[1] : words[0]
            swept[String(name), default: 0] += 1
        }
        for (name, overloads) in declared.sorted(by: { $0.key < $1.key }) {
            XCTAssertGreaterThanOrEqual(
                swept[name] ?? 0, overloads,
                "\(name) has \(overloads) public overload(s) and \(swept[name] ?? 0) entries in everyCall"
            )
        }
        for name in swept.keys.sorted() where declared[name] == nil {
            XCTFail("everyCall entry \(name) is not a public request method")
        }
    }

    /// Plain http to a real host is refused by every method before anything
    /// is sent, with a message that says why. Loopback stays allowed for
    /// tests; see `isAllowedURL`.
    func testEveryPublicMethodRefusesPlainHttp() {
        let (sdk, warmup) = clients("http-key")
        sdk.apiBaseUrl = "http://api.zerobounce.net/v2"
        sdk.bulkApiRootUrl = "http://bulkapi.zerobounce.net"
        sdk.bulkApiBaseUrl = "http://bulkapi.zerobounce.net/v2"
        sdk.setListEvaluatorBaseUrl("http://bulkapi.zerobounce.net/v2/listevaluator")
        sdk.setInboxPlacementBaseUrl("http://bulkapi.zerobounce.net/api/ipt")
        warmup.baseUrl = "http://warmup-api.zerobounce.net"
        for (name, call) in everyCall(sdk, warmup) {
            let (error, sent) = run(name, call)
            XCTAssertEqual(sent.count, 0, "\(name) sent a request over plain http")
            XCTAssertTrue(describe(error).contains("https://"), "\(name): \(describe(error))")
        }
    }

    /// A redirect could carry the key to another host. Every method stops at
    /// the 302 and reports it with its status.
    func testEveryPublicMethodRefusesARedirect() {
        let (sdk, warmup) = clients("redirect-key")
        for (name, call) in everyCall(sdk, warmup) {
            let (error, sent) = run(name, call)
            XCTAssertEqual(sent.count, 1, "\(name) followed the redirect: \(sent.map { $0.host + $0.path })")
            XCTAssertFalse(sent.contains { $0.path.hasPrefix("/followed") }, name)
            XCTAssertEqual((error as? ZBError)?.statusCode, 302, "\(name): \(describe(error))")
        }
    }

    /// Every request carries the SDK's timeout, not URLRequest's default.
    func testEveryPublicMethodSetsTheRequestTimeout() {
        // "success-false" makes every answer an error, so the downloads write
        // no file.
        let (sdk, warmup) = clients("success-false-timeout")
        for (name, call) in everyCall(sdk, warmup) {
            let (_, sent) = run(name, call)
            XCTAssertEqual(sent.count, 1, name)
            XCTAssertEqual(sent.first?.timeout, ZeroBounceSDK.requestTimeout, name)
        }
        XCTAssertEqual(ZeroBounceSDK.requestTimeout, 120)
        XCTAssertEqual(ZeroBounceSDK.makeSession().configuration.timeoutIntervalForRequest, 120)
    }

    /// Every base URL can be set; a trailing slash on any of them must not
    /// put "//" into the request path.
    func testBaseUrlsWithATrailingSlash() {
        let (sdk, warmup) = clients("success-false-slash")
        sdk.apiBaseUrl = "https://api.zerobounce.net/v2/"
        sdk.bulkApiRootUrl = "https://bulkapi.zerobounce.net/"
        sdk.bulkApiBaseUrl = "https://bulkapi.zerobounce.net/v2//"
        sdk.setListEvaluatorBaseUrl("https://bulkapi.zerobounce.net/v2/listevaluator/")
        sdk.setInboxPlacementBaseUrl("https://bulkapi.zerobounce.net/api/ipt/")
        warmup.baseUrl = "https://warmup-api.zerobounce.net/"
        for (name, call) in everyCall(sdk, warmup) {
            let (_, sent) = run(name, call)
            XCTAssertEqual(sent.count, 1, name)
            XCTAssertFalse(sent.first?.rawPath.contains("//") ?? true, "\(name): \(sent.first?.rawPath ?? "")")
        }
    }

    /// getfile answers with a file or not at all. A JSON body, whatever its
    /// keys and content type, is an error that keeps the HTTP status.
    func testGetFileJsonBodyIsAnErrorWithItsStatus() {
        for key in ["getfile-message-key", "getfile-Message-key"] {
            let (sdk, _) = clients(key)
            let calls: [(String, (@escaping Report) -> ())] = [
                ("getFile", { r in sdk.getFile(fileId: "f") { r(self.err($0)) } }),
                ("scoringGetFile", { r in sdk.scoringGetFile(fileId: "f") { r(self.err($0)) } }),
                ("getFileStreaming", { r in sdk.getFileStreaming(fileId: "f", downloadPath: self.download) { r(self.err($0)) } }),
                ("emailFinderGetFile", { r in sdk.emailFinderGetFile(fileId: "f", downloadPath: self.download) { r(self.err($0)) } }),
                ("domainSearchGetFile", { r in sdk.domainSearchGetFile(fileId: "f", downloadPath: self.download) { r(self.err($0)) } }),
            ]
            for (name, call) in calls {
                try? FileManager.default.removeItem(atPath: download)
                let (error, _) = run(name, call)
                XCTAssertEqual((error as? ZBError)?.statusCode, 200, "\(key) \(name): \(describe(error))")
                XCTAssertTrue(describe(error).contains("still processing"), "\(key) \(name): \(describe(error))")
                XCTAssertFalse(FileManager.default.fileExists(atPath: download), "\(key) \(name) saved the error as a file")
            }
        }
    }

    /// A dirty key given to a client that already has one must not leave the
    /// old key in place: the caller is told, and nothing is sent with either.
    func testReinitializingWithADirtyKeyDoesNotKeepThePreviousKey() {
        let sdk = ZeroBounceSDK()
        XCTAssertTrue(sdk.initialize(apiKey: "first-key"))
        XCTAssertFalse(sdk.initialize(apiKey: " second-key\n"))
        let (error, sent) = run("getCredits") { r in sdk.getCredits { r(self.err($0)) } }
        XCTAssertEqual(sent.count, 0, "sent with key \(sent.first?.apiKey ?? "")")
        if case .notInitialized? = error as? ZBError {} else {
            XCTFail("expected notInitialized, got \(describe(error))")
        }

        let warmup = ZeroBounceWarmup()
        XCTAssertTrue(warmup.initialize(apiKey: "first-warm"))
        XCTAssertFalse(warmup.initialize(apiKey: "second-warm\t"))
        let (warmError, warmSent) = run("getSeeds") { r in warmup.getSeeds { r(self.err($0)) } }
        XCTAssertEqual(warmSent.count, 0, "sent with key \(warmSent.first?.apiKey ?? "")")
        XCTAssertTrue(describe(warmError).contains("not initialized"), describe(warmError))
    }
}

/// Parity with the other SDKs (standard §3): API errors carry their HTTP
/// status, the greylist Message is a result, the key stays out of reflection,
/// and the guards below each have a test that fails without them.
extension TransportSafetyTests {
    /// `"success": false` on an HTTP 200 is an error, with that status, on
    /// every `ZeroBounceSDK` request method.
    func testSuccessFalseIsAnErrorWithItsStatusOnEveryCall() {
        let (sdk, warmup) = clients("success-false-sweep")
        let calls = everyCall(sdk, warmup).filter { !$0.0.hasPrefix("warmup ") }
        // That everyCall reaches every public request method is checked
        // against the sources by testTheSweepCoversEveryPublicRequestMethod.
        XCTAssertGreaterThanOrEqual(calls.count, 64)
        for (name, call) in calls {
            try? FileManager.default.removeItem(atPath: download)
            let (error, sent) = run(name, call)
            XCTAssertEqual(sent.count, 1, name)
            XCTAssertEqual((error as? ZBError)?.statusCode, 200, "\(name): \(describe(error))")
            XCTAssertTrue(describe(error).contains("File cannot be found."), "\(name): \(describe(error))")
            XCTAssertFalse(FileManager.default.fileExists(atPath: download), "\(name) saved the error as a file")
        }
    }

    /// A non-2xx answer to a streaming download is an error with its status,
    /// and nothing is saved, whatever the body looks like.
    func testStreamingDownloadNon2xxIsAnErrorWithItsStatus() {
        // A 400 with a plain-text body: neither JSON nor HTML.
        let (sdk, _) = clients("double-error-streaming")
        let calls: [(String, (@escaping Report) -> ())] = [
            ("getFileStreaming", { r in sdk.getFileStreaming(fileId: "f", downloadPath: self.download) { r(self.err($0)) } }),
            ("scoringGetFileStreaming", { r in
                sdk.scoringGetFileStreaming(fileId: "f", downloadPath: self.download) { r(self.err($0)) }
            }),
        ]
        for (name, call) in calls {
            try? FileManager.default.removeItem(atPath: download)
            let (error, _) = run(name, call)
            XCTAssertEqual((error as? ZBError)?.statusCode, 400, "\(name): \(describe(error))")
            XCTAssertTrue(describe(error).contains("api_key is invalid"), "\(name): \(describe(error))")
            XCTAssertFalse(FileManager.default.fileExists(atPath: download), "\(name) saved the error as a file")
        }
    }

    /// URLSession nests the request URL in the underlying error as well, and
    /// may list several underlying errors. The key is masked at every depth.
    func testRedactionReachesNestedUnderlyingErrors() {
        let key = "nested-secret-key"
        // NSErrorFailingURLStringKey, which Mac Catalyst does not declare.
        let failingURLString = "NSErrorFailingURLStringKey"
        let url = "https://api.zerobounce.net/v2/getcredits?api_key=\(key)"
        let innermost = NSError(domain: "kCFErrorDomainCFNetwork", code: -1004, userInfo: [
            failingURLString: url,
            NSURLErrorFailingURLErrorKey: URL(string: url)!,
        ])
        let underlying = NSError(domain: "kCFErrorDomainCFNetwork", code: -1004, userInfo: [
            failingURLString: url,
            NSUnderlyingErrorKey: innermost,
        ])
        let error = NSError(domain: NSURLErrorDomain, code: URLError.cannotConnectToHost.rawValue, userInfo: [
            failingURLString: url,
            NSURLErrorFailingURLErrorKey: URL(string: url)!,
            NSUnderlyingErrorKey: underlying,
            "NSMultipleUnderlyingErrorsKey": [underlying],
        ])
        let redacted = ZeroBounceSDK.redactingApiKey(key, in: error)
        XCTAssertFalse(mentionsKey(redacted, key), "\(redacted)")
        let nested = (redacted as NSError).userInfo[NSUnderlyingErrorKey] as? NSError
        XCTAssertEqual(nested?.code, -1004)
        XCTAssertEqual(nested?.userInfo[failingURLString] as? String,
                       "https://api.zerobounce.net/v2/getcredits?api_key=***")
        XCTAssertEqual((redacted as? URLError)?.code, .cannotConnectToHost)
    }

    private func mentionsKey(_ value: Any, _ key: String) -> Bool {
        if let error = value as? NSError {
            return "\(error)".contains(key) || error.userInfo.values.contains { mentionsKey($0, key) }
        }
        if let list = value as? [Any] { return list.contains { mentionsKey($0, key) } }
        return "\(value)".contains(key)
    }

    /// Every error the API reports carries its HTTP status: the dead-key
    /// bodies on an HTTP 200, and the batch-wide "all" error.
    func testApiErrorsOnA200CarryTheStatus() {
        let (sdk, _) = clients("dead-key-status")
        let start = Date(timeIntervalSince1970: 0)
        let calls: [(String, (@escaping Report) -> ())] = [
            ("validate", { r in sdk.validate(email: "a@example.com") { r(self.err($0)) } }),
            ("getActivityData", { r in sdk.getActivityData(email: "a@example.com") { r(self.err($0)) } }),
            ("getApiUsage", { r in sdk.getApiUsage(startDate: start, endDate: start) { r(self.err($0)) } }),
            ("findEmail", { r in sdk.findEmail(domain: "example.com", firstName: "Ada") { r(self.err($0)) } }),
            ("findDomain", { r in sdk.findDomain(domain: "example.com") { r(self.err($0)) } }),
            ("guessFormat", { r in sdk.guessFormat(domain: "example.com") { r(self.err($0)) } }),
            ("addFilter", { r in sdk.addFilter(rule: "allow", target: "email", value: "a@example.com") { r(self.err($0)) } }),
            ("deleteFilter", { r in sdk.deleteFilter(rule: "allow", target: "email", value: "a@example.com") { r(self.err($0)) } }),
            ("listFilters GET", { r in sdk.listFilters { r(self.err($0)) } }),
            ("listFilters POST", { r in sdk.listFilters(usePost: true) { r(self.err($0)) } }),
        ]
        for (name, call) in calls {
            let (error, _) = run(name, call)
            XCTAssertEqual((error as? ZBError)?.statusCode, 200, "\(name): \(describe(error))")
            XCTAssertTrue(describe(error).contains("Invalid API key"), "\(name): \(describe(error))")
        }

        let (batch, _) = clients("batch-account-status")
        let (error, _) = run("validateBatch") { r in
            batch.validateBatch(emails: [["email_address": "a@example.com"]]) { r(self.err($0)) }
        }
        XCTAssertEqual((error as? ZBError)?.statusCode, 200, describe(error))
        XCTAssertTrue(describe(error).contains("ran out of credits"), describe(error))
    }

    /// LIVE: a repeated greylisted validate answers a bare
    /// {"Message": "Greylist validation still in progress..."}. That is a
    /// result whose text is on `message`, not an error.
    func testValidateGreylistMessageIsAResult() {
        let (sdk, _) = clients("greylist-key")
        var post = ZBValidateOptions()
        post.usePost = true
        for options in [nil, post] as [ZBValidateOptions?] {
            var response: ZBValidateResponse?
            let (error, sent) = run("validate") { r in
                sdk.validate(email: "grey@example.com", options: options) { result in
                    if case .Success(let value) = result { response = value }
                    r(self.err(result))
                }
            }
            XCTAssertEqual(sent.count, 1)
            XCTAssertNil(error, describe(error))
            XCTAssertEqual(response?.message, "Greylist validation still in progress, please try again later.")
            XCTAssertNil(response?.status)
            XCTAssertNil(response?.processedAt)
        }
    }

    /// `dump`, `Mirror` and `String(reflecting:)` must not show the key.
    func testReflectionNeverShowsTheApiKey() {
        let key = "reflected-secret-key"
        let (sdk, warmup) = clients(key)
        // Reach the lazily created helper too, which holds the client.
        _ = run("findEmail S3") { r in
            sdk.emailFinderS3File(options: ZBBulkFileJobOptions(fileName: "f.csv", returnUrl: "https://example.com")) { r(self.err($0)) }
        }
        for subject in [sdk as Any, warmup as Any] {
            var dumped = ""
            dump(subject, to: &dumped)
            XCTAssertFalse(dumped.contains(key), dumped)
            XCTAssertFalse(String(reflecting: subject).contains(key))
            XCTAssertFalse("\(subject)".contains(key))
            let children = Mirror(reflecting: subject).children.map { "\($0.label ?? ""): \($0.value)" }
            XCTAssertFalse(children.joined(separator: "\n").contains(key), "\(children)")
            XCTAssertTrue(dumped.contains("apiKey"), dumped)
        }
        // The key is still in use.
        let (_, sent) = run("getCredits") { r in sdk.getCredits { r(self.err($0)) } }
        XCTAssertEqual(sent.first?.apiKey, key)
    }
}

/// A loopback HTTP/1.1 server on a real socket. Every request gets a 200 whose
/// Content-Length promises 1000 bytes more than the body it sends, and then
/// the connection closes: a body cut short, the way a dropped connection
/// looks to the client.
final class CutShortServer {
    let port: UInt16
    private let listener: Int32

    init() throws {
        listener = socket(AF_INET, SOCK_STREAM, 0)
        var yes: Int32 = 1
        setsockopt(listener, SOL_SOCKET, SO_REUSEADDR, &yes, socklen_t(MemoryLayout<Int32>.size))
        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = 0
        address.sin_addr.s_addr = inet_addr("127.0.0.1")
        let fd = listener
        let bound = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard listener >= 0, bound == 0, listen(listener, 64) == 0 else {
            close(listener)
            throw NSError(domain: "CutShortServer", code: Int(errno))
        }
        var length = socklen_t(MemoryLayout<sockaddr_in>.size)
        _ = withUnsafeMutablePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { getsockname(fd, $0, &length) }
        }
        port = UInt16(bigEndian: address.sin_port)
        Thread.detachNewThread {
            while true {
                let client = accept(fd, nil, nil)
                if client < 0 { return }
                Thread.detachNewThread { CutShortServer.serve(client) }
            }
        }
    }

    func stop() {
        shutdown(listener, SHUT_RDWR)
        close(listener)
    }

    private static func serve(_ client: Int32) {
        defer { close(client) }
        var noSigPipe: Int32 = 1
        setsockopt(client, SOL_SOCKET, SO_NOSIGPIPE, &noSigPipe, socklen_t(MemoryLayout<Int32>.size))
        let separator = Data("\r\n\r\n".utf8)
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 65536)
        while data.range(of: separator) == nil {
            let count = recv(client, &buffer, buffer.count, 0)
            if count <= 0 { return }
            data.append(buffer, count: count)
        }
        let end = data.range(of: separator)!
        let head = String(decoding: data[..<end.lowerBound], as: UTF8.self)
        var expected = 0
        for line in head.components(separatedBy: "\r\n").dropFirst()
        where line.lowercased().hasPrefix("content-length:") {
            expected = Int(line.dropFirst(15).trimmingCharacters(in: .whitespaces)) ?? 0
        }
        // Read the whole request body before answering.
        var received = data.count - end.upperBound
        while received < expected {
            let count = recv(client, &buffer, buffer.count, 0)
            if count <= 0 { break }
            received += count
        }
        let path = head.split(separator: " ").dropFirst().first.map(String.init) ?? ""
        let (type, body) = answer(path)
        var out = Data(("HTTP/1.1 200 OK\r\nContent-Type: \(type)\r\n"
            + "Content-Length: \(body.count + 1000)\r\nConnection: close\r\n\r\n").utf8)
        out.append(body)
        var sent = 0
        while sent < out.count {
            let count = out.withUnsafeBytes { Darwin.send(client, $0.baseAddress! + sent, out.count - sent, 0) }
            if count <= 0 { return }
            sent += count
        }
    }

    /// What each call would accept as a success, had it all arrived.
    private static func answer(_ path: String) -> (String, Data) {
        if path.contains("getfile") || path.contains("download") {
            return ("text/csv", Data("email\na@example.com\n".utf8))
        }
        if path.contains("getcredits") { return ("application/json", Data(#"{"Credits":"7"}"#.utf8)) }
        if path.contains("seed-count") { return ("application/json", Data("42".utf8)) }
        let json = #"{"success":true,"ok":true,"message":"ok","file_id":"f","file_name":"f.csv","#
            + #""address":"a@example.com","email":"a@example.com","domain":"example.com","status":"valid","#
            + #""processed_at":"2010-01-01","email_batch":[],"errors":[]}"#
        return ("application/json", Data(json.utf8))
    }
}

/// Round 6 (2026-11-12 audit): the key quoted back in an error body, and a
/// body cut short on a 200, over the complete sweep.
extension TransportSafetyTests {
    /// The forms a key can take in a body: as sent, percent-encoded in a
    /// URL, and JSON-escaped.
    private func keyForms(_ key: String) -> [String] {
        var strict = CharacterSet.alphanumerics
        strict.insert(charactersIn: "-._~")
        return Array(Set([
            key,
            key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key,
            key.addingPercentEncoding(withAllowedCharacters: strict) ?? key,
            key.replacingOccurrences(of: "/", with: "\\/"),
        ] + jsonEscapedEchoes(key)))
    }

    private func leaks(_ error: Error, _ key: String) -> String? {
        var texts = ["\(error)", String(reflecting: error), error.localizedDescription, describe(error)]
        var dumped = ""
        dump(error, to: &dumped)
        texts.append(dumped)
        if let zb = error as? ZBError {
            switch zb {
            case .httpError(let message, _): texts.append(message)
            case .decodeError(let messages): texts.append(contentsOf: messages)
            case .saveFileError(let message): texts.append(message)
            default: break
            }
        }
        for form in keyForms(key) {
            if let text = texts.first(where: { $0.contains(form) }) { return "\(form) in \(text)" }
            if mentions(error, form) { return "\(form) in the user info of \(error as NSError)" }
        }
        return nil
    }

    /// A body that quotes the key never hands it back in an error, whatever
    /// the status and shape, on every public request method. The key has a
    /// "|" and "%" (percent-encoded in a URL) and a "/", '"' and "+" (escaped
    /// in JSON, "+" by .NET) so each of its forms can be told apart. The
    /// escaped-only echo quotes the SMTP password of testSmtpConfiguration
    /// too.
    func testAnErrorBuiltFromTheBodyNeverCarriesTheApiKey() {
        let modes = ["echo-200-error-", "echo-200-success-false-", "echo-400-text-", "echo-400-json-",
                     "echo-400-escaped-"]
        var failures = 0
        for mode in modes {
            let key = mode + "se|cr/et\"K%e+y"
            let (sdk, warmup) = clients(key)
            for (name, call) in everyCall(sdk, warmup) {
                try? FileManager.default.removeItem(atPath: download)
                let (error, sent) = run("\(mode)\(name)", call)
                XCTAssertEqual(sent.count, 1, "\(mode) \(name)")
                // The Warmup API reports its errors by status only, so a 200
                // body is its result there; only its CSV downloads refuse JSON.
                let mustFail = mode.hasPrefix("echo-400-") || !name.hasPrefix("warmup ") || name.contains("download")
                guard let error = error else {
                    if mustFail { XCTFail("\(mode) \(name) succeeded") }
                    continue
                }
                failures += 1
                if let leak = leaks(error, key) {
                    XCTFail("\(mode) \(name): \(leak)")
                }
                if let leak = leaks(error, TransportSafetyTests.smtpPassword) {
                    XCTFail("\(mode) \(name) leaked the SMTP password: \(leak)")
                }
                if mode.hasPrefix("echo-400-") {
                    XCTAssertEqual((error as? ZBError)?.statusCode, 400, "\(mode) \(name): \(describe(error))")
                }
                XCTAssertFalse(FileManager.default.fileExists(atPath: download), "\(mode) \(name) saved the error as a file")
            }
        }
        XCTAssertGreaterThanOrEqual(failures, 5 * 64 + 3 * 26 + 2 * 2)
    }

    /// Warmup answers that are neither its JSON nor a CSV file: a 200 in
    /// plain text and a 200 HTML page (as text/html, and served as text/csv),
    /// each quoting the Warmup key and the request with the SMTP password.
    /// Every Warmup call fails on them, the CSV downloads included, with
    /// neither secret in any part of the error. A plain-text 200 to a CSV
    /// download is the file itself, so it is the one success.
    func testAWarmupErrorNeverCarriesTheKeyOrTheSmtpPassword() {
        let modes = ["warm-echo-text-", "warm-echo-html-", "warm-echo-htmlcsv-"]
        var checked = 0
        for mode in modes {
            let key = mode + "se|cr/et\"K%e+y"
            let (sdk, warmup) = clients(key)
            let calls = everyCall(sdk, warmup).filter { $0.0.hasPrefix("warmup ") }
            XCTAssertGreaterThanOrEqual(calls.count, 26)
            for (name, call) in calls {
                let (error, sent) = run("\(mode)\(name)", call)
                XCTAssertEqual(sent.count, 1, "\(mode) \(name)")
                if name.contains("download") && mode == "warm-echo-text-" {
                    XCTAssertNil(error, "\(mode) \(name): \(describe(error))")
                    continue
                }
                guard let error = error else {
                    XCTFail("\(mode) \(name) succeeded")
                    continue
                }
                checked += 1
                if let leak = leaks(error, key) {
                    XCTFail("\(mode) \(name): \(leak)")
                }
                if let leak = leaks(error, TransportSafetyTests.smtpPassword) {
                    XCTFail("\(mode) \(name) leaked the SMTP password: \(leak)")
                }
                if name.contains("download") {
                    XCTAssertEqual((error as? ZBError)?.statusCode, 200, "\(mode) \(name): \(describe(error))")
                }
            }
        }
        XCTAssertGreaterThanOrEqual(checked, 3 * 26 - 2)
    }

    /// The Warmup CSV downloads hand back a file or an error: an HTML page
    /// (by content type, or served as text/csv), a JSON body and an empty
    /// body are all errors with their status 200, never CSV text.
    func testAWarmupCsvDownloadRefusesAnythingButCsv() {
        let keys = ["html-200-warm", "warm-echo-htmlcsv-key", "warm-json-download", "empty-warm"]
        for key in keys {
            let (sdk, warmup) = clients(key)
            let downloads = everyCall(sdk, warmup).filter { $0.0.hasPrefix("warmup download") }
            XCTAssertEqual(downloads.count, 2)
            for (name, call) in downloads {
                let (error, _) = run("\(key) \(name)", call)
                guard let error = error else {
                    XCTFail("\(key) \(name) returned the body as CSV")
                    continue
                }
                XCTAssertEqual((error as? ZBError)?.statusCode, 200, "\(key) \(name): \(describe(error))")
            }
        }
    }

    /// Every download (getfile and its streaming, scoring, email finder and
    /// domain search forms, and the Warmup CSV downloads) refuses a 200 that
    /// is an HTML page by content type alone (no tags in the body), JSON by
    /// content type alone, and a JSON array by body alone: each is an error
    /// with status 200, and no file is written.
    func testEveryDownloadRefusesHtmlOrJsonByContentTypeOrBody() {
        let keys = ["dl-html-bare-key", "dl-html-plain-key", "dl-json-array-key", "dl-json-type-key", "dl-json-csv-key"]
        for key in keys {
            let (sdk, warmup) = clients(key)
            let downloads = everyCall(sdk, warmup).filter {
                $0.0.lowercased().contains("getfile") || $0.0.hasPrefix("warmup download")
            }
            XCTAssertEqual(downloads.count, 10, downloads.map { $0.0 }.joined(separator: ", "))
            for (name, call) in downloads {
                try? FileManager.default.removeItem(atPath: download)
                let (error, sent) = run("\(key) \(name)", call)
                XCTAssertEqual(sent.count, 1, "\(key) \(name)")
                guard let error = error else {
                    XCTFail("\(key) \(name) took the body for a file")
                    continue
                }
                XCTAssertEqual((error as? ZBError)?.statusCode, 200, "\(key) \(name): \(describe(error))")
                XCTAssertFalse(FileManager.default.fileExists(atPath: download), "\(key) \(name) saved the body as a file")
            }
        }
    }

    /// A 200 whose body stops short of its Content-Length is a transport
    /// error on every public request method (GET, POST, PUT, DELETE, uploads,
    /// downloads, Warmup), never a success with the part that arrived, and no
    /// file is left behind. A real socket, since URLSession's own length check
    /// is what differs between methods.
    func testABodyCutShortIsATransportErrorOnEveryCall() throws {
        let server = try CutShortServer()
        defer { server.stop() }
        ZeroBounceSDK.urlSession = ZeroBounceSDK.makeSession()
        let (sdk, warmup) = clients("cut-short-key")
        let base = "http://127.0.0.1:\(server.port)"
        sdk.apiBaseUrl = base + "/v2"
        sdk.bulkApiRootUrl = base
        sdk.bulkApiBaseUrl = base + "/v2"
        sdk.setListEvaluatorBaseUrl(base + "/v2/listevaluator")
        sdk.setInboxPlacementBaseUrl(base + "/api/ipt")
        warmup.baseUrl = base
        let calls = everyCall(sdk, warmup)
        XCTAssertGreaterThanOrEqual(calls.count, 64 + 26)
        for (name, call) in calls {
            try? FileManager.default.removeItem(atPath: download)
            let (error, _) = run(name, call)
            guard let error = error else {
                XCTFail("\(name) succeeded with a body cut short")
                continue
            }
            // The transport error a caller can switch on; Warmup reports its
            // transport errors by their description.
            if name.hasPrefix("warmup ") {
                XCTAssertTrue(describe(error).lowercased().contains("network connection was lost"), "\(name): \(error)")
            } else {
                XCTAssertEqual((error as? URLError)?.code, .networkConnectionLost, "\(name): \(error)")
            }
            XCTAssertNil(leaks(error, "cut-short-key"), "\(name): \(error)")
            XCTAssertFalse(FileManager.default.fileExists(atPath: download), "\(name) kept a partial file")
        }
    }
}
