//
//  ZeroBounceWarmup.swift
//  Zero Bounce iOS SDK
//
//  Client for the ZeroBounce Warmup API
//  (https://www.zerobounce.net/docs/warmup-api).
//
//  The Warmup API is a separate product from email validation: its own host,
//  its own team-scoped key, and an API-Key header instead of an api_key
//  parameter. Use `ZeroBounceWarmup` with a Warmup API key; `ZeroBounceSDK`
//  stays for the validation key, and the two never mix.
//

import Foundation

/// ZB managed onboarding only. A `nil` field is left out of the request.
public struct ZBWarmupEmailContent {
    public var companyName: String?
    public var companyWebsite: String?
    public var companyDescription: String?
    /// Any of `transactional`, `newsletter`, `marketing`.
    public var typesOfEmails: [String]?
    public var exampleEmail: String?

    public init(
        companyName: String? = nil,
        companyWebsite: String? = nil,
        companyDescription: String? = nil,
        typesOfEmails: [String]? = nil,
        exampleEmail: String? = nil
    ) {
        self.companyName = companyName
        self.companyWebsite = companyWebsite
        self.companyDescription = companyDescription
        self.typesOfEmails = typesOfEmails
        self.exampleEmail = exampleEmail
    }
}

/// ZB managed onboarding only, and write-only on the API.
public struct ZBWarmupManagedSending {
    public var weekdaysOnly: Bool?
    public var timezone: String?
    /// Sent as `timezone_offset`: hours from UTC, -11.0 to 14.0. Fractional
    /// offsets such as 5.5 or 5.75 are allowed.
    public var timezoneOffsetHours: Double?
    /// YYYY-MM-DD.
    public var warmupStartDate: String?

    /// The whole-hour form of `timezoneOffsetHours`, kept for 3.x code. It
    /// reads `nil` when the offset is fractional.
    @available(*, deprecated, renamed: "timezoneOffsetHours",
               message: "timezone_offset accepts fractional hours; use timezoneOffsetHours")
    public var timezoneOffset: Int? {
        get { timezoneOffsetHours.flatMap { Int(exactly: $0) } }
        set { timezoneOffsetHours = newValue.map(Double.init) }
    }

    public init(
        weekdaysOnly: Bool? = nil,
        timezone: String? = nil,
        timezoneOffsetHours: Double? = nil,
        warmupStartDate: String? = nil
    ) {
        self.weekdaysOnly = weekdaysOnly
        self.timezone = timezone
        self.timezoneOffsetHours = timezoneOffsetHours
        self.warmupStartDate = warmupStartDate
    }

    /// The 3.x initializer, with a whole-hour offset.
    @available(*, deprecated, renamed: "init(weekdaysOnly:timezone:timezoneOffsetHours:warmupStartDate:)",
               message: "timezone_offset accepts fractional hours; use timezoneOffsetHours")
    public init(
        weekdaysOnly: Bool? = nil,
        timezone: String? = nil,
        timezoneOffset: Int?,
        warmupStartDate: String? = nil
    ) {
        self.init(weekdaysOnly: weekdaysOnly, timezone: timezone,
                  timezoneOffsetHours: timezoneOffset.map(Double.init),
                  warmupStartDate: warmupStartDate)
    }
}

public struct ZBWarmupAddSendingAccountOptions {
    /// Required for `self_managed` (0 to 4), ignored for `zb_managed`.
    public var engagementRuleId: Int?
    /// Self-managed only: do not fail with 409 when the address is already
    /// registered.
    public var ignoreConflict: Bool?
    /// ZB managed only.
    public var emailContent: ZBWarmupEmailContent?
    /// ZB managed only.
    public var managedSending: ZBWarmupManagedSending?

    public init(
        engagementRuleId: Int? = nil,
        ignoreConflict: Bool? = nil,
        emailContent: ZBWarmupEmailContent? = nil,
        managedSending: ZBWarmupManagedSending? = nil
    ) {
        self.engagementRuleId = engagementRuleId
        self.ignoreConflict = ignoreConflict
        self.emailContent = emailContent
        self.managedSending = managedSending
    }
}

public struct ZBWarmupListFromAddressesOptions {
    /// Letters, digits and `. - _ @ +` only.
    public var searchFrom: String?
    /// The API defaults to 0.
    public var offset: Int?
    /// The API defaults to 100.
    public var limit: Int?

