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
    /// A null or missing `file_id` is an empty id, as in the other SDKs
    /// (standard section 3: null reads as the type's empty value). Declared in
    /// an extension so the memberwise initializer is kept.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decodeIfPresent(Bool.self, forKey: .success)
        message = try container.decodeFileMessage(forKey: .message)
        fileName = try container.decodeNullAsEmpty(String.self, forKey: .fileName, empty: "")
        fileId = try container.decodeIfPresent(String.self, forKey: .fileId) ?? ""
    }
}

extension KeyedDecodingContainer {
    /// A field the typed model does not make optional: a null or a missing key
    /// reads as `empty` (standard section 3 and B, never an error). A message-only
    /// body is recognised by its keys before decoding (ZBError.messageOnlyFailure),
    /// not by a failed decode.
    func decodeNullAsEmpty<T: Decodable>(_ type: T.Type, forKey key: Key, empty: T) throws -> T {
        if !contains(key) {
            return empty
        }
        if try decodeNil(forKey: key) {
            return empty
        }
        return try decode(T.self, forKey: key)
    }

    /// A file-job `message` (send, delete and file status answers): one string,
    /// or a list of strings joined with a line feed; null or missing reads nil.
    func decodeFileMessage(forKey key: Key) throws -> String? {
        if let lines = try? decode([String].self, forKey: key) {
            return lines.joined(separator: "\n")
        }
        return try decodeIfPresent(String.self, forKey: key)
    }
}
