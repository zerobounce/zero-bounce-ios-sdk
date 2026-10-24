//
//  ZeroBounceSDK.swift
//  Zero Bounce iOS SDK
//
//  Created by ZeroBounce on 08/07/2019.
//  Copyright © 2019 ZeroBounce. All rights reserved.
//

import Foundation

import UIKit

public class ZeroBounceSDK {
    
    static public let shared = ZeroBounceSDK()
    
    var bulkApiRootUrl = "https://bulkapi.zerobounce.net"
    var bulkApiBaseUrl = "https://bulkapi.zerobounce.net/v2"
    var bulkApiScoringBaseUrl = "https://bulkapi.zerobounce.net/v2/scoring"
    /// The list evaluator and the Inbox Placement Tester have their own base
    /// URLs, not paths built from the bulk one. `initialize` alone leaves them
    /// pointing at the live API.
    var listEvaluatorBaseUrl = "https://bulkapi.zerobounce.net/v2/listevaluator"
    var inboxPlacementBaseUrl = "https://bulkapi.zerobounce.net/api/ipt"
    var apiKey: String?
    var apiBaseUrl = ZBApiURL.API_DEFAULT_URL.rawValue
    let dateFormatter = DateFormatter()
    
    private lazy var priority3Api = Priority3Api(sdk: self)

    var normalizedApiKey: String? {
        guard let apiKey = apiKey, !apiKey.isEmpty else { return nil }
        return apiKey
    }

    public init() {
        dateFormatter.dateFormat = "yyyy-MM-dd"
    }
    
    /// Sets the API key. A key with surrounding whitespace or control
    /// characters is refused rather than stored: it would otherwise be quoted,
    /// unredacted, in a transport error.
    public func initialize(
        apiKey: String,
        apiBaseUrl: ZBApiURL = .API_DEFAULT_URL
    ) {
        guard ZeroBounceSDK.isCleanApiKey(apiKey) else {
            print("ZeroBounce: api_key has surrounding whitespace or control characters; it was not accepted.")
            return
        }
        self.apiKey = apiKey
        self.apiBaseUrl = apiBaseUrl.rawValue
    }

    /// Whether a key is free of surrounding whitespace and control characters.
    /// An empty key stays allowed: it is reported as `notInitialized` by the
    /// first call that needs it.
    internal static func isCleanApiKey(_ apiKey: String) -> Bool {
        if apiKey.isEmpty { return true }
        if apiKey != apiKey.trimmingCharacters(in: .whitespacesAndNewlines) { return false }
        return apiKey.unicodeScalars.allSatisfy { !CharacterSet.controlCharacters.contains($0) }
    }

    /// Refuses a URL that is not https, so the api_key is never put on the
    /// wire in the clear. Loopback is allowed so an offline test can point the
    /// SDK at a local stub.
    internal static func isAllowedURL(_ url: URL) -> Bool {
        let scheme = url.scheme?.lowercased() ?? ""
        if scheme == "https" { return true }
        guard scheme == "http", let host = url.host?.lowercased() else { return false }
        return host == "127.0.0.1" || host == "localhost" || host == "::1"
    }
    
    // MARK: Validate
    ///
    /// - parameter email: The email address you want to validate
    /// - parameter ipAddress: The IP Address the email signed up from (Can be blank)
    ///
    public func validate(email: String, ipAddress: String? = nil, completion: @escaping (ZBResult<ZBValidateResponse>) -> ()) {
        validate(email: email, ipAddress: ipAddress, options: nil, completion: completion)
    }

