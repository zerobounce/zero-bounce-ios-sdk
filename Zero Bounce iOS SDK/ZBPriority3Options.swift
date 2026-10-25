//
//  ZBPriority3Options.swift
//  Zero Bounce iOS SDK
//

import Foundation

public struct ZBEmailFinderSendFileOptions {
    public var firstNameColumn: Int = 0
    public var lastNameColumn: Int = 0
    public var middleNameColumn: Int = 0
    public var fullNameColumn: Int = 0
    public var hasHeaderRow: Bool?

    public init() {}
}

public struct ZBDomainSearchSendFileOptions {
    public var hasHeaderRow: Bool?

    public init() {}
}

/// LIVE: `returnUrl` is required, although the docs call it optional. Without
/// it `POST /validateS3file` answers HTTP 400 "Provided return URL is not
/// permitted: None", so it is an initializer argument rather than an optional
/// field, the way every other S3/SFTP job needs one.
public struct ZBValidateS3FileOptions {
    public var fileName: String
    public var returnUrl: String
    public var hasHeaderRow: Bool?
    public var removeDuplicates: Bool?
    public var emailAddressColumn: Int?
    public var firstNameColumn: Int = 0
    public var lastNameColumn: Int = 0
    public var genderColumn: Int = 0
    public var ipAddressColumn: Int = 0
    public var allowPhase2: Bool?

    public init(fileName: String, returnUrl: String) {
        self.fileName = fileName
        self.returnUrl = returnUrl
    }
}

/// LIVE: `returnUrl` is required here too. See `ZBValidateS3FileOptions`.
public struct ZBScoreS3FileOptions {
    public var fileName: String
    public var returnUrl: String
    public var hasHeaderRow: Bool?
    public var removeDuplicates: Bool?
    public var emailAddressColumn: Int?

    public init(fileName: String, returnUrl: String) {
        self.fileName = fileName
        self.returnUrl = returnUrl
    }
}

public struct ZBS3ListFileEntry: Codable {
    public let name: String
    public let size: Int
    public let lastModified: String

    enum CodingKeys: String, CodingKey {
        case name
        case size
        case lastModified = "last_modified"
    }
}
