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

public struct ZBValidateS3FileOptions {
    public var fileName: String
    public var hasHeaderRow: Bool?
    public var removeDuplicates: Bool?
    public var removeDuplicate: Bool?
    public var emailAddressColumn: Int?
    public var returnUrl: String?
    public var firstNameColumn: Int = 0
    public var lastNameColumn: Int = 0
    public var genderColumn: Int = 0
    public var ipAddressColumn: Int = 0
    public var allowPhase2: Bool?

    public init(fileName: String) {
        self.fileName = fileName
    }
}

public struct ZBScoreS3FileOptions {
    public var fileName: String
    public var hasHeaderRow: Bool?
    public var removeDuplicates: Bool?
    public var removeDuplicate: Bool?
    public var emailAddressColumn: Int?

    public init(fileName: String) {
        self.fileName = fileName
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
