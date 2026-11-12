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
    /// The status is 200 when the API answered a failure on a success code:
    /// `"success": false` (`getfile` and `deletefile` for an unknown file id),
    /// a dead key's error-only body, `validateBatch`'s account-level
    /// "all" error, and a body that is not the call's answer (not JSON, or
    /// JSON of another shape).
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
    
    /// Whether a JSON body is an error with no "success" field to gate on: a
    /// non-empty "error", "error_message" or "Error" string. LIVE: an invalid
    /// or drained key answers validate, activity and getapiusage with
    /// {"error": ...}, and the filters with {"Error": ...}, on an HTTP 200.
    /// "message" and "Message" are not among the keys: successful responses
    /// use them too (a filter change answers with a bare "Message").
    static func errorOnlyBody(_ data: Data) -> Bool {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              object["success"] == nil else {
            return false
        }
        return ["error", "error_message", "Error"].contains { key in
            guard let text = object[key] as? String else { return false }
            return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    /// Whether a body is a JSON object. A file download never is: getfile
    /// answers with JSON only to say why there is no file.
    static func looksLikeJsonObject(_ data: Data) -> Bool {
        let head = String(decoding: data.prefix(64), as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return head.hasPrefix("{")
    }

    /// Whether a body is JSON rather than a file: an object, or an array
    /// that parses as JSON (a CSV line can start with "[" too).
    static func looksLikeJson(_ data: Data) -> Bool {
        if looksLikeJsonObject(data) { return true }
        let head = String(decoding: data.prefix(64), as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return head.hasPrefix("[") && (try? JSONSerialization.jsonObject(with: data)) != nil
    }

    /// Why a 2xx answer to a file download is not the file, or nil when it
    /// is one. An empty body, an HTML page (by content type or by body) and
    /// JSON (by content type or by body) are errors that keep the status:
    /// the API answers with JSON only to say why there is no file, and a
    /// proxy or block page may come as `text/html` with no tags a body check
    /// would see. `data` may be only the start of a large download.
    static func downloadFailure(_ data: Data, response: URLResponse?, statusCode: Int) -> ZBError? {
        let type = (response?.mimeType ?? "").lowercased()
        let htmlType = isHtmlType(response)
        let jsonType = type == "application/json" || type == "text/json" || type.hasSuffix("+json")
        let message = self.message(from: data, statusCode: statusCode)
        if data.isEmpty || message.contains("HTML error page") || successMeansFailure(data)
            || looksLikeJsonObject(data) {
            return .httpError(message: message, statusCode: statusCode)
        }
        if htmlType {
            return .httpError(
                message: "ZeroBounce returned an HTML page (\(type)) instead of a file: \(message)",
                statusCode: statusCode
            )
        }
        if jsonType || looksLikeJson(data) {
            return .httpError(
                message: "ZeroBounce returned JSON instead of a file: \(message)",
                statusCode: statusCode
            )
        }
        return nil
    }

    /// Whether a response is sent as an HTML page (`text/html`,
    /// `application/xhtml+xml`).
    static func isHtmlType(_ response: URLResponse?) -> Bool {
        let type = (response?.mimeType ?? "").lowercased()
        return type == "text/html" || type == "application/xhtml+xml"
    }

    /// The error for a 2xx with a body sent as an HTML page, or nil. A proxy
    /// or block page is not an API answer even when its body would decode
    /// (`{"a":1}`), so the content type alone decides; the status is kept.
    static func htmlPageError(_ data: Data, response: URLResponse?, statusCode: Int) -> ZBError? {
        guard !data.isEmpty, isHtmlType(response) else { return nil }
        let type = (response?.mimeType ?? "").lowercased()
        let message = self.message(from: data, statusCode: statusCode)
        if message.contains("HTML error page") {
            return .httpError(message: message, statusCode: statusCode)
        }
        return .httpError(
            message: "ZeroBounce returned an HTML page (\(type)) instead of an API response.",
            statusCode: statusCode
        )
    }

    /// The error for a 2xx body that is not the call's answer: not JSON
    /// (plain text, CSV sent as `application/json`), or JSON of another
    /// shape. The API answered, so it is an API error with the HTTP status
    /// (standard §3), never `.decodeError`, which is left for arguments
    /// refused before sending.
    static func unreadableBody(_ data: Data, statusCode: Int) -> ZBError {
        let text = message(from: data, statusCode: statusCode)
        let isJson = (try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])) != nil
        if isJson || text.hasPrefix("ZeroBounce returned") || text.hasPrefix("Empty response") {
            return .httpError(message: text, statusCode: statusCode)
        }
        return .httpError(
            message: "ZeroBounce returned a response that is not valid JSON: \(text)",
            statusCode: statusCode
        )
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
                for key in ["message", "error_message", "error", "Message", "Error"] {
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
