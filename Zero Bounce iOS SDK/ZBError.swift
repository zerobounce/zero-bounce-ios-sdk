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

    /// The keys of a message-only answer (standard section 3, E3).
    private static let messageOnlyKeys: Set<String> = ["error", "message", "error_message", "Message", "Error", "detail"]

    /// The failure for a message-only body on the email-finder and domain-search
    /// calls, or nil. Decided by the keys alone: an object with at least one key,
    /// every key a message key, and no "success", whatever the message is (text,
    /// blank, null, a list). The text is the first non-blank message (a list is
    /// joined with a line feed), or a generic text when there is none.
    static func messageOnlyFailure(_ data: Data, statusCode: Int) -> ZBError? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              !object.isEmpty, object["success"] == nil,
              object.keys.allSatisfy({ messageOnlyKeys.contains($0) }) else {
            return nil
        }
        var text = ""
        for key in ["Message", "message", "error", "error_message", "Error", "detail"] where text.isEmpty {
            if let value = object[key] as? String {
                text = stripErrorPrefix(value)
            } else if let lines = object[key] as? [String] {
                text = lines.map { stripErrorPrefix($0) }.filter { !$0.isEmpty }.joined(separator: "\n")
            }
        }
        if text.isEmpty {
            text = "ZeroBounce returned an error with no message text (HTTP \(statusCode))."
        }
        return .httpError(message: text, statusCode: statusCode)
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
        let isJson = ZBStrictJson.isStrict(data)
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

/// A strict RFC 8259 check of a response body. JSONSerialization and
/// JSONDecoder are lenient: they take trailing commas (`{"a":1,}`), leading
/// zeros (`01`), raw control characters in strings and unknown escapes
/// (`\x41`), so almost-JSON from a proxy would pass as the API's answer. Only
/// space, tab, CR and LF may surround the value.
internal struct ZBStrictJson {
    private let bytes: [UInt8]
    private var at = 0
    private static let maxDepth = 512

    private init(_ data: Data) {
        bytes = [UInt8](data)
    }

    /// Whether `data` is exactly one strict JSON value.
    static func isStrict(_ data: Data) -> Bool {
        var scan = ZBStrictJson(data)
        scan.whitespace()
        guard scan.value(depth: 0) else { return false }
        scan.whitespace()
        return scan.at == scan.bytes.count
    }

    /// `JSONSerialization.jsonObject(with:options:)` for a body that passed
    /// `isStrict`; anything else throws.
    static func jsonObject(with data: Data, options: JSONSerialization.ReadingOptions = []) throws -> Any {
        guard isStrict(data) else {
            throw ZBError.decodeError(messages: ["not strict JSON"])
        }
        return try JSONSerialization.jsonObject(with: data, options: options)
    }

    private var current: UInt8? { at < bytes.count ? bytes[at] : nil }

    private mutating func whitespace() {
        while let byte = current, byte == 0x20 || byte == 0x09 || byte == 0x0A || byte == 0x0D {
            at += 1
        }
    }

    private mutating func digits() -> Bool {
        guard let byte = current, (0x30...0x39).contains(byte) else { return false }
        while let byte = current, (0x30...0x39).contains(byte) { at += 1 }
        return true
    }

    private mutating func number() -> Bool {
        if current == 0x2D { at += 1 }  // -
        if current == 0x30 {
            at += 1
        } else if !digits() {
            return false
        }
        if current == 0x2E {  // .
            at += 1
            guard digits() else { return false }
        }
        if current == 0x65 || current == 0x45 {  // e E
            at += 1
            if current == 0x2B || current == 0x2D { at += 1 }
            guard digits() else { return false }
        }
        return true
    }

    private mutating func string() -> Bool {
        guard current == 0x22 else { return false }
        at += 1
        while let byte = current {
            at += 1
            switch byte {
            case 0x22:
                return true
            case 0x00..<0x20:
                return false
            case 0x5C:  // backslash
                guard let escape = current else { return false }
                at += 1
                if escape == 0x75 {  // u
                    for _ in 0..<4 {
                        guard let hex = current, (0x30...0x39).contains(hex) || (0x41...0x46).contains(hex)
                            || (0x61...0x66).contains(hex) else { return false }
                        at += 1
                    }
                } else if ![0x22, 0x5C, 0x2F, 0x62, 0x66, 0x6E, 0x72, 0x74].contains(escape) {
                    return false
                }
            default:
                break
            }
        }
        return false
    }

    private mutating func literal(_ word: String) -> Bool {
        let expected = Array(word.utf8)
        guard at + expected.count <= bytes.count, Array(bytes[at..<at + expected.count]) == expected else {
            return false
        }
        at += expected.count
        return true
    }

    private mutating func value(depth: Int) -> Bool {
        guard let byte = current, depth <= ZBStrictJson.maxDepth else { return false }
        switch byte {
        case 0x7B:  // {
            at += 1
            whitespace()
            if current == 0x7D { at += 1; return true }
            while true {
                guard string() else { return false }
                whitespace()
                guard current == 0x3A else { return false }
                at += 1
                whitespace()
                guard value(depth: depth + 1) else { return false }
                whitespace()
                if current == 0x2C { at += 1; whitespace(); continue }
                if current == 0x7D { at += 1; return true }
                return false
            }
        case 0x5B:  // [
            at += 1
            whitespace()
            if current == 0x5D { at += 1; return true }
            while true {
                whitespace()
                guard value(depth: depth + 1) else { return false }
                whitespace()
                if current == 0x2C { at += 1; continue }
                if current == 0x5D { at += 1; return true }
                return false
            }
        case 0x22:
            return string()
        case 0x74:
            return literal("true")
        case 0x66:
            return literal("false")
        case 0x6E:
            return literal("null")
        default:
            return number()
        }
    }
}
