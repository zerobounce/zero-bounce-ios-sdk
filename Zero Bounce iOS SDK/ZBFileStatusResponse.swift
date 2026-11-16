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

extension ZBFileStatusResponse {
    /// `message` is a string or a list of strings (joined with a line feed). A
    /// null `file_id` or `file_status` reads as "" (standard section 3). A
    /// present `success` that is not a real flag (a boolean, 0 or 1, or "true",
    /// "false", "0" or "1" in any case) throws; it does not read as false. A
    /// null or missing `success` reads as false.
    ///
    /// The body must carry one non-null known field: `file_status`, `file_id`,
    /// `file_name`, `upload_date`, `file_phase_2_status`, `complete_percentage`,
    /// `error_reason`, `return_url`, or a real `success` flag. `{"foo": 1}` and
    /// `{"": ""}` throw, so a call reports them as an API error with the HTTP
    /// status. `{"file_status": "Processing"}` and `{"success": true}` are
    /// results. Declared in an extension so the memberwise initializer is kept.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let flag = try container.decodeSuccessFlag(forKey: .success)
        let knownFields: [CodingKeys] = [
            .fileStatus, .fileId, .fileName, .uploadDate, .filePhase2Status,
            .completePercentage, .errorReason, .returnUrl,
        ]
        var hasKnownField = false
        for key in knownFields where container.contains(key) {
            if try container.decodeNil(forKey: key) == false {
                hasKnownField = true
                break
            }
        }
        guard flag != nil || hasKnownField else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "no file status field in the body"
            ))
        }
        success = flag ?? false
        message = try container.decodeFileMessage(forKey: .message)
        fileId = try container.decodeNullAsEmpty(String.self, forKey: .fileId, empty: "")
        fileName = try container.decodeIfPresent(String.self, forKey: .fileName)
        uploadDate = try container.decodeIfPresent(String.self, forKey: .uploadDate)
        fileStatus = try container.decodeNullAsEmpty(String.self, forKey: .fileStatus, empty: "")
        filePhase2Status = try container.decodeIfPresent(String.self, forKey: .filePhase2Status)
        completePercentage = try container.decodeIfPresent(String.self, forKey: .completePercentage)
        errorReason = try container.decodeIfPresent(String.self, forKey: .errorReason)
        returnUrl = try container.decodeIfPresent(String.self, forKey: .returnUrl)
    }
}
