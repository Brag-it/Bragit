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
  func rxFollowUser(id: String) -> Completable
  func rxUnfollowUser(id: String) -> Completable
  func rxFetchFollowers() -> Observable<[String]>
  func rxhasNickName(nickName: String) -> Observable<Bool>
  func rxChangeNickName(nickName: String) -> Single<Void>
  func updateLastUploaded(userId: String, at date: Date) async throws
  func rxUpdateLastUploaded(userId: String, at date: Date) -> Observable<Void>
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

  func rxFollowUser(id: String) -> Completable {
    Completable.create { [weak self] observer in
      guard let self = self else {
        observer(.completed)
        return Disposables.create()
      }

      Task {
        do {
          try await self.followUser(id: id)
          observer(.completed)
        } catch {
          print(error)
          observer(.error(error))
        }
      }

      return Disposables.create()
    }
  }

  // 언팔로우 하기
  func unfollowUser(id: String) async throws {
    guard userId != nil else {
      print("⚠️ UserManager userId nil")
      return
    }

    try await client
      .from("Follow")
      .delete()
      .match(["user_id": userId!, "follow_id": id])
      .execute()
  }

  func rxUnfollowUser(id: String) -> Completable {
    Completable.create { [weak self] observer in
      guard let self = self else {
        observer(.completed)
        return Disposables.create()
      }

      Task {
        do {
          try await self.unfollowUser(id: id)
          observer(.completed)
        } catch {
          print(error)
          observer(.error(error))
        }
      }

      return Disposables.create()
    }
  }

  // 팔로워들 id 가져오기
  func rxFetchFollowers() -> Observable<[String]> {
    .create { [weak self] observer in
      guard self?.userId != nil else {
        print("⚠️ UserManager userId nil")
        return Disposables.create()
      }

      Task { [weak self] in
        do {
          guard let self = self else { return }
          let users: [FollowResponse] = try await self.client
            .from("Follow")
            .select()
            .eq("follow_id", value: userId)
            .execute()
            .value

          observer.onNext(users.map { $0.userId })
          observer.onCompleted()
        } catch {
          print(error)
          observer.onError(error)
        }
      }

      return Disposables.create()
    }
  }

  // 닉네임 확인
  func rxhasNickName(nickName: String) -> Observable<Bool> {
    .create { [weak self] observer in
      let task = Task { [weak self] in
        do {
          guard let self = self else {
            observer.onError(NSError(
              domain: "selfError",
              code: 500,
              userInfo: [NSLocalizedDescriptionKey: "self is nil"]))
            return Disposables.create()
          }

          let users: [User] = try await self.client
            .from("User_Info")
            .select()
            .eq("nickname", value: nickName)
            .execute()
            .value

          observer.onNext(users.isEmpty == false)
          observer.onCompleted()
        } catch {
          print(error)
          observer.onError(error)
        }
        return Disposables.create()
      }
      return Disposables.create(with: task.cancel)
    }
  }

  // 닉네임 변경
  func rxChangeNickName(nickName: String) -> Single<Void> {
    Single.create { [weak self] observer in
      guard let self = self, let userId = self.userId else {
        observer(.failure(
          NSError(
            domain: "UserManagerError",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "User not logged in"]
          )
        ))
        return Disposables.create()
      }
      Task { [weak self] in
        do {
          guard let self = self else { return }
          try await self.client
            .from("User_Info")
            .update(["nickname": nickName])
            .eq("id", value: userId)
            .execute()
          observer(.success(()))
        } catch {
          print(error)
          observer(.failure(error))
        }
      }

      return Disposables.create()
    }
  }

  // 마지막 업로드 시간을 갱신
  func updateLastUploaded(userId: String, at date: Date) async throws {
    do {
      _ = try await client
        .from("User_Info")
        .update(["latest_uploaded": date])
        .eq("id", value: userId)
        .execute()
    } catch {
      throw error
    }
  }

  func rxUpdateLastUploaded(userId: String, at date: Date) -> Observable<Void> {
    .create { [weak self] observer in
      guard let self else {
        observer.onCompleted()
        return Disposables.create()
      }
      Task {
        do {
          try await self.updateLastUploaded(userId: userId, at: date)
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

