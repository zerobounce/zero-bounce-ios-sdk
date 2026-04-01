//
//  ZBFileStatusResponse.swift
//  Zero Bounce iOS SDK
//
//  Created by ZeroBounce on 09/07/2019.
//  Copyright © 2019 ZeroBounce. All rights reserved.
//

import Foundation

public struct ZBFileStatusResponse : Codable, Equatable {
    public let success: Bool
    public let message: String?
    public let fileId: String
    public let fileName: String?
    public let uploadDate: String?
    public let fileStatus: String
    /// Present when the bulk API returns phase 2 state (e.g. after optional catch-all processing).
    public let filePhase2Status: String?
    public let completePercentage: String?
    public let errorReason: String?
    public let returnUrl: String?
    
    enum CodingKeys : String, CodingKey {
        case success
        case message
        case fileId = "file_id"
        case fileName = "file_name"
        case uploadDate = "upload_date"
        case fileStatus = "file_status"
        case filePhase2Status = "file_phase_2_status"
        case completePercentage = "complete_percentage"
        case errorReason = "error_reason"
        case returnUrl = "return_url"
    }
}