    public init(searchFrom: String? = nil, offset: Int? = nil, limit: Int? = nil) {
        self.searchFrom = searchFrom
        self.offset = offset
        self.limit = limit
    }
}

public class ZeroBounceWarmup {

    /// Onboarding models accepted by `addSendingAccount`.
    public static let selfManaged = "self_managed"
    public static let zbManaged = "zb_managed"

    /// team_id is required by the schema but always replaced with the key's
    /// team, so any value does.
    private static let anyTeamId = 1
    private static let basePath = "/api/v1/warmup"

    public static let shared = ZeroBounceWarmup()

    /// The parsed JSON body: a dictionary, an array, or a number, depending on
    /// the endpoint. `nil` for the documented empty successes, which are an
    /// HTTP 204 and an empty 200.
    public enum ZBWarmupResult {
        case Success(Any?)
        case Failure(Error)
    }

    /// CSV text, for the two download endpoints.
    public enum ZBWarmupCsvResult {
        case Success(String)
        case Failure(Error)
    }

    internal var apiKey: String?
    /// The base URL ZeroBounce gave you. Tests point this at a local stub.
    /// Trailing slashes are dropped when it is set.
    public var baseUrl = "https://warmup-api.zerobounce.net" {
        didSet { baseUrl = ZeroBounceSDK.normalizedBaseUrl(baseUrl) }
    }

    public init() {}

    /// Sets the Warmup API key. It is sent in an `API-Key` header, and it is
    /// not the validation key.
    ///
    /// A key with surrounding whitespace or control characters is refused
    /// rather than stored: it would otherwise be quoted, unredacted, in a
    /// transport error.
    ///
    /// - returns: false when the key was refused. The client is then left
    ///   uninitialized, so every call fails with "not initialized" instead of
    ///   going on with a key set earlier.
    @discardableResult
    public func initialize(apiKey: String) -> Bool {
        guard ZeroBounceSDK.isCleanApiKey(apiKey) else {
            print("ZeroBounce: the Warmup api_key has surrounding whitespace or control characters; it was not accepted.")
            self.apiKey = nil
            return false
        }
        self.apiKey = apiKey
        return true
    }

    // MARK: Sending accounts

    /// Every sending account of the key's team. An empty team answers an empty
    /// list, not a 404.
    public func listSendingAccounts(completion: @escaping (ZBWarmupResult) -> ()) {
        send(method: "GET", path: "/sending-accounts", completion: completion)
    }

    public func getSendingAccount(fromAddress: String, completion: @escaping (ZBWarmupResult) -> ()) {
        guard let value = required(fromAddress, "from_address", completion) else { return }
        send(method: "GET", path: "/sending-account",
             query: [URLQueryItem(name: "from_address", value: value)], completion: completion)
    }

