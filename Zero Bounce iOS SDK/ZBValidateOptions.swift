//
//  ZBValidateOptions.swift
//  Zero Bounce iOS SDK
//

import Foundation

/// Optional query/body parameters for validate and validatebatch.
public struct ZBValidateOptions {
    /// Validation timeout in seconds (3–60 for single validate, 10–120 for batch).
    public var timeout: Int?
    /// Maps to activity_data.
    public var activityData: Bool?
    /// Maps to verify_plus.
    public var verifyPlus: Bool?
    /// Maps to domain_info. Fills `domainWebsiteExists` and `domainRegistrantCompanyName`.
    public var domainInfo: Bool?
    /// Maps to greylist_processing. Retries a greylisted address in the background.
    public var greylistProcessing: Bool?
    /// Maps to callback_url: where the greylist retry posts its result. It needs
    /// `greylistProcessing` set to true and is rejected without it, and when
    /// blank, before any request is sent.
    public var callbackUrl: String?
    /// When true, uses form-encoded POST for /validate.
    public var usePost: Bool

    public init(
        timeout: Int? = nil,
        activityData: Bool? = nil,
        verifyPlus: Bool? = nil,
        domainInfo: Bool? = nil,
        greylistProcessing: Bool? = nil,
        callbackUrl: String? = nil,
        usePost: Bool = false
    ) {
        self.timeout = timeout
        self.activityData = activityData
        self.verifyPlus = verifyPlus
        self.domainInfo = domainInfo
        self.greylistProcessing = greylistProcessing
        self.callbackUrl = callbackUrl
        self.usePost = usePost
    }

    /// The documented fields shared by the six S3 and SFTP/FTP file jobs.
    ///
    /// `fileName` is required by every job except `validateSFTPFile`, where the
    /// docs list it as optional: leaving it nil there uses the input bucket
    /// configured in your ZeroBounce settings.
}

public struct ZBBulkFileJobOptions {
    public var fileName: String?
    public var hasHeaderRow: Bool
    public var removeDuplicates: Bool?
    public var returnUrl: String?

    public init(
        fileName: String? = nil,
        hasHeaderRow: Bool = true,
        removeDuplicates: Bool? = nil,
        returnUrl: String? = nil
    ) {
        self.fileName = fileName
        self.hasHeaderRow = hasHeaderRow
        self.removeDuplicates = removeDuplicates
        self.returnUrl = returnUrl
    }
}

/// One entry of the `providers` list of a new Inbox Placement test: how many
/// seeds of a given provider the test should use. `providerIds` asks for a
/// provider without capping its seeds; this caps it.
public struct ZBInboxPlacementTestProvider {
    public var id: Int
    public var maxSeeds: Int

    public init(id: Int, maxSeeds: Int) {
        self.id = id
        self.maxSeeds = maxSeeds
    }
}

/// The optional fields of a new Inbox Placement test. Only what is set is sent.
public struct ZBCreateInboxPlacementTestOptions {
    /// 1 (send your own email), 2 or 3. `senderEmail` is required when it is 1.
    public var testType: Int?
    public var senderEmail: String?
    public var providerIds: [Int]?
    public var seedIds: [Int]?
    /// Per-provider seed caps, sent as `providers: [{"id": …, "maxSeeds": …}]`.
    public var providers: [ZBInboxPlacementTestProvider]?
    public var webhookUrl: String?

    public init(
        testType: Int? = nil,
        senderEmail: String? = nil,
        providerIds: [Int]? = nil,
        seedIds: [Int]? = nil,
        providers: [ZBInboxPlacementTestProvider]? = nil,
        webhookUrl: String? = nil
    ) {
        self.testType = testType
        self.senderEmail = senderEmail
        self.providerIds = providerIds
        self.seedIds = seedIds
        self.providers = providers
        self.webhookUrl = webhookUrl
    }
}

/// The documented filters of the Inbox Placement test list.
public struct ZBListInboxPlacementTestsOptions {
    /// `running` or `finished`. Anything else is rejected before a request.
    public var status: String?
    /// Sent as `createdAfter`, the way the endpoint spells it.
    public var createdAfter: String?
    /// Sent as `createdBefore`.
    public var createdBefore: String?
    public var page: Int?
    /// 1–100. LIVE: it goes on the wire as `page_size`; `pageSize` is accepted
    /// and then silently ignored, so the whole list comes back unpaginated.
    public var pageSize: Int?

    public init(
        status: String? = nil,
        createdAfter: String? = nil,
        createdBefore: String? = nil,
        page: Int? = nil,
        pageSize: Int? = nil
    ) {
        self.status = status
        self.createdAfter = createdAfter
        self.createdBefore = createdBefore
        self.page = page
        self.pageSize = pageSize
    }
}
