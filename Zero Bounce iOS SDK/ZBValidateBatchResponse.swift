//
//  ZBValidateBatchResponse.swift
//  Zero Bounce iOS SDK
//
//  Created by Iliescu Andrei on 25.04.2023.
//  Copyright © 2023 Mount Software. All rights reserved.
//

import Foundation

public struct ZBValidateBatchResponse: Codable {
    let emailBatch: [ZBValidateResponse]
    let errors: [String]
    
    enum CodingKeys: String, CodingKey {
        case emailBatch = "email_batch"
        case errors
    }
}
