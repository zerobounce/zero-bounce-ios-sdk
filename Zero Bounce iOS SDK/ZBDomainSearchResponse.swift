//
//  ZBDomainSearchResponse.swift
//  Zero Bounce iOS SDK
//
//  Created by Robert Manea on 03.10.2025.
//  Copyright © 2025 ZeroBounce. All rights reserved.
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

extension ZBDomainSearchResponse {
    /// A null or missing `other_domain_formats` is an empty list (standard
    /// section 3). Declared in an extension so the memberwise initializer is kept.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        domain = try container.decode(String.self, forKey: .domain)
        companyName = try container.decode(String.self, forKey: .companyName)
        format = try container.decode(String.self, forKey: .format)
        confidence = try container.decode(ZBConfidence.self, forKey: .confidence)
        didYouMean = try container.decodeIfPresent(String.self, forKey: .didYouMean)
        failureReason = try container.decodeIfPresent(String.self, forKey: .failureReason)
        otherDomainFormats = try container.decodeIfPresent([ZBDomainFormat].self, forKey: .otherDomainFormats) ?? []
    }
}
