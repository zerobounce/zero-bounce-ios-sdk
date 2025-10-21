//
//  ZBEmailFinderResponse.swift
//  Zero Bounce iOS SDK
//
//  Created by Andreea Sinescu on 23.08.2023.
//  Copyright © 2023 Mount Software. All rights reserved.
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