    public func validate(
        email: String,
        ipAddress: String? = nil,
        options: ZBValidateOptions?,
        completion: @escaping (ZBResult<ZBValidateResponse>) -> ()
    ) {
        guard let apiKey = normalizedApiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }
        if let options = options, let timeout = options.timeout {
            if timeout < 3 || timeout > 60 {
                completion(ZBResult.Failure(ZBError.decodeError(messages: [
                    "Invalid parameter: timeout (must be between 3 and 60 seconds)"
                ])))
                return
            }
        }
        if let options = options, let callbackUrl = options.callbackUrl {
            if callbackUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                completion(ZBResult.Failure(ZBError.decodeError(messages: [
                    "Empty parameter: callback_url"
                ])))
                return
            }
            // The callback is where the greylist retry posts its result, so it
            // is meaningless — and rejected by the API — without the retry.
            if options.greylistProcessing != true {
                completion(ZBResult.Failure(ZBError.decodeError(messages: [
                    "Invalid parameter: callback_url requires greylist_processing to be true"
                ])))
                return
            }
        }

        let ipAddressPart = ipAddress != nil ? "\(ipAddress!)" : ""
        var items: [URLQueryItem] = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "email", value: email),
            URLQueryItem(name: "ip_address", value: ipAddressPart),
        ]
        if let options = options {
            if options.usePost {
                var fields: [String: String] = [
                    "api_key": apiKey,
                    "email": email,
                    "ip_address": ipAddressPart,
                ]
                if let timeout = options.timeout {
                    fields["timeout"] = String(timeout)
                }
                if let activityData = options.activityData {
                    fields["activity_data"] = activityData ? "true" : "false"
                }
                if let verifyPlus = options.verifyPlus {
                    fields["verify_plus"] = verifyPlus ? "true" : "false"
                }
                if let domainInfo = options.domainInfo {
                    fields["domain_info"] = domainInfo ? "true" : "false"
                }
                if let greylistProcessing = options.greylistProcessing {
                    fields["greylist_processing"] = greylistProcessing ? "true" : "false"
                }
                if let callbackUrl = options.callbackUrl {
                    fields["callback_url"] = callbackUrl
                }
                sendFormPostRequest(url: apiBaseUrl + "/validate", formFields: fields, completion: completion)
                return
            }
            if let timeout = options.timeout {
                items.append(URLQueryItem(name: "timeout", value: String(timeout)))
            }
            if let activityData = options.activityData {
                items.append(URLQueryItem(name: "activity_data", value: activityData ? "true" : "false"))
            }
            if let verifyPlus = options.verifyPlus {
                items.append(URLQueryItem(name: "verify_plus", value: verifyPlus ? "true" : "false"))
            }
            if let domainInfo = options.domainInfo {
                items.append(URLQueryItem(name: "domain_info", value: domainInfo ? "true" : "false"))
            }
            if let greylistProcessing = options.greylistProcessing {
                items.append(URLQueryItem(
                    name: "greylist_processing", value: greylistProcessing ? "true" : "false"
                ))
            }
            if let callbackUrl = options.callbackUrl {
                items.append(URLQueryItem(name: "callback_url", value: callbackUrl))
            }
        }
        sendJsonRequest(url: makeURL("/validate", queryItems: items), completion: completion)
    }
    
    // MARK: Validate Batch
    ///
    /// - parameter emails: List of email addresses you want to validate
    ///
    public func validateBatch(emails: [[String:String]], completion: @escaping (ZBResult<ZBValidateBatchResponse>) -> ()) {
        validateBatch(emails: emails, options: nil, completion: completion)
    }

    public func validateBatch(
        emails: [[String:String]],
        options: ZBValidateOptions?,
        completion: @escaping (ZBResult<ZBValidateBatchResponse>) -> ()
    ) {
        guard let apiKey = normalizedApiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }
        if let options = options, let timeout = options.timeout {
            if timeout < 10 || timeout > 120 {
                completion(ZBResult.Failure(ZBError.decodeError(messages: [
                    "Invalid parameter: timeout (must be between 10 and 120 seconds)"
                ])))
                return
            }
        }

        let emailBatch: [[String: Any]] = emails.map { item in
            var mapped: [String: Any] = [:]
            for (key, value) in item {
                if key == "ip_address" && value.isEmpty {
                    mapped[key] = NSNull()
                } else {
                    mapped[key] = value
                }
            }
            return mapped
        }
        var params: [String: Any] = [
            "api_key": apiKey,
            "email_batch": emailBatch
        ]
        if let options = options {
            if let timeout = options.timeout {
                // LIVE: validatebatch takes timeout as a JSON *string*. Sent as a
                // number the API rejects the whole batch with the account-level
                // "Invalid API Key or your account ran out of credits".
                params["timeout"] = String(timeout)
            }
            if let activityData = options.activityData {
                params["activity_data"] = activityData
            }
            if let verifyPlus = options.verifyPlus {
                params["verify_plus"] = verifyPlus
            }
        }

        let jsonDataParams = try? JSONSerialization.data(withJSONObject: params)
        sendPostJsonRequest(url: "\(apiBaseUrl)/validatebatch", params: jsonDataParams) { (result: ZBResult<ZBValidateBatchResponse>) in
            if case .Success(let response) = result,
               let account = response.errors.first(where: { $0.emailAddress == "all" }) {
                let text = account.error.isEmpty
                    ? "Invalid API Key or your account ran out of credits"
                    : account.error
                completion(.Failure(ZBError.decodeError(messages: [text])))
                return
            }
            completion(result)
        }
    }
    
    // MARK: Email Finder
    ///
    /// - parameter domain: The email domain for which to find the email format
    /// - parameter firstName: The first name of the person whose email format is being searched
    /// - parameter middleName: The middle name of the person whose email format is being searched
    /// - parameter lastName: The last name of the person whose email format is being searched
    ///
    public func findEmail(
        domain: String,
        firstName: String,
        middleName: String? = nil,
        lastName: String? = nil,
        completion: @escaping (ZBResult<ZBEmailFinderResponse>) -> ()
    ) {
        _findEmail(
            domain: domain,
            companyName: nil,
            firstName: firstName,
            middleName: middleName,
            lastName: lastName,
            completion: completion
        )
    }
    
    ///
    /// - parameter companyName: The company name for which to find the email format
    /// - parameter firstName: The first name of the person whose email format is being searched
    /// - parameter middleName: The middle name of the person whose email format is being searched
    /// - parameter lastName: The last name of the person whose email format is being searched
    ///
    public func findEmail(
        companyName: String,
        firstName: String,
        middleName: String? = nil,
        lastName: String? = nil,
        completion: @escaping (ZBResult<ZBEmailFinderResponse>) -> ()
    ) {
        _findEmail(
            domain: nil,
            companyName: companyName,
            firstName: firstName,
            middleName: middleName,
            lastName: lastName,
            completion: completion
        )
    }
    
    private func _findEmail(
        domain: String?,
        companyName: String?,
        firstName: String,
        middleName: String? = nil,
        lastName: String? = nil,
        completion: @escaping (ZBResult<ZBEmailFinderResponse>) -> ()
    ) {
        guard let apiKey = normalizedApiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }
        
        var items: [URLQueryItem] = [URLQueryItem(name: "api_key", value: apiKey)]
        if let domain {
            items.append(URLQueryItem(name: "domain", value: domain))
        }
        if let companyName {
            items.append(URLQueryItem(name: "company_name", value: companyName))
        }
        items.append(URLQueryItem(name: "first_name", value: firstName))
        if let middleName {
            items.append(URLQueryItem(name: "middle_name", value: middleName))
        }
        if let lastName {
            items.append(URLQueryItem(name: "last_name", value: lastName))
        }
        sendJsonRequest(url: makeURL("/guessformat", queryItems: items), completion: completion)
    }
    
    // MARK: Domain Search
    ///
    /// - parameter domain: The email domain for which to find the email format
    ///
    public func findDomain(
        domain: String,
        completion: @escaping (ZBResult<ZBDomainSearchResponse>) -> ()
    ) {
        _findDomain(
            domain: domain,
            companyName: nil,
            completion: completion
        )
    }
    
    ///
    /// - parameter companyName: The company name for which to find the email format
    ///
    public func findDomain(
        companyName: String,
        completion: @escaping (ZBResult<ZBDomainSearchResponse>) -> ()
    ) {
        _findDomain(
            domain: nil,
            companyName: companyName,
            completion: completion
        )
    }
    
    private func _findDomain(
        domain: String?,
        companyName: String?,
        completion: @escaping (ZBResult<ZBDomainSearchResponse>) -> ()
    ) {
        guard let apiKey = normalizedApiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }
        
        var items: [URLQueryItem] = [URLQueryItem(name: "api_key", value: apiKey)]
        if let domain {
            items.append(URLQueryItem(name: "domain", value: domain))
        }
        if let companyName {
            items.append(URLQueryItem(name: "company_name", value: companyName))
        }
        sendJsonRequest(url: makeURL("/guessformat", queryItems: items), completion: completion)
    }
    
    @available(*, deprecated, message: "Use findEmail() for Email Finder API, or findDomain() for Domain Search API")
    public func guessFormat(
        domain: String,
        firstName: String? = nil,
        middleName: String? = nil,
        lastName: String? = nil,
        completion: @escaping (ZBResult<ZBEmailFinderResponse>) -> ()
    ) {
        guard let apiKey = normalizedApiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }
        
        var items: [URLQueryItem] = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "domain", value: domain),
        ]
        if let firstName {
            items.append(URLQueryItem(name: "first_name", value: firstName))
        }
        if let middleName {
            items.append(URLQueryItem(name: "middle_name", value: middleName))
        }
        if let lastName {
            items.append(URLQueryItem(name: "last_name", value: lastName))
        }
        sendJsonRequest(url: makeURL("/guessformat", queryItems: items), completion: completion)
    }
    
    // MARK: Get Credits
    ///
    /// This API will tell you how many credits you have left on your account. It's simple, fast and easy to use.
    ///
    public func getCredits(completion: @escaping (ZBResult<ZBCreditsResponse>) -> ()) {
        guard let apiKey = normalizedApiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }
        
        sendJsonRequest(url: makeURL("/getcredits", queryItems: [URLQueryItem(name: "api_key", value: apiKey)]), completion: completion)
    }
    
    // MARK: Get Api Usage
    ///
    /// - parameter startDate: The start date of when you want to view API usage
    /// - parameter endDate: The end date of when you want to view API usage
    ///
    public func getApiUsage(startDate: Date, endDate: Date, completion: @escaping (ZBResult<ZBGetApiUsageResponse>) -> ()) {
        guard let apiKey = normalizedApiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }
        
        let startString = self.dateFormatter.string(from: startDate)
        let endString = self.dateFormatter.string(from: endDate)
        
        sendJsonRequest(url: makeURL("/getapiusage", queryItems: [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "start_date", value: startString),
            URLQueryItem(name: "end_date", value: endString),
        ]), completion: completion)
    }
    
    // MARK: Activity Data
    ///
    /// - parameter email: The email inbox you want to check the activity data for
    ///
    public func getActivityData(email: String, completion: @escaping (ZBResult<ZBActivityDataResponse>) -> ()) {
        guard let apiKey = normalizedApiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }
        
        sendJsonRequest(url: makeURL("/activity", queryItems: [URLQueryItem(name: "api_key", value: apiKey), URLQueryItem(name: "email", value: email)]), completion: completion)
    }

    // MARK: Score Email
    ///
    /// Real-time AI scoring for a single email (GET /scoring).
    ///
    public func scoreEmail(email: String, completion: @escaping (ZBResult<ZBScoreEmailResponse>) -> ()) {
        guard let apiKey = normalizedApiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }

        sendJsonRequest(
            url: makeURL("/scoring", queryItems: [
                URLQueryItem(name: "api_key", value: apiKey),
                URLQueryItem(name: "email", value: email),
            ]),
            completion: completion
        )
    }

    ///
    /// Real-time AI scoring for a single email (POST /scoring, form-encoded).
    ///
    public func scoreEmailPost(email: String, completion: @escaping (ZBResult<ZBScoreEmailResponse>) -> ()) {
        guard let apiKey = normalizedApiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }

        sendFormPostRequest(
            url: apiBaseUrl + "/scoring",
            formFields: [
                "api_key": apiKey,
                "email": email,
            ],
            completion: completion
        )
    }

    // MARK: Priority 3 — bulk finder, list evaluator, filters, S3

    public func sendEmailFinderFile(
        filePath: String,
        domainColumn: Int,
        options: ZBEmailFinderSendFileOptions? = nil,
        completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()
    ) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.sendEmailFinderFile(filePath: filePath, domainColumn: domainColumn, options: options, completion: completion)
    }

    public func sendEmailFinderFileData(
        fileData: Data,
        fileName: String,
        domainColumn: Int,
        options: ZBEmailFinderSendFileOptions? = nil,
        completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()
    ) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.sendEmailFinderFileData(fileData: fileData, fileName: fileName, domainColumn: domainColumn, options: options, completion: completion)
    }

    public func emailFinderFileStatus(fileId: String, completion: @escaping (ZBResult<ZBFileStatusResponse>) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.bulkRootFileStatus(baseUrl: "\(bulkApiRootUrl)/email-finder", fileId: fileId, completion: completion)
    }

    public func emailFinderGetFile(fileId: String, downloadPath: String, completion: @escaping (ZBResult<ZBGetFileResponse>) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.bulkRootGetFile(baseUrl: "\(bulkApiRootUrl)/email-finder", fileId: fileId, downloadPath: downloadPath, completion: completion)
    }

    public func emailFinderDeleteFile(fileId: String, completion: @escaping (ZBResult<ZBDeleteFileResponse>) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.bulkRootDeleteFile(baseUrl: "\(bulkApiRootUrl)/email-finder", fileId: fileId, completion: completion)
    }

    public func sendDomainSearchFile(
        filePath: String,
        domainColumn: Int,
        options: ZBDomainSearchSendFileOptions? = nil,
        completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()
    ) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.sendDomainSearchFile(filePath: filePath, domainColumn: domainColumn, options: options, completion: completion)
    }

    public func sendDomainSearchFileData(
        fileData: Data,
        fileName: String,
        domainColumn: Int,
        options: ZBDomainSearchSendFileOptions? = nil,
        completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()
    ) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.sendDomainSearchFileData(fileData: fileData, fileName: fileName, domainColumn: domainColumn, options: options, completion: completion)
    }

    public func domainSearchFileStatus(fileId: String, completion: @escaping (ZBResult<ZBFileStatusResponse>) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.bulkRootFileStatus(baseUrl: "\(bulkApiRootUrl)/domain-search", fileId: fileId, completion: completion)
    }

    public func domainSearchGetFile(fileId: String, downloadPath: String, completion: @escaping (ZBResult<ZBGetFileResponse>) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.bulkRootGetFile(baseUrl: "\(bulkApiRootUrl)/domain-search", fileId: fileId, downloadPath: downloadPath, completion: completion)
    }

    public func domainSearchDeleteFile(fileId: String, completion: @escaping (ZBResult<ZBDeleteFileResponse>) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.bulkRootDeleteFile(baseUrl: "\(bulkApiRootUrl)/domain-search", fileId: fileId, completion: completion)
    }

    public func sendListEvaluatorFile(
        filePath: String,
        emailAddressColumn: Int,
        completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()
    ) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.sendListEvaluatorFile(filePath: filePath, emailAddressColumn: emailAddressColumn, completion: completion)
    }

    public func sendListEvaluatorFileData(
        fileData: Data,
        fileName: String,
        emailAddressColumn: Int,
        completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()
    ) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.sendListEvaluatorFileData(fileData: fileData, fileName: fileName, emailAddressColumn: emailAddressColumn, completion: completion)
    }

    public func getListEvaluatorResult(fileId: String, completion: @escaping (ZBDictionaryResult) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.getListEvaluatorResult(fileId: fileId, completion: completion)
    }

    /// Submits a list the list evaluator has finished for bulk validation.
    ///
    /// Takes the id of a finished evaluation, not a path to upload: that is
    /// what the live endpoint wants.
    public func sendEvaluatedFile(fileId: String, completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.sendEvaluatedFile(fileId: fileId, completion: completion)
    }

    public func addFilter(rule: String, target: String, value: String, completion: @escaping (ZBDictionaryResult) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.addFilter(rule: rule, target: target, value: value, completion: completion)
    }

    /// Lists the account's filters.
    ///
    /// The body is a JSON array, so this hands back `ZBJsonResult`: cast the
    /// success value to `[[String: Any]]`.
    public func listFilters(usePost: Bool = false, completion: @escaping (ZBJsonResult) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.listFilters(usePost: usePost, completion: completion)
    }

    public func deleteFilter(rule: String, target: String, value: String, completion: @escaping (ZBDictionaryResult) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.deleteFilter(rule: rule, target: target, value: value, completion: completion)
    }

    public func validateS3File(options: ZBValidateS3FileOptions, completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.validateS3File(options: options, completion: completion)
    }

    public func scoreS3File(options: ZBScoreS3FileOptions, completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.scoreS3File(options: options, completion: completion)
    }

    public func exportS3File(fileId: String, exportBucket: String, completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.exportS3File(fileId: fileId, exportBucket: exportBucket, completion: completion)
    }

    // MARK: S3 email finder / domain search, SFTP/FTP bulk
    //
    // https://www.zerobounce.net/docs/api-integrations/amazon-s3-bulk-api
    // https://www.zerobounce.net/docs/api-integrations/sftp_bulk_api
    //
    // These live on the bulkapi host WITHOUT the /v2 path. The SFTP server,
    // path and protocol are never sent by the SDK; they come from your
    // ZeroBounce settings.

    public func emailFinderS3File(options: ZBBulkFileJobOptions, completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.emailFinderS3File(options: options, completion: completion)
    }

    public func domainSearchS3File(options: ZBBulkFileJobOptions, completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.domainSearchS3File(options: options, completion: completion)
    }

    /// This is the one job whose file_name the docs list as optional: leave
    /// `options.fileName` nil to use the input bucket from your settings.
    public func validateSFTPFile(options: ZBBulkFileJobOptions, completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.validateSFTPFile(options: options, completion: completion)
    }

    public func scoreSFTPFile(options: ZBBulkFileJobOptions, completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.scoreSFTPFile(options: options, completion: completion)
    }

    public func emailFinderSFTPFile(options: ZBBulkFileJobOptions, completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.emailFinderSFTPFile(options: options, completion: completion)
    }

    public func domainSearchSFTPFile(options: ZBBulkFileJobOptions, completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.domainSearchSFTPFile(options: options, completion: completion)
    }

    /// Note the field name: this endpoint takes export_path, not the
    /// export_bucket that `exportS3File` sends. Pass nil to use the export path
    /// from your ZeroBounce settings.
    public func exportSFTPFile(fileId: String, exportPath: String?, completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.exportSFTPFile(fileId: fileId, exportPath: exportPath, completion: completion)
    }

    // MARK: Inbox Placement Tester
    //
    // Its own host, the API key on the query string, camelCase JSON bodies.
    // Spends the account's inbox-test credits.

    public func getInboxPlacementProviders(completion: @escaping (ZBDictionaryResult) -> ()) {
        priority3Api.getInboxPlacementProviders(completion: completion)
    }

    public func getInboxPlacementTestTypes(completion: @escaping (ZBDictionaryResult) -> ()) {
        priority3Api.getInboxPlacementTestTypes(completion: completion)
    }

    public func createInboxPlacementTest(
        name: String,
        options: ZBCreateInboxPlacementTestOptions? = nil,
        completion: @escaping (ZBDictionaryResult) -> ()
    ) {
        priority3Api.createInboxPlacementTest(name: name, options: options, completion: completion)
    }

    public func getInboxPlacementTest(testId: String, completion: @escaping (ZBDictionaryResult) -> ()) {
        priority3Api.getInboxPlacementTest(testId: testId, completion: completion)
    }

    public func listInboxPlacementTests(
        options: ZBListInboxPlacementTestsOptions? = nil,
        completion: @escaping (ZBDictionaryResult) -> ()
    ) {
        priority3Api.listInboxPlacementTests(options: options, completion: completion)
    }

    public func deleteInboxPlacementTest(testId: String, completion: @escaping (ZBDictionaryResult) -> ()) {
        priority3Api.deleteInboxPlacementTest(testId: testId, completion: completion)
    }

    public func getInboxPlacementWebhook(completion: @escaping (ZBDictionaryResult) -> ()) {
        priority3Api.getInboxPlacementWebhook(completion: completion)
    }

    public func setInboxPlacementWebhook(webhookUrl: String, completion: @escaping (ZBDictionaryResult) -> ()) {
        priority3Api.setInboxPlacementWebhook(webhookUrl: webhookUrl, completion: completion)
    }

    /// Overrides the list evaluator base URL. It is a separate host rather than
    /// a path built from the bulk base, so `initialize` alone does not change it.
    public func setListEvaluatorBaseUrl(_ url: String) {
        listEvaluatorBaseUrl = url
    }

    /// Overrides the Inbox Placement Tester base URL. See `setListEvaluatorBaseUrl`.
    public func setInboxPlacementBaseUrl(_ url: String) {
        inboxPlacementBaseUrl = url
    }

    public func listS3files(bucket: String? = nil, search: String? = nil, completion: @escaping (ZBResult<[ZBS3ListFileEntry]>) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.listS3files(bucket: bucket, search: search, completion: completion)
    }
    
    // MARK: File Status
    ///
    /// - parameter fileId: The returned file ID when calling sendFile API.
    ///
    public func fileStatus(fileId: String, completion: @escaping (ZBResult<ZBFileStatusResponse>) -> ()) {
        _fileStatus(scoring: false, fileId: fileId, completion: completion)
    }
    
    ///
    /// - parameter fileId: The returned file ID when calling scoringSendFile API.
    ///
    public func scoringFileStatus(fileId: String, completion: @escaping (ZBResult<ZBFileStatusResponse>) -> ()) {
        _fileStatus(scoring: true, fileId: fileId, completion: completion)
    }
    
    private func _fileStatus(scoring: Bool, fileId: String, completion: @escaping (ZBResult<ZBFileStatusResponse>) -> ()) {
        guard let apiKey = normalizedApiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }
        
        sendJsonRequest(url: makeBulkURL(scoring: scoring, subpath: "/filestatus", queryItems: [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "file_id", value: fileId),
        ]), completion: completion)
    }
    
    // MARK: Delete File
    ///
    /// - parameter fileId: The returned file ID when calling sendfile API.
    ///
    public func deleteFile(fileId: String, completion: @escaping (ZBResult<ZBDeleteFileResponse>) -> ()) {
        _deleteFile(scoring: false, fileId: fileId, completion: completion)
    }
    
    ///
    /// - parameter fileId: The returned file ID when calling scoringSendfile API.
    ///
    public func scoringDeleteFile(fileId: String, completion: @escaping (ZBResult<ZBDeleteFileResponse>) -> ()) {
        _deleteFile(scoring: true, fileId: fileId, completion: completion)
    }
    
    private func _deleteFile(scoring: Bool, fileId: String, completion: @escaping (ZBResult<ZBDeleteFileResponse>) -> ()) {
        guard let apiKey = normalizedApiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }
        
        sendJsonRequest(url: makeBulkURL(scoring: scoring, subpath: "/deletefile", queryItems: [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "file_id", value: fileId),
        ]), completion: completion)
    }
    
    
    
    // MARK: Send File
    ///
    /// The sendfile API allows user to send a file for bulk email validation
    ///
    /// - parameter filePath: The path to a local file in String format
    /// - parameter emailAddressColumn: The column index of the email address in the file. Index starts from 1
    /// - parameter returnUrl: The URL will be used to call back when the validation is completed
    /// - parameter firstNameColumn: The column index of the first name column
    /// - parameter lastNameColumn: The column index of the last name column
    /// - parameter genderColumn: The column index of the gender column
    /// - parameter ipAddressColumn: The IP Address the email signed up from
    /// - parameter hasHeaderRow: If the first row from the submitted file is a header row. true or false
    ///
    public func sendFile(
        filePath: String,
        emailAddressColumn: Int,
        returnUrl: String? = nil,
        firstNameColumn: Int? = nil,
        lastNameColumn: Int? = nil,
        genderColumn: Int? = nil,
        ipAddressColumn: Int? = nil,
        hasHeaderRow: Bool = false,
        allowPhase2: Bool? = nil,
        completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()
    ) {
        _sendFile(scoring: false, filePath: filePath, emailAddressColumn: emailAddressColumn,
                  returnUrl: returnUrl, firstNameColumn: firstNameColumn, lastNameColumn:lastNameColumn, genderColumn: genderColumn,
                  ipAddressColumn: ipAddressColumn, hasHeaderRow: hasHeaderRow, allowPhase2: allowPhase2,
                  completion: completion)
    }
    
    ///
    /// Send a file for bulk email validation from in-memory data (e.g. CSV built in memory).
    ///
    public func sendFile(
        fileData: Data,
        fileName: String,
        emailAddressColumn: Int,
        returnUrl: String? = nil,
        firstNameColumn: Int? = nil,
        lastNameColumn: Int? = nil,
        genderColumn: Int? = nil,
        ipAddressColumn: Int? = nil,
        hasHeaderRow: Bool = false,
        allowPhase2: Bool? = nil,
        completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()
    ) {
        _sendFileWithData(scoring: false, fileData: fileData, fileName: fileName, emailAddressColumn: emailAddressColumn,
                          returnUrl: returnUrl, firstNameColumn: firstNameColumn, lastNameColumn: lastNameColumn,
                          genderColumn: genderColumn, ipAddressColumn: ipAddressColumn, hasHeaderRow: hasHeaderRow,
                          allowPhase2: allowPhase2,
                          completion: completion)
    }
    
    ///
    /// The scoringSendfile API allows user to send a file for bulk email validation (AI Scoring)
    ///
    public func scoringSendFile(
        filePath: String,
        emailAddressColumn: Int,
        returnUrl: String? = nil,
        hasHeaderRow: Bool = false,
        completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()
    ) {
        
        _sendFile(scoring: true, filePath: filePath, emailAddressColumn: emailAddressColumn,
                  returnUrl: returnUrl, hasHeaderRow: hasHeaderRow,
                  completion: completion)
    }
    
    ///
    /// Send a file for bulk email scoring from in-memory data.
    ///
    public func scoringSendFile(
        fileData: Data,
        fileName: String,
        emailAddressColumn: Int,
        returnUrl: String? = nil,
        hasHeaderRow: Bool = false,
        completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()
    ) {
        _sendFileWithData(scoring: true, fileData: fileData, fileName: fileName, emailAddressColumn: emailAddressColumn,
                          returnUrl: returnUrl, hasHeaderRow: hasHeaderRow, completion: completion)
    }
    
    private func _sendFile(
        scoring: Bool,
        filePath: String,
        emailAddressColumn: Int,
        returnUrl: String? = nil,
        firstNameColumn: Int? = nil,
        lastNameColumn: Int? = nil,
        genderColumn:Int? = nil,
        ipAddressColumn:Int? = nil,
        hasHeaderRow: Bool = false,
        allowPhase2: Bool? = nil,
        completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()
    ) {
        
        guard let apiKey = normalizedApiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }
        
        var parameters = [
            "api_key": apiKey,
            "email_address_column": emailAddressColumn,
            "has_header_row": hasHeaderRow,
        ] as [String : Any]
        
        if let returnUrl = returnUrl {
            parameters["return_url"] = returnUrl
        }
        if let firstNameColumn = firstNameColumn {
            parameters["first_name_column"] = firstNameColumn
        }
        
        if let lastNameColumn = lastNameColumn {
            parameters["last_name_column"] = lastNameColumn
        }
        
        if let genderColumn = genderColumn {
            parameters["gender_column"] = genderColumn
        }
        
        if let ipAddressColumn = ipAddressColumn {
            parameters["ip_address_column"] = ipAddressColumn
        }
        if !scoring, let allowPhase2 = allowPhase2 {
            parameters["allow_phase_2"] = allowPhase2 ? "true" : "false"
        }
        
        do {
            let r = try ZBMultiPartRequest.createFileRequest(
                url: "\(bulkApiBaseUrl)\(scoring ? "/scoring" : "")/sendfile",
                parameters: parameters,
                filePathKey: "file", paths: [filePath]
            )
            sendJsonRequest(request: r, completion: completion)
        } catch {
            completion(ZBResult.Failure(error))
        }
    }
    
    private func _sendFileWithData(
        scoring: Bool,
        fileData: Data,
        fileName: String,
        emailAddressColumn: Int,
        returnUrl: String? = nil,
        firstNameColumn: Int? = nil,
        lastNameColumn: Int? = nil,
        genderColumn: Int? = nil,
        ipAddressColumn: Int? = nil,
        hasHeaderRow: Bool = false,
        allowPhase2: Bool? = nil,
        completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()
    ) {
        guard let apiKey = normalizedApiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }
        
        var parameters = [
            "api_key": apiKey,
            "email_address_column": emailAddressColumn,
            "has_header_row": hasHeaderRow,
        ] as [String : Any]
        
        if let returnUrl = returnUrl {
            parameters["return_url"] = returnUrl
        }
        if let firstNameColumn = firstNameColumn {
            parameters["first_name_column"] = firstNameColumn
        }
        if let lastNameColumn = lastNameColumn {
            parameters["last_name_column"] = lastNameColumn
        }
        if let genderColumn = genderColumn {
            parameters["gender_column"] = genderColumn
        }
        if let ipAddressColumn = ipAddressColumn {
            parameters["ip_address_column"] = ipAddressColumn
        }
        if !scoring, let allowPhase2 = allowPhase2 {
            parameters["allow_phase_2"] = allowPhase2 ? "true" : "false"
        }
        
        do {
            let r = try ZBMultiPartRequest.createFileRequestWithData(
                url: "\(bulkApiBaseUrl)\(scoring ? "/scoring" : "")/sendfile",
                parameters: parameters,
                filePathKey: "file",
                fileData: fileData,
                fileName: fileName
            )
            sendJsonRequest(request: r, completion: completion)
        } catch {
            completion(ZBResult.Failure(error))
        }
    }
    
    
    // MARK: Get File
    ///
    /// The getfile API allows users to get the validation results file for the file been submitted using sendfile API
    ///
    /// - parameter fileId: The returned file ID when calling sendfile API
    ///
    public func getFile(fileId: String, completion: @escaping (ZBResult<ZBGetFileResponse>) -> ()) {
        _getFile(scoring: false, fileId: fileId, options: nil, completion: completion)
    }
    
    /// Validation bulk `getfile` with optional `download_type` and `activity_data`.
    public func getFile(fileId: String, options: ZBGetFileOptions, completion: @escaping (ZBResult<ZBGetFileResponse>) -> ()) {
        _getFile(scoring: false, fileId: fileId, options: options, completion: completion)
    }
    
    /// As `getFile`, but written straight to `downloadPath` as it arrives
    /// instead of being held in memory first — use it for a result file too
    /// large to buffer.
    ///
    /// It is opt-in because a streamed body cannot be inspected as a whole,
    /// and `getfile` answers an unknown or deleted file id with a JSON error
    /// rather than a file. The first bytes are checked before the download is
    /// moved into place, so an error still reaches the failure result and no
    /// partial file is left behind.
    public func getFileStreaming(
        fileId: String,
        downloadPath: String,
        options: ZBGetFileOptions? = nil,
        completion: @escaping (ZBResult<ZBGetFileResponse>) -> ()
    ) {
        _getFileStreaming(scoring: false, fileId: fileId, downloadPath: downloadPath,
                          options: options, completion: completion)
    }

    /// The AI scoring counterpart of `getFileStreaming`.
    public func scoringGetFileStreaming(
        fileId: String,
        downloadPath: String,
        options: ZBGetFileOptions? = nil,
        completion: @escaping (ZBResult<ZBGetFileResponse>) -> ()
    ) {
        _getFileStreaming(scoring: true, fileId: fileId, downloadPath: downloadPath,
                          options: options, completion: completion)
    }

    private func _getFileStreaming(
        scoring: Bool,
        fileId: String,
        downloadPath: String,
        options: ZBGetFileOptions?,
        completion: @escaping (ZBResult<ZBGetFileResponse>) -> ()
    ) {
        guard let apiKey = normalizedApiKey else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        guard !downloadPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            completion(.Failure(ZBError.decodeError(messages: ["Empty parameter: downloadPath"])))
            return
        }
        guard let requestURL = buildGetFileURL(
            scoring: scoring, apiKey: apiKey, fileId: fileId, options: options
        ), ZeroBounceSDK.isAllowedURL(requestURL) else {
            completion(.Failure(ZBError.invalidEndpoint))
            return
        }

        var request = URLRequest(url: requestURL)
        request.timeoutInterval = 120
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        ZeroBounceSDK.urlSession.downloadTask(with: request) { location, response, error in
            if let error = error {
                completion(.Failure(error))
                return
            }
            guard let location = location,
                  let statusCode = (response as? HTTPURLResponse)?.statusCode else {
                completion(.Failure(ZBError.noResponse))
                return
            }
            defer { try? FileManager.default.removeItem(at: location) }

            // Enough to tell a file from an error page, without reading the
            // whole download back into memory.
            let probe = (try? FileHandle(forReadingFrom: location))
                .map { handle -> Data in
                    defer { try? handle.close() }
                    return (try? handle.read(upToCount: 4096)) ?? Data()
                } ?? Data()

            if 300..<400 ~= statusCode {
                completion(.Failure(ZBError.httpError(
                    message: "ZeroBounce returned a redirect, which this client does not follow.",
                    statusCode: statusCode
                )))
                return
            }
            guard 200...299 ~= statusCode, !probe.isEmpty else {
                completion(.Failure(ZBError.httpError(
                    message: ZBError.message(from: probe, statusCode: statusCode),
                    statusCode: statusCode
                )))
                return
            }
            let message = ZBError.message(from: probe, statusCode: statusCode)
            if message.contains("HTML error page") || ZBError.successMeansFailure(probe) {
                completion(.Failure(ZBError.httpError(message: message, statusCode: statusCode)))
                return
            }

            do {
                let outURL = URL(fileURLWithPath: downloadPath)
                try FileManager.default.createDirectory(
                    at: outURL.deletingLastPathComponent(), withIntermediateDirectories: true
                )
                try? FileManager.default.removeItem(at: outURL)
                try FileManager.default.moveItem(at: location, to: outURL)
                completion(.Success(ZBGetFileResponse(localFilePath: downloadPath)))
            } catch {
                completion(.Failure(ZBError.saveFileError(message: "\(error)")))
            }
        }.resume()
    }

    ///
    /// The scoringGetFile API allows users to get the validation results file for the file been submitted using scoringSendfile API
    ///
    public func scoringGetFile(fileId: String, completion: @escaping (ZBResult<ZBGetFileResponse>) -> ()) {
        _getFile(scoring: true, fileId: fileId, options: nil, completion: completion)
    }
    
    /// Scoring bulk `getfile` with optional `download_type` (`activityData` is ignored).
    public func scoringGetFile(fileId: String, options: ZBGetFileOptions, completion: @escaping (ZBResult<ZBGetFileResponse>) -> ()) {
        _getFile(scoring: true, fileId: fileId, options: options, completion: completion)
    }
    
    private func buildGetFileURL(scoring: Bool, apiKey: String, fileId: String, options: ZBGetFileOptions?) -> URL? {
        var comp = URLComponents(string: "\(bulkApiBaseUrl)\(scoring ? "/scoring" : "")/getfile")
        var items: [URLQueryItem] = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "file_id", value: fileId)
        ]
        if let options = options {
            if let dt = options.downloadType {
                items.append(URLQueryItem(name: "download_type", value: dt.queryValue))
            }
            if !scoring, let ad = options.activityData {
                items.append(URLQueryItem(name: "activity_data", value: ad ? "true" : "false"))
            }
        }
        comp?.queryItems = items
        return comp?.url
    }
    
    private func getFileJsonIndicatesFailure(_ d: [String: Any]) -> Bool {
        if let success = d["success"] as? Bool, success == false { return true }
        func nonEmpty(_ key: String) -> Bool {
            guard let s = d[key] as? String else { return false }
            return !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        if nonEmpty("message") || nonEmpty("error") || nonEmpty("error_message") { return true }
        return false
    }
    
    private func _getFile(scoring: Bool, fileId: String, options: ZBGetFileOptions?, completion: @escaping (ZBResult<ZBGetFileResponse>) -> ()) {
        guard let apiKey = normalizedApiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }
        guard let requestURL = buildGetFileURL(scoring: scoring, apiKey: apiKey, fileId: fileId, options: options) else {
            completion(ZBResult.Failure(ZBError.invalidEndpoint))
            return
        }
        
        sendRequest(url: requestURL.absoluteString) { result in
            switch result {
            case .success(let response, let data):
                if ZBError.message(from: data, statusCode: 200).contains("HTML error page")
                    || data.isEmpty {
                    completion(.Failure(ZBError.decodeError(messages: [
                        ZBError.message(from: data, statusCode: 200)
                    ])))
                    return
                }
                
                if let dict = try? JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as? [String: Any] {
                    if self.getFileJsonIndicatesFailure(dict) {
                        completion(.Failure(ZBError.decodeError(jsonData: data)))
                        return
                    }
                    if dict["success"] != nil {
                        completion(.Failure(ZBError.decodeError(jsonData: data)))
                        return
                    }
                }
                
                let fileName = (response.suggestedFilename != nil) ? response.suggestedFilename! : "file_\(fileId).csv"
                guard let text = String(data: data, encoding: .utf8) else {
                    completion(.Failure(ZBError.noData))
                    return
                }
                
                print("Zero Bounce SDK getFile fileName=\(fileName)")
                ZBFileManager.writeFile(text: text, to: fileName) { writeResult in
                    switch writeResult {
                    case .success(let path):
                        completion(.Success(ZBGetFileResponse(localFilePath: path)))
                        break;
                    case .failure(let error):
                        completion(.Failure(error))
                        break;
                    }
                }
                
            case .failure(let error):
                completion(.Failure(error))
            }
        }
    }
    
    // MARK: Request handling
    public enum ZBResult<T: Codable> {
        case Success(T)
        case Failure(Error)
    }

    public enum ZBDictionaryResult {
        case Success([String: Any])
        case Failure(Error)
    }

    /// A parsed JSON body that may be an object or an array.
    ///
    /// LIVE: `/filters/list` answers with a JSON array — `[]` when no filters
    /// are set — so a dictionary-only result could never carry it.
    public enum ZBJsonResult {
        case Success(Any)
        case Failure(Error)
    }
    
    private func makeURL(_ path: String, queryItems: [URLQueryItem]) -> String {
        var components = URLComponents(string: apiBaseUrl + path)!
        components.queryItems = queryItems
        return components.url!.absoluteString
    }

    private func makeBulkURL(scoring: Bool, subpath: String, queryItems: [URLQueryItem]) -> String {
        let base = "\(bulkApiBaseUrl)\(scoring ? "/scoring" : "")"
        var components = URLComponents(string: base + subpath)!
        components.queryItems = queryItems
        return components.url!.absoluteString
    }

    private func sendJsonRequest<T: Codable>(url: String, completion: @escaping (ZBResult<T>) -> ()) {
        guard let urlValue = URL(string: url) else {
            completion(.Failure(ZBError.invalidEndpoint))
            return
        }
        var r = URLRequest(url: urlValue)
        r.httpMethod = "GET"
        r.timeoutInterval = 120
        sendJsonRequest(request: r, completion: completion)
    }
    
    private func sendPostJsonRequest<T: Codable>(url: String, params: Data?, completion: @escaping (ZBResult<T>) -> ()) {
        var r = URLRequest(url: URL(string: url)!)
        r.httpMethod = "POST"
        r.timeoutInterval = 120
        
        guard let data = params else { return }
        r.httpBody = data
        
        sendJsonRequest(request: r, completion: completion)
    }

    private func sendFormPostRequest<T: Codable>(
        url: String,
        formFields: [String: String],
        completion: @escaping (ZBResult<T>) -> ()
    ) {
        guard let urlValue = URL(string: url) else {
            completion(.Failure(ZBError.invalidEndpoint))
            return
        }
        var components = URLComponents()
        components.queryItems = formFields.map { URLQueryItem(name: $0.key, value: $0.value) }
        var request = URLRequest(url: urlValue)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = components.percentEncodedQuery?.data(using: .utf8)
        sendJsonRequest(request: request, completion: completion)
    }
    
    private enum RequestResult {
        case success(URLResponse, Data)
        case failure(Error)
    }
    
    private func sendJsonRequest<T: Codable>(request:URLRequest, completion: @escaping (ZBResult<T>) -> ()) {
        sendRequest(request: request) { result in
            switch result {
            case .success(_, let data):
                do {
                    let value = try JSONDecoder().decode(T.self, from: data)
                    completion(.Success(value))
                } catch {
                    completion(.Failure(ZBError.decodeError(messages: [
                        ZBError.message(from: data, statusCode: 200)
                    ])))
                }
                
            case .failure (let error):
                completion(.Failure(error))
            }
        }
    }
    
    private func sendRequest(url:String, result: @escaping (RequestResult) -> ()) {
        sendRequest(request: URLRequest(url: URL(string: url)!), result: result)
    }
    
    private func sendRequest(request:URLRequest,  result: @escaping (RequestResult) -> ()) {
        guard let url = request.url, ZeroBounceSDK.isAllowedURL(url) else {
            result(RequestResult.failure(ZBError.decodeError(messages: ["url must be an https:// URL"])))
            return
        }
        ZeroBounceSDK.urlSession.dataTask(with: request, completionHandler: { data, response, error -> Void in
            if let error = error {
                result(RequestResult.failure(error))
                return
            }
            
            guard let response = response else {
                result(RequestResult.failure(ZBError.noResponse))
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
                result(RequestResult.failure(ZBError.noResponse))
                return
            }
            
            let body = data ?? Data()
            if 300..<400 ~= statusCode {
                // Redirects are not followed: one could send the api_key to
                // another host.
                result(RequestResult.failure(ZBError.httpError(
                    message: "ZeroBounce returned a redirect, which this client does not follow.",
                    statusCode: statusCode
                )))
                return
            }
            guard 200...299 ~= statusCode else {
                result(RequestResult.failure(ZBError.httpError(
                    message: ZBError.message(from: body, statusCode: statusCode),
                    statusCode: statusCode
                )))
                return
            }
            if body.isEmpty || ZBError.message(from: body, statusCode: statusCode).contains("HTML error page") {
                result(RequestResult.failure(ZBError.httpError(
                    message: ZBError.message(from: body, statusCode: statusCode),
                    statusCode: statusCode
                )))
                return
            }
            // LIVE: a "success": false field on an HTTP 200 is a failure, not
            // a result. getfile and deletefile report an unknown or deleted
            // file id that way, and the caller should not have to inspect a
            // flag to notice.
            if ZBError.successMeansFailure(body) {
                result(RequestResult.failure(ZBError.httpError(
                    message: ZBError.message(from: body, statusCode: statusCode),
                    statusCode: statusCode
                )))
                return
            }

            result(RequestResult.success(response, body))
        }).resume()
    }

    /// The session every request goes through. Redirects are not followed: one
    /// could send the api_key to another host. The offline suite replaces this
    /// with a session whose configuration registers its stub protocol.
    internal static var urlSession: URLSession = ZeroBounceSDK.makeSession()

    private static let redirectBlocker = ZBRedirectBlocker()

    internal static func makeSession(protocolClasses: [AnyClass]? = nil) -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        if let protocolClasses = protocolClasses {
            configuration.protocolClasses = protocolClasses
        }
        return URLSession(configuration: configuration, delegate: redirectBlocker, delegateQueue: nil)
    }

    /// Escapes a value as a single path segment, so a slash in it stays encoded.
    internal static func escapePathSegment(_ value: String) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }

    /// One request with an explicit method and an optional JSON body, for the
    /// Inbox Placement Tester's PUT and DELETE.
    internal func priority3JsonDictionaryRequest(
        method: String,
        url: String,
        body: [String: Any]?,
        extraHeaders: [String: String] = [:],
        completion: @escaping (ZBDictionaryResult) -> ()
    ) {
        guard let urlValue = URL(string: url) else {
            completion(.Failure(ZBError.invalidEndpoint))
            return
        }
        var request = URLRequest(url: urlValue)
        request.httpMethod = method
        request.timeoutInterval = 120
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        for (name, value) in extraHeaders {
            request.setValue(value, forHTTPHeaderField: name)
        }
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [.sortedKeys])
        }
        sendRequest(request: request) { result in
            switch result {
            case .success(_, let data):
                // DELETE answers with an empty body.
                if data.isEmpty {
                    completion(.Success([:]))
                    return
                }
                do {
                    let object = try JSONSerialization.jsonObject(with: data, options: [])
                    if let dict = object as? [String: Any] {
                        completion(.Success(dict))
                    } else {
                        completion(.Failure(ZBError.decodeError(jsonData: data)))
                    }
                } catch {
                    completion(.Failure(error))
                }
            case .failure(let error):
                completion(.Failure(error))
            }
        }
    }

    internal func priority3QueryURL(base: String, query: [String: String]) -> String {
        var components = URLComponents(string: base)!
        components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        return components.url!.absoluteString
    }

    internal func priority3SendJson<T: Codable>(url: String, completion: @escaping (ZBResult<T>) -> ()) {
        sendJsonRequest(url: url, completion: completion)
    }

    internal func priority3SendJsonRequest<T: Codable>(request: URLRequest, completion: @escaping (ZBResult<T>) -> ()) {
        sendJsonRequest(request: request, completion: completion)
    }

    internal func priority3FormPostSendFile(
        url: String,
        formFields: [String: String],
        completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()
    ) {
        sendFormPostRequest(url: url, formFields: formFields, completion: completion)
    }

    /// As priority3SendDictionary, but keeps an array body instead of
    /// rejecting it.
    internal func priority3SendJson(url: String, completion: @escaping (ZBJsonResult) -> ()) {
        sendRequest(url: url) { result in
            switch result {
            case .success(_, let data):
                do {
                    completion(.Success(try JSONSerialization.jsonObject(with: data, options: [])))
                } catch {
                    completion(.Failure(error))
                }
            case .failure(let error):
                completion(.Failure(error))
            }
        }
    }

    internal func priority3FormPostJson(
        url: String,
        formFields: [String: String],
        completion: @escaping (ZBJsonResult) -> ()
    ) {
        priority3FormPostDictionary(url: url, formFields: formFields) { result in
            switch result {
            case .Success(let dict):
                completion(.Success(dict))
            case .Failure(let error):
                completion(.Failure(error))
            }
        }
    }

    internal func priority3SendDictionary(url: String, completion: @escaping (ZBDictionaryResult) -> ()) {
        sendRequest(url: url) { result in
            switch result {
            case .success(_, let data):
                do {
                    let object = try JSONSerialization.jsonObject(with: data, options: [])
                    if let dict = object as? [String: Any] {
                        completion(.Success(dict))
                    } else {
                        completion(.Failure(ZBError.decodeError(jsonData: data)))
                    }
                } catch {
                    completion(.Failure(error))
                }
            case .failure(let error):
                completion(.Failure(error))
            }
        }
    }

    internal func priority3FormPostDictionary(
        url: String,
        formFields: [String: String],
        completion: @escaping (ZBDictionaryResult) -> ()
    ) {
        guard let urlValue = URL(string: url) else {
            completion(.Failure(ZBError.invalidEndpoint))
            return
        }
        var components = URLComponents()
        components.queryItems = formFields.map { URLQueryItem(name: $0.key, value: $0.value) }
        var request = URLRequest(url: urlValue)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = components.percentEncodedQuery?.data(using: .utf8)
        sendRequest(request: request) { result in
            switch result {
            case .success(_, let data):
                do {
                    let object = try JSONSerialization.jsonObject(with: data, options: [])
                    if let dict = object as? [String: Any] {
                        completion(.Success(dict))
                    } else {
                        completion(.Failure(ZBError.decodeError(jsonData: data)))
                    }
                } catch {
                    completion(.Failure(error))
                }
            case .failure(let error):
                completion(.Failure(error))
            }
        }
    }

    internal func priority3Download(
        url: String,
        downloadPath: String,
        completion: @escaping (ZBResult<ZBGetFileResponse>) -> ()
    ) {
        sendRequest(url: url) { result in
            switch result {
            case .success(_, let data):
                let bodyStr = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if bodyStr.hasPrefix("{") {
                    if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let success = dict["success"] as? Bool, success == false {
                            completion(.Failure(ZBError.decodeError(jsonData: data)))
                            return
                        }
                        if dict["message"] != nil || dict["error"] != nil || dict["error_message"] != nil {
                            completion(.Failure(ZBError.decodeError(jsonData: data)))
                            return
                        }
                    }
                }
                do {
                    let outURL = URL(fileURLWithPath: downloadPath)
                    try FileManager.default.createDirectory(at: outURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                    try data.write(to: outURL)
                    completion(.Success(ZBGetFileResponse(localFilePath: downloadPath)))
                } catch {
                    completion(.Failure(error))
                }
            case .failure(let error):
                completion(.Failure(error))
            }
        }
    }
}

/// Hands the 3xx back to the caller instead of following it.
private final class ZBRedirectBlocker: NSObject, URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        completionHandler(nil)
    }
}
