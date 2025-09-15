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
    case tapBack
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
    case .tapBack:
      steps.accept(AppStep.pop)
      return .empty()
    case .tapNext:
      print("[REACTOR] Action .tapNext received")
      if currentState.imageData != nil {
        print("[REACTOR] imageData exists: \(currentState.imageData!.count) bytes")
        return .concat([
          .just(.setLoading(true)),
          uploadProfileImage()
            .catch { error in
              print("[REACTOR] Upload failed: \(error)")
              return .just(.setError("이미지 업로드 실패: \(error.localizedDescription)"))
            }
            .do { [weak self] mutation in
              print("[REACTOR] mutation upload: \(mutation)")
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
        print("[REACITOR] 사진 데이터가 없음")
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

      print("[REACTOR] Starting task on thread: \(Thread.isMainThread ? "main" : "background") bytes")

      Task {
        do {
          print("[UPLOAD] Requesting auth session...")
          let session = try await self.supabase.auth.session
          print("[UPLOAD] Got session. userId=\(session.user.id)")
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
                upsert: true
              )
            )

          print("[DEBUG] 리스폰스: \(uploadResponse)")
          let publicURL = try self.supabase.storage
            .from("profile-image")
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
}
