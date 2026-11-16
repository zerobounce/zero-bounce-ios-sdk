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
    /// "all" error, and a body that is not the call's answer: not JSON, a
    /// message-only object (on the calls that read one), or a file status
    /// body with none of its known fields.
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

    /// The value of a `success` field when it is a real flag, or nil: a JSON
    /// boolean, the number 0 or 1, or "true", "false", "0" or "1" in any case,
    /// trimmed. `null`, "", "maybe", a list, an object, 2 and 0.4 are not a
    /// flag, so they are neither a failure nor a result field.
    static func successFlag(_ value: Any?) -> Bool? {
        guard let value = value else { return nil }
        if let number = value as? NSNumber {
            if CFGetTypeID(number) == CFBooleanGetTypeID() { return number.boolValue }
            return successFlag(number: number.doubleValue)
        }
        if let text = value as? String { return successFlag(text: text) }
        return nil
    }

    /// A numeric `success`: 0 and 1 only.
    static func successFlag(number: Double) -> Bool? {
        if number == 0 { return false }
        if number == 1 { return true }
        return nil
    }

    /// A textual `success`: "true", "false", "0" or "1", any case, trimmed.
    static func successFlag(text: String) -> Bool? {
        switch text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "true", "1": return true
        case "false", "0": return false
        default: return nil
        }
    }

    /// Whether a JSON body says the call failed although the HTTP status was a
    /// success: its `success` is a real flag, and a false one (see
    /// `successFlag`).
    static func successMeansFailure(_ data: Data) -> Bool {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return false
        }
        return successFlag(object["success"]) == false
    }
    
    /// Whether a JSON body is an error with no real "success" flag to gate on:
    /// a non-empty "error", "error_message" or "Error" string. LIVE: an invalid
    /// or drained key answers validate, activity and getapiusage with
    /// {"error": ...}, and the filters with {"Error": ...}, on an HTTP 200.
    /// A `success` that is not a flag (null, "maybe", 2) does not gate.
    /// "message" and "Message" are not among the keys: successful responses
    /// use them too (a filter change answers with a bare "Message").
    static func errorOnlyBody(_ data: Data) -> Bool {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              successFlag(object["success"]) == nil else {
            return false
        }
        return ["error", "error_message", "Error"].contains { key in
            guard let text = object[key] as? String else { return false }
            return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    /// The keys of a message-only answer (standard section 3, E3).
    private static let messageOnlyKeys: Set<String> = ["error", "message", "error_message", "Message", "Error", "detail"]

    /// Whether a typed call's answer is read by `messageOnlyFailure`. The
    /// filters, Inbox Placement, the list evaluator and validate/credits are
    /// not: a bare "Message" is a successful filter change, and validate
    /// keeps its greylist Message.
    static func readsMessageOnly<T>(_ type: T.Type) -> Bool {
        type == ZBSendFileResponse.self || type == ZBDeleteFileResponse.self
            || type == ZBFileStatusResponse.self || type == ZBActivityDataResponse.self
            || type == ZBScoreEmailResponse.self || type == ZBValidateBatchResponse.self
            || type == ZBGetApiUsageResponse.self || type == ZBEmailFinderResponse.self
            || type == ZBDomainSearchResponse.self
    }

    /// The failure for an answer with no result in it, or nil: an object with
    /// no keys (a `success` that is not a real flag is no key), or one whose
    /// keys are message keys beside nothing but nulls. `{"domain": null}`
    /// with no message stays a result, and so does any non-null field or a
    /// real `success` flag. The text is the first non-blank message (a list
    /// is joined with a line feed), or a generic text when there is none.
    static func messageOnlyFailure(_ data: Data, statusCode: Int) -> ZBError? {
        guard var object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        if successFlag(object["success"]) == nil { object["success"] = nil }
        if !object.isEmpty {
            guard object.keys.contains(where: { messageOnlyKeys.contains($0) }),
                  object.allSatisfy({ messageOnlyKeys.contains($0.key) || $0.value is NSNull }) else {
                return nil
            }
        }
        var text = ""
        for key in messageKeyOrder where text.isEmpty {
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

    /// How many leading bytes of a download are padding: spaces, tabs, CR,
    /// LF, vertical tab, form feed, UTF-8 BOMs and U+00A0. There is no limit
    /// to it.
    static func paddingLength(_ data: Data) -> Int {
        data.withUnsafeBytes { raw -> Int in
            let bytes = raw.bindMemory(to: UInt8.self)
            var at = 0
            while at < bytes.count {
                let byte = bytes[at]
                if byte == 0x20 || (0x09...0x0D).contains(byte) {
                    at += 1
                } else if byte == 0xEF, at + 2 < bytes.count, bytes[at + 1] == 0xBB, bytes[at + 2] == 0xBF {
                    at += 3
                } else if byte == 0xC2, at + 1 < bytes.count, bytes[at + 1] == 0xA0 {
                    at += 2
                } else {
                    break
                }
            }
            return at
        }
    }

    /// Whether `data` is the start of a padding sequence cut short (a BOM or
    /// a U+00A0 at the end of a chunk): a longer read could make it padding.
    static func isPartialPadding(_ data: Data) -> Bool {
        let bytes = [UInt8](data)
        return bytes == [0xEF] || bytes == [0xEF, 0xBB] || bytes == [0xC2]
    }

    /// The body after its padding.
    private static func unpadded(_ data: Data) -> Data {
        data.dropFirst(paddingLength(data))
    }

    /// Whether a body is a JSON object, after its padding. A file download
    /// never is: getfile answers with JSON only to say why there is no file.
    static func looksLikeJsonObject(_ data: Data) -> Bool {
        unpadded(data).first == 0x7B
    }

    /// Whether a body is JSON rather than a file: an object, or an array
    /// that parses as JSON (a CSV line can start with "[" too).
    static func looksLikeJson(_ data: Data) -> Bool {
        let body = unpadded(data)
        if body.first == 0x7B { return true }
        return body.first == 0x5B && (try? JSONSerialization.jsonObject(with: body)) != nil
    }

    /// Whether the start of a body is an HTML page: a `<!doctype html`,
    /// `<html`, `<head` or `<body` tag in its first 2000 characters.
    static func looksLikeHtml(_ data: Data) -> Bool {
        let head = decodedBody(data.prefix(65536)).trimmingCharacters(in: .whitespacesAndNewlines)
        let prefix = String(head.prefix(2000)).lowercased()
        return prefix.contains("<!doctype html") || prefix.contains("<html")
            || prefix.contains("<head") || prefix.contains("<body")
    }

    /// A body as text: bytes that are not UTF-8 (or a character cut by the end
    /// of a probe) become U+FFFD rather than emptying the text, and a leading
    /// byte order mark is dropped.
    private static func decodedBody(_ data: Data) -> String {
        var text = String(decoding: data, as: UTF8.self)
        if text.unicodeScalars.first == "\u{FEFF}" { text.unicodeScalars.removeFirst() }
        return text
    }

    /// Why a 2xx answer to a file download is not the file, or nil when it
    /// is one. Padding (spaces, tabs, line breaks, BOMs, U+00A0) is skipped
    /// first, wherever it ends; a body of nothing else is empty. An empty
    /// body, an HTML page (by content type or by body) and JSON (by content
    /// type, an object, or an array that parses) are errors that keep the
    /// status: the API answers with JSON only to say why there is no file,
    /// and a proxy or block page may come as `text/html` with no tags a body
    /// check would see. `data` may be only the start of a large download.
    static func downloadFailure(_ data: Data, response: URLResponse?, statusCode: Int) -> ZBError? {
        let type = (response?.mimeType ?? "").lowercased()
        let htmlType = isHtmlType(response)
        let jsonType = type == "application/json" || type == "text/json" || type.hasSuffix("+json")
        let body = unpadded(data)
        if body.isEmpty {
            return .httpError(message: "Empty response from ZeroBounce (HTTP \(statusCode))", statusCode: statusCode)
        }
        if body.first == 0x7B || looksLikeHtml(body) {
            return .httpError(message: message(from: body, statusCode: statusCode), statusCode: statusCode)
        }
        if htmlType {
            return .httpError(
                message: "ZeroBounce returned an HTML page (\(type)) instead of a file: "
                    + message(from: body, statusCode: statusCode),
                statusCode: statusCode
            )
        }
        if jsonType || looksLikeJson(body) {
            return .httpError(
                message: "ZeroBounce returned JSON instead of a file: \(message(from: body, statusCode: statusCode))",
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
    /// (plain text, CSV sent as `application/json`), or JSON the typed model
    /// refuses. The only shapes refused on purpose are a message-only object
    /// (`messageOnlyFailure`) and a file status with no known field
    /// (`ZBFileStatusResponse`); other models read what they find. The API
    /// answered, so it is an API error with the HTTP status (standard §3),
    /// never `.decodeError`, which is left for arguments refused before
    /// sending.
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

    /// The message keys, in the order `messageOnlyFailure` and `message(from:)`
    /// read them.
    private static let messageKeyOrder = ["Message", "message", "error", "error_message", "Error", "detail"]

    /// How many bytes a streaming download's probe reads after its padding
    /// (`ZeroBounceSDK.downloadProbe`): 4096, or 1 MiB when the file starts
    /// with "[".
    private static let probeWindow = 4096
    private static let arrayProbeWindow = 1 << 20

    /// Whether `data` is as long as the probe reads, so a body that does not
    /// parse may only be the start of a longer one.
    private static func isFullProbeWindow(_ data: Data, startsWithArray: Bool) -> Bool {
        data.count >= (startsWithArray ? arrayProbeWindow : probeWindow)
    }

    static func message(from data: Data, statusCode: Int) -> String {
        let body = decodedBody(data)
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
                // The same order `messageOnlyFailure` reads.
                for key in messageKeyOrder {
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
            }
            // A JSON error too long to show, or the start of one cut short
            // by a streaming download's probe, which cannot be parsed. A
            // full probe window is cut short whatever its trimmed length is
            // (a window of padding after the brace trims to almost nothing).
            if trimmed.count > 1000 || isFullProbeWindow(data, startsWithArray: trimmed.hasPrefix("[")) {
                return "ZeroBounce returned a JSON error response that is too long to show."
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
