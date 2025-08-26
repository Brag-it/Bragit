//
//  BlockManager.swift
//  Bragit
//
//  Created by seongjun cho on 8/25/25.
//

import Foundation

import Supabase
import RxSwift
import Dependencies

protocol BlockManagerProtocol {
  func fetchMyBlockUsers() async throws -> [String]
}

class BlockManager: BlockManagerProtocol {
  @Dependency(\.supabase) var client
  @LocalStorage(location: .nowUser) var userId: String?

  struct BlockResponse: Decodable {
    let blockId: String

    enum CodingKeys: String, CodingKey {
      case blockId = "block_id"
    }
  }

  // 블록한 유저 ID 가져오기
  func fetchMyBlockUsers() async throws -> [String] {

    guard userId != nil else {
      print("⚠️ BlockManager userId nil")
      return [String]()
    }

    let users: [BlockResponse] = try await client
      .from("Block")
      .select("block_id")
      .eq("user_id", value: userId)
      .execute()
      .value

    return users.map { $0.blockId }
  }
}
