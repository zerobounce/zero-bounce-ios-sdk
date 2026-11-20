//
//  ZeroBounceWarmupProtocol.swift
//  Zero Bounce iOS SDK
//
//  The public API of `ZeroBounceWarmup` as a protocol, so app code can hold
//  `any ZeroBounceWarmupProtocol` and a test can hand it a fake.
//

import Foundation

/// Every public API method of `ZeroBounceWarmup` (the Warmup API), with the
/// same signatures, so code under test can take a fake in place of the client:
///
/// ```swift
/// final class WarmupStatus {
///     let client: any ZeroBounceWarmupProtocol
///     init(client: any ZeroBounceWarmupProtocol = ZeroBounceWarmup.shared) { self.client = client }
/// }
/// ```
///
/// Setup is left out: `initialize(apiKey:)`, `baseUrl` and the static `shared`,
/// `selfManaged` and `zbManaged`. Configure the real client before handing it
/// over.
///
/// The protocol gains a requirement with every method the client gains, in
/// minor releases. It is meant for test fakes and type annotations, not as a
/// stable contract for your own conforming types: a fake may have to add
/// methods when you upgrade.
///
/// Swift protocols cannot declare default arguments, so each requirement takes
/// every argument. The extension below adds, for each method with defaults, the
/// overload that leaves all of them out; to pass some but not all of them
/// through the protocol, pass the rest explicitly (`nil` for an optional).
public protocol ZeroBounceWarmupProtocol {
    /// Every sending account of the key's team. An empty team answers an empty
    /// list, not a 404.
    func listSendingAccounts(completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ())

    func getSendingAccount(fromAddress: String, completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ())

    /// Adds a from-address to warmup.
    ///
    /// For a ZB managed account a 200 means accepted; the mailbox is
    /// provisioned afterwards.
    func addSendingAccount(
        fromAddress: String,
        onboardingModel: String,
        options: ZBWarmupAddSendingAccountOptions?,
        completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ()
    )

    /// Changes an account's engagement rule, status and auto-enable flag.
    ///
    /// `statusId` is 0 to 8 (4 Paused, 5 Disabled). `autoEnable` is accepted
    /// only for an account that is not active.
    func updateSendingAccount(
        fromAddress: String,
        engagementRuleId: Int,
        statusId: Int,
        autoEnable: Bool,
        completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ()
    )

    /// Removes a sending account. Destructive and cannot be undone.
    func deleteSendingAccount(fromAddress: String, completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ())

    /// Moves an account and its history to a new from-address. Despite the
    /// path it uses, nothing about SMTP credentials is stored.
    func changeFromAddress(
        oldFromAddress: String,
        newFromAddress: String,
        completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ()
    )

    func listFromAddresses(
        options: ZBWarmupListFromAddressesOptions?,
        completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ()
    )

    /// The rule catalogue: -1 Custom, 0 Default, 1 Slow Pace, 2 Repair,
    /// 3 Boost, 4 Protect.
    func getEngagementRules(completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ())

    /// Sets a standard rule (0 to 4) on an address.
    func setEngagementRule(
        cFrom: String,
        ruleId: Int,
        completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ()
    )

    func getCustomEngagement(cFrom: String, completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ())

    /// Creates a custom rule. Starts a 7 day cooldown on updates.
    func createCustomEngagement(
        cFrom: String,
        replyPct: Int,
        importantPct: Int,
        clickPct: Int,
        completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ()
    )

    /// Updates a custom rule. During the 7 day cooldown this fails with
    /// HTTP 429.
    func updateCustomEngagement(
        cFrom: String,
        replyPct: Int,
        importantPct: Int,
        clickPct: Int,
        completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ()
    )

    /// Deletes a custom rule, falling back to standard rule
    /// `engagementRuleId` (1 to 4).
    func deleteCustomEngagement(
        cFrom: String,
        engagementRuleId: Int,
        completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ()
    )

    func getSeeds(completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ())

    /// The seed list as CSV (columns `seed,provider`).
    func downloadSeeds(completion: @escaping (ZeroBounceWarmup.ZBWarmupCsvResult) -> ())

    /// The number of seeds. Answers a bare number, not an object.
    func getSeedCount(completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ())

    func getProgressToday(completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ())

    func getSentToday(completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ())

    func getEmailsPerDay(completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ())

    /// Statistics for an address. An address with no history answers zeros.
    func getStatistics(fromAddress: String, completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ())

    /// Daily statistics between two YYYY-MM-DD dates, inclusive.
    func getStatisticsPerDay(
        fromAddress: String,
        startDate: String,
        endDate: String,
        completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ()
    )

    func getStatisticsDetailed(cFrom: String, completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ())

    /// An address's statistics as CSV.
    func downloadStatistics(cFrom: String, completion: @escaping (ZeroBounceWarmup.ZBWarmupCsvResult) -> ())

    func getFromAddressStatistics(fromAddress: String, completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ())

    /// SPF, DKIM and DMARC status of a from-address's domain.
    ///
    /// Pass an email address: the live API answers "Please provide a valid
    /// email address" for a bare domain, although the docs describe a domain.
    func checkDomainDmarc(
        fromAddress: String,
        dkimSelector: String?,
        completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ()
    )

    /// Checks that SMTP credentials connect and hand off a message.
    ///
    /// Nothing is stored, and the test message goes to a ZeroBounce test
    /// recipient, not `fromAddress`. The live API answers a failed SMTP login
    /// with HTTP 500.
    func testSmtpConfiguration(
        fromAddress: String,
        username: String,
        password: String,
        server: String,
        port: Int,
        completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ()
    )
}

extension ZeroBounceWarmup: ZeroBounceWarmupProtocol {}

// `public extension` rather than `public func`: these forward to a
// requirement, they are not request methods of their own, and the source
// sweeps in the tests look for `public func`.
public extension ZeroBounceWarmupProtocol {
    /// Calls the requirement with `options: nil`, the class's default arguments.
    func addSendingAccount(
        fromAddress: String,
        onboardingModel: String,
        completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ()
    ) {
        addSendingAccount(
            fromAddress: fromAddress,
            onboardingModel: onboardingModel,
            options: nil,
            completion: completion
        )
    }

    /// Calls the requirement with `options: nil`, the class's default arguments.
    func listFromAddresses(completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ()) {
        listFromAddresses(options: nil, completion: completion)
    }

    /// Calls the requirement with `dkimSelector: nil`, the class's default arguments.
    func checkDomainDmarc(fromAddress: String, completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ()) {
        checkDomainDmarc(fromAddress: fromAddress, dkimSelector: nil, completion: completion)
    }
}
