//
//  ZeroBounceSDK.swift
//  Zero Bounce iOS SDK
//
//  Created by ZeroBounce on 08/07/2019.
//  Copyright © 2019 ZeroBounce. All rights reserved.
//

import Foundation

import UIKit

public class ZeroBounceSDK {
    
    static public let shared = ZeroBounceSDK()
    
    // Every base URL drops its trailing slashes when set: each path appended
    // to it starts with one, so "https://host/v2/" would build "/v2//validate".
    var bulkApiRootUrl = "https://bulkapi.zerobounce.net" {
        didSet { bulkApiRootUrl = ZeroBounceSDK.normalizedBaseUrl(bulkApiRootUrl) }
    }
    var bulkApiBaseUrl = "https://bulkapi.zerobounce.net/v2" {
        didSet { bulkApiBaseUrl = ZeroBounceSDK.normalizedBaseUrl(bulkApiBaseUrl) }
    }
    /// The bulk AI scoring endpoints are the bulk ones under `/scoring`, so
    /// this follows `bulkApiBaseUrl` rather than standing beside it as a
    /// second base that an override would silently miss.
    var bulkApiScoringBaseUrl: String { bulkApiBaseUrl + "/scoring" }
    /// The list evaluator and the Inbox Placement Tester have their own base
    /// URLs, not paths built from the bulk one. `initialize` alone leaves them
    /// pointing at the live API.
    var listEvaluatorBaseUrl = "https://bulkapi.zerobounce.net/v2/listevaluator" {
        didSet { listEvaluatorBaseUrl = ZeroBounceSDK.normalizedBaseUrl(listEvaluatorBaseUrl) }
    }
    var inboxPlacementBaseUrl = "https://bulkapi.zerobounce.net/api/ipt" {
        didSet { inboxPlacementBaseUrl = ZeroBounceSDK.normalizedBaseUrl(inboxPlacementBaseUrl) }
    }
    var apiKey: String?
    var apiBaseUrl = ZBApiURL.API_DEFAULT_URL.rawValue {
        didSet { apiBaseUrl = ZeroBounceSDK.normalizedBaseUrl(apiBaseUrl) }
    }
    let dateFormatter = DateFormatter()
    
    private lazy var priority3Api = Priority3Api(sdk: self)

    var normalizedApiKey: String? {
        guard let apiKey = apiKey, !apiKey.isEmpty else { return nil }
        return apiKey
    }

    public init() {
        dateFormatter.dateFormat = "yyyy-MM-dd"
    }
    
    /// Sets the API key. A key with surrounding whitespace or control
    /// characters is refused rather than stored: it would otherwise be quoted,
    /// unredacted, in a transport error.
    ///
    /// - returns: false when the key was refused. The client is then left
    ///   uninitialized, so every call reports `ZBError.notInitialized` instead
    ///   of going on with a key set earlier.
    @discardableResult
    public func initialize(
        apiKey: String,
        apiBaseUrl: ZBApiURL = .API_DEFAULT_URL
    ) -> Bool {
        guard ZeroBounceSDK.isCleanApiKey(apiKey) else {
            print("ZeroBounce: api_key has surrounding whitespace or control characters; it was not accepted.")
            self.apiKey = nil
            return false
        }
        self.apiKey = apiKey
        self.apiBaseUrl = apiBaseUrl.rawValue
        return true
    }

    /// The URL without trailing slashes or surrounding whitespace.
    internal static func normalizedBaseUrl(_ url: String) -> String {
        var value = url.trimmingCharacters(in: .whitespacesAndNewlines)
        while value.hasSuffix("/") { value.removeLast() }
        return value
    }

    /// Whether a key is free of surrounding whitespace and control characters.
    /// An empty key stays allowed: it is reported as `notInitialized` by the
    /// first call that needs it.
    internal static func isCleanApiKey(_ apiKey: String) -> Bool {
        if apiKey.isEmpty { return true }
        if apiKey != apiKey.trimmingCharacters(in: .whitespacesAndNewlines) { return false }
        return apiKey.unicodeScalars.allSatisfy { !CharacterSet.controlCharacters.contains($0) }
    }

    /// Refuses a URL that is not https, so the api_key is never put on the
    /// wire in the clear. Loopback is allowed so an offline test can point the
    /// SDK at a local stub.
    /// `error` with the API key replaced by "***" wherever its user info
    /// carries it. URLSession puts the request URL, `api_key` query parameter
    /// included, into every transport error (`NSErrorFailingURLKey`,
    /// `NSErrorFailingURLStringKey`, and again in the underlying error). The
    /// domain and code stay the same, so `error as? URLError` and checks such
    /// as `.code == .timedOut` keep working.
    ///
    /// A `ZBError` built from a response body is cleaned the same way: a
    /// server or proxy may quote the key back (`{"error":"Invalid API key
    /// <key>"}`, or a plain-text page quoting the request URL), so the
    /// message of `.httpError`, `.decodeError` and `.saveFileError` is
    /// redacted too, and the case and status stay the same.
    internal static func redactingApiKey(_ apiKey: String?, in error: Error) -> Error {
        redacting([apiKey].compactMap { $0 }, in: error)
    }

    /// The forms a secret can take in an error's text: as sent and
    /// JSON-escaped, and each of those percent-encoded (a query string or
    /// form body, loosely or strictly encoded, a space as `%20` or `+`), as
    /// a server echoing a URL-encoded JSON request would write it, and
    /// JSON-escaped twice (a JSON request quoted inside a JSON error).
    /// Longest first, so no form is cut in two by a shorter one.
    internal static func secretForms(_ secrets: [String]) -> [String] {
        var strict = CharacterSet.alphanumerics
        strict.insert(charactersIn: "-._~")
        var forms = Set<String>()
        for secret in secrets where !secret.isEmpty {
            let escaped = jsonEscapedForms(secret)
            for form in [secret] + escaped {
                forms.insert(form)
                forms.insert(form.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? form)
                let encoded = form.addingPercentEncoding(withAllowedCharacters: strict) ?? form
                forms.insert(encoded)
                forms.insert(encoded.replacingOccurrences(of: "%20", with: "+"))
            }
            for form in escaped {
                forms.formUnion(jsonEscapedForms(form))
            }
        }
        return forms.sorted { $0.count > $1.count }
    }

    /// `secret` as a JSON serializer may write it inside a string: `\` and
    /// `"` escaped, with or without `\/` for "/" (Foundation writes it), and
    /// also with `"`, `+`, `<`, `>`, `&`, `'`, `` ` `` and non-ASCII as
    /// `\uXXXX` (.NET's System.Text.Json and HTML-safe encoders), in either
    /// hex case.
    internal static func jsonEscapedForms(_ secret: String) -> Set<String> {
        func escaped(slash: Bool, htmlSafe: Bool, upper: Bool) -> String {
            let hex = upper ? "\\u%04X" : "\\u%04x"
            var out = ""
            for scalar in secret.unicodeScalars {
                switch scalar.value {
                case 0x5C: out += "\\\\"
                case 0x2F where slash: out += "\\/"
                case 0x08: out += "\\b"
                case 0x0C: out += "\\f"
                case 0x0A: out += "\\n"
                case 0x0D: out += "\\r"
                case 0x09: out += "\\t"
                case 0x22, 0x2B, 0x3C, 0x3E, 0x26, 0x27, 0x60:
                    if htmlSafe {
                        out += String(format: hex, scalar.value)
                    } else if scalar.value == 0x22 {
                        out += "\\\""
                    } else {
                        out.unicodeScalars.append(scalar)
                    }
                case ..<0x20:
                    out += String(format: hex, scalar.value)
                case 0x7F... where htmlSafe:
                    // Non-ASCII; beyond the BMP as a UTF-16 surrogate pair.
                    for unit in String(scalar).utf16 { out += String(format: hex, UInt32(unit)) }
                default:
                    out.unicodeScalars.append(scalar)
                }
            }
            return out
        }
        var forms = Set<String>()
        for slash in [false, true] {
            for htmlSafe in [false, true] {
                for upper in [false, true] {
                    forms.insert(escaped(slash: slash, htmlSafe: htmlSafe, upper: upper))
                }
            }
        }
        return forms
    }

    /// What an error says in place of text that still held a secret after
    /// masking.
    internal static let secretOmittedMessage = "The response body was omitted because it contained a credential."

    /// How many times `revealsSecret` decodes: the SDK's own request encoding
    /// plus three layers a server or proxy may add when it echoes the request
    /// back.
    internal static let secretDecodeLayers = 4

    /// `text` with every form of every secret replaced by "***". Redaction is
    /// closed under encoding: when a view of the result decoded up to
    /// `secretDecodeLayers` times (URL-decoding, "+" as a space,
    /// JSON-unescaping, in any order) still holds a secret, the whole text is
    /// replaced by `secretOmittedMessage`.
    internal static func redacting(_ secrets: [String], in text: String) -> String {
        let masked = secretForms(secrets).reduce(text) { $0.replacingOccurrences(of: $1, with: "***") }
        return revealsSecret(masked, secrets) ? secretOmittedMessage : masked
    }

    /// Whether a secret can be read in `text` or in any view of it decoded
    /// up to `secretDecodeLayers` times: URL-decoded, form-decoded ("+" as a space too) and
    /// JSON-unescaped (`\/` and `\uXXXX` included), in any order.
    internal static func revealsSecret(_ text: String, _ secrets: [String]) -> Bool {
        let needles = secrets.filter { !$0.isEmpty }.map { Array($0.utf8) }
        guard !needles.isEmpty else { return false }
        func search(_ bytes: [UInt8], _ layers: Int) -> Bool {
            if needles.contains(where: { containsBytes(bytes, $0) }) { return true }
            guard layers > 0, bytes.contains(where: { $0 == 0x25 || $0 == 0x2B || $0 == 0x5C }) else { return false }
            for view in [percentDecoded(bytes, plusAsSpace: false), percentDecoded(bytes, plusAsSpace: true),
                         jsonUnescaped(bytes)] where view != bytes {
                if search(view, layers - 1) { return true }
            }
            return false
        }
        return search(Array(text.utf8), secretDecodeLayers)
    }

