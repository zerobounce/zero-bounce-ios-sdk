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
    
    private init() {}
    
    public func initialize(apiKey:String) {
        self.apiKey = apiKey
    }
    
    public func validate(email:String, ipAddress:String? = nil, completion: (Result<[ZBValidateResponse]>) -> ()) {
        let ipAddressPart = ipAddress != nil ? "\(ipAddress!)" : ""
        request(url: "\(apiBaseUrl)/validate?api_key=\(apiKey!)&email=\(email)&ip_address=\(ipAddressPart)",
                completion: completion)
    }
    
    public enum Result<T : Codable>
    {
        case Success(T)
        case Failure(NSError?)
    }

    private func request<T : Codable>(url:String, completion: (Result<[T]>) -> ()) {
        
    }
    
    
}
