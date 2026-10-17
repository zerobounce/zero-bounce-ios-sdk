//
//  ZBScoreEmailResponse.swift
//  Zero Bounce iOS SDK
//

import Foundation

/// Response for GET/POST /scoring (real-time AI scoring).
public struct ZBScoreEmailResponse: Codable, Equatable {
    public let email: String?
    public let score: Int?
}
