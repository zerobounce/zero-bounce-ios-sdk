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
    /// An error the API itself reported, with the HTTP status it came back
    /// with, so a caller can tell 429 from 500 without parsing the message.
    /// The status is 200 when the API answered a failure on a success code,
    /// which `getfile` and `deletefile` do for an unknown file id.
    case httpError(message: String, statusCode: Int)

    /// The HTTP status behind this error, when there was one.
    public var statusCode: Int? {
        switch self {
        case .httpError(_, let statusCode):
            return statusCode
        case .invalidResponse(let statusCode):
            return statusCode
        default:
            return nil
        }
    }

    /// Whether a JSON body says the call failed although the HTTP status was a
    /// success. The API sends `success` as a JSON false, "false" or "False".
    static func successMeansFailure(_ data: Data) -> Bool {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let value = object["success"] else {
            return false
        }
        if let flag = value as? Bool { return !flag }
        if let text = value as? String { return text.lowercased() == "false" }
        if let number = value as? NSNumber { return number.intValue == 0 }
        return false
    }
    
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
    
    static func message(from data: Data, statusCode: Int) -> String {
        let body = String(data: data, encoding: .utf8) ?? ""
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "Empty response from ZeroBounce (HTTP \(statusCode))"
        }
        let prefix = String(trimmed.prefix(2000)).lowercased()
        if prefix.contains("<!doctype html") || prefix.contains("<html") || prefix.contains("<head") || prefix.contains("<body") {
            if let title = htmlTitle(in: body), !title.isEmpty {
                return "ZeroBounce returned an HTML error page (\"\(title)\") instead of an API response."
            }
            return "ZeroBounce returned an HTML error page instead of an API response."
        }
        if trimmed.hasPrefix("{") || trimmed.hasPrefix("[") {
            if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let title = object["title"] as? String,
                   title.contains("Access denied") || title.contains("1020"),
                   (object["cloudflare_error"] as? Bool) == true {
                    return title
                }
                for key in ["message", "error_message", "error"] {
                    if let value = object[key] as? String {
                        let text = stripErrorPrefix(value)
                        if !text.isEmpty { return text }
                    }
                }
                for (key, value) in object where key != "success" && (key.contains("message") || key.contains("error")) {
                    if let text = value as? String {
                        let stripped = stripErrorPrefix(text)
                        if !stripped.isEmpty { return stripped }
                    }
                }
            } else if trimmed.count > 1000 {
                return "ZeroBounce returned a response that is not valid JSON."
            }
            if trimmed.count > 1000 {
                return "ZeroBounce returned a response that is not valid JSON."
            }
            return trimmed
        }
        if trimmed.count > 1000 {
            return "ZeroBounce returned a response that is not valid JSON."
        }
        let message = stripErrorPrefix(trimmed)
        if message.isEmpty {
            return "Empty response from ZeroBounce (HTTP \(statusCode))"
        }
        return message
    }

    private static func stripErrorPrefix(_ value: String) -> String {
        var message = value.trimmingCharacters(in: .whitespacesAndNewlines)
        while message.hasPrefix("Error:") || message.hasPrefix("[Error]:") {
            if message.hasPrefix("Error:") {
                message = String(message.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                message = String(message.dropFirst(8)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return message
    }

    private static func htmlTitle(in body: String) -> String? {
        let lower = body.lowercased()
        guard let start = lower.range(of: "<title"),
              let open = lower.range(of: ">", range: start.upperBound..<lower.endIndex),
              let close = lower.range(of: "</title>", range: open.upperBound..<lower.endIndex) else {
            return nil
        }
        return String(body[open.upperBound..<close.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
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
        case .httpError(let message, _):
            return message
        default:
            return "No error description provided"
        }
    }
}
