//
//  ZBDomainSearchResponse.swift
//  Zero Bounce iOS SDK
//
//  Created by Robert Manea on 03.10.2025.
//  Copyright © 2025 Mount Software. All rights reserved.
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

public struct ZBDomainSearchResponse: Codable, Equatable {
    public let domain: String
    public let companyName: String
    public let format: String
    public let confidence: ZBConfidence
    public let didYouMean: String?
    public let failureReason: String?
    public var otherDomainFormats: [ZBDomainFormat]
    
    enum CodingKeys: String, CodingKey {
        case domain
        case companyName = "company_name"
        case format
        case confidence
        case didYouMean = "did_you_mean"
        case failureReason = "failure_reason"
        case otherDomainFormats = "other_domain_formats"
    }
}
