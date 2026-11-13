//
//  ZBSendFileResponse.swift
//  Zero Bounce iOS SDK
//
//  Created by ZeroBounce on 09/07/2019.
//  Copyright © 2019 ZeroBounce. All rights reserved.
//

import Foundation

public struct ZBSendFileResponse: Codable, Equatable {
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

extension ZBSendFileResponse {
    /// `message` may be one string or a list of strings (a failed upload);
    /// a list is joined with a line feed. A null or missing `file_id` is an
    /// empty id, as in the other SDKs (standard section 3: null reads as the
    /// type's empty value). Declared in an extension so the memberwise
    /// initializer is kept.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decodeIfPresent(Bool.self, forKey: .success)
        if let lines = try? container.decode([String].self, forKey: .message) {
            message = lines.joined(separator: "\n")
        } else {
            message = try container.decodeIfPresent(String.self, forKey: .message)
        }
        fileName = try container.decode(String.self, forKey: .fileName)
        fileId = try container.decodeIfPresent(String.self, forKey: .fileId) ?? ""
    }
}
