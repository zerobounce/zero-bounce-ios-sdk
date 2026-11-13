//
//  ZBValidateBatchResponse.swift
//  Zero Bounce iOS SDK
//
//  Created by Iliescu Andrei on 25.04.2023.
//  Copyright © 2023 ZeroBounce. All rights reserved.
//

import Foundation

public struct ZBValidateBatchResponse: Codable, Equatable {
    /// An Array of validated emails
    public let emailBatch: [ZBValidateResponse]
    
    /// An Array of errors encuontered, if any
    public let errors: [ZBValidateBatchErrorResponse]
    
    enum CodingKeys: String, CodingKey {
        case emailBatch = "email_batch"
        case errors
    }
}

extension ZBValidateBatchResponse {
    /// A null or missing list is empty (standard section 3), not a decode error.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        emailBatch = try container.decodeIfPresent([ZBValidateResponse].self, forKey: .emailBatch) ?? []
        errors = try container.decodeIfPresent([ZBValidateBatchErrorResponse].self, forKey: .errors) ?? []
    }
}

public struct ZBValidateBatchErrorResponse: Codable, Equatable {
    public let error: String
    public let emailAddress: String
    
    enum CodingKeys: String, CodingKey {
        case error
        case emailAddress = "email_address"
    }
}

extension ZBValidateBatchErrorResponse {
    /// A null `error` or `email_address` reads as "" (standard section 3).
    /// Declared in an extension so the memberwise initializer is kept.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        error = try container.decodeNullAsEmpty(String.self, forKey: .error, empty: "")
        emailAddress = try container.decodeNullAsEmpty(String.self, forKey: .emailAddress, empty: "")
    }
}