    /// Adds a from-address to warmup.
    ///
    /// For a ZB managed account a 200 means accepted; the mailbox is
    /// provisioned afterwards.
    public func addSendingAccount(
        fromAddress: String,
        onboardingModel: String,
        options: ZBWarmupAddSendingAccountOptions? = nil,
        completion: @escaping (ZBWarmupResult) -> ()
    ) {
        guard let address = required(fromAddress, "from_address", completion) else { return }
        guard onboardingModel == ZeroBounceWarmup.selfManaged
                || onboardingModel == ZeroBounceWarmup.zbManaged else {
            completion(.Failure(ZBError.decodeError(messages: [
                "Invalid parameter: onboarding_model (must be self_managed or zb_managed)"
            ])))
            return
        }

        var body: [String: Any] = [
            "from_address": address,
            "onboarding_model": onboardingModel
        ]

        if onboardingModel == ZeroBounceWarmup.selfManaged {
            guard let ruleId = options?.engagementRuleId else {
                completion(.Failure(ZBError.decodeError(messages: [
                    "Empty parameter: engagement_rule_id (required for self_managed)"
                ])))
                return
            }
            guard inRange(ruleId, 0, 4, "engagement_rule_id", completion) else { return }
            body["engagement_rule_id"] = ruleId
            if options?.emailContent != nil || options?.managedSending != nil {
                completion(.Failure(ZBError.decodeError(messages: [
                    "Invalid parameter: email_content and managed_sending are for zb_managed"
                ])))
                return
            }
        }

        if let ignoreConflict = options?.ignoreConflict {
            body["ignore_conflict"] = ignoreConflict
        }

        if let content = options?.emailContent {
            var node: [String: Any] = [:]
            if let value = content.companyName { node["company_name"] = value }
            if let value = content.companyWebsite { node["company_website"] = value }
            if let value = content.companyDescription { node["company_description"] = value }
            if let types = content.typesOfEmails {
                let allowed = ["transactional", "newsletter", "marketing"]
                guard types.allSatisfy({ allowed.contains($0.lowercased()) }) else {
                    completion(.Failure(ZBError.decodeError(messages: [
                        "Invalid parameter: types_of_emails (transactional, newsletter and/or marketing)"
                    ])))
                    return
                }
                node["types_of_emails"] = types.map { $0.lowercased() }
            }
            if let value = content.exampleEmail { node["example_email"] = value }
            body["email_content"] = node
        }

        if let sending = options?.managedSending {
            var node: [String: Any] = [:]
            if let value = sending.weekdaysOnly { node["weekdays_only"] = value }
            if let value = sending.timezone { node["timezone"] = value }
            if let offset = sending.timezoneOffsetHours {
                guard offset.isFinite, offset >= -11, offset <= 14 else {
                    completion(.Failure(ZBError.decodeError(messages: [
                        "Invalid parameter: timezone_offset (must be -11.0 to 14.0)"
                    ])))
                    return
                }
                // A whole number goes out as an integer (3, not 3.0).
                if let hours = Int(exactly: offset) {
                    node["timezone_offset"] = hours
                } else {
                    node["timezone_offset"] = offset
                }
            }
            if let date = sending.warmupStartDate {
                guard isoDate(date, "warmup_start_date", completion) else { return }
                node["warmup_start_date"] = date
            }
            body["managed_sending"] = node
        }

        send(method: "POST", path: "/sending-accounts", body: body, completion: completion)
    }

    /// Changes an account's engagement rule, status and auto-enable flag.
    ///
    /// `statusId` is 0 to 8 (4 Paused, 5 Disabled). `autoEnable` is accepted
    /// only for an account that is not active.
    public func updateSendingAccount(
        fromAddress: String,
        engagementRuleId: Int,
        statusId: Int,
        autoEnable: Bool,
        completion: @escaping (ZBWarmupResult) -> ()
    ) {
        guard let address = required(fromAddress, "from_address", completion),
              inRange(engagementRuleId, 0, 4, "engagement_rule_id", completion),
              inRange(statusId, 0, 8, "status_id", completion) else { return }
        send(method: "PUT", path: "/sending-accounts", body: [
            "team_id": ZeroBounceWarmup.anyTeamId,
            "from_address": address,
            "engagement_rule_id": engagementRuleId,
            "status_id": statusId,
            "auto_enable": autoEnable
        ], completion: completion)
    }

    /// Removes a sending account. Destructive and cannot be undone.
    public func deleteSendingAccount(fromAddress: String, completion: @escaping (ZBWarmupResult) -> ()) {
        guard let value = required(fromAddress, "from_address", completion) else { return }
        send(method: "DELETE", path: "/sending-accounts",
             query: [URLQueryItem(name: "from_address", value: value)], completion: completion)
    }

    /// Moves an account and its history to a new from-address. Despite the
    /// path it uses, nothing about SMTP credentials is stored.
    public func changeFromAddress(
        oldFromAddress: String,
        newFromAddress: String,
        completion: @escaping (ZBWarmupResult) -> ()
    ) {
        guard let old = required(oldFromAddress, "old_from_address", completion),
              let new = required(newFromAddress, "new_from_address", completion) else { return }
        send(method: "PUT", path: "/smtp-credentials", body: [
            "team_id": ZeroBounceWarmup.anyTeamId,
            "old_from_address": old,
            "new_from_address": new
        ], completion: completion)
    }

