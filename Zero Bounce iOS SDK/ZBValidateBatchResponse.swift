//
//  ZBValidateBatchResponse.swift
//  Zero Bounce iOS SDK
//
//  Created by Iliescu Andrei on 25.04.2023.
//  Copyright © 2023 Mount Software. All rights reserved.
//

import Foundation

public struct ZBValidateBatchResponse: Codable, Equatable {
    
    /// An Array of validated emails
    let emailBatch: [ZBValidateResponse]
    
    /// An Array of errors encuontered, if any
    let errors: [ZBValidateBatchErrorResponse]
    
    enum CodingKeys: String, CodingKey {
        case emailBatch = "email_batch"
        case errors
    }
}

public struct ZBValidateBatchErrorResponse: Codable, Equatable {
    let error: String
    let emailAddress: String
    
    enum CodingKeys: String, CodingKey {
        case error
        case emailAddress = "email_address"
    }
}
