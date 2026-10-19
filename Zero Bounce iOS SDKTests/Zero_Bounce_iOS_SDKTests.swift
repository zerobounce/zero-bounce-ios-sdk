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

        let requestExpectation = expectation(description: "Request should finish")
        ZeroBounceSDK.shared.sendEmailFinderFile(filePath: csvPath, domainColumn: 1) { result in
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
        ZeroBounceSDK.shared.validateS3File(options: ZBValidateS3FileOptions(fileName: "bucket/key.csv")) { result in
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
            city: nil, region: nil, zipCode: nil, country: nil, processedAt: "date"
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
            city: nil, region: nil, zipCode: nil, country: nil, processedAt: "date"
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
                switch error as? ZBError {
                case .decodeError:
                    XCTAssertTrue(true)
                    
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
                guard case .decodeError(let msgs) = zbe else {
                    XCTFail("expected decodeError")
                    return
                }
                XCTAssertTrue(msgs.joined().contains("Phase 2"))
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

private struct OfflineRecord {
    let method: String
    let host: String
    let path: String
    let apiKey: String
    let query: String
    let body: String
}

private final class OfflineURLProtocol: URLProtocol {
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
            if let blank = rest.range(of: "\r\n\r\n") {
                apiKey = String(rest[blank.upperBound...].prefix { $0 != "\r" })
            }
        }
        let record = OfflineRecord(
            method: method,
            host: url.host ?? "",
            path: url.path,
            apiKey: apiKey,
            query: url.query ?? "",
            body: body
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
        if key.hasPrefix("cf-json-") {
            let json = #"{"type":"https://developers.cloudflare.com/support/error-1020/","title":"Error 1020: Access denied","status":403,"error_code":1020,"cloudflare_error":true}"#
            return (403, "application/json", Data(json.utf8))
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
    override func setUp() {
        super.setUp()
        OfflineURLProtocol.enabled = true
        OfflineURLProtocol.records = []
        URLProtocol.registerClass(OfflineURLProtocol.self)
    }

    override func tearDown() {
        OfflineURLProtocol.enabled = false
        URLProtocol.unregisterClass(OfflineURLProtocol.self)
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
}
