//
//  UserManager.swift
//  Bragit
//
//  Created by seongjun cho on 8/26/25.
//

import Foundation

import Supabase
import RxSwift
import Dependencies

protocol UserManagerProtocol {
  func fetchFollowUsers() async throws -> [String]
}

class UserManager: UserManagerProtocol {
  @Dependency(\.supabase) var client
  @LocalStorage(location: .nowUser) var userId: String?

  struct FollowResponse: Decodable {
    let followId: String

    enum CodingKeys: String, CodingKey {
      case followId = "follow_id"
    }
  }

  // 팔로우한 유저 ID 가져오기
  func fetchFollowUsers() async throws -> [String] {

    guard userId != nil else {
      print("⚠️ UserManager userId nil")
      return [String]()
    }

    let users: [FollowResponse] = try await client
      .from("Follow")
      .select("follow_id")
      .eq("user_id", value: userId)
      .execute()
      .value

    return users.map { $0.followId }
  }
}
