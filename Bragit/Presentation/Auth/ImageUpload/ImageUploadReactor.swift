//
//  ImageUploadReactor.swift
//  Bragit
//
//  Created by luca on 8/31/25.
//

import Foundation

import Dependencies
import ReactorKit
import RxCocoa
import RxFlow
import RxRelay
import RxSwift
import Storage
import Supabase

final class ImageUploadReactor: Reactor, Stepper {
  enum Action {
    case tapNext
    case tapLater
    case pickedImageData(Data)
  }

  enum Mutation {
    case setLoading(Bool)
    case setError(String?)
    //    case setRegistrationComplete(Bool)
    case setProfileURL(String?)
    case setImageData(Data?)
  }

  struct State {
    var isLoading: Bool = false
    var errorMessage: String?
    var profileURL: String?
    var imageData: Data?
  }

  let initialState = State()
  let steps = PublishRelay<Step>()
  private let userInfo: UserRegistrationInfo

  @Dependency(\.supabase) private var supabase
  @Dependency(\.authClient) private var authClient

  init(userInfo: UserRegistrationInfo) {
    self.userInfo = userInfo
  }

  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .tapNext:
      if currentState.imageData != nil {
        print("[DEBUG] 사진 데이터 있음, 크기: \(currentState.imageData!.count) bytes")
        return .concat([
          .just(.setLoading(true)),
          uploadProfileImage()
            .catch { error in
              print("[ERROR] 업로드 실패: \(error)")
              return .just(.setError("이미지 업로드 실패: \(error.localizedDescription)"))
            }
            .do { [weak self] mutation in
              guard let self else { return }
              switch mutation {
              case .setProfileURL(let url):
                self.steps.accept(AppStep.signSelectTag(profileURL: url))
              default:
                break
              }
            },
          .just(.setLoading(false))
        ])
      } else {
        print("[DEBUG] 사진 데이터가 없음")
        self.steps.accept(AppStep.signSelectTag(profileURL: nil))
        return .empty()
      }

    case .tapLater:
      self.steps.accept(AppStep.signSelectTag(profileURL: nil))
      return .empty()

    case .pickedImageData(let data):
      print("[DEBUG] 사진 선택됨, 크기: \(data.count) bytes")
      return .just(.setImageData(data))
    }
  }

  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    case .setLoading(let isLoading):
      newState.isLoading = isLoading
    case .setError(let message):
      newState.errorMessage = message
    //    case .setRegistrationComplete:
    //      break
    case .setProfileURL(let url):
      newState.profileURL = url
    case .setImageData(let data):
      newState.imageData = data
    }
    return newState
  }

  func transform(state: Observable<State>) -> Observable<State> {
    state.observe(on: MainScheduler.instance)
  }

  // Supabase 스토리지에 사진 저장
  private func uploadProfileImage() -> Observable<Mutation> {
    Observable.create { [weak self] observer in
      guard let self = self,
        let imageData = self.currentState.imageData
      else {
        observer.onCompleted()
        return Disposables.create()
      }

      print("[DEBUG] 이미지 업로드, 크기: \(imageData.count) bytes")

      Task {
        do {
          let session = try await self.supabase.auth.session
          let userId = session.user.id
          print("[DEBUG] 유저 아이디: \(userId)")

          let fileName = "\(userId.uuidString).jpg"  // 파일 이름
          let filePath = "profiles/\(fileName)"  // 'profile-image/profiles/파일.jpg'(버킷/폴더/파일)
          print("[DEBUG] 파일 경로: \(filePath)")

          print("[DEBUG] 버킷에 업로드 중")
          let uploadResponse = try await self.supabase.storage
            .from("profile-image")
            .upload(
              filePath,
              data: imageData,
              options: FileOptions(
                cacheControl: "3600",
                contentType: "image/jpeg",
                upsert: false
              )
            )

          print("[DEBUG] 리스폰스: \(uploadResponse)")
          let publicURL = try self.supabase.storage
            .from("profile-images")
            .getPublicURL(path: filePath)

          print("[DEBUG] URL: \(publicURL.absoluteString)")
          observer.onNext(.setProfileURL(publicURL.absoluteString))
          observer.onCompleted()
        } catch {
          print("[ERROR] Image upload error: \(error)")
          print("[ERROR] 에러 타입: \(type(of: error))")
          if let storageError = error as? StorageError {
            print("[ERROR] 스토리지 에러: \(storageError)")
          }
          observer.onNext(.setError("업로드 중 오류 발생"))
          observer.onCompleted()
        }
      }
      return Disposables.create()
    }
  }

  //  private func registerUser() -> Observable<Mutation> {
  //    Observable.create { [weak self] observer in
  //      guard let self else {
  //        observer.onCompleted()
  //        return Disposables.create()
  //      }
  //      Task {
  //        do {
  //          observer.onNext(.setLoading(true))
  //          let session = try await self.supabase.auth.session
  //          let userId = session.user.id
  //          let profileURL = self.currentState.profileURL
  //          print("[DEBUG] 사진 유무: \(profileURL ?? "nil")")
  //
  //          let userInfo = UserInfo(
  //            id: userId,
  //            nickname: self.userInfo.nickname,
  //            profile: profileURL,
  //            provider: self.userInfo.isAppleLogin ? "apple" : "mail",
  //            signDate: Date(),
  //            latestUploaded: nil
  //          )
  //
  //          print("[DEBUG] 디비에 유저 정보 저장")
  //          try await self.saveUserInfo(userInfo)
  //          print("[DEBUG] 유저 정보 저장 완료")
  //
  //          observer.onNext(.setRegistrationComplete(true))
  //          observer.onNext(.setLoading(false))
  //          observer.onCompleted()
  //
  //          await MainActor.run { self.steps.accept(AppStep.home) }
  //        } catch {
  //          print("[ERROR] Registration error: \(error)")
  //          observer.onNext(.setError("회원가입 중 오류가 발생했습니다"))
  //          observer.onNext(.setLoading(false))
  //          observer.onCompleted()
  //        }
  //      }
  //      return Disposables.create()
  //    }
  //  }
  //
  //  private func saveUserInfo(_ userInfo: UserInfo) async throws {
  //    _ =
  //      try await supabase
  //      .from("User_Info")
  //      .insert(userInfo)
  //      .execute()
  //  }
  //}

  //struct UserInfo: Codable {
  //  let id: UUID
  //  let nickname: String
  //  let profile: String?
  //  let provider: String
  //  let signDate: Date
  //  let latestUploaded: Date?
  //
  //  enum CodingKeys: String, CodingKey {
  //    case id
  //    case nickname
  //    case profile
  //    case provider
  //    case signDate = "sign_date"
  //    case latestUploaded = "latest_uploaded"
  //  }
}
