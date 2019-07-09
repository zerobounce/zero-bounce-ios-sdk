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

    public func validate(email: String, ipAddress: String? = nil, completion: @escaping (ZBResult<ZBValidateResponse>) -> ()) {
        //print("ZeroBounceSDK validate email=\(email)")
        guard let apiKey = self.apiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }

        let ipAddressPart = ipAddress != nil ? "\(ipAddress!)" : ""
        sendJsonRequest(url: "\(apiBaseUrl)/validate?api_key=\(apiKey)&email=\(email)&ip_address=\(ipAddressPart)", completion: completion)
    }

    public func getCredits(completion: @escaping (ZBResult<ZBCreditsResponse>) -> ()) {
        guard let apiKey = self.apiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }

        sendJsonRequest(url: "\(apiBaseUrl)/getcredits?api_key=\(apiKey)", completion: completion)
    }

    public func fileStatus(fileId: String, completion: @escaping (ZBResult<ZBFileStatusResponse>) -> ()) {
        guard let apiKey = self.apiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }

        sendJsonRequest(url: "\(bulkApiBaseUrl)/filestatus?api_key=\(apiKey)&file_id=\(fileId)", completion: completion)
    }

    public func deleteFile(fileId: String, completion: @escaping (ZBResult<ZBDeleteFileResponse>) -> ()) {
        guard let apiKey = self.apiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }

        sendJsonRequest(url: "\(bulkApiBaseUrl)/filestatus?api_key=\(apiKey)&file_id=\(fileId)", completion: completion)
    }

    public func getApiUsage(startDate: Date, endDate: Date, completion: @escaping (ZBResult<ZBGetApiUsageResponse>) -> ()) {
        guard let apiKey = self.apiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }

        let startString = self.dateFormatter.string(from: startDate)
        let endString = self.dateFormatter.string(from: endDate)

        sendJsonRequest(url: "\(apiBaseUrl)/getapiusage?api_key=\(apiKey)&start_date=\(startString)&end_date=\(endString)", completion: completion)
    }
    
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
                self.writeFile(text: text, to: fileName) { writeResult in
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

    public enum ZBError: LocalizedError {
        case notInitialized
        case apiError
        case invalidEndpoint
        case noResponse
        case invalidResponse(statusCode: Int)
        case noData
        case decodeError
        case saveFileError(message: String)
        public var errorDescription: String? {
            switch self {
            case .notInitialized:
                return "ZeroBounceSDK is not initialized. Please call ZeroBounceSDK.shared.initialize(apiKey) first"
            case .invalidResponse(let statusCode):
                return "Invalid Response (status code: \(statusCode))" 
            case .saveFileError(let message):
                return message
            default:
                return "No error description provided"
            }
        }
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
            case .success( _, let data):

                do {
                    // let value = try self.jsonDecoder.decode(T.self, from: data)
                    let value = try JSONDecoder().decode(T.self, from: data)
                    completion(ZBResult.Success(value))
                } catch {
                    NSLog("ZeroBounceSDK error \(error)")
                    completion(ZBResult.Failure(ZBError.decodeError))
                }
                break
            case .failure (let error):
                completion(ZBResult.Failure(error))
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

    private enum WriteFileResult {
        case success(String)
        case failure(Error)
    }

    private func writeFile(text:String, to fileNamed: String, folder: String = "SavedFiles", result: @escaping (WriteFileResult) -> ()) {
        guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            result(.failure(ZBError.saveFileError(message: "Cannot access downloads directory")))
            return
        }

        guard let writePath = NSURL(fileURLWithPath: path).appendingPathComponent(folder) else {
            result(.failure(ZBError.saveFileError(message: "Cannot access folder \(folder)")))
            return
        }
        
        do {
            try FileManager.default.createDirectory(atPath: writePath.path, withIntermediateDirectories: true)
        } catch {
            result(.failure(ZBError.saveFileError(message: "Cannot create directory \(writePath.path)")))
            return
        }

        let file = writePath.appendingPathComponent(fileNamed)

        do {
            try text.write(to: file, atomically: false, encoding: .utf8)
        } catch {
            result(.failure(ZBError.saveFileError(message: "Cannot write to file \(file.path)")))
            return
        }

        result(.success(file.path))
    }


}
