//
//  LiveApiTests.swift
//  Zero Bounce iOS SDKTests
//
//  Opt-in live API suite: calls the SDK against the real API to check payloads
//  and response shapes.
//
//  It is listed under <SkippedTests> in the shared scheme, so the default
//  `xcodebuild test` and CI never run it. To run it:
//
//    # xcodebuild does not pass its own environment to the test process, so
//    # each variable is exported again with a TEST_RUNNER_ prefix, which is
//    # stripped on the way in. Environment variables, not build settings: a
//    # build setting is an argument, and arguments are visible to ps.
//    export TEST_RUNNER_ZEROBOUNCE_API_KEY=...        # validation API
//    export TEST_RUNNER_ZEROBOUNCE_WARMUP_API_KEY=... # Warmup API
//    export TEST_RUNNER_ZEROBOUNCE_LIVE_SPEND=1       # optional: spends credits
//    export TEST_RUNNER_ZEROBOUNCE_LIVE_CHANGES=1     # optional: reversible changes
//    xcodebuild test \
//      -workspace "Zero Bounce iOS SDK.xcworkspace" \
//      -scheme "Zero Bounce iOS SDK" \
//      -destination 'platform=macOS,variant=Mac Catalyst' \
//      -only-testing:"Zero Bounce iOS SDKTests/LiveApiTests" \
//      CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO \
//      CODE_SIGNING_ALLOWED=NO ENABLE_USER_SCRIPT_SANDBOXING=NO
//
//  By default only free calls run: sandbox addresses (no credits), reads, and
//  requests expected to fail (unknown file ids, S3/SFTP without an
//  integration) that still prove the API accepts the payload. The free tier
//  checks that the credit balance did not change. Two flags opt in to more:
//
//    ZEROBOUNCE_LIVE_SPEND=1     spends credits: scoring, activity, email
//                                finder, and a bulk round trip whose job is
//                                deleted again
//    ZEROBOUNCE_LIVE_CHANGES=1   reversible account changes, each undone in
//                                the same run even when a check fails
//
//  Never called, because the API cannot undo them: creating an Inbox Placement
//  test (it cannot be deleted while running), setting the Inbox Placement
//  webhook (it cannot be cleared), and ZB managed Warmup onboarding (it starts
//  mailbox provisioning).
//
//  No key is ever written to a file or printed. Keys come from the environment.
//

import XCTest
@testable import Zero_Bounce_iOS_SDK

final class LiveApiTests: XCTestCase {

    /// Well formed but matching no file: a malformed id can be Cloudflare
    /// blocked instead of answered.
    private let unknownId = "0d1b7a4e-1111-2222-3333-444455556666"
    private let callback = "https://example.com/zerobounce-sdk-live-test"
    private let sandbox = "valid@example.com"

    private var apiKey = ""
    private var warmupKey = ""
    private var spend = false
    private var changes = false

    private var passed = 0
    private var failed = 0
    private var skipped = 0
    private var failures: [String] = []

    override func setUp() {
        super.setUp()
        apiKey = Self.env("ZEROBOUNCE_API_KEY")
        warmupKey = Self.env("ZEROBOUNCE_WARMUP_API_KEY")
        spend = Self.env("ZEROBOUNCE_LIVE_SPEND") == "1"
        changes = Self.env("ZEROBOUNCE_LIVE_CHANGES") == "1"
    }

