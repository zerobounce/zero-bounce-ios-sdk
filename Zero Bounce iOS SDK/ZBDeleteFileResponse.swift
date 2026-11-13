//
//  ZBDeleteFileResponse.swift
//  Zero Bounce iOS SDK
//
//  Created by ZeroBounce on 09/07/2019.
//  Copyright © 2019 ZeroBounce. All rights reserved.
//

import Foundation

public struct ZBDeleteFileResponse: Codable, Equatable {
    public let success: Bool?
    public let message: String?
    public let fileName: String
    public let fileId: String
    
    enum CodingKeys: String, CodingKey {
        case success
        case message
        case fileName = "file_name"
        case fileId = "file_id"
    }
}

extension ZBDeleteFileResponse {
    /// `message` is a string or a list of strings (joined with a line feed);
    /// a null `file_name` or `file_id` reads as "" (standard section 3).
    /// Declared in an extension so the memberwise initializer is kept.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decodeIfPresent(Bool.self, forKey: .success)
        message = try container.decodeFileMessage(forKey: .message)
        fileName = try container.decodeNullAsEmpty(String.self, forKey: .fileName, empty: "")
        fileId = try container.decodeNullAsEmpty(String.self, forKey: .fileId, empty: "")
    }
}
