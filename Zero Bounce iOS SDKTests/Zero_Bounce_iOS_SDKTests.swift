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
            domain: "", didYouMean: "", domainAgeDays: "", mxRecord: "",
            smtpProvider: "", firstName: nil, lastName: nil, gender: nil,
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
                case .decodeError(let messages):
                    XCTAssertTrue(messages[0] == "Error test")
                    
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
            domain: "", didYouMean: "", domainAgeDays: "", mxRecord: "",
            smtpProvider: "", firstName: nil, lastName: nil, gender: nil,
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
        
        let getFileResponse = ZBGetFileResponse(localFilePath: "path")
        let mockedData = try! JSONEncoder().encode(getFileResponse)
        let mock = Mock(url: apiEndpoint, dataType: .json, statusCode: 200, data: [.get: mockedData])
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
        
        let getFileResponse = ZBGetFileResponse(localFilePath: "path")
        let mockedData = try! JSONEncoder().encode(getFileResponse)
        let mock = Mock(url: apiEndpoint, dataType: .json, statusCode: 200, data: [.get: mockedData])
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
        let getFileResponse = ZBGetFileResponse(localFilePath: "path")
        let mockedData = try! JSONEncoder().encode(getFileResponse)
        let mock = Mock(url: apiEndpoint, dataType: .json, statusCode: 200, data: [.get: mockedData])
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
        let getFileResponse = ZBGetFileResponse(localFilePath: "path")
        let mockedData = try! JSONEncoder().encode(getFileResponse)
        let mock = Mock(url: apiEndpoint, dataType: .json, statusCode: 200, data: [.get: mockedData])
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
            authHeader: authHeader
        )
        OfflineURLProtocol.lock.lock()
        OfflineURLProtocol.records.append(record)
        OfflineURLProtocol.lock.unlock()
        usleep(UInt32(Int.random(in: 0...20) * 1000))

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
        if key.hasPrefix("html-403-") || key.hasPrefix("html-200-") {
            return (key.hasPrefix("html-403-") ? 403 : 200, "text/html", htmlPage())
        }
        if key.hasPrefix("empty-") { return (200, "application/json", Data()) }
        if key.hasPrefix("malformed-") {
            return (200, "application/json", Data(("<<<not-json>>>" + String(repeating: "x", count: 5000)).utf8))
        }
        if key.hasPrefix("success-false") {
            return (200, "application/json", Data(#"{"success":false,"message":"File cannot be found."}"#.utf8))
        }
        if key.hasPrefix("cf-json-") {
            let json = #"{"type":"https://developers.cloudflare.com/support/error-1020/","title":"Error 1020: Access denied","status":403,"error_code":1020,"cloudflare_error":true}"#
            return (403, "application/json", Data(json.utf8))
        }
        if request.path.contains("/api/v1/warmup/") {
            // The Warmup endpoints answer with different shapes: an object, a
            // bare number, and CSV for the two downloads.
            if key.hasPrefix("warm-empty") { return (204, "application/json", Data()) }
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
                        timezoneOffset: 3,
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
                    managedSending: ZBWarmupManagedSending(timezoneOffset: 15)
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