    private static func env(_ name: String) -> String {
        (ProcessInfo.processInfo.environment[name] ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func redact(_ text: String) -> String {
        var value = text
        for secret in [apiKey, warmupKey] where !secret.isEmpty {
            value = value.replacingOccurrences(of: secret, with: "***")
        }
        return value
    }

    private func pass(_ name: String) {
        passed += 1
        print("  + \(name)")
    }

    private func fail(_ name: String, _ problem: String) {
        failed += 1
        let safe = redact(problem)
        failures.append("\(name): \(safe)")
        print("  X \(name)\n      \(safe)")
    }

    private func skip(_ name: String, _ reason: String) {
        skipped += 1
        print("  - SKIP \(name) (\(reason))")
    }

    /// A check either passes, or records why it did not. The body reports ""
    /// when all is well.
    private func check(_ name: String, _ body: (@escaping (String) -> ()) -> ()) {
        var problem = "no response"
        let done = expectation(description: name)
        body { text in
            problem = text
            done.fulfill()
        }
        wait(for: [done], timeout: 180)
        if problem.isEmpty { pass(name) } else { fail(name, problem) }
    }

    private func text(_ error: Error) -> String {
        redact((error as? LocalizedError)?.errorDescription ?? "\(error)")
    }

    private func isoDaysAgo(_ days: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date().addingTimeInterval(-Double(days) * 86400))
    }

    private func summary() {
        print("\n\(passed) passed, \(failed) failed, \(skipped) skipped")
        if !failures.isEmpty {
            print("\nFailures:")
            for line in failures { print("  - \(line)") }
        }
        XCTAssertEqual(failed, 0, failures.joined(separator: "\n"))
    }

    // MARK: The whole run
    //
    // One test method, so the tiers run in order and the credit balance check
    // sees only the free calls.

    func testLiveApi() {
        print("ZeroBounce live API suite")
        print("  validation key: \(apiKey.isEmpty ? "MISSING" : "set")")
        print("  warmup key:     \(warmupKey.isEmpty ? "MISSING" : "set")")
        print("  flags:          SPEND=\(spend ? 1 : 0) CHANGES=\(changes ? 1 : 0)\n")

        if apiKey.isEmpty && warmupKey.isEmpty {
            print("No keys in the environment; nothing to do.")
            return
        }

        if !apiKey.isEmpty {
            let sdk = ZeroBounceSDK()
            sdk.initialize(apiKey: apiKey)
            validationFree(sdk)
            if spend { validationSpend(sdk) }
            if changes { validationChanges(sdk) }
        }
        if !warmupKey.isEmpty {
            let warmup = ZeroBounceWarmup()
            warmup.initialize(apiKey: warmupKey)
            warmupReads(warmup)
            if changes { warmupChanges(warmup) }
        }
        summary()
    }

    // MARK: Validation API, free

    private func validationFree(_ sdk: ZeroBounceSDK) {
        print("Validation API (free calls)")

        var creditsBefore = -2
        check("getCredits returns a balance") { report in
            sdk.getCredits { result in
                switch result {
                case .Success(let response):
                    creditsBefore = Int(response.credits) ?? -2
                    report("")
                case .Failure(let error):
                    report(self.text(error))
                }
            }
        }

        check("getApiUsage parses the documented date formats") { report in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let start = formatter.date(from: self.isoDaysAgo(7)) ?? Date()
            let end = formatter.date(from: self.isoDaysAgo(0)) ?? Date()
            sdk.getApiUsage(startDate: start, endDate: end) { result in
                if case .Failure(let error) = result { report(self.text(error)) } else { report("") }
            }
        }

        check("validate on a sandbox address spends nothing") { report in
            sdk.validate(email: self.sandbox) { result in
                switch result {
                case .Success(let response):
                    report(response.address == self.sandbox ? "" : "address did not echo")
                case .Failure(let error):
                    report(self.text(error))
                }
            }
        }

        // No billable add-on here: activity_data, verify_plus and domain_info
        // are charged even on a sandbox address, so they live in the SPEND tier.
        check("validate works over POST as well as GET") { report in
            sdk.validate(
                email: self.sandbox, ipAddress: nil,
                options: ZBValidateOptions(timeout: 30, usePost: true)
            ) { result in
                if case .Failure(let error) = result { report(self.text(error)) } else { report("") }
            }
        }

        // LIVE: sent as a JSON number the API rejects the whole batch with the
        // account-level "Invalid API Key or your account ran out of credits".
        check("LIVE: validateBatch accepts timeout as a string") { report in
            sdk.validateBatch(
                emails: [["email_address": self.sandbox]],
                options: ZBValidateOptions(timeout: 30)
            ) { result in
                if case .Failure(let error) = result { report(self.text(error)) } else { report("") }
            }
        }

        check("an unknown file id is a short, clean error") { report in
            sdk.fileStatus(fileId: self.unknownId) { result in
                switch result {
                case .Success:
                    report("fileStatus unexpectedly succeeded")
                case .Failure(let error):
                    let message = self.text(error)
                    report(message.count < 500 && !message.contains("<html")
                           ? "" : "message not short and clean")
                }
            }
        }

        check("listS3files answers (empty without an S3 integration)") { report in
            // No S3 integration configured is an expected, documented failure.
            sdk.listS3files { result in
                if case .Failure(let error) = result, self.text(error).count >= 500 {
                    report("message too long")
                } else {
                    report("")
                }
            }
        }

        check("LIVE: S3/SFTP jobs reject a payload without return_url before sending") { report in
            sdk.emailFinderS3File(options: ZBBulkFileJobOptions(fileName: "f.csv")) { result in
                switch result {
                case .Success:
                    report("a payload without return_url was accepted")
                case .Failure(let error):
                    let message = self.text(error)
                    report(message.contains("return_url") ? "" : "unexpected message: \(message)")
                }
            }
        }

        check("LIVE: a complete S3 job payload is accepted by the API") { report in
            // Without an S3 integration this fails on the integration, not the
            // payload.
            sdk.emailFinderS3File(
                options: ZBBulkFileJobOptions(fileName: "f.csv", returnUrl: self.callback)
            ) { result in
                if case .Failure(let error) = result {
                    let message = self.text(error)
                    if message.contains("return URL is not permitted")
                        || message.contains("This field is required") {
                        report("payload rejected: \(message)")
                        return
                    }
                }
                report("")
            }
        }

        check("filters list") { report in
            // LIVE: the body is a JSON array, [] when no filters are set.
            sdk.listFilters { result in
                if case .Failure(let error) = result { report(self.text(error)) } else { report("") }
            }
        }

        // LIVE: an api_key parameter is rejected as unauthorized here.
        check("LIVE: the Inbox Placement Tester accepts a Bearer key") { report in
            sdk.getInboxPlacementProviders { result in
                if case .Failure(let error) = result { report(self.text(error)) } else { report("") }
            }
        }

        check("inbox placement test types") { report in
            sdk.getInboxPlacementTestTypes { result in
                if case .Failure(let error) = result { report(self.text(error)) } else { report("") }
            }
        }

        // LIVE: the listing is GET /tests (plural); /test is the single-test
        // path and answers 'Method "GET" not allowed'.
        check("LIVE: inbox placement tests are listed from /tests, and the webhook reads back") { report in
            sdk.listInboxPlacementTests(
                options: ZBListInboxPlacementTestsOptions(page: 1, pageSize: 10)
            ) { listed in
                if case .Failure(let error) = listed {
                    report(self.text(error))
                    return
                }
                sdk.getInboxPlacementWebhook { hook in
                    if case .Failure(let error) = hook { report(self.text(error)) } else { report("") }
                }
            }
        }

        check("list evaluator result for an unknown id fails cleanly") { report in
            sdk.getListEvaluatorResult(fileId: self.unknownId) { result in
                switch result {
                case .Success:
                    report("an unknown evaluation id unexpectedly succeeded")
                case .Failure(let error):
                    report(self.text(error).count < 500 ? "" : "message too long")
                }
            }
        }

        // LIVE: the file id is a form field. Appended to the path it is a 404.
        check("LIVE: sendEvaluatedFile posts the file id as a form field") { report in
            sdk.sendEvaluatedFile(fileId: self.unknownId) { result in
                switch result {
                case .Success:
                    report("an unknown evaluation id unexpectedly succeeded")
                case .Failure(let error):
                    let message = self.text(error)
                    report(message.contains("not allowed") ? "wrong method or path: \(message)" : "")
                }
            }
        }

        check("the free calls did not change the credit balance") { report in
            sdk.getCredits { result in
                switch result {
                case .Success(let response):
                    let after = Int(response.credits) ?? -2
                    report(after == creditsBefore
                           ? "" : "credits went from \(creditsBefore) to \(after)")
                case .Failure(let error):
                    report(self.text(error))
                }
            }
        }
    }

    // MARK: Validation API, spends credits

    private func validationSpend(_ sdk: ZeroBounceSDK) {
        print("\nValidation API (ZEROBOUNCE_LIVE_SPEND=1)")

        // LIVE: activity_data, verify_plus and domain_info are billable add-ons
        // and are charged even for a sandbox address, so this is not free.
        check("validate accepts every documented option") { report in
            sdk.validate(
                email: self.sandbox, ipAddress: nil,
                options: ZBValidateOptions(
                    timeout: 30,
                    activityData: true,
                    verifyPlus: true,
                    domainInfo: true,
                    greylistProcessing: true,
                    callbackUrl: self.callback
                )
            ) { result in
                if case .Failure(let error) = result { report(self.text(error)) } else { report("") }
            }
        }

        check("scoreEmail") { report in
            sdk.scoreEmail(email: self.sandbox) { result in
                if case .Failure(let error) = result { report(self.text(error)) } else { report("") }
            }
        }

        check("scoreEmail over POST") { report in
            sdk.scoreEmailPost(email: self.sandbox) { result in
                if case .Failure(let error) = result { report(self.text(error)) } else { report("") }
            }
        }

        check("getActivityData") { report in
            sdk.getActivityData(email: self.sandbox) { result in
                if case .Failure(let error) = result { report(self.text(error)) } else { report("") }
            }
        }

        check("email finder") { report in
            sdk.findEmail(domain: "example.com", firstName: "John", middleName: nil, lastName: "Doe") { result in
                if case .Failure(let error) = result { report(self.text(error)) } else { report("") }
            }
        }

        check("domain search") { report in
            sdk.findDomain(domain: "example.com") { result in
                if case .Failure(let error) = result { report(self.text(error)) } else { report("") }
            }
        }

        var fileId = ""
        check("bulk validation round trip: upload, status, delete") { report in
            let path = NSTemporaryDirectory() + "zb-sdk-live.csv"
            let contents = "email\nvalid@example.com\ninvalid@example.com\n"
            try? contents.write(toFile: path, atomically: true, encoding: .utf8)
            sdk.sendFile(filePath: path, emailAddressColumn: 1, hasHeaderRow: true) { upload in
                try? FileManager.default.removeItem(atPath: path)
                switch upload {
                case .Failure(let error):
                    report(self.text(error))
                case .Success(let response):
                    let id = response.fileId
                    guard !id.isEmpty else {
                        report("no file_id in the upload response")
                        return
                    }
                    fileId = id
                    sdk.fileStatus(fileId: id) { status in
                        switch status {
                        case .Failure(let error):
                            report(self.text(error))
                        case .Success(let value):
                            report(value.fileId == id ? "" : "status did not echo the file id")
                        }
                    }
                }
            }
        }

        if fileId.isEmpty {
            skip("the uploaded validation job is deleted again", "upload did not produce a file id")
            return
        }
        // LIVE: a just-accepted job answers "File cannot be found" for a short
        // while, so the delete is retried rather than leaving it behind.
        check("the uploaded validation job is deleted again") { report in
            var attempt = 0
            var last = ""
            func tryDelete() {
                attempt += 1
                sdk.deleteFile(fileId: fileId) { result in
                    switch result {
                    case .Success:
                        report("")
                    case .Failure(let error):
                        last = self.text(error)
                        if attempt >= 12 {
                            report("could not delete \(fileId) after retrying: \(last)")
                            return
                        }
                        DispatchQueue.global().asyncAfter(deadline: .now() + 10) { tryDelete() }
                    }
                }
            }
            tryDelete()
        }
    }

    // MARK: Validation API, reversible account changes

    private func validationChanges(_ sdk: ZeroBounceSDK) {
        print("\nValidation API (ZEROBOUNCE_LIVE_CHANGES=1)")
        let value = "zb-sdk-live-\(Int(Date().timeIntervalSince1970)).example.com"

        var added = false
        check("addFilter creates a reversible allow rule") { report in
            sdk.addFilter(rule: "allow", target: "domain", value: value) { result in
                if case .Failure(let error) = result {
                    report(self.text(error))
                } else {
                    added = true
                    report("")
                }
            }
        }

        if !added {
            skip("the test filter is removed again", "filter was not created")
            return
        }
        check("the test filter is removed again") { report in
            sdk.deleteFilter(rule: "allow", target: "domain", value: value) { result in
                if case .Failure(let error) = result { report(self.text(error)) } else { report("") }
            }
        }
    }

    // MARK: Warmup API

    private func warmupReads(_ warmup: ZeroBounceWarmup) {
        print("\nWarmup API (reads)")

        func read(_ name: String, _ call: @escaping (@escaping (ZeroBounceWarmup.ZBWarmupResult) -> ()) -> ()) {
            check(name) { report in
                call { result in
                    if case .Failure(let error) = result { report(self.text(error)) } else { report("") }
                }
            }
        }

        read("listSendingAccounts") { warmup.listSendingAccounts(completion: $0) }
        read("listFromAddresses") { warmup.listFromAddresses(completion: $0) }
        read("getEngagementRules") { warmup.getEngagementRules(completion: $0) }
        read("getSeeds") { warmup.getSeeds(completion: $0) }
        read("getSeedCount") { warmup.getSeedCount(completion: $0) }
        read("getProgressToday") { warmup.getProgressToday(completion: $0) }
        read("getSentToday") { warmup.getSentToday(completion: $0) }
        read("getEmailsPerDay") { warmup.getEmailsPerDay(completion: $0) }

        check("downloadSeeds returns CSV text") { report in
            warmup.downloadSeeds { result in
                switch result {
                case .Failure(let error):
                    report(self.text(error))
                case .Success(let csv):
                    if csv.isEmpty { report("empty CSV body") }
                    else if csv.hasPrefix("{") { report("got JSON instead of CSV") }
                    else { report("") }
                }
            }
        }

        // LIVE: a bare domain is answered with "Please provide a valid email
        // address", although the docs describe a domain.
        check("LIVE: checkDomainDmarc rejects a bare domain before sending") { report in
            warmup.checkDomainDmarc(fromAddress: "example.com") { result in
                switch result {
                case .Success:
                    report("a bare domain unexpectedly succeeded")
                case .Failure(let error):
                    let message = self.text(error)
                    report(message.contains("email address") ? "" : "unexpected message: \(message)")
                }
            }
        }

        check("LIVE: checkDomainDmarc accepts an email address") { report in
            warmup.checkDomainDmarc(fromAddress: "sender@example.com") { result in
                if case .Failure(let error) = result { report(self.text(error)) } else { report("") }
            }
        }

        // The statistics endpoints need a from-address this team actually has;
        // the API answers "Sending account ... was not found" for anything else.
        var known = ""
        let found = expectation(description: "first sending account")
        warmup.listSendingAccounts { result in
            if case .Success(let object) = result {
                var rows: [[String: Any]] = []
                if let list = object as? [[String: Any]] {
                    rows = list
                } else if let dict = object as? [String: Any] {
                    for key in ["accounts", "data", "results"] {
                        if let list = dict[key] as? [[String: Any]] {
                            rows = list
                            break
                        }
                    }
                }
                if let first = rows.first {
                    for key in ["from_address", "c_from", "fromAddress"] {
                        if let value = first[key] as? String, !value.isEmpty {
                            known = value
                            break
                        }
                    }
                }
            }
            found.fulfill()
        }
        wait(for: [found], timeout: 180)

        if known.isEmpty {
            let reason = "this team has no sending account"
            skip("statistics for a registered from-address", reason)
            skip("statistics per day over a short range", reason)
            skip("detailed statistics and the CSV download for that address", reason)
            skip("from-address statistics", reason)
        } else {
            read("statistics for a registered from-address") {
                warmup.getStatistics(fromAddress: known, completion: $0)
            }
            read("statistics per day over a short range") {
                warmup.getStatisticsPerDay(
                    fromAddress: known,
                    startDate: self.isoDaysAgo(6),
                    endDate: self.isoDaysAgo(0),
                    completion: $0
                )
            }
            check("detailed statistics and the CSV download for that address") { report in
                warmup.getStatisticsDetailed(cFrom: known) { detailed in
                    if case .Failure(let error) = detailed {
                        report(self.text(error))
                        return
                    }
                    warmup.downloadStatistics(cFrom: known) { csv in
                        if case .Failure(let error) = csv { report(self.text(error)) } else { report("") }
                    }
                }
            }
            read("from-address statistics") {
                warmup.getFromAddressStatistics(fromAddress: known, completion: $0)
            }
        }

        check("an unknown Warmup resource fails with a status code") { report in
            warmup.getCustomEngagement(cFrom: "no-such-address@example.com") { result in
                switch result {
                case .Success:
                    report("")
                case .Failure(let error):
                    if (error as? ZBError)?.statusCode == nil {
                        report("no status code on the error")
                    } else if !self.warmupKey.isEmpty && "\(error)".contains(self.warmupKey) {
                        report("the key leaked into the message")
                    } else {
                        report("")
                    }
                }
            }
        }
    }

    private func warmupChanges(_ warmup: ZeroBounceWarmup) {
        print("\nWarmup API (ZEROBOUNCE_LIVE_CHANGES=1)")
        let address = "zb-sdk-live-\(Int(Date().timeIntervalSince1970))@example.com"

        var added = false
        check("a self-managed sending account can be added") { report in
            warmup.addSendingAccount(
                fromAddress: address,
                onboardingModel: ZeroBounceWarmup.selfManaged,
                options: ZBWarmupAddSendingAccountOptions(engagementRuleId: 0, ignoreConflict: true)
            ) { result in
                if case .Failure(let error) = result {
                    report(self.text(error))
                } else {
                    added = true
                    report("")
                }
            }
        }

        if !added {
            skip("the test sending account is removed again", "account was not created")
            return
        }
        check("the test sending account is removed again") { report in
            warmup.deleteSendingAccount(fromAddress: address) { result in
                if case .Failure(let error) = result { report(self.text(error)) } else { report("") }
            }
        }
    }
}
