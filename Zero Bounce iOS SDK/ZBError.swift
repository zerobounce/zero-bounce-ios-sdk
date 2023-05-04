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
        var messages: [String] = []
        do {
            guard let response = try JSONSerialization.jsonObject(with: jsonData, options: .mutableLeaves) as? [String: Any] else {
                return .decodeError(messages: [])
            }
            for (key, value) in response {
                if key == "error", let message = value as? String {
                    messages.append(message)
                }
                if key == "message" {
                    if let message = value as? String {
                        messages.append(message)
                    } else {
                        if let messageList = value as? [String] {
                            for message in messageList {
                                messages.append(message)
                            }
                        }
                    }
                }
                return .decodeError(messages: messages)
            }
        } catch {
            /// No messages
            NSLog("Response could not be decoded")
        }
        return .decodeError(messages: [])
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
