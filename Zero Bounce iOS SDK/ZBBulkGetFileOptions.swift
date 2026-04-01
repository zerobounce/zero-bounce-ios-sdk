//
//  ZBBulkGetFileOptions.swift
//  Zero Bounce iOS SDK
//

import Foundation

/// Values for bulk `getfile` `download_type` (validation and scoring).
public enum ZBDownloadType: String {
    case phase1
    case phase2
    case combined

    public var queryValue: String {
        switch self {
        case .phase1: return "phase_1"
        case .phase2: return "phase_2"
        case .combined: return "combined"
        }
    }
}

/// Optional query parameters for bulk `getfile`.
/// `activityData` applies to validation bulk only; it is ignored for `scoringGetFile`.
public struct ZBGetFileOptions {
    public var downloadType: ZBDownloadType?
    public var activityData: Bool?

    public init(downloadType: ZBDownloadType? = nil, activityData: Bool? = nil) {
        self.downloadType = downloadType
        self.activityData = activityData
    }
}
