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
import Functions

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
  func rxGetProfileURL() -> Observable<String>
  func rxProfileImageUpload(image: Data) -> Observable<Void>
  func rxUpdateUserProfileImage(imageURLstring: String) -> Single<Void>
  func rxCancelAccount() -> Single<Void>
  func rxFetchFollowingCount(userId: String) -> Observable<Int>
  func rxFetchFollowerCount(userId: String) -> Observable<Int>
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

  // 프로필 사진 업로드
  func rxProfileImageUpload(image: Data) -> Observable<Void> {
    Observable.create { [weak self] observer in
      guard let self = self else {
        observer.onCompleted()
        return Disposables.create()
      }
      print("[REACTOR] Starting task on thread: \(Thread.isMainThread ? "main" : "background") bytes")
      Task {
        do {
          print("[UPLOAD] Requesting auth session...")
          let session = try await self.client.auth.session
          print("[UPLOAD] Got session. userId=\(session.user.id)")
          let userId = session.user.id
          print("[DEBUG] 유저 아이디: \(userId)")

          let fileName = "\(userId.uuidString).jpg"  // 파일 이름
          let filePath = "profiles/\(fileName)"  // 'profile-image/profiles/파일.jpg'(버킷/폴더/파일)
          print("[DEBUG] 파일 경로: \(filePath)")

          print("[DEBUG] 버킷에 업로드 중")
          _ = try await self.client.storage
            .from("profile-image")
            .upload(
              filePath,
              data: image,
              options: FileOptions(
                cacheControl: "3600",
                contentType: "image/jpeg",
                upsert: true
              )
            )
          observer.onNext(())
          observer.onCompleted()
        } catch {
          print("[ERROR] Image upload error: \(error)")
          print("[ERROR] 에러 타입: \(type(of: error))")
          if let storageError = error as? StorageError {
            print("[ERROR] 스토리지 에러: \(storageError)")
          }
          observer.onError(error)
        }
      }
      return Disposables.create()
    }
  }

  // 프로필 사진 URL 가져오기
  func rxGetProfileURL() -> Observable<String> {
    Observable.create { [weak self] observer in
      guard let self = self else {
        observer.onCompleted()
        return Disposables.create()
      }
      print("[REACTOR] Starting task on thread: \(Thread.isMainThread ? "main" : "background") bytes")
      Task {
        do {
          print("[UPLOAD] Requesting auth session...")
          let session = try await self.client.auth.session
          print("[UPLOAD] Got session. userId=\(session.user.id)")
          let userId = session.user.id
          print("[DEBUG] 유저 아이디: \(userId)")

          let fileName = "\(userId.uuidString).jpg"  // 파일 이름
          let filePath = "profiles/\(fileName)"  // 'profile-image/profiles/파일.jpg'(버킷/폴더/파일)

          let publicURL = try self.client.storage
            .from("profile-image")
            .getPublicURL(path: filePath)

          print("[DEBUG] URL: \(publicURL.absoluteString)")
          observer.onNext(publicURL.absoluteString)
          observer.onCompleted()

        } catch {
          print("[ERROR] Image upload error: \(error)")
          print("[ERROR] 에러 타입: \(type(of: error))")
          if let storageError = error as? StorageError {
            print("[ERROR] 스토리지 에러: \(storageError)")
          }
          observer.onCompleted()
        }
      }
      return Disposables.create()
    }
  }

  // 유저 프로필 업데이트
  func rxUpdateUserProfileImage(imageURLstring: String) -> Single<Void> {
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
            .update(["profile": imageURLstring])
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

  // 탈퇴하기
  func rxCancelAccount() -> Single<Void> {
    
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

      Task {
        do {
          try await self.client
            .from("User_Info")
            .delete()
            .eq("id", value: userId)
            .execute()

          try await self.client
            .functions
            .invoke(
              "delete-user",
              options: FunctionInvokeOptions(
                body: ["userId": userId.lowercased()]
              )
            )
          observer(.success(()))
        } catch {
          print(error)
          observer(.failure(error))
        }
      }

      return Disposables.create()
    }
  }

  // 특정 유저의 팔로잉 수 가져오기
  func rxFetchFollowingCount(userId: String) -> Observable<Int> {
    .create { [weak self] observer in
      Task { [weak self] in
        do {
          guard let self = self else { return }
          let count = try await self.client
            .from("Follow")
            .select("*", head: true, count: .exact)
            .eq("user_id", value: userId)
            .execute()
            .count
          
          observer.onNext(count ?? 0)
          observer.onCompleted()
        } catch {
          print(error)
          observer.onError(error)
        }
      }
      
      return Disposables.create()
    }
  }

  // 특정 유저의 팔로워 수 가져오기
  func rxFetchFollowerCount(userId: String) -> Observable<Int> {
    .create { [weak self] observer in
      Task { [weak self] in
        do {
          guard let self = self else { return }
          let count = try await self.client
            .from("Follow")
            .select("*", head: true, count: .exact)
            .eq("follow_id", value: userId)
            .execute()
            .count

          observer.onNext(count ?? 0)
          observer.onCompleted()
        } catch {
          print(error)
          observer.onError(error)
        }
      }
      
      return Disposables.create()
    }
  }
}
