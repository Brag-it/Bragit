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
  func rxBlockUser(blockId: String) -> Observable<Void>
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

  struct BlockData: Codable {
    let blockId: String
    let userId: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
      case blockId = "block_id"
      case userId = "user_id"
      case createdAt = "created_at"
    }

    init(blockId: String, userId: String, createdAt: Date) {
      self.blockId = blockId
      self.userId = userId
      self.createdAt = createdAt
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

  // 유저 차단하기
  func rxBlockUser(blockId: String) -> Observable<Void> {
    .create { [weak self] observer in
      guard let self = self, let userId = userId else {
        observer.onCompleted()
        return Disposables.create()
      }

      Task {
        do {
          let blockInfo = BlockData(blockId: blockId, userId: userId, createdAt: Date())
          try await self.client
            .from("Block")
            .insert(blockInfo, returning: .representation)
            .execute()
          observer.onNext(())
          observer.onCompleted()
        } catch {
          observer.onError(error)
        }
      }

      return Disposables.create()
    }
  }
}
