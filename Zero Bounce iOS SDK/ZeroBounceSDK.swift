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
    
    let apiBaseUrl = "https://api.zerobounce.net/v2"
    let bulkApiBaseUrl = "https://bulkapi.zerobounce.net/v2"
    let bulkApiScoringBaseUrl = "https://bulkapi.zerobounce.net/v2/scoring"
    var apiKey: String?
    let dateFormatter = DateFormatter()
    
    fileprivate init() {
        dateFormatter.dateFormat = "yyyy-MM-dd"
    }
    
    public func initialize(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // MARK: Validate
    ///
    /// - parameter email: The email address you want to validate
    /// - parameter ipAddress: The IP Address the email signed up from (Can be blank)
    ///
    public func validate(email: String, ipAddress: String? = nil, completion: @escaping (ZBResult<ZBValidateResponse>) -> ()) {
        guard let apiKey = self.apiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }
        
        let ipAddressPart = ipAddress != nil ? "\(ipAddress!)" : ""
        sendJsonRequest(url: "\(apiBaseUrl)/validate?api_key=\(apiKey)&email=\(email)&ip_address=\(ipAddressPart)", completion: completion)
    }
    
    // MARK: Validate Batch
    ///
    /// - parameter emails: List of email addresses you want to validate
    ///
    public func validateBatch(emails: [[String:String]], completion: @escaping (ZBResult<ZBValidateBatchResponse>) -> ()) {
        guard let apiKey = self.apiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }
        
        let params: [String: Any] = [
            "api_key": apiKey,
            "email_batch": emails
        ]
        
        let jsonDataParams = try? JSONSerialization.data(withJSONObject: params)
        sendPostJsonRequest(url: "\(bulkApiBaseUrl)/validatebatch", params: jsonDataParams, completion: completion)
    }
    
    // MARK: Email Finder
    ///
    /// - parameter domain: The email domain for which to find the email format
    /// - parameter firstName: The first name of the person whose email format is being searched
    /// - parameter middleName: The middle name of the person whose email format is being searched
    /// - parameter lastName: The last name of the person whose email format is being searched
    ///
    public func guessFormat(
        domain: String,
        firstName: String? = nil,
        middleName: String? = nil,
        lastName: String? = nil,
        completion: @escaping (ZBResult<ZBEmailFinderResponse>) -> ()
    ) {
        guard let apiKey = self.apiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }
        
        var url = "\(apiBaseUrl)/guessformat?api_key=\(apiKey)&domain=\(domain)"
        
        if let firstName {
            url += "&first_name=\(firstName)"
        }
        
        if let middleName {
            url += "&middle_name=\(middleName)"
        }
        
        if let lastName {
            url += "&last_name=\(lastName)"
        }
        
        sendJsonRequest(
            url: url.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!,
            completion: completion
        )
    }
    
    // MARK: Get Credits
    ///
    /// This API will tell you how many credits you have left on your account. It's simple, fast and easy to use.
    ///
    public func getCredits(completion: @escaping (ZBResult<ZBCreditsResponse>) -> ()) {
        guard let apiKey = self.apiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }
        
        sendJsonRequest(url: "\(apiBaseUrl)/getcredits?api_key=\(apiKey)", completion: completion)
    }
    
    // MARK: Get Api Usage
    ///
    /// - parameter startDate: The start date of when you want to view API usage
    /// - parameter endDate: The end date of when you want to view API usage
    ///
    public func getApiUsage(startDate: Date, endDate: Date, completion: @escaping (ZBResult<ZBGetApiUsageResponse>) -> ()) {
        guard let apiKey = self.apiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }
        
        let startString = self.dateFormatter.string(from: startDate)
        let endString = self.dateFormatter.string(from: endDate)
        
        sendJsonRequest(url: "\(apiBaseUrl)/getapiusage?api_key=\(apiKey)&start_date=\(startString)&end_date=\(endString)", completion: completion)
    }
    
    // MARK: Activity Data
    ///
    /// - parameter email: The email inbox you want to check the activity data for
    ///
    public func getActivityData(email: String, completion: @escaping (ZBResult<ZBActivityDataResponse>) -> ()) {
        guard let apiKey = self.apiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }
        
        sendJsonRequest(url: "\(apiBaseUrl)/activity?api_key=\(apiKey)&email=\(email)", completion: completion)
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
        guard let apiKey = self.apiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }
        
        sendJsonRequest(url: "\(bulkApiBaseUrl)\(scoring ? "/scoring" : "")/filestatus?api_key=\(apiKey)&file_id=\(fileId)", completion: completion)
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
        guard let apiKey = self.apiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }
        
        sendJsonRequest(url: "\(bulkApiBaseUrl)\(scoring ? "/scoring" : "")/deletefile?api_key=\(apiKey)&file_id=\(fileId)", completion: completion)
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
        completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()
    ) {
        _sendFile(scoring: false, filePath: filePath, emailAddressColumn: emailAddressColumn,
                  returnUrl: returnUrl, firstNameColumn: firstNameColumn, lastNameColumn:lastNameColumn, genderColumn: genderColumn,
                  ipAddressColumn: ipAddressColumn, hasHeaderRow: hasHeaderRow,
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
        completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()
    ) {
        
        guard let apiKey = self.apiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }
        
        var parameters = [
            "api_key": apiKey,
            "email_address_column": emailAddressColumn,
            "has_header_row": hasHeaderRow,
        ] as [String : Any]
        
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
    
    
    // MARK: Get File
    ///
    /// The getfile API allows users to get the validation results file for the file been submitted using sendfile API
    ///
    /// - parameter fileId: The returned file ID when calling sendfile API
    ///
    public func getFile(fileId: String, completion: @escaping (ZBResult<ZBGetFileResponse>) -> ()) {
        _getFile(scoring: false, fileId: fileId, completion: completion)
    }
    
    ///
    /// The scoringGetFile API allows users to get the validation results file for the file been submitted using scoringSendfile API
    ///
    public func scoringGetFile(fileId: String, completion: @escaping (ZBResult<ZBGetFileResponse>) -> ()) {
        _getFile(scoring: true, fileId: fileId, completion: completion)
    }
    
    private func _getFile(scoring: Bool, fileId: String, completion: @escaping (ZBResult<ZBGetFileResponse>) -> ()) {
        guard let apiKey = self.apiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }
        
        sendRequest(url: "\(bulkApiBaseUrl)\(scoring ? "/scoring" : "")/getfile?api_key=\(apiKey)&file_id=\(fileId)") { result in
            switch result {
            case .success(let response, let data):
                
                if let response = try? JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as? [String: Any] {
                    if let success = response["success"] as? Bool, success == false {
                        completion(.Failure(ZBError.decodeError(jsonData: data)))
                        return
                    }
                }
                
                let fileName = (response.suggestedFilename != nil) ? response.suggestedFilename! : "file_\(fileId).csv"
                guard let text = String(data: data, encoding: .utf8) else {
                    completion(.Failure(ZBError.noData))
                    return
                }
                
                print("Zero Bounce SDK getFile data: \(text), fileName=\(fileName)")
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
    
    private func sendJsonRequest<T: Codable>(url: String, completion: @escaping (ZBResult<T>) -> ()) {
        var r = URLRequest(url: URL(string: url)!)
        r.httpMethod = "GET"
        
        NSLog("ZeroBounceSDK request url=\(url)")
        sendJsonRequest(request: r, completion: completion)
    }
    
    private func sendPostJsonRequest<T: Codable>(url: String, params: Data?, completion: @escaping (ZBResult<T>) -> ()) {
        var r = URLRequest(url: URL(string: url)!)
        r.httpMethod = "POST"
        
        guard let data = params else { return }
        r.httpBody = data
        
        NSLog("ZeroBounceSDK request url=\(url)")
        sendJsonRequest(request: r, completion: completion)
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
                    NSLog("ZeroBounceSDK error \(error)")
                    completion(.Failure(ZBError.decodeError(jsonData: data)))
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
        URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
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
            
            NSLog("ZeroBounceSDK statusCode: \(statusCode)")
            guard 200..<299 ~= statusCode else {
                result(RequestResult.failure(ZBError.invalidResponse(statusCode: statusCode)))
                return
            }
            
            guard let data = data else {
                result(RequestResult.failure(ZBError.noData))
                return
            }
            
            let json = String(data: data, encoding: .utf8)
            NSLog("ZeroBounceSDK data json: \(String(describing: json))")
            
            result(RequestResult.success(response, data))
        }).resume()
    }
}
