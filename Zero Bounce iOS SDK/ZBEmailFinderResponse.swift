//
//  ZBEmailFinderResponse.swift
//  Zero Bounce iOS SDK
//
//  Created by Andreea Sinescu on 23.08.2023.
//  Copyright © 2023 Mount Software. All rights reserved.
//

import Foundation

public struct ZBDomainFormat: Codable, Equatable {
    var format: String
    var confidence: ZBConfidence

    enum CodingKeys: String, CodingKey {
        case format
        case confidence
    }
}

public struct ZBEmailFinderResponse: Codable, Equatable {
    public let email: String
    public let domain: String
    public let format: String
    public let status: ZBValidateStatus
    public let subStatus: ZBValidateSubStatus?
    public let confidence: ZBConfidence
    public let didYouMean: String?
    public let failureReason: String?
    public var otherDomainFormats: [ZBDomainFormat]
    
    enum CodingKeys: String, CodingKey {
        case email
        case domain
        case format
        case status
        case subStatus = "sub_status"
        case confidence
        case didYouMean = "did_you_mean"
        case failureReason = "failure_reason"
        case otherDomainFormats = "other_domain_formats"
    }
}