    public func listFromAddresses(
        options: ZBWarmupListFromAddressesOptions? = nil,
        completion: @escaping (ZBWarmupResult) -> ()
    ) {
        var query: [URLQueryItem] = []
        if let search = options?.searchFrom {
            let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: ".-_@+"))
            guard search.unicodeScalars.allSatisfy({ allowed.contains($0) }) else {
                completion(.Failure(ZBError.decodeError(messages: [
                    "Invalid parameter: search_from (letters, digits and . - _ @ + only)"
                ])))
                return
            }
            query.append(URLQueryItem(name: "search_from", value: search))
        }
        if let offset = options?.offset {
            guard inRange(offset, 0, Int.max, "offset", completion) else { return }
            query.append(URLQueryItem(name: "offset", value: String(offset)))
        }
        if let limit = options?.limit {
            guard inRange(limit, 0, Int.max, "limit", completion) else { return }
            query.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        send(method: "GET", path: "/from-addresses", query: query, completion: completion)
    }

    // MARK: Engagement rules

    /// The rule catalogue: -1 Custom, 0 Default, 1 Slow Pace, 2 Repair,
    /// 3 Boost, 4 Protect.
    public func getEngagementRules(completion: @escaping (ZBWarmupResult) -> ()) {
        send(method: "GET", path: "/engagement-rules", completion: completion)
    }

    /// Sets a standard rule (0 to 4) on an address.
    public func setEngagementRule(cFrom: String, ruleId: Int, completion: @escaping (ZBWarmupResult) -> ()) {
        guard let value = required(cFrom, "c_from", completion),
              inRange(ruleId, 0, 4, "rule_id", completion) else { return }
        send(method: "PUT", path: "/engagement-rule",
             query: [URLQueryItem(name: "c_from", value: value)],
             body: ["rule_id": ruleId], completion: completion)
    }

    public func getCustomEngagement(cFrom: String, completion: @escaping (ZBWarmupResult) -> ()) {
        guard let value = required(cFrom, "c_from", completion) else { return }
        // c_from is one path segment here, so a slash must stay encoded, and
        // a "." or ".." would walk the request out of the endpoint.
        guard value != "." && value != ".." else {
            completion(.Failure(ZBError.decodeError(messages: ["Invalid parameter: c_from"])))
            return
        }
        send(method: "GET", path: "/custom-engagement/\(ZeroBounceSDK.escapePathSegment(value))",
             completion: completion)
    }

    /// Creates a custom rule. Starts a 7 day cooldown on updates.
    public func createCustomEngagement(
        cFrom: String,
        replyPct: Int,
        importantPct: Int,
        clickPct: Int,
        completion: @escaping (ZBWarmupResult) -> ()
    ) {
        guard let body = engagementBody(cFrom, replyPct, importantPct, clickPct, completion) else { return }
        send(method: "POST", path: "/custom-engagement", body: body, completion: completion)
    }

    /// Updates a custom rule. During the 7 day cooldown this fails with
    /// HTTP 429.
    public func updateCustomEngagement(
        cFrom: String,
        replyPct: Int,
        importantPct: Int,
        clickPct: Int,
        completion: @escaping (ZBWarmupResult) -> ()
    ) {
        guard let body = engagementBody(cFrom, replyPct, importantPct, clickPct, completion) else { return }
        send(method: "PUT", path: "/custom-engagement", body: body, completion: completion)
    }

    /// Deletes a custom rule, falling back to standard rule
    /// `engagementRuleId` (1 to 4).
    public func deleteCustomEngagement(
        cFrom: String,
        engagementRuleId: Int,
        completion: @escaping (ZBWarmupResult) -> ()
    ) {
        guard let value = required(cFrom, "c_from", completion),
              inRange(engagementRuleId, 1, 4, "engagement_rule_id", completion) else { return }
        send(method: "DELETE", path: "/custom-engagement",
             body: ["c_from": value, "engagement_rule_id": engagementRuleId], completion: completion)
    }

    // MARK: Seeds, progress and statistics

    public func getSeeds(completion: @escaping (ZBWarmupResult) -> ()) {
        send(method: "GET", path: "/seeds", completion: completion)
    }

    /// The seed list as CSV (columns `seed,provider`).
    public func downloadSeeds(completion: @escaping (ZBWarmupCsvResult) -> ()) {
        sendCsv(path: "/seeds/download", query: [], completion: completion)
    }

    /// The number of seeds. Answers a bare number, not an object.
    public func getSeedCount(completion: @escaping (ZBWarmupResult) -> ()) {
        send(method: "GET", path: "/seed-count", completion: completion)
    }

    public func getProgressToday(completion: @escaping (ZBWarmupResult) -> ()) {
        send(method: "GET", path: "/progress-today", completion: completion)
    }

    public func getSentToday(completion: @escaping (ZBWarmupResult) -> ()) {
        send(method: "GET", path: "/sent-today", completion: completion)
    }

    public func getEmailsPerDay(completion: @escaping (ZBWarmupResult) -> ()) {
        send(method: "GET", path: "/emails-per-day", completion: completion)
    }

    /// Statistics for an address. An address with no history answers zeros.
    public func getStatistics(fromAddress: String, completion: @escaping (ZBWarmupResult) -> ()) {
        guard let value = required(fromAddress, "from_address", completion) else { return }
        send(method: "GET", path: "/statistics",
             query: [URLQueryItem(name: "from_address", value: value)], completion: completion)
    }

    /// Daily statistics between two YYYY-MM-DD dates, inclusive.
    public func getStatisticsPerDay(
        fromAddress: String,
        startDate: String,
        endDate: String,
        completion: @escaping (ZBWarmupResult) -> ()
    ) {
        guard let value = required(fromAddress, "from_address", completion),
              isoDate(startDate, "start_date", completion),
              isoDate(endDate, "end_date", completion) else { return }
        guard startDate <= endDate else {
            completion(.Failure(ZBError.decodeError(messages: [
                "Invalid parameter: start_date is later than end_date"
            ])))
            return
        }
        send(method: "GET", path: "/statistics-per-day", query: [
            URLQueryItem(name: "from_address", value: value),
            URLQueryItem(name: "start_date", value: startDate),
            URLQueryItem(name: "end_date", value: endDate)
        ], completion: completion)
    }

    public func getStatisticsDetailed(cFrom: String, completion: @escaping (ZBWarmupResult) -> ()) {
        guard let value = required(cFrom, "c_from", completion) else { return }
        send(method: "GET", path: "/statistics-detailed",
             query: [URLQueryItem(name: "c_from", value: value)], completion: completion)
    }

    /// An address's statistics as CSV.
    public func downloadStatistics(cFrom: String, completion: @escaping (ZBWarmupCsvResult) -> ()) {
        let trimmed = cFrom.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            completion(.Failure(ZBError.decodeError(messages: ["Empty parameter: c_from"])))
            return
        }
        sendCsv(path: "/statistics/download",
                query: [URLQueryItem(name: "c_from", value: trimmed)], completion: completion)
    }

    public func getFromAddressStatistics(fromAddress: String, completion: @escaping (ZBWarmupResult) -> ()) {
        guard let value = required(fromAddress, "from_address", completion) else { return }
        send(method: "GET", path: "/from-address-statistics",
             query: [URLQueryItem(name: "from_address", value: value)], completion: completion)
    }

    // MARK: Deliverability checks

    /// SPF, DKIM and DMARC status of a from-address's domain.
    ///
    /// Pass an email address: the live API answers "Please provide a valid
    /// email address" for a bare domain, although the docs describe a domain.
    public func checkDomainDmarc(
        fromAddress: String,
        dkimSelector: String? = nil,
        completion: @escaping (ZBWarmupResult) -> ()
    ) {
        guard let value = required(fromAddress, "from_address", completion) else { return }
        guard value.contains("@") else {
            completion(.Failure(ZBError.decodeError(messages: [
                "Invalid parameter: from_address (an email address, e.g. sender@example.com)"
            ])))
            return
        }
        var query = [URLQueryItem(name: "from_address", value: value)]
        if let selector = dkimSelector, !selector.isEmpty {
            query.append(URLQueryItem(name: "dkim_selector", value: selector))
        }
        send(method: "GET", path: "/check-domain-dmarc", query: query, completion: completion)
    }

    /// Checks that SMTP credentials connect and hand off a message.
    ///
    /// Nothing is stored, and the test message goes to a ZeroBounce test
    /// recipient, not `fromAddress`. The live API answers a failed SMTP login
    /// with HTTP 500.
    public func testSmtpConfiguration(
        fromAddress: String,
        username: String,
        password: String,
        server: String,
        port: Int,
        completion: @escaping (ZBWarmupResult) -> ()
    ) {
        guard let address = required(fromAddress, "from_address", completion),
              let user = required(username, "username", completion),
              let secret = required(password, "password", completion),
              let host = required(server, "server", completion),
              inRange(port, 1, 65535, "port", completion) else { return }
        send(method: "POST", path: "/test-smtp-configuration", body: [
            "from_address": address,
            "username": user,
            "password": secret,
            "server": host,
            "port": port
        ], secrets: [secret, user], completion: completion)
    }

    // MARK: Argument checks

    private func required(
        _ value: String,
        _ name: String,
        _ completion: @escaping (ZBWarmupResult) -> ()
    ) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            completion(.Failure(ZBError.decodeError(messages: ["Empty parameter: \(name)"])))
            return nil
        }
        return trimmed
    }

    private func inRange(
        _ value: Int,
        _ low: Int,
        _ high: Int,
        _ name: String,
        _ completion: @escaping (ZBWarmupResult) -> ()
    ) -> Bool {
        if value < low || value > high {
            let bound = high == Int.max ? "a non-negative integer" : "\(low) to \(high)"
            completion(.Failure(ZBError.decodeError(messages: [
                "Invalid parameter: \(name) (must be \(bound))"
            ])))
            return false
        }
        return true
    }

    private func isoDate(
        _ value: String,
        _ name: String,
        _ completion: @escaping (ZBWarmupResult) -> ()
    ) -> Bool {
        let parts = value.split(separator: "-", omittingEmptySubsequences: false)
        let shaped = value.count == 10 && parts.count == 3
            && parts[0].count == 4 && parts[1].count == 2 && parts[2].count == 2
            && parts.allSatisfy { $0.allSatisfy(\.isNumber) }
        if !shaped {
            completion(.Failure(ZBError.decodeError(messages: [
                "Invalid parameter: \(name) (expected YYYY-MM-DD)"
            ])))
            return false
        }
        return true
    }

    /// reply_pct 5-45, important_pct 5-40, click_pct 0-70 and at most
    /// important_pct x 1.75.
    private func engagementBody(
        _ cFrom: String,
        _ replyPct: Int,
        _ importantPct: Int,
        _ clickPct: Int,
        _ completion: @escaping (ZBWarmupResult) -> ()
    ) -> [String: Any]? {
        guard let value = required(cFrom, "c_from", completion),
              inRange(replyPct, 5, 45, "reply_pct", completion),
              inRange(importantPct, 5, 40, "important_pct", completion),
              inRange(clickPct, 0, 70, "click_pct", completion) else { return nil }
        guard clickPct * 100 <= importantPct * 175 else {
            completion(.Failure(ZBError.decodeError(messages: [
                "Invalid parameter: click_pct (at most important_pct x 1.75)"
            ])))
            return nil
        }
        return [
            "c_from": value,
            "reply_pct": replyPct,
            "important_pct": importantPct,
            "click_pct": clickPct
        ]
    }

    // MARK: Request handling

    /// The Warmup key never travels in a URL, but a transport error may quote
    /// the header, an error body may quote the key or the request back, and
    /// test-smtp-configuration carries SMTP credentials in its body. Every
    /// form of each (as sent, percent-encoded, JSON-escaped) is masked.
    private func redact(_ text: String, _ secrets: [String]) -> String {
        ZeroBounceSDK.redacting([apiKey].compactMap { $0 } + secrets, in: text)
    }

    /// `completion` with the key and `secrets` redacted from any error it is
    /// handed. `send` and `sendCsv`, which every public method goes through,
    /// wrap the caller's completion this way, so an error built from a body
    /// is redacted on every path.
    private func redacted(
        _ secrets: [String],
        _ completion: @escaping (ZBWarmupResult) -> ()
    ) -> (ZBWarmupResult) -> () {
        let all = [apiKey].compactMap { $0 } + secrets
        return { result in
            if case .Failure(let error) = result {
                completion(.Failure(ZeroBounceSDK.redacting(all, in: error)))
            } else {
                completion(result)
            }
        }
    }

    private func redacted(_ completion: @escaping (ZBWarmupCsvResult) -> ()) -> (ZBWarmupCsvResult) -> () {
        let all = [apiKey].compactMap { $0 }
        return { result in
            if case .Failure(let error) = result {
                completion(.Failure(ZeroBounceSDK.redacting(all, in: error)))
            } else {
                completion(result)
            }
        }
    }

    private func buildRequest(
        method: String,
        path: String,
        query: [URLQueryItem],
        body: [String: Any]?
    ) -> URLRequest? {
        guard let apiKey = apiKey, !apiKey.isEmpty else { return nil }
        guard var components = URLComponents(string: baseUrl + ZeroBounceWarmup.basePath + path) else {
            return nil
        }
        if !query.isEmpty { components.queryItems = query }
        guard let url = components.url else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = ZeroBounceSDK.requestTimeout
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(apiKey, forHTTPHeaderField: "API-Key")
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [.sortedKeys])
        }
        return request
    }

    private func send(
        method: String,
        path: String,
        query: [URLQueryItem] = [],
        body: [String: Any]? = nil,
        secrets: [String] = [],
        completion: @escaping (ZBWarmupResult) -> ()
    ) {
        let completion = redacted(secrets, completion)
        perform(method: method, path: path, query: query, body: body, secrets: secrets) { result in
            switch result {
            case .failure(let error):
                completion(.Failure(error))
            case .success(let (data, _)):
                // 204 and an empty 200 are the documented empty successes.
                if data.isEmpty {
                    completion(.Success(nil))
                    return
                }
                guard let object = try? JSONSerialization.jsonObject(
                    with: data, options: [.fragmentsAllowed]
                ) else {
                    completion(.Failure(ZBError.decodeError(messages: [
                        self.redact(ZBError.message(from: data, statusCode: 200), secrets)
                    ])))
                    return
                }
                completion(.Success(object))
            }
        }
    }

    private func sendCsv(
        path: String,
        query: [URLQueryItem],
        completion: @escaping (ZBWarmupCsvResult) -> ()
    ) {
        let completion = redacted(completion)
        perform(method: "GET", path: path, query: query, body: nil, secrets: []) { result in
            switch result {
            case .failure(let error):
                completion(.Failure(error))
            case .success(let (data, response)):
                let text = String(data: data, encoding: .utf8) ?? ""
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                // An error comes back as JSON, and a proxy or block page as
                // HTML, by content type or by body, so neither is a file.
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 200
                if let failure = ZBError.downloadFailure(data, response: response, statusCode: statusCode) {
                    completion(.Failure(failure))
                    return
                }
                if trimmed.isEmpty || trimmed.hasPrefix("[") {
                    completion(.Failure(ZBError.httpError(
                        message: ZBError.message(from: data, statusCode: statusCode),
                        statusCode: statusCode
                    )))
                    return
                }
                completion(.Success(text))
            }
        }
    }

    private func perform(
        method: String,
        path: String,
        query: [URLQueryItem],
        body: [String: Any]?,
        secrets: [String],
        completion: @escaping (Result<(Data, URLResponse), Error>) -> ()
    ) {
        guard let request = buildRequest(method: method, path: path, query: query, body: body) else {
            if apiKey == nil || apiKey?.isEmpty == true {
                completion(.failure(ZBError.decodeError(messages: [
                    "The Warmup API is not initialized. Please call ZeroBounceWarmup.shared.initialize(apiKey:) first"
                ])))
            } else {
                completion(.failure(ZBError.invalidEndpoint))
            }
            return
        }
        guard let url = request.url, ZeroBounceSDK.isAllowedURL(url) else {
            completion(.failure(ZBError.decodeError(messages: ["baseUrl must be an https:// URL"])))
            return
        }
        ZeroBounceSDK.urlSession.dataTask(with: request) { data, response, error in
            if let error = error ?? ZeroBounceSDK.cutShortError(response, received: Int64(data?.count ?? 0)) {
                completion(.failure(ZBError.decodeError(messages: [
                    self.redact(error.localizedDescription, secrets)
                ])))
                return
            }
            guard let http = response as? HTTPURLResponse else {
                completion(.failure(ZBError.noResponse))
                return
            }
            let statusCode = http.statusCode
            let payload = data ?? Data()
            if 300..<400 ~= statusCode {
                completion(.failure(ZBError.httpError(
                    message: "ZeroBounce returned a redirect, which this client does not follow.",
                    statusCode: statusCode
                )))
                return
            }
            guard 200...299 ~= statusCode else {
                completion(.failure(ZBError.httpError(
                    message: self.redact(ZBError.message(from: payload, statusCode: statusCode), secrets),
                    statusCode: statusCode
                )))
                return
            }
            // A page sent as HTML is never the JSON or CSV a call expects,
            // whatever its body looks like.
            if let page = ZBError.htmlPageError(payload, response: http, statusCode: statusCode) {
                completion(.failure(page))
                return
            }
            completion(.success((payload, http)))
        }.resume()
    }
}

/// `dump`, `Mirror(reflecting:)` and debuggers show the Warmup key masked.
extension ZeroBounceWarmup: CustomReflectable {
    public var customMirror: Mirror {
        Mirror(self, children: [
            "apiKey": ZeroBounceSDK.maskedKey(apiKey),
            "baseUrl": baseUrl,
        ], displayStyle: .class)
    }
}
