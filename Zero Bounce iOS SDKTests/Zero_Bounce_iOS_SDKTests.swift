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
                switch error as? ZBError {
                case .invalidResponse:
                    XCTAssertTrue(true)
                    
                default:
                    XCTAssertTrue(false)
                }
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
            startDate: startString, endDate: endString
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
        let apiEndpoint = URL(string: "\(ZeroBounceSDK.shared.bulkApiBaseUrl)/validatebatch")!
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
        let apiEndpoint = URL(string: "\(ZeroBounceSDK.shared.bulkApiBaseUrl)/validatebatch")!
        
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
        let apiEndpoint = URL(string: "\(ZeroBounceSDK.shared.bulkApiBaseUrl)/validatebatch")!
        
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
    func testGuessFormat() {
        let domain = "example.com"
        let firstName = "Example"
        let apiEndpoint = URL(
            string: "\(ZeroBounceSDK.shared.apiBaseUrl)/guessformat?api_key=\(apiKey)&domain=\(domain)&first_name=\(firstName)"
        )!
        let emailFinderResponse = ZBEmailFinderResponse(
            email: "example@example.com", domain: domain, format: "first", status: .valid,
            subStatus: ZBValidateSubStatus.none, confidence: .medium, didYouMean: "", failureReason: "",
            otherDomainFormats: [
                ZBDomainFormat(format: "first.last", confidence: .medium),
                ZBDomainFormat(format: "firstl", confidence: .low),
                ZBDomainFormat(format: "last_first", confidence: .unknown)
            ]
        )
        
        let mockedData = try! JSONEncoder().encode(emailFinderResponse)
        let mock = Mock(url: apiEndpoint, dataType: .json, statusCode: 200, data: [.get: mockedData])
        mock.register()

        let requestExpectation = expectation(description: "Request should finish")
        ZeroBounceSDK.shared.guessFormat(domain: domain, firstName: firstName) { result in
            defer { requestExpectation.fulfill() }
            switch result {
            case .Success(let response):
                NSLog("guessFormat success response=\(response)")
                XCTAssertEqual(response, emailFinderResponse)
                
            case .Failure(let error):
                NSLog("guessFormat failure error=\(String(describing: error))")
                XCTAssertTrue(false)
            }
        }

        wait(for: [requestExpectation], timeout: 60)
    }
    
    // MARK: File Status
    func testFileStatus() {
        let fileId = "file_id"
        let apiEndpoint = URL(
            string: "\(ZeroBounceSDK.shared.bulkApiBaseUrl)/filestatus?api_key=\(ZeroBounceSDK.shared.apiKey!)&file_id=\(fileId)"
        )!
        
        let fileStatusResponse = ZBFileStatusResponse(
            success: true, fileId: "fileId", fileName: "fileName",
            uploadDate: "date", fileStatus: "Completed",
            completePercentage: "100%", returnUrl: nil
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
            success: true, fileId: "fileId", fileName: "fileName",
            uploadDate: "date", fileStatus: "Completed",
            completePercentage: "100%", returnUrl: nil
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
}
