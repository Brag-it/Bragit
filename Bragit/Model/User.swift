//
//  User.swift
//  Bragit
//
//  Created by seongjun cho on 8/28/25.
//

import Foundation

struct User: Codable, Hashable {
  let id: String
  let nickname: String?
  let profile: String?
  let provider: String
  let signDate: Date?
  let latestUploaded: Date?
  let refreshToken: String?

  enum CodingKeys: String, CodingKey {
    case id
    case nickname
    case profile
    case provider
    case signDate = "sign_date"
    case latestUploaded = "latest_uploaded"
    case refreshToken = "apple_refresh_token"
  }
}
