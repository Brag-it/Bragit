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
  func rxFetchFollowUsers() -> Observable<[String]>
  func fetchUsersBy(ids: [String]) async throws -> [User]
  func rxfetchUsersBy(ids: [String]) -> Observable<[User]>
  func followUser(id: String) async throws
  func unfollowUser(id: String) async throws
}

class UserManager: UserManagerProtocol {
  @Dependency(\.supabase) var client
  @LocalStorage(location: .nowUser) var userId: String?

  struct FollowResponse: Codable {
    let userId: String
    let followId: String

    enum CodingKeys: String, CodingKey {
      case followId = "follow_id"
      case userId = "user_id"
    }
  }
  // ID들로 유저정보 가져오기
  func fetchUsersBy(ids: [String]) async throws -> [User] {
    let users: [User] = try await client
      .from("User_Info")
      .select()
      .in("id", values: ids)
      .order("latest_uploaded", ascending: false)
      .execute()
      .value

    return users
  }

  func rxfetchUsersBy(ids: [String]) -> Observable<[User]> {
    .create { [weak self] observer in
      guard let self = self else {
        observer.onCompleted()
        return Disposables.create()
      }

      Task {
        do {
          let users = try await self.fetchUsersBy(ids: ids)
          observer.onNext(users)
          observer.onCompleted()
        } catch {
          print(error)
          observer.onError(error)
        }
      }

      return Disposables.create()
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
      .select()
      .eq("user_id", value: userId)
      .execute()
      .value

    return users.map { $0.followId }
  }

  func rxFetchFollowUsers() -> Observable<[String]> {
    .create { [weak self] observer in
      guard let self = self else {
        observer.onCompleted()
        return Disposables.create()
      }

      Task {
        do {
          let users = try await self.fetchFollowUsers()
          observer.onNext(users)
          observer.onCompleted()
        } catch {
          print(error)
          observer.onError(error)
        }
      }

      return Disposables.create()
    }
  }

  // 팔로우 하기
  func followUser(id: String) async throws {
    guard userId != nil else {
      print("⚠️ UserManager userId nil")
      return
    }

    try await client
      .from("Follow")
      .insert(FollowResponse(userId: userId!, followId: id))
      .execute()
  }

  // 언팔로우 하기
  func unfollowUser(id: String) async throws {
    guard userId != nil else {
      print("⚠️ UserManager userId nil")
      return
    }
    print("me \(userId!)")
    print("unfollowUser \(id)")
    try await client
      .from("Follow")
      .delete()
      .match(["user_id": userId!, "follow_id": id])
      .execute()
  }
}
