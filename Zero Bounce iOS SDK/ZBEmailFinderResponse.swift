//
//  ZBEmailFinderResponse.swift
//  Zero Bounce iOS SDK
//
//  Created by Andreea Sinescu on 23.08.2023.
//  Copyright © 2023 ZeroBounce. All rights reserved.
//

import Foundation

public struct ZBEmailFinderResponse: Codable, Equatable {
    public let email: String
    public let emailConfidence: ZBEmailConfidence
    public let domain: String
    public let companyName: String
    public let didYouMean: String?
    public let failureReason: String?
    
    enum CodingKeys: String, CodingKey {
        case email
        case emailConfidence = "email_confidence"
        case domain
        case companyName = "company_name"
        case didYouMean = "did_you_mean"
        case failureReason = "failure_reason"
    }
}

extension ZBEmailFinderResponse {
    /// A null `email`, `email_confidence`, `domain` or `company_name` reads as
    /// the type's empty value (standard section 3). A missing key still fails,
    /// so a message-only body is an error, not an empty answer (standard E3).
    /// Declared in an extension so the memberwise initializer is kept.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        email = try container.decodeNullAsEmpty(String.self, forKey: .email, empty: "")
        emailConfidence = try container.decodeNullAsEmpty(ZBEmailConfidence.self, forKey: .emailConfidence, empty: ZBEmailConfidence.none)
        domain = try container.decodeNullAsEmpty(String.self, forKey: .domain, empty: "")
        companyName = try container.decodeNullAsEmpty(String.self, forKey: .companyName, empty: "")
        didYouMean = try container.decodeIfPresent(String.self, forKey: .didYouMean)
        failureReason = try container.decodeIfPresent(String.self, forKey: .failureReason)
    }
}
