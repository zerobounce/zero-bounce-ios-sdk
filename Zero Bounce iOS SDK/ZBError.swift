//
//  ZBError.swift
//  ZeroBounceExample
//
//  Created by ZeroBounce on 10/07/2019.
//  Copyright © 2019 ZeroBounce. All rights reserved.
//

import Foundation

public enum ZBError: LocalizedError {
    case notInitialized
    case apiError
    case invalidEndpoint
    case noResponse
    case invalidResponse(statusCode: Int)
    case noData
    case decodeError(messages: [String])
    case saveFileError(message: String)
    
    static func decodeError(jsonData: Data) -> ZBError {
        guard let response = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableLeaves) as? [String: Any] else {
            return .decodeError(messages: [])
        }
        var messages: [String] = []
        for key in ["message", "error_message", "error"] {
            if let s = response[key] as? String {
                let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
                if !t.isEmpty { messages.append(t) }
            }
        }
        if messages.isEmpty {
            for (key, value) in response where key != "success" {
                if let s = value as? String {
                    let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !t.isEmpty { messages.append(t) }
                } else if let arr = value as? [String] {
                    messages.append(contentsOf: arr)
                }
            }
        }
        return .decodeError(messages: messages)
    }
    
    public var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "ZeroBounceSDK is not initialized. Please call ZeroBounceSDK.shared.initialize(apiKey) first"
        case .invalidResponse(let statusCode):
            return "Invalid Response (status code: \(statusCode))"
        case .saveFileError(let message):
            return message
        case .decodeError(let messages):
            return "Messages: \n \(messages.joined(separator: "\n"))"
        default:
            return "No error description provided"
        }
    }
}