    private static func containsBytes(_ haystack: [UInt8], _ needle: [UInt8]) -> Bool {
        guard !needle.isEmpty, haystack.count >= needle.count else { return false }
        var start = 0
        while start + needle.count <= haystack.count {
            if haystack[start] == needle[0] && Array(haystack[start..<start + needle.count]) == needle {
                return true
            }
            start += 1
        }
        return false
    }

    private static func hexValue(_ byte: UInt8) -> UInt8? {
        switch byte {
        case 0x30...0x39: return byte - 0x30
        case 0x41...0x46: return byte - 0x37
        case 0x61...0x66: return byte - 0x57
        default: return nil
        }
    }

    /// Each %XX as its byte, and "+" as a space when `plusAsSpace` is set.
    private static func percentDecoded(_ bytes: [UInt8], plusAsSpace: Bool) -> [UInt8] {
        var out: [UInt8] = []
        out.reserveCapacity(bytes.count)
        var i = 0
        while i < bytes.count {
            if bytes[i] == 0x25, i + 2 < bytes.count, let high = hexValue(bytes[i + 1]), let low = hexValue(bytes[i + 2]) {
                out.append(high << 4 | low)
                i += 3
            } else if plusAsSpace && bytes[i] == 0x2B {
                out.append(0x20)
                i += 1
            } else {
                out.append(bytes[i])
                i += 1
            }
        }
        return out
    }

    private static func hex4(_ bytes: [UInt8], _ at: Int) -> UInt32? {
        guard at + 4 <= bytes.count else { return nil }
        var value: UInt32 = 0
        for byte in bytes[at..<at + 4] {
            guard let digit = hexValue(byte) else { return nil }
            value = value << 4 | UInt32(digit)
        }
        return value
    }

    /// JSON string escapes undone; anything else is kept.
    private static func jsonUnescaped(_ bytes: [UInt8]) -> [UInt8] {
        let simple: [UInt8: UInt8] = [0x22: 0x22, 0x5C: 0x5C, 0x2F: 0x2F, 0x62: 0x08, 0x66: 0x0C,
                                      0x6E: 0x0A, 0x72: 0x0D, 0x74: 0x09]
        var out: [UInt8] = []
        out.reserveCapacity(bytes.count)
        var i = 0
        while i < bytes.count {
            guard bytes[i] == 0x5C, i + 1 < bytes.count else {
                out.append(bytes[i])
                i += 1
                continue
            }
            if let decoded = simple[bytes[i + 1]] {
                out.append(decoded)
                i += 2
                continue
            }
            guard bytes[i + 1] == 0x75, var code = hex4(bytes, i + 2) else {
                out.append(bytes[i])
                i += 1
                continue
            }
            i += 6
            if (0xD800...0xDBFF).contains(code), i + 1 < bytes.count, bytes[i] == 0x5C, bytes[i + 1] == 0x75,
               let low = hex4(bytes, i + 2), (0xDC00...0xDFFF).contains(low) {
                code = 0x10000 + ((code - 0xD800) << 10) + (low - 0xDC00)
                i += 6
            }
            if let scalar = Unicode.Scalar(code) {
                out.append(contentsOf: Array(String(Character(scalar)).utf8))
            } else {
                out.append(contentsOf: Array("\u{FFFD}".utf8))
            }
        }
        return out
    }

    /// `error` with every form of every secret replaced by "***", wherever
    /// its text or user info carries it. An error that carries none comes
    /// back as it was.
    internal static func redacting(_ secrets: [String], in error: Error) -> Error {
        let forms = secretForms(secrets)
        guard !forms.isEmpty else { return error }
        var changed = false
        func clean(_ text: String) -> String {
            var cleaned = forms.reduce(text) { $0.replacingOccurrences(of: $1, with: "***") }
            if revealsSecret(cleaned, secrets) {
                cleaned = secretOmittedMessage
            }
            if cleaned != text { changed = true }
            return cleaned
        }
        if let zbError = error as? ZBError {
            switch zbError {
            case .httpError(let message, let statusCode):
                return ZBError.httpError(message: clean(message), statusCode: statusCode)
            case .decodeError(let messages):
                return ZBError.decodeError(messages: messages.map(clean))
            case .saveFileError(let message):
                return ZBError.saveFileError(message: clean(message))
            default:
                return zbError
            }
        }
        func scrub(_ value: Any) -> Any {
            switch value {
            case let text as String:
                return clean(text)
            case let url as URL:
                let text = url.absoluteString
                let cleaned = clean(text)
                if cleaned == text { return url }
                return URL(string: cleaned) ?? cleaned
            case let nested as NSError:
                return redact(nested)
            case let list as [Any]:
                return list.map(scrub)
            default:
                return value
            }
        }
        func redact(_ error: NSError) -> NSError {
            NSError(domain: error.domain, code: error.code, userInfo: error.userInfo.mapValues(scrub))
        }
        let redacted = redact(error as NSError)
        guard changed else { return error }
        if redacted.domain == NSURLErrorDomain {
            return URLError(URLError.Code(rawValue: redacted.code), userInfo: redacted.userInfo)
        }
        return redacted
    }

    /// A transport error when fewer body bytes arrived than the response's
    /// Content-Length announced. URLSession checks this itself for some
    /// requests only: a PUT or DELETE whose 200 was cut short came back as
    /// complete, with the part that arrived. A body the session decoded
    /// (Content-Encoding) is not the length the header gave, so it is not
    /// compared.
    internal static func cutShortError(_ response: URLResponse?, received: Int64) -> URLError? {
        guard let http = response as? HTTPURLResponse, http.expectedContentLength >= 0,
              received < http.expectedContentLength else {
            return nil
        }
        let encoding = (http.value(forHTTPHeaderField: "Content-Encoding") ?? "")
            .trimmingCharacters(in: .whitespaces).lowercased()
        guard encoding.isEmpty || encoding == "identity" else { return nil }
        return URLError(.networkConnectionLost, userInfo: [
            NSLocalizedDescriptionKey: "The network connection was lost: the response ended after "
                + "\(received) of the \(http.expectedContentLength) bytes it announced."
        ])
    }

    internal static func isAllowedURL(_ url: URL) -> Bool {
        let scheme = url.scheme?.lowercased() ?? ""
        if scheme == "https" { return true }
        guard scheme == "http", let host = url.host?.lowercased() else { return false }
        return host == "127.0.0.1" || host == "localhost" || host == "::1"
    }
    
    // MARK: Validate
    ///
    /// - parameter email: The email address you want to validate
    /// - parameter ipAddress: The IP Address the email signed up from (Can be blank)
    ///
    public func validate(email: String, ipAddress: String? = nil, completion: @escaping (ZBResult<ZBValidateResponse>) -> ()) {
        validate(email: email, ipAddress: ipAddress, options: nil, completion: completion)
    }

