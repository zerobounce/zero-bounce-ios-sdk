//
//  ZBValidateOptions.swift
//  Zero Bounce iOS SDK
//

import Foundation

/// Optional query/body parameters for validate and validatebatch.
public struct ZBValidateOptions {
    /// Validation timeout in seconds (3–60 for single validate, 10–120 for batch).
    public var timeout: Int?
    /// Maps to activity_data.
    public var activityData: Bool?
    /// Maps to verify_plus.
    public var verifyPlus: Bool?
    /// When true, uses form-encoded POST for /validate.
    public var usePost: Bool

    public init(timeout: Int? = nil, activityData: Bool? = nil, verifyPlus: Bool? = nil, usePost: Bool = false) {
        self.timeout = timeout
        self.activityData = activityData
        self.verifyPlus = verifyPlus
        self.usePost = usePost
    }
}
