//
//  ZeroBounceSDK.swift
//  Zero Bounce iOS SDK
//
//  Created by Mount Software on 08/07/2019.
//  Copyright © 2019 Mount Software. All rights reserved.
//

import Foundation

public class ZeroBounceSDK {
    
    static public let shared = ZeroBounceSDK()

    private let apiBaseUrl = "https://api.zerobounce.net/v2"
    private let bulkApiBaseUrl = "https://bulkapi.zerobounce.net/v2"
    private var apiKey: String?
    private let jsonDecoder: JSONDecoder = {
        let jsonDecoder = JSONDecoder()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-mm-dd"
        jsonDecoder.dateDecodingStrategy = .formatted(dateFormatter)
        return jsonDecoder
    }()
    
    private init() {}
    
    public func initialize(apiKey:String) {
        self.apiKey = apiKey
    }
    
    public func validate(email:String, ipAddress:String? = nil, completion: @escaping (ZBResult<ZBValidateResponse>) -> ()) {
        let ipAddressPart = ipAddress != nil ? "\(ipAddress!)" : ""
        request(url: "\(apiBaseUrl)/validate?api_key=\(apiKey!)&email=\(email)&ip_address=\(ipAddressPart)",
                result: completion)
    }
    
    public enum ZBResult<T : Codable>
    {
        case Success(T)
        case Failure(Error?)
    }
    
    public enum ZBError : Error {
        case apiError
        case invalidEndpoint
        case noResponse
        case invalidResponse
        case noData
        case decodeError
    }

    private func request<T : Codable>(url:String, result: @escaping (ZBResult<T>) -> ()) {
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
            NSLog("ZeroBounceSDK response: \(String(describing: response))")
            if let error = error {
                result(ZBResult.Failure(error))
                return
            }
            
            guard let response = response else {
                result(ZBResult.Failure(ZBError.noResponse))
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, 200..<299 ~= statusCode else {
                result(ZBResult.Failure(ZBError.invalidResponse))
                return
            }
            
            guard let data = data else {
                result(ZBResult.Failure(ZBError.noData))
                return
            }
            
            do {
                let value = try self.jsonDecoder.decode(T.self, from: data)
                result(ZBResult.Success(value))
            }
            catch {
                result(ZBResult.Failure(ZBError.decodeError))
            }
            
        }).resume()
     }
    
    
}
