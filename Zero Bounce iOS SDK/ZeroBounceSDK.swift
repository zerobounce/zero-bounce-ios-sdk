//
//  ZeroBounceSDK.swift
//  Zero Bounce iOS SDK
//
//  Created by Mount Software on 08/07/2019.
//  Copyright © 2019 Mount Software. All rights reserved.
//

import Foundation

import UIKit

public class ZeroBounceSDK {

    static public let shared = ZeroBounceSDK()

    private let apiBaseUrl = "https://api.zerobounce.net/v2"
    private let bulkApiBaseUrl = "https://bulkapi.zerobounce.net/v2"
    private var apiKey: String?
    private let dateFormatter = DateFormatter()

    fileprivate init() {
        dateFormatter.dateFormat = "yyyy-MM-dd"
    }

    public func initialize(apiKey: String) {
        self.apiKey = apiKey
    }

    ///
    /// - parameter email: The email address you want to validate
    /// - parameter ipAddress: The IP Address the email signed up from (Can be blank)
    ///
    public func validate(email: String, ipAddress: String? = nil, completion: @escaping (ZBResult<ZBValidateResponse>) -> ()) {
        //print("ZeroBounceSDK validate email=\(email)")
        guard let apiKey = self.apiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }

        let ipAddressPart = ipAddress != nil ? "\(ipAddress!)" : ""
        sendJsonRequest(url: "\(apiBaseUrl)/validate?api_key=\(apiKey)&email=\(email)&ip_address=\(ipAddressPart)", completion: completion)
    }

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

    ///
    /// - parameter fileId: The returned file ID when calling sendFile API.
    ///
    public func fileStatus(fileId: String, completion: @escaping (ZBResult<ZBFileStatusResponse>) -> ()) {
        guard let apiKey = self.apiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }

        sendJsonRequest(url: "\(bulkApiBaseUrl)/filestatus?api_key=\(apiKey)&file_id=\(fileId)", completion: completion)
    }

    ///
    /// - parameter fileId: The returned file ID when calling sendfile API.
    ///
    public func deleteFile(fileId: String, completion: @escaping (ZBResult<ZBDeleteFileResponse>) -> ()) {
        guard let apiKey = self.apiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }

        sendJsonRequest(url: "\(bulkApiBaseUrl)/filestatus?api_key=\(apiKey)&file_id=\(fileId)", completion: completion)
    }

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
    
    ///
    /// The sendfile API allows user to send a file for bulk email validation
    ///
    public func sendFile(
        filePath: String, emailAddressColumn:Int, returnUrl: String? = nil,
        firstNameColumn: Int? = nil, lastNameColumn: Int? = nil, genderColumn:Int? = nil, ipAddressColumn:Int? = nil, hasHeaderRow: Bool = false,
        completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()) {
        
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
            let r = try ZBMultiPartRequest.createFileRequest(url: "\(bulkApiBaseUrl)/sendFile", parameters: parameters, filePathKey: "file", paths: [filePath])
            sendJsonRequest(request: r, completion: completion)
        } catch {
            completion(ZBResult.Failure(error))
            return
        }
    }
    
    ///
    /// The getfile API allows users to get the validation results file for the file been submitted using sendfile API
    ///
    public func getFile(fileId: String, completion: @escaping (ZBResult<ZBGetFileResponse>) -> ()) {
        guard let apiKey = self.apiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }

        sendRequest(url: "\(bulkApiBaseUrl)/getFile?api_key=\(apiKey)&file_id=\(fileId)") { result in 
            switch result {
            case .success(let response, let data):

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
                break;
            case .failure(let error):
                completion(.Failure(error))
                break;
            }
        }
    }

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
                    completion(.Failure(ZBError.decodeError))
                }
                break
            case .failure (let error):
                completion(.Failure(error))
                break
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
            //NSLog("ZeroBounceSDK response: \(response)")

            guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
                result(RequestResult.failure(ZBError.noResponse))
                return
            }

            NSLog("ZeroBounceSDK statusCode: \(statusCode)")

            /*
            guard 200..<299 ~= statusCode else {
                result(RequestResult.failure(ZBError.invalidResponse(statusCode: statusCode)))
                return
            }
            */

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