    public func validate(
        email: String,
        ipAddress: String? = nil,
        options: ZBValidateOptions?,
        completion: @escaping (ZBResult<ZBValidateResponse>) -> ()
    ) {
        guard let apiKey = normalizedApiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }
        if let options = options, let timeout = options.timeout {
            if timeout < 3 || timeout > 60 {
                completion(ZBResult.Failure(ZBError.decodeError(messages: [
                    "Invalid parameter: timeout (must be between 3 and 60 seconds)"
                ])))
                return
            }
        }
        if let options = options, let callbackUrl = options.callbackUrl {
            if callbackUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                completion(ZBResult.Failure(ZBError.decodeError(messages: [
                    "Empty parameter: callback_url"
                ])))
                return
            }
            // The callback is where the greylist retry posts its result, so it
            // is meaningless — and rejected by the API — without the retry.
            if options.greylistProcessing != true {
                completion(ZBResult.Failure(ZBError.decodeError(messages: [
                    "Invalid parameter: callback_url requires greylist_processing to be true"
                ])))
                return
            }
        }

        let ipAddressPart = ipAddress != nil ? "\(ipAddress!)" : ""
        var items: [URLQueryItem] = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "email", value: email),
            URLQueryItem(name: "ip_address", value: ipAddressPart),
        ]
        if let options = options {
            if options.usePost {
                var fields: [String: String] = [
                    "api_key": apiKey,
                    "email": email,
                    "ip_address": ipAddressPart,
                ]
                if let timeout = options.timeout {
                    fields["timeout"] = String(timeout)
                }
                if let activityData = options.activityData {
                    fields["activity_data"] = activityData ? "true" : "false"
                }
                if let verifyPlus = options.verifyPlus {
                    fields["verify_plus"] = verifyPlus ? "true" : "false"
                }
                if let domainInfo = options.domainInfo {
                    fields["domain_info"] = domainInfo ? "true" : "false"
                }
                if let greylistProcessing = options.greylistProcessing {
                    fields["greylist_processing"] = greylistProcessing ? "true" : "false"
                }
                if let callbackUrl = options.callbackUrl {
                    fields["callback_url"] = callbackUrl
                }
                sendFormPostRequest(url: apiBaseUrl + "/validate", formFields: fields, completion: completion)
                return
            }
            if let timeout = options.timeout {
                items.append(URLQueryItem(name: "timeout", value: String(timeout)))
            }
            if let activityData = options.activityData {
                items.append(URLQueryItem(name: "activity_data", value: activityData ? "true" : "false"))
            }
            if let verifyPlus = options.verifyPlus {
                items.append(URLQueryItem(name: "verify_plus", value: verifyPlus ? "true" : "false"))
            }
            if let domainInfo = options.domainInfo {
                items.append(URLQueryItem(name: "domain_info", value: domainInfo ? "true" : "false"))
            }
            if let greylistProcessing = options.greylistProcessing {
                items.append(URLQueryItem(
                    name: "greylist_processing", value: greylistProcessing ? "true" : "false"
                ))
            }
            if let callbackUrl = options.callbackUrl {
                items.append(URLQueryItem(name: "callback_url", value: callbackUrl))
            }
        }
        sendJsonRequest(url: makeURL("/validate", queryItems: items), completion: completion)
    }
    
    // MARK: Validate Batch
    ///
    /// - parameter emails: List of email addresses you want to validate
    ///
    public func validateBatch(emails: [[String:String]], completion: @escaping (ZBResult<ZBValidateBatchResponse>) -> ()) {
        validateBatch(emails: emails, options: nil, completion: completion)
    }

    public func validateBatch(
        emails: [[String:String]],
        options: ZBValidateOptions?,
        completion: @escaping (ZBResult<ZBValidateBatchResponse>) -> ()
    ) {
        guard let apiKey = normalizedApiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }
        if let options = options, let timeout = options.timeout {
            if timeout < 10 || timeout > 120 {
                completion(ZBResult.Failure(ZBError.decodeError(messages: [
                    "Invalid parameter: timeout (must be between 10 and 120 seconds)"
                ])))
                return
            }
        }

        let emailBatch: [[String: Any]] = emails.map { item in
            var mapped: [String: Any] = [:]
            for (key, value) in item {
                if key == "ip_address" && value.isEmpty {
                    mapped[key] = NSNull()
                } else {
                    mapped[key] = value
                }
            }
            return mapped
        }
        var params: [String: Any] = [
            "api_key": apiKey,
            "email_batch": emailBatch
        ]
        if let options = options {
            if let timeout = options.timeout {
                // LIVE: validatebatch takes timeout as a JSON *string*. Sent as a
                // number the API rejects the whole batch with the account-level
                // "Invalid API Key or your account ran out of credits".
                params["timeout"] = String(timeout)
            }
            if let activityData = options.activityData {
                params["activity_data"] = activityData
            }
            if let verifyPlus = options.verifyPlus {
                params["verify_plus"] = verifyPlus
            }
        }

        let jsonDataParams = try? JSONSerialization.data(withJSONObject: params)
        // An "all" entry is an account-level error for the whole batch, such
        // as a dead key, reported with the HTTP status it came back with.
        sendPostJsonRequest(
            url: "\(apiBaseUrl)/validatebatch",
            params: jsonDataParams,
            inspect: { (response: ZBValidateBatchResponse, statusCode: Int) -> ZBError? in
                guard let account = response.errors.first(where: { $0.emailAddress == "all" }) else {
                    return nil
                }
                let text = account.error.isEmpty
                    ? "Invalid API Key or your account ran out of credits"
                    : account.error
                return ZBError.httpError(message: text, statusCode: statusCode)
            },
            completion: completion
        )
    }
    
    // MARK: Email Finder
    ///
    /// - parameter domain: The email domain for which to find the email format
    /// - parameter firstName: The first name of the person whose email format is being searched. Optional: a search by middle or last name alone is allowed, but at least one of the three names is needed.
    /// - parameter middleName: The middle name of the person whose email format is being searched
    /// - parameter lastName: The last name of the person whose email format is being searched
    ///
    public func findEmail(
        domain: String,
        firstName: String? = nil,
        middleName: String? = nil,
        lastName: String? = nil,
        completion: @escaping (ZBResult<ZBEmailFinderResponse>) -> ()
    ) {
        _findEmail(
            domain: domain,
            companyName: nil,
            firstName: firstName,
            middleName: middleName,
            lastName: lastName,
            completion: completion
        )
    }
    
    ///
    /// - parameter companyName: The company name for which to find the email format
    /// - parameter firstName: The first name of the person whose email format is being searched. Optional, as on the domain overload.
    /// - parameter middleName: The middle name of the person whose email format is being searched
    /// - parameter lastName: The last name of the person whose email format is being searched
    ///
    public func findEmail(
        companyName: String,
        firstName: String? = nil,
        middleName: String? = nil,
        lastName: String? = nil,
        completion: @escaping (ZBResult<ZBEmailFinderResponse>) -> ()
    ) {
        _findEmail(
            domain: nil,
            companyName: companyName,
            firstName: firstName,
            middleName: middleName,
            lastName: lastName,
            completion: completion
        )
    }
    
    private func _findEmail(
        domain: String?,
        companyName: String?,
        firstName: String?,
        middleName: String? = nil,
        lastName: String? = nil,
        completion: @escaping (ZBResult<ZBEmailFinderResponse>) -> ()
    ) {
        guard let apiKey = normalizedApiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }

        func present(_ value: String?) -> String? {
            guard let value = value,
                  !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
            return value
        }
        // first_name is optional, so a person can be looked up by middle or
        // last name alone. With no name at all /guessformat is the domain
        // search instead, which `findDomain` already covers, so that is
        // rejected here rather than quietly answering something else.
        let names = [present(firstName), present(middleName), present(lastName)]
        if names.allSatisfy({ $0 == nil }) {
            completion(ZBResult.Failure(ZBError.decodeError(messages: [
                "Empty parameter: first_name, middle_name or last_name is required (use findDomain for a domain search)"
            ])))
            return
        }

        var items: [URLQueryItem] = [URLQueryItem(name: "api_key", value: apiKey)]
        if let domain {
            items.append(URLQueryItem(name: "domain", value: domain))
        }
        if let companyName {
            items.append(URLQueryItem(name: "company_name", value: companyName))
        }
        if let firstName = names[0] {
            items.append(URLQueryItem(name: "first_name", value: firstName))
        }
        if let middleName = names[1] {
            items.append(URLQueryItem(name: "middle_name", value: middleName))
        }
        if let lastName = names[2] {
            items.append(URLQueryItem(name: "last_name", value: lastName))
        }
        sendJsonRequest(url: makeURL("/guessformat", queryItems: items), completion: completion)
    }
    
    // MARK: Domain Search
    ///
    /// - parameter domain: The email domain for which to find the email format
    ///
    public func findDomain(
        domain: String,
        completion: @escaping (ZBResult<ZBDomainSearchResponse>) -> ()
    ) {
        _findDomain(
            domain: domain,
            companyName: nil,
            completion: completion
        )
    }
    
    ///
    /// - parameter companyName: The company name for which to find the email format
    ///
    public func findDomain(
        companyName: String,
        completion: @escaping (ZBResult<ZBDomainSearchResponse>) -> ()
    ) {
        _findDomain(
            domain: nil,
            companyName: companyName,
            completion: completion
        )
    }
    
    private func _findDomain(
        domain: String?,
        companyName: String?,
        completion: @escaping (ZBResult<ZBDomainSearchResponse>) -> ()
    ) {
        guard let apiKey = normalizedApiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }
        
        var items: [URLQueryItem] = [URLQueryItem(name: "api_key", value: apiKey)]
        if let domain {
            items.append(URLQueryItem(name: "domain", value: domain))
        }
        if let companyName {
            items.append(URLQueryItem(name: "company_name", value: companyName))
        }
        sendJsonRequest(url: makeURL("/guessformat", queryItems: items), completion: completion)
    }
    
    @available(*, deprecated, message: "Use findEmail() for Email Finder API, or findDomain() for Domain Search API")
    public func guessFormat(
        domain: String,
        firstName: String? = nil,
        middleName: String? = nil,
        lastName: String? = nil,
        completion: @escaping (ZBResult<ZBEmailFinderResponse>) -> ()
    ) {
        guard let apiKey = normalizedApiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }
        
        var items: [URLQueryItem] = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "domain", value: domain),
        ]
        if let firstName {
            items.append(URLQueryItem(name: "first_name", value: firstName))
        }
        if let middleName {
            items.append(URLQueryItem(name: "middle_name", value: middleName))
        }
        if let lastName {
            items.append(URLQueryItem(name: "last_name", value: lastName))
        }
        sendJsonRequest(url: makeURL("/guessformat", queryItems: items), completion: completion)
    }
    
    // MARK: Get Credits
    ///
    /// This API will tell you how many credits you have left on your account. It's simple, fast and easy to use.
    ///
    public func getCredits(completion: @escaping (ZBResult<ZBCreditsResponse>) -> ()) {
        guard let apiKey = normalizedApiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }
        
        sendJsonRequest(url: makeURL("/getcredits", queryItems: [URLQueryItem(name: "api_key", value: apiKey)]), completion: completion)
    }
    
    // MARK: Get Api Usage
    ///
    /// - parameter startDate: The start date of when you want to view API usage
    /// - parameter endDate: The end date of when you want to view API usage
    ///
    public func getApiUsage(startDate: Date, endDate: Date, completion: @escaping (ZBResult<ZBGetApiUsageResponse>) -> ()) {
        guard let apiKey = normalizedApiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }
        
        let startString = self.dateFormatter.string(from: startDate)
        let endString = self.dateFormatter.string(from: endDate)
        
        sendJsonRequest(url: makeURL("/getapiusage", queryItems: [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "start_date", value: startString),
            URLQueryItem(name: "end_date", value: endString),
        ]), completion: completion)
    }
    
    // MARK: Activity Data
    ///
    /// - parameter email: The email inbox you want to check the activity data for
    ///
    public func getActivityData(email: String, completion: @escaping (ZBResult<ZBActivityDataResponse>) -> ()) {
        guard let apiKey = normalizedApiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }
        
        sendJsonRequest(url: makeURL("/activity", queryItems: [URLQueryItem(name: "api_key", value: apiKey), URLQueryItem(name: "email", value: email)]), completion: completion)
    }

    // MARK: Score Email
    ///
    /// Real-time AI scoring for a single email (GET /scoring).
    ///
    public func scoreEmail(email: String, completion: @escaping (ZBResult<ZBScoreEmailResponse>) -> ()) {
        guard let apiKey = normalizedApiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }

        sendJsonRequest(
            url: makeURL("/scoring", queryItems: [
                URLQueryItem(name: "api_key", value: apiKey),
                URLQueryItem(name: "email", value: email),
            ]),
            completion: completion
        )
    }

    ///
    /// Real-time AI scoring for a single email (POST /scoring, form-encoded).
    ///
    public func scoreEmailPost(email: String, completion: @escaping (ZBResult<ZBScoreEmailResponse>) -> ()) {
        guard let apiKey = normalizedApiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }

        sendFormPostRequest(
            url: apiBaseUrl + "/scoring",
            formFields: [
                "api_key": apiKey,
                "email": email,
            ],
            completion: completion
        )
    }

    // MARK: Priority 3 — bulk finder, list evaluator, filters, S3

    public func sendEmailFinderFile(
        filePath: String,
        domainColumn: Int,
        options: ZBEmailFinderSendFileOptions? = nil,
        completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()
    ) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.sendEmailFinderFile(filePath: filePath, domainColumn: domainColumn, options: options, completion: completion)
    }

    public func sendEmailFinderFileData(
        fileData: Data,
        fileName: String,
        domainColumn: Int,
        options: ZBEmailFinderSendFileOptions? = nil,
        completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()
    ) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.sendEmailFinderFileData(fileData: fileData, fileName: fileName, domainColumn: domainColumn, options: options, completion: completion)
    }

    public func emailFinderFileStatus(fileId: String, completion: @escaping (ZBResult<ZBFileStatusResponse>) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.bulkRootFileStatus(baseUrl: "\(bulkApiRootUrl)/email-finder", fileId: fileId, completion: completion)
    }

    public func emailFinderGetFile(fileId: String, downloadPath: String, completion: @escaping (ZBResult<ZBGetFileResponse>) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.bulkRootGetFile(baseUrl: "\(bulkApiRootUrl)/email-finder", fileId: fileId, downloadPath: downloadPath, completion: completion)
    }

    public func emailFinderDeleteFile(fileId: String, completion: @escaping (ZBResult<ZBDeleteFileResponse>) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.bulkRootDeleteFile(baseUrl: "\(bulkApiRootUrl)/email-finder", fileId: fileId, completion: completion)
    }

    public func sendDomainSearchFile(
        filePath: String,
        domainColumn: Int,
        options: ZBDomainSearchSendFileOptions? = nil,
        completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()
    ) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.sendDomainSearchFile(filePath: filePath, domainColumn: domainColumn, options: options, completion: completion)
    }

    public func sendDomainSearchFileData(
        fileData: Data,
        fileName: String,
        domainColumn: Int,
        options: ZBDomainSearchSendFileOptions? = nil,
        completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()
    ) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.sendDomainSearchFileData(fileData: fileData, fileName: fileName, domainColumn: domainColumn, options: options, completion: completion)
    }

    public func domainSearchFileStatus(fileId: String, completion: @escaping (ZBResult<ZBFileStatusResponse>) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.bulkRootFileStatus(baseUrl: "\(bulkApiRootUrl)/domain-search", fileId: fileId, completion: completion)
    }

    public func domainSearchGetFile(fileId: String, downloadPath: String, completion: @escaping (ZBResult<ZBGetFileResponse>) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.bulkRootGetFile(baseUrl: "\(bulkApiRootUrl)/domain-search", fileId: fileId, downloadPath: downloadPath, completion: completion)
    }

    public func domainSearchDeleteFile(fileId: String, completion: @escaping (ZBResult<ZBDeleteFileResponse>) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.bulkRootDeleteFile(baseUrl: "\(bulkApiRootUrl)/domain-search", fileId: fileId, completion: completion)
    }

    public func sendListEvaluatorFile(
        filePath: String,
        emailAddressColumn: Int,
        completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()
    ) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.sendListEvaluatorFile(filePath: filePath, emailAddressColumn: emailAddressColumn, completion: completion)
    }

    public func sendListEvaluatorFileData(
        fileData: Data,
        fileName: String,
        emailAddressColumn: Int,
        completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()
    ) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.sendListEvaluatorFileData(fileData: fileData, fileName: fileName, emailAddressColumn: emailAddressColumn, completion: completion)
    }

    public func getListEvaluatorResult(fileId: String, completion: @escaping (ZBDictionaryResult) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.getListEvaluatorResult(fileId: fileId, completion: completion)
    }

    /// Submits a list the list evaluator has finished for bulk validation.
    ///
    /// Takes the id of a finished evaluation, not a path to upload: that is
    /// what the live endpoint wants.
    public func sendEvaluatedFile(fileId: String, completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.sendEvaluatedFile(fileId: fileId, completion: completion)
    }

    public func addFilter(rule: String, target: String, value: String, completion: @escaping (ZBDictionaryResult) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.addFilter(rule: rule, target: target, value: value, completion: completion)
    }

    /// Lists the account's filters.
    ///
    /// The body is a JSON array, so this hands back `ZBJsonResult`: cast the
    /// success value to `[[String: Any]]`.
    public func listFilters(usePost: Bool = false, completion: @escaping (ZBJsonResult) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.listFilters(usePost: usePost, completion: completion)
    }

    public func deleteFilter(rule: String, target: String, value: String, completion: @escaping (ZBDictionaryResult) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.deleteFilter(rule: rule, target: target, value: value, completion: completion)
    }

    public func validateS3File(options: ZBValidateS3FileOptions, completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.validateS3File(options: options, completion: completion)
    }

    public func scoreS3File(options: ZBScoreS3FileOptions, completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.scoreS3File(options: options, completion: completion)
    }

    /// `export_bucket` is optional: pass nil to use the export bucket from
    /// your ZeroBounce settings.
    public func exportS3File(fileId: String, exportBucket: String?, completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.exportS3File(fileId: fileId, exportBucket: exportBucket, completion: completion)
    }

    // MARK: S3 email finder / domain search, SFTP/FTP bulk
    //
    // https://www.zerobounce.net/docs/api-integrations/amazon-s3-bulk-api
    // https://www.zerobounce.net/docs/api-integrations/sftp_bulk_api
    //
    // These live on the bulkapi host WITHOUT the /v2 path. The SFTP server,
    // path and protocol are never sent by the SDK; they come from your
    // ZeroBounce settings.

    public func emailFinderS3File(options: ZBBulkFileJobOptions, completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.emailFinderS3File(options: options, completion: completion)
    }

    public func domainSearchS3File(options: ZBBulkFileJobOptions, completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.domainSearchS3File(options: options, completion: completion)
    }

    /// `options.fileName` and `options.returnUrl` are both required, and a
    /// missing or blank one is rejected before a request is sent. The docs list
    /// this job's file_name as optional, but the live API rejects the call
    /// without it ("Empty parameter: file_name").
    public func validateSFTPFile(options: ZBBulkFileJobOptions, completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.validateSFTPFile(options: options, completion: completion)
    }

    public func scoreSFTPFile(options: ZBBulkFileJobOptions, completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.scoreSFTPFile(options: options, completion: completion)
    }

    public func emailFinderSFTPFile(options: ZBBulkFileJobOptions, completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.emailFinderSFTPFile(options: options, completion: completion)
    }

    public func domainSearchSFTPFile(options: ZBBulkFileJobOptions, completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.domainSearchSFTPFile(options: options, completion: completion)
    }

    /// Note the field name: this endpoint takes export_path, not the
    /// export_bucket that `exportS3File` sends. Pass nil to use the export path
    /// from your ZeroBounce settings.
    public func exportSFTPFile(fileId: String, exportPath: String?, completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.exportSFTPFile(fileId: fileId, exportPath: exportPath, completion: completion)
    }

    // MARK: Inbox Placement Tester
    //
    // Its own host, camelCase JSON bodies, and the key in an
    // Authorization: Bearer header rather than on the query string.
    // Spends the account's inbox-test credits. As everywhere else, a missing
    // or empty key is reported as `notInitialized` before anything is sent,
    // rather than going out as an empty "Bearer " header.

    public func getInboxPlacementProviders(completion: @escaping (ZBDictionaryResult) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.getInboxPlacementProviders(completion: completion)
    }

    public func getInboxPlacementTestTypes(completion: @escaping (ZBDictionaryResult) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.getInboxPlacementTestTypes(completion: completion)
    }

    public func createInboxPlacementTest(
        name: String,
        options: ZBCreateInboxPlacementTestOptions? = nil,
        completion: @escaping (ZBDictionaryResult) -> ()
    ) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.createInboxPlacementTest(name: name, options: options, completion: completion)
    }

    public func getInboxPlacementTest(testId: String, completion: @escaping (ZBDictionaryResult) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.getInboxPlacementTest(testId: testId, completion: completion)
    }

    public func listInboxPlacementTests(
        options: ZBListInboxPlacementTestsOptions? = nil,
        completion: @escaping (ZBDictionaryResult) -> ()
    ) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.listInboxPlacementTests(options: options, completion: completion)
    }

    public func deleteInboxPlacementTest(testId: String, completion: @escaping (ZBDictionaryResult) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.deleteInboxPlacementTest(testId: testId, completion: completion)
    }

    public func getInboxPlacementWebhook(completion: @escaping (ZBDictionaryResult) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.getInboxPlacementWebhook(completion: completion)
    }

    public func setInboxPlacementWebhook(webhookUrl: String, completion: @escaping (ZBDictionaryResult) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.setInboxPlacementWebhook(webhookUrl: webhookUrl, completion: completion)
    }

    /// Overrides the list evaluator base URL. It is a separate host rather than
    /// a path built from the bulk base, so `initialize` alone does not change it.
    public func setListEvaluatorBaseUrl(_ url: String) {
        listEvaluatorBaseUrl = url
    }

    /// Overrides the Inbox Placement Tester base URL. See `setListEvaluatorBaseUrl`.
    public func setInboxPlacementBaseUrl(_ url: String) {
        inboxPlacementBaseUrl = url
    }

    public func listS3files(bucket: String? = nil, search: String? = nil, completion: @escaping (ZBResult<[ZBS3ListFileEntry]>) -> ()) {
        guard normalizedApiKey != nil else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        priority3Api.listS3files(bucket: bucket, search: search, completion: completion)
    }
    
    // MARK: File Status
    ///
    /// - parameter fileId: The returned file ID when calling sendFile API.
    ///
    public func fileStatus(fileId: String, completion: @escaping (ZBResult<ZBFileStatusResponse>) -> ()) {
        _fileStatus(scoring: false, fileId: fileId, completion: completion)
    }
    
    ///
    /// - parameter fileId: The returned file ID when calling scoringSendFile API.
    ///
    public func scoringFileStatus(fileId: String, completion: @escaping (ZBResult<ZBFileStatusResponse>) -> ()) {
        _fileStatus(scoring: true, fileId: fileId, completion: completion)
    }
    
    private func _fileStatus(scoring: Bool, fileId: String, completion: @escaping (ZBResult<ZBFileStatusResponse>) -> ()) {
        guard let apiKey = normalizedApiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }
        
        sendJsonRequest(url: makeBulkURL(scoring: scoring, subpath: "/filestatus", queryItems: [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "file_id", value: fileId),
        ]), completion: completion)
    }
    
    // MARK: Delete File
    ///
    /// - parameter fileId: The returned file ID when calling sendfile API.
    ///
    public func deleteFile(fileId: String, completion: @escaping (ZBResult<ZBDeleteFileResponse>) -> ()) {
        _deleteFile(scoring: false, fileId: fileId, completion: completion)
    }
    
    ///
    /// - parameter fileId: The returned file ID when calling scoringSendfile API.
    ///
    public func scoringDeleteFile(fileId: String, completion: @escaping (ZBResult<ZBDeleteFileResponse>) -> ()) {
        _deleteFile(scoring: true, fileId: fileId, completion: completion)
    }
    
    private func _deleteFile(scoring: Bool, fileId: String, completion: @escaping (ZBResult<ZBDeleteFileResponse>) -> ()) {
        guard let apiKey = normalizedApiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }
        
        sendJsonRequest(url: makeBulkURL(scoring: scoring, subpath: "/deletefile", queryItems: [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "file_id", value: fileId),
        ]), completion: completion)
    }
    
    
    
    // MARK: Send File
    ///
    /// The sendfile API allows user to send a file for bulk email validation
    ///
    /// - parameter filePath: The path to a local file in String format
    /// - parameter emailAddressColumn: The column index of the email address in the file. Index starts from 1
    /// - parameter returnUrl: The URL will be used to call back when the validation is completed
    /// - parameter firstNameColumn: The column index of the first name column
    /// - parameter lastNameColumn: The column index of the last name column
    /// - parameter genderColumn: The column index of the gender column
    /// - parameter ipAddressColumn: The IP Address the email signed up from
    /// - parameter hasHeaderRow: If the first row from the submitted file is a header row. true or false
    /// - parameter allowPhase2: Validate catch-all emails in a second phase (Verify+). Not sent when nil
    /// - parameter removeDuplicate: Whether the API removes duplicate emails. Not sent when nil, and the API
    ///   then removes them (default true). When more than 50% of the rows are duplicates and this is true,
    ///   the API answers HTTP 400 instead of accepting the file. `scoringSendFile` takes it too.
    ///
    public func sendFile(
        filePath: String,
        emailAddressColumn: Int,
        returnUrl: String? = nil,
        firstNameColumn: Int? = nil,
        lastNameColumn: Int? = nil,
        genderColumn: Int? = nil,
        ipAddressColumn: Int? = nil,
        hasHeaderRow: Bool = false,
        allowPhase2: Bool? = nil,
        removeDuplicate: Bool? = nil,
        completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()
    ) {
        _sendFile(scoring: false, filePath: filePath, emailAddressColumn: emailAddressColumn,
                  returnUrl: returnUrl, firstNameColumn: firstNameColumn, lastNameColumn:lastNameColumn, genderColumn: genderColumn,
                  ipAddressColumn: ipAddressColumn, hasHeaderRow: hasHeaderRow, allowPhase2: allowPhase2,
                  removeDuplicate: removeDuplicate, completion: completion)
    }
    
    ///
    /// Send a file for bulk email validation from in-memory data (e.g. CSV built in memory).
    ///
    public func sendFile(
        fileData: Data,
        fileName: String,
        emailAddressColumn: Int,
        returnUrl: String? = nil,
        firstNameColumn: Int? = nil,
        lastNameColumn: Int? = nil,
        genderColumn: Int? = nil,
        ipAddressColumn: Int? = nil,
        hasHeaderRow: Bool = false,
        allowPhase2: Bool? = nil,
        removeDuplicate: Bool? = nil,
        completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()
    ) {
        _sendFileWithData(scoring: false, fileData: fileData, fileName: fileName, emailAddressColumn: emailAddressColumn,
                          returnUrl: returnUrl, firstNameColumn: firstNameColumn, lastNameColumn: lastNameColumn,
                          genderColumn: genderColumn, ipAddressColumn: ipAddressColumn, hasHeaderRow: hasHeaderRow,
                          allowPhase2: allowPhase2, removeDuplicate: removeDuplicate,
                          completion: completion)
    }
    
    ///
    /// The scoringSendfile API allows user to send a file for bulk email validation (AI Scoring)
    ///
    public func scoringSendFile(
        filePath: String,
        emailAddressColumn: Int,
        returnUrl: String? = nil,
        hasHeaderRow: Bool = false,
        removeDuplicate: Bool? = nil,
        completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()
    ) {
        
        _sendFile(scoring: true, filePath: filePath, emailAddressColumn: emailAddressColumn,
                  returnUrl: returnUrl, hasHeaderRow: hasHeaderRow, removeDuplicate: removeDuplicate,
                  completion: completion)
    }
    
    ///
    /// Send a file for bulk email scoring from in-memory data.
    ///
    public func scoringSendFile(
        fileData: Data,
        fileName: String,
        emailAddressColumn: Int,
        returnUrl: String? = nil,
        hasHeaderRow: Bool = false,
        removeDuplicate: Bool? = nil,
        completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()
    ) {
        _sendFileWithData(scoring: true, fileData: fileData, fileName: fileName, emailAddressColumn: emailAddressColumn,
                          returnUrl: returnUrl, hasHeaderRow: hasHeaderRow, removeDuplicate: removeDuplicate,
                          completion: completion)
    }
    
    private func _sendFile(
        scoring: Bool,
        filePath: String,
        emailAddressColumn: Int,
        returnUrl: String? = nil,
        firstNameColumn: Int? = nil,
        lastNameColumn: Int? = nil,
        genderColumn:Int? = nil,
        ipAddressColumn:Int? = nil,
        hasHeaderRow: Bool = false,
        allowPhase2: Bool? = nil,
        removeDuplicate: Bool? = nil,
        completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()
    ) {
        
        guard let apiKey = normalizedApiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }
        
        var parameters = [
            "api_key": apiKey,
            "email_address_column": emailAddressColumn,
            "has_header_row": hasHeaderRow,
        ] as [String : Any]
        
        if let returnUrl = returnUrl {
            parameters["return_url"] = returnUrl
        }
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
        if !scoring, let allowPhase2 = allowPhase2 {
            parameters["allow_phase_2"] = allowPhase2 ? "true" : "false"
        }
        // Left out when nil, and the API then removes duplicates (default true).
        if let removeDuplicate = removeDuplicate {
            parameters["remove_duplicate"] = removeDuplicate ? "true" : "false"
        }
        
        do {
            let r = try ZBMultiPartRequest.createFileRequest(
                url: scoring ? bulkApiScoringBaseUrl + "/sendfile" : bulkApiBaseUrl + "/sendfile",
                parameters: parameters,
                filePathKey: "file", paths: [filePath]
            )
            sendJsonRequest(request: r, completion: completion)
        } catch {
            completion(ZBResult.Failure(error))
        }
    }
    
    private func _sendFileWithData(
        scoring: Bool,
        fileData: Data,
        fileName: String,
        emailAddressColumn: Int,
        returnUrl: String? = nil,
        firstNameColumn: Int? = nil,
        lastNameColumn: Int? = nil,
        genderColumn: Int? = nil,
        ipAddressColumn: Int? = nil,
        hasHeaderRow: Bool = false,
        allowPhase2: Bool? = nil,
        removeDuplicate: Bool? = nil,
        completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()
    ) {
        guard let apiKey = normalizedApiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }
        
        var parameters = [
            "api_key": apiKey,
            "email_address_column": emailAddressColumn,
            "has_header_row": hasHeaderRow,
        ] as [String : Any]
        
        if let returnUrl = returnUrl {
            parameters["return_url"] = returnUrl
        }
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
        if !scoring, let allowPhase2 = allowPhase2 {
            parameters["allow_phase_2"] = allowPhase2 ? "true" : "false"
        }
        // Left out when nil, and the API then removes duplicates (default true).
        if let removeDuplicate = removeDuplicate {
            parameters["remove_duplicate"] = removeDuplicate ? "true" : "false"
        }
        
        do {
            let r = try ZBMultiPartRequest.createFileRequestWithData(
                url: scoring ? bulkApiScoringBaseUrl + "/sendfile" : bulkApiBaseUrl + "/sendfile",
                parameters: parameters,
                filePathKey: "file",
                fileData: fileData,
                fileName: fileName
            )
            sendJsonRequest(request: r, completion: completion)
        } catch {
            completion(ZBResult.Failure(error))
        }
    }
    
    
    // MARK: Get File
    ///
    /// The getfile API allows users to get the validation results file for the file been submitted using sendfile API
    ///
    /// - parameter fileId: The returned file ID when calling sendfile API
    ///
    public func getFile(fileId: String, completion: @escaping (ZBResult<ZBGetFileResponse>) -> ()) {
        _getFile(scoring: false, fileId: fileId, options: nil, completion: completion)
    }
    
    /// Validation bulk `getfile` with optional `download_type` and `activity_data`.
    public func getFile(fileId: String, options: ZBGetFileOptions, completion: @escaping (ZBResult<ZBGetFileResponse>) -> ()) {
        _getFile(scoring: false, fileId: fileId, options: options, completion: completion)
    }
    
    /// As `getFile`, but written straight to `downloadPath` as it arrives
    /// instead of being held in memory first — use it for a result file too
    /// large to buffer.
    ///
    /// It is opt-in because a streamed body cannot be inspected as a whole,
    /// and `getfile` answers an unknown or deleted file id with a JSON error
    /// rather than a file. The first bytes are checked before the download is
    /// moved into place, so an error still reaches the failure result and no
    /// partial file is left behind.
    public func getFileStreaming(
        fileId: String,
        downloadPath: String,
        options: ZBGetFileOptions? = nil,
        completion: @escaping (ZBResult<ZBGetFileResponse>) -> ()
    ) {
        _getFileStreaming(scoring: false, fileId: fileId, downloadPath: downloadPath,
                          options: options, completion: completion)
    }

    /// The AI scoring counterpart of `getFileStreaming`.
    public func scoringGetFileStreaming(
        fileId: String,
        downloadPath: String,
        options: ZBGetFileOptions? = nil,
        completion: @escaping (ZBResult<ZBGetFileResponse>) -> ()
    ) {
        _getFileStreaming(scoring: true, fileId: fileId, downloadPath: downloadPath,
                          options: options, completion: completion)
    }

    private func _getFileStreaming(
        scoring: Bool,
        fileId: String,
        downloadPath: String,
        options: ZBGetFileOptions?,
        completion: @escaping (ZBResult<ZBGetFileResponse>) -> ()
    ) {
        let completion = redacted(completion)
        guard let apiKey = normalizedApiKey else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        guard !downloadPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            completion(.Failure(ZBError.decodeError(messages: ["Empty parameter: downloadPath"])))
            return
        }
        guard let requestURL = buildGetFileURL(
            scoring: scoring, apiKey: apiKey, fileId: fileId, options: options
        ) else {
            completion(.Failure(ZBError.invalidEndpoint))
            return
        }
        guard ZeroBounceSDK.isAllowedURL(requestURL) else {
            completion(.Failure(ZBError.decodeError(messages: ["url must be an https:// URL"])))
            return
        }

        var request = URLRequest(url: requestURL)
        request.timeoutInterval = ZeroBounceSDK.requestTimeout
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        ZeroBounceSDK.urlSession.downloadTask(with: request) { location, response, error in
            if let error = error {
                completion(.Failure(ZeroBounceSDK.redactingApiKey(self.apiKey, in: error)))
                return
            }
            guard let location = location,
                  let statusCode = (response as? HTTPURLResponse)?.statusCode else {
                completion(.Failure(ZBError.noResponse))
                return
            }
            defer { try? FileManager.default.removeItem(at: location) }
            let size = (try? FileManager.default.attributesOfItem(atPath: location.path)[.size] as? NSNumber)?
                .int64Value ?? 0
            if let cut = ZeroBounceSDK.cutShortError(response, received: size) {
                completion(.Failure(cut))
                return
            }

            // Enough to tell a file from an error page, without reading the
            // whole download back into memory.
            let probe = (try? FileHandle(forReadingFrom: location))
                .map { handle -> Data in
                    defer { try? handle.close() }
                    return (try? handle.read(upToCount: 4096)) ?? Data()
                } ?? Data()

            if 300..<400 ~= statusCode {
                completion(.Failure(ZBError.httpError(
                    message: "ZeroBounce returned a redirect, which this client does not follow.",
                    statusCode: statusCode
                )))
                return
            }
            guard 200...299 ~= statusCode, !probe.isEmpty else {
                completion(.Failure(ZBError.httpError(
                    message: ZBError.message(from: probe, statusCode: statusCode),
                    statusCode: statusCode
                )))
                return
            }
            if let failure = ZBError.downloadFailure(probe, response: response, statusCode: statusCode) {
                completion(.Failure(failure))
                return
            }

            do {
                let outURL = URL(fileURLWithPath: downloadPath)
                try FileManager.default.createDirectory(
                    at: outURL.deletingLastPathComponent(), withIntermediateDirectories: true
                )
                // Never removes the old file first: it stays until the new
                // one is complete beside it.
                try ZBFileManager.replaceFile(at: outURL, withContentsOf: location)
                completion(.Success(ZBGetFileResponse(localFilePath: downloadPath)))
            } catch {
                completion(.Failure(ZBError.saveFileError(message: "\(error)")))
            }
        }.resume()
    }

    ///
    /// The scoringGetFile API allows users to get the validation results file for the file been submitted using scoringSendfile API
    ///
    public func scoringGetFile(fileId: String, completion: @escaping (ZBResult<ZBGetFileResponse>) -> ()) {
        _getFile(scoring: true, fileId: fileId, options: nil, completion: completion)
    }
    
    /// Scoring bulk `getfile` with optional `download_type` (`activityData` is ignored).
    public func scoringGetFile(fileId: String, options: ZBGetFileOptions, completion: @escaping (ZBResult<ZBGetFileResponse>) -> ()) {
        _getFile(scoring: true, fileId: fileId, options: options, completion: completion)
    }
    
    private func buildGetFileURL(scoring: Bool, apiKey: String, fileId: String, options: ZBGetFileOptions?) -> URL? {
        var comp = URLComponents(string: (scoring ? bulkApiScoringBaseUrl : bulkApiBaseUrl) + "/getfile")
        var items: [URLQueryItem] = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "file_id", value: fileId)
        ]
        if let options = options {
            if let dt = options.downloadType {
                items.append(URLQueryItem(name: "download_type", value: dt.queryValue))
            }
            if !scoring, let ad = options.activityData {
                items.append(URLQueryItem(name: "activity_data", value: ad ? "true" : "false"))
            }
        }
        comp?.queryItems = items
        return comp?.url
    }
    
    private func _getFile(scoring: Bool, fileId: String, options: ZBGetFileOptions?, completion: @escaping (ZBResult<ZBGetFileResponse>) -> ()) {
        let completion = redacted(completion)
        guard let apiKey = normalizedApiKey else {
            completion(ZBResult.Failure(ZBError.notInitialized))
            return
        }
        guard let requestURL = buildGetFileURL(scoring: scoring, apiKey: apiKey, fileId: fileId, options: options) else {
            completion(ZBResult.Failure(ZBError.invalidEndpoint))
            return
        }
        
        sendRequest(url: requestURL.absoluteString) { result in
            switch result {
            case .success(let response, let data):
                // getfile answers with the file or not at all. An HTML page
                // or JSON (by content type or by body) or an empty body is an
                // error that keeps the HTTP status.
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 200
                if let failure = ZBError.downloadFailure(data, response: response, statusCode: statusCode) {
                    completion(.Failure(failure))
                    return
                }
                
                let fileName = (response.suggestedFilename != nil) ? response.suggestedFilename! : "file_\(fileId).csv"
                guard let text = String(data: data, encoding: .utf8) else {
                    completion(.Failure(ZBError.noData))
                    return
                }
                
                print("Zero Bounce SDK getFile fileName=\(fileName)")
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
                
            case .failure(let error):
                completion(.Failure(error))
            }
        }
    }
    
    // MARK: Request handling
    public enum ZBResult<T: Codable> {
        case Success(T)
        case Failure(Error)
    }

    public enum ZBDictionaryResult {
        case Success([String: Any])
        case Failure(Error)
    }

    /// A parsed JSON body that may be an object or an array.
    ///
    /// LIVE: `/filters/list` answers with a JSON array — `[]` when no filters
    /// are set — so a dictionary-only result could never carry it.
    public enum ZBJsonResult {
        case Success(Any)
        case Failure(Error)
    }
    
    private func makeURL(_ path: String, queryItems: [URLQueryItem]) -> String {
        var components = URLComponents(string: apiBaseUrl + path)!
        components.queryItems = queryItems
        return components.url!.absoluteString
    }

    private func makeBulkURL(scoring: Bool, subpath: String, queryItems: [URLQueryItem]) -> String {
        let base = scoring ? bulkApiScoringBaseUrl : bulkApiBaseUrl
        var components = URLComponents(string: base + subpath)!
        components.queryItems = queryItems
        return components.url!.absoluteString
    }

    private func sendJsonRequest<T: Codable>(url: String, completion: @escaping (ZBResult<T>) -> ()) {
        guard let urlValue = URL(string: url) else {
            completion(.Failure(ZBError.invalidEndpoint))
            return
        }
        var r = URLRequest(url: urlValue)
        r.httpMethod = "GET"
        r.timeoutInterval = ZeroBounceSDK.requestTimeout
        sendJsonRequest(request: r, completion: completion)
    }
    
    private func sendPostJsonRequest<T: Codable>(
        url: String,
        params: Data?,
        inspect: ((T, Int) -> ZBError?)? = nil,
        completion: @escaping (ZBResult<T>) -> ()
    ) {
        var r = URLRequest(url: URL(string: url)!)
        r.httpMethod = "POST"
        r.timeoutInterval = ZeroBounceSDK.requestTimeout
        
        guard let data = params else { return }
        r.httpBody = data
        
        sendJsonRequest(request: r, inspect: inspect, completion: completion)
    }

    private func sendFormPostRequest<T: Codable>(
        url: String,
        formFields: [String: String],
        completion: @escaping (ZBResult<T>) -> ()
    ) {
        guard let urlValue = URL(string: url) else {
            completion(.Failure(ZBError.invalidEndpoint))
            return
        }
        var components = URLComponents()
        components.queryItems = formFields.map { URLQueryItem(name: $0.key, value: $0.value) }
        var request = URLRequest(url: urlValue)
        request.httpMethod = "POST"
        request.timeoutInterval = ZeroBounceSDK.requestTimeout
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = components.percentEncodedQuery?.data(using: .utf8)
        sendJsonRequest(request: request, completion: completion)
    }
    
    private enum RequestResult {
        case success(URLResponse, Data)
        case failure(Error)
    }
    
    /// - parameter inspect: a last check on the decoded value, for an error
    ///   that only the value shows (validatebatch's "all" entry). It gets the
    ///   HTTP status, so the error can carry it.
    private func sendJsonRequest<T: Codable>(
        request: URLRequest,
        inspect: ((T, Int) -> ZBError?)? = nil,
        completion: @escaping (ZBResult<T>) -> ()
    ) {
        let completion = redacted(completion)
        sendRequest(request: request) { result in
            switch result {
            case .success(let response, let data):
                let statusCode = ZeroBounceSDK.statusCode(of: response)
                // A model whose fields are all optional, such as
                // ZBGetApiUsageResponse, decodes {"error": "Invalid API key"}
                // as an empty result.
                if let failure = self.errorOnlyFailure(data, statusCode: statusCode) {
                    completion(.Failure(failure))
                    return
                }
                do {
                    // JSONDecoder is lenient (trailing commas, leading zeros,
                    // raw control characters), so the body is checked first.
                    guard ZBStrictJson.isStrict(data) else {
                        throw ZBError.decodeError(messages: ["not strict JSON"])
                    }
                    let value = try JSONDecoder().decode(T.self, from: data)
                    if let failure = inspect?(value, statusCode) {
                        completion(.Failure(failure))
                        return
                    }
                    completion(.Success(value))
                } catch {
                    // LIVE: a dead key answers the finder and the domain
                    // search with a bare {"Message": ...}, which carries its
                    // text. (Validate's greylist Message decodes, and stays a
                    // result.) Any other body that is not the call's answer -
                    // not JSON, or JSON of another shape - is an API error
                    // with the status too (standard §3).
                    completion(.Failure(ZBError.unreadableBody(data, statusCode: statusCode)))
                }
                
            case .failure (let error):
                completion(.Failure(error))
            }
        }
    }
    
    private func sendRequest(url:String, result: @escaping (RequestResult) -> ()) {
        guard let urlValue = URL(string: url) else {
            result(.failure(ZBError.invalidEndpoint))
            return
        }
        var request = URLRequest(url: urlValue)
        request.timeoutInterval = ZeroBounceSDK.requestTimeout
        sendRequest(request: request, result: result)
    }
    
    /// `allowEmptyBody` lets a 2xx with no body through as a success, for a
    /// DELETE; any other call that gets one has lost its answer.
    private func sendRequest(
        request:URLRequest,
        allowEmptyBody: Bool = false,
        result unredacted: @escaping (RequestResult) -> ()
    ) {
        let apiKey = self.apiKey
        let result = { (outcome: RequestResult) in
            if case .failure(let error) = outcome {
                unredacted(.failure(ZeroBounceSDK.redactingApiKey(apiKey, in: error)))
            } else {
                unredacted(outcome)
            }
        }
        guard let url = request.url, ZeroBounceSDK.isAllowedURL(url) else {
            result(RequestResult.failure(ZBError.decodeError(messages: ["url must be an https:// URL"])))
            return
        }
        ZeroBounceSDK.urlSession.dataTask(with: request, completionHandler: { data, response, error -> Void in
            if let error = error {
                result(RequestResult.failure(error))
                return
            }
            
            guard let response = response else {
                result(RequestResult.failure(ZBError.noResponse))
                return
            }
            if let cut = ZeroBounceSDK.cutShortError(response, received: Int64(data?.count ?? 0)) {
                result(RequestResult.failure(cut))
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
                result(RequestResult.failure(ZBError.noResponse))
                return
            }
            
            let body = data ?? Data()
            if 300..<400 ~= statusCode {
                // Redirects are not followed: one could send the api_key to
                // another host.
                result(RequestResult.failure(ZBError.httpError(
                    message: "ZeroBounce returned a redirect, which this client does not follow.",
                    statusCode: statusCode
                )))
                return
            }
            guard 200...299 ~= statusCode else {
                result(RequestResult.failure(ZBError.httpError(
                    message: ZBError.message(from: body, statusCode: statusCode),
                    statusCode: statusCode
                )))
                return
            }
            if let page = ZBError.htmlPageError(body, response: response, statusCode: statusCode) {
                result(RequestResult.failure(page))
                return
            }
            if (body.isEmpty && !allowEmptyBody)
                || ZBError.message(from: body, statusCode: statusCode).contains("HTML error page") {
                result(RequestResult.failure(ZBError.httpError(
                    message: ZBError.message(from: body, statusCode: statusCode),
                    statusCode: statusCode
                )))
                return
            }
            // LIVE: a "success": false field on an HTTP 200 is a failure, not
            // a result. getfile and deletefile report an unknown or deleted
            // file id that way, and the caller should not have to inspect a
            // flag to notice.
            if ZBError.successMeansFailure(body) {
                result(RequestResult.failure(ZBError.httpError(
                    message: ZBError.message(from: body, statusCode: statusCode),
                    statusCode: statusCode
                )))
                return
            }

            result(RequestResult.success(response, body))
        }).resume()
    }

    /// How long every request waits before timing out, in seconds. Set on
    /// each `URLRequest` the SDK builds, uploads and downloads included;
    /// `URLRequest`'s own default is 60.
    internal static let requestTimeout: TimeInterval = 120

    /// The session every request goes through, `ZeroBounceWarmup`'s included.
    /// Redirects are not followed: one could send the api_key to another host.
    /// Apps change it through `setSessionConfiguration(_:)`; the offline suite
    /// replaces it with a session whose configuration registers its stub
    /// protocol.
    internal static var urlSession: URLSession = ZeroBounceSDK.makeSession()

    private static let redirectBlocker = ZBRedirectBlocker()

    /// Builds every request from `configuration` instead of the default
    /// ephemeral one — for example to stub HTTP in your own tests by putting a
    /// `URLProtocol` subclass in its `protocolClasses`. Pass nil to go back to
    /// the default.
    ///
    /// Requests go through the SDK's own `URLSession`, not `URLSession.shared`,
    /// so a protocol registered globally with `URLProtocol.registerClass(_:)`
    /// does not see them; this is the supported way in. It applies to
    /// `ZeroBounceSDK` and `ZeroBounceWarmup` alike. Whatever the
    /// configuration, redirects are still refused and only https:// URLs
    /// (or loopback) are called.
    ///
    /// Call it before making requests, such as at launch or in a test's
    /// `setUp`. Requests already in flight finish on the previous session.
    public static func setSessionConfiguration(_ configuration: URLSessionConfiguration?) {
        let previous = urlSession
        urlSession = makeSession(configuration: configuration)
        previous.finishTasksAndInvalidate()
    }

    internal static func makeSession(
        configuration: URLSessionConfiguration? = nil,
        protocolClasses: [AnyClass]? = nil
    ) -> URLSession {
        let sessionConfiguration: URLSessionConfiguration
        if let configuration = configuration {
            // URLSession copies its configuration; copying here as well keeps
            // the protocolClasses below off the caller's object.
            sessionConfiguration = (configuration.copy() as? URLSessionConfiguration) ?? configuration
        } else {
            sessionConfiguration = URLSessionConfiguration.ephemeral
            sessionConfiguration.timeoutIntervalForRequest = requestTimeout
        }
        if let protocolClasses = protocolClasses {
            sessionConfiguration.protocolClasses = protocolClasses
        }
        return URLSession(configuration: sessionConfiguration, delegate: redirectBlocker, delegateQueue: nil)
    }

    /// Escapes a value as a single path segment, so a slash in it stays encoded.
    internal static func escapePathSegment(_ value: String) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }

    /// One request with an explicit method and an optional JSON body, for the
    /// Inbox Placement Tester's PUT and DELETE.
    internal func priority3JsonDictionaryRequest(
        method: String,
        url: String,
        body: [String: Any]?,
        extraHeaders: [String: String] = [:],
        completion: @escaping (ZBDictionaryResult) -> ()
    ) {
        let completion = redacted(completion)
        guard let urlValue = URL(string: url) else {
            completion(.Failure(ZBError.invalidEndpoint))
            return
        }
        var request = URLRequest(url: urlValue)
        request.httpMethod = method
        request.timeoutInterval = ZeroBounceSDK.requestTimeout
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        for (name, value) in extraHeaders {
            request.setValue(value, forHTTPHeaderField: name)
        }
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [.sortedKeys])
        }
        // A DELETE may answer a 2xx with no body. An empty answer to any other
        // method, or with any other status, is still an error.
        sendRequest(request: request, allowEmptyBody: method == "DELETE") { result in
            switch result {
            case .success(let response, let data):
                if data.isEmpty {
                    completion(.Success([:]))
                    return
                }
                if let failure = self.errorOnlyFailure(data, statusCode: ZeroBounceSDK.statusCode(of: response)) {
                    completion(.Failure(failure))
                    return
                }
                do {
                    let object = try ZBStrictJson.jsonObject(with: data, options: [])
                    if let dict = object as? [String: Any] {
                        completion(.Success(dict))
                    } else {
                        completion(.Failure(ZBError.unreadableBody(data, statusCode: ZeroBounceSDK.statusCode(of: response))))
                    }
                } catch {
                    completion(.Failure(ZBError.unreadableBody(data, statusCode: ZeroBounceSDK.statusCode(of: response))))
                }
            case .failure(let error):
                completion(.Failure(error))
            }
        }
    }

    internal func priority3QueryURL(base: String, query: [String: String]) -> String {
        var components = URLComponents(string: base)!
        components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        return components.url!.absoluteString
    }

    /// The failure for a body that is an error with no "success" field.
    /// LIVE: an invalid or drained key answers getapiusage with
    /// {"error": "Invalid API key"} and the filters with {"Error": ...} on an
    /// HTTP 200, which used to come back as their result. Reported as
    /// `.httpError` with that status, like every other error the API reports.
    private func errorOnlyFailure(_ data: Data, statusCode: Int) -> ZBError? {
        guard ZBError.errorOnlyBody(data) else { return nil }
        return .httpError(message: ZBError.message(from: data, statusCode: statusCode), statusCode: statusCode)
    }

    /// `completion` with the API key redacted from any error it is handed.
    /// Every request helper wraps the caller's completion this way before
    /// anything else, so an error built from a response body (a message the
    /// server quoted the key in) reaches the caller redacted, on every path.
    private func redacted<T>(_ completion: @escaping (ZBResult<T>) -> ()) -> (ZBResult<T>) -> () {
        let apiKey = self.apiKey
        return { result in
            if case .Failure(let error) = result {
                completion(.Failure(ZeroBounceSDK.redactingApiKey(apiKey, in: error)))
            } else {
                completion(result)
            }
        }
    }

    private func redacted(_ completion: @escaping (ZBDictionaryResult) -> ()) -> (ZBDictionaryResult) -> () {
        let apiKey = self.apiKey
        return { result in
            if case .Failure(let error) = result {
                completion(.Failure(ZeroBounceSDK.redactingApiKey(apiKey, in: error)))
            } else {
                completion(result)
            }
        }
    }

    private func redacted(_ completion: @escaping (ZBJsonResult) -> ()) -> (ZBJsonResult) -> () {
        let apiKey = self.apiKey
        return { result in
            if case .Failure(let error) = result {
                completion(.Failure(ZeroBounceSDK.redactingApiKey(apiKey, in: error)))
            } else {
                completion(result)
            }
        }
    }

    /// The HTTP status of a response that `sendRequest` passed on, so 2xx.
    private static func statusCode(of response: URLResponse) -> Int {
        (response as? HTTPURLResponse)?.statusCode ?? 200
    }

    internal func priority3SendJson<T: Codable>(url: String, completion: @escaping (ZBResult<T>) -> ()) {
        sendJsonRequest(url: url, completion: completion)
    }

    internal func priority3SendJsonRequest<T: Codable>(request: URLRequest, completion: @escaping (ZBResult<T>) -> ()) {
        sendJsonRequest(request: request, completion: completion)
    }

    internal func priority3FormPostSendFile(
        url: String,
        formFields: [String: String],
        completion: @escaping (ZBResult<ZBSendFileResponse>) -> ()
    ) {
        sendFormPostRequest(url: url, formFields: formFields, completion: completion)
    }

    /// As priority3SendDictionary, but keeps an array body instead of
    /// rejecting it.
    internal func priority3SendJson(url: String, completion: @escaping (ZBJsonResult) -> ()) {
        let completion = redacted(completion)
        sendRequest(url: url) { result in
            switch result {
            case .success(let response, let data):
                if let failure = self.errorOnlyFailure(data, statusCode: ZeroBounceSDK.statusCode(of: response)) {
                    completion(.Failure(failure))
                    return
                }
                do {
                    completion(.Success(try ZBStrictJson.jsonObject(with: data, options: [])))
                } catch {
                    completion(.Failure(ZBError.unreadableBody(data, statusCode: ZeroBounceSDK.statusCode(of: response))))
                }
            case .failure(let error):
                completion(.Failure(error))
            }
        }
    }

    internal func priority3FormPostJson(
        url: String,
        formFields: [String: String],
        completion: @escaping (ZBJsonResult) -> ()
    ) {
        priority3FormPostDictionary(url: url, formFields: formFields) { result in
            switch result {
            case .Success(let dict):
                completion(.Success(dict))
            case .Failure(let error):
                completion(.Failure(error))
            }
        }
    }

    internal func priority3SendDictionary(url: String, completion: @escaping (ZBDictionaryResult) -> ()) {
        let completion = redacted(completion)
        sendRequest(url: url) { result in
            switch result {
            case .success(let response, let data):
                if let failure = self.errorOnlyFailure(data, statusCode: ZeroBounceSDK.statusCode(of: response)) {
                    completion(.Failure(failure))
                    return
                }
                do {
                    let object = try ZBStrictJson.jsonObject(with: data, options: [])
                    if let dict = object as? [String: Any] {
                        completion(.Success(dict))
                    } else {
                        completion(.Failure(ZBError.unreadableBody(data, statusCode: ZeroBounceSDK.statusCode(of: response))))
                    }
                } catch {
                    completion(.Failure(ZBError.unreadableBody(data, statusCode: ZeroBounceSDK.statusCode(of: response))))
                }
            case .failure(let error):
                completion(.Failure(error))
            }
        }
    }

    internal func priority3FormPostDictionary(
        url: String,
        formFields: [String: String],
        completion: @escaping (ZBDictionaryResult) -> ()
    ) {
        let completion = redacted(completion)
        guard let urlValue = URL(string: url) else {
            completion(.Failure(ZBError.invalidEndpoint))
            return
        }
        var components = URLComponents()
        components.queryItems = formFields.map { URLQueryItem(name: $0.key, value: $0.value) }
        var request = URLRequest(url: urlValue)
        request.httpMethod = "POST"
        request.timeoutInterval = ZeroBounceSDK.requestTimeout
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = components.percentEncodedQuery?.data(using: .utf8)
        sendRequest(request: request) { result in
            switch result {
            case .success(let response, let data):
                if let failure = self.errorOnlyFailure(data, statusCode: ZeroBounceSDK.statusCode(of: response)) {
                    completion(.Failure(failure))
                    return
                }
                do {
                    let object = try ZBStrictJson.jsonObject(with: data, options: [])
                    if let dict = object as? [String: Any] {
                        completion(.Success(dict))
                    } else {
                        completion(.Failure(ZBError.unreadableBody(data, statusCode: ZeroBounceSDK.statusCode(of: response))))
                    }
                } catch {
                    completion(.Failure(ZBError.unreadableBody(data, statusCode: ZeroBounceSDK.statusCode(of: response))))
                }
            case .failure(let error):
                completion(.Failure(error))
            }
        }
    }

    internal func priority3Download(
        url: String,
        downloadPath: String,
        completion: @escaping (ZBResult<ZBGetFileResponse>) -> ()
    ) {
        let completion = redacted(completion)
        sendRequest(url: url) { result in
            switch result {
            case .success(let response, let data):
                // As getfile: JSON or an HTML page (by content type or by
                // body) is an error with the HTTP status.
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 200
                if let failure = ZBError.downloadFailure(data, response: response, statusCode: statusCode) {
                    completion(.Failure(failure))
                    return
                }
                do {
                    let outURL = URL(fileURLWithPath: downloadPath)
                    try FileManager.default.createDirectory(at: outURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                    try ZBFileManager.replaceFile(at: outURL, with: data)
                    completion(.Success(ZBGetFileResponse(localFilePath: downloadPath)))
                } catch {
                    completion(.Failure(error))
                }
            case .failure(let error):
                completion(.Failure(error))
            }
        }
    }
}

/// Hands the 3xx back to the caller instead of following it.
private final class ZBRedirectBlocker: NSObject, URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        completionHandler(nil)
    }
}

/// `dump`, `Mirror(reflecting:)` and debuggers show the client's settings
/// with the API key masked: the default reflection lists every stored
/// property, the key included.
extension ZeroBounceSDK: CustomReflectable {
    public var customMirror: Mirror {
        Mirror(self, children: [
            "apiKey": ZeroBounceSDK.maskedKey(apiKey),
            "apiBaseUrl": apiBaseUrl,
            "bulkApiRootUrl": bulkApiRootUrl,
            "bulkApiBaseUrl": bulkApiBaseUrl,
            "listEvaluatorBaseUrl": listEvaluatorBaseUrl,
            "inboxPlacementBaseUrl": inboxPlacementBaseUrl,
        ], displayStyle: .class)
    }

    /// "***" for a key that is set, "nil" otherwise.
    internal static func maskedKey(_ apiKey: String?) -> String {
        apiKey?.isEmpty == false ? "***" : "nil"
    }
}
