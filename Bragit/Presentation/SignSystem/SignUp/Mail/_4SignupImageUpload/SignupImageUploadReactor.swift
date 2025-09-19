//
//  SignupImageUploadReactor.swift
//  Bragit
//
//  Created by luca on 9/18/25.
//

import UIKit

import Dependencies
import ReactorKit
import RxCocoa
import RxFlow
import RxRelay
import RxSwift
import Storage
import Supabase

final class SignupImageUploadReactor: Reactor, Stepper {
  // MARK: - Reactor
  enum Action {
    case tapNext
    case tapLater
    case tapBack
    case pickedImageData(Data)
  }

  enum Mutation {
    case setLoading(Bool)
    case setError(String?)
    case setProfileURL(String?)
    case setImageData(Data?)
  }

  struct State {
    var isLoading: Bool = false
    var errorMessage: String?
    var profileURL: String?
    var imageData: Data?
  }

  let initialState: State
  let steps = PublishRelay<Step>()

  @Dependency(\.supabase) private var supabase
  @Dependency(\.authClient) private var authClient

  // MARK: - Init
  init() {
    self.initialState = State()
  }

  // MARK: - Mutate
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .tapBack:
      steps.accept(AppStep.pop)
      return .empty()
    case .tapLater:
      steps.accept(AppStep.signupTagSelect)
      return .empty()
    case .tapNext:
      guard currentState.imageData != nil else {
        return .just(.setError("사진을 선택해 주세요"))
      }
      return .concat([
        .just(.setLoading(true)),
        uploadAndSaveProfile()
          .catch { error in
            return .just(.setError("이미지 업로드 실패: \(error.localizedDescription)"))
          }
          .do { [weak self] mutation in
            guard let self else { return }
            if case .setProfileURL(let url) = mutation, url != nil {
              self.steps.accept(AppStep.signupTagSelect)
            }
          },
        .just(.setLoading(false)),
      ])
    case .pickedImageData(let data):
      print("🎨 사진 선택됨, 크기: \(data.count)")
      return .just(.setImageData(data))
    }
  }

  // MARK: - Reduce
  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    case .setLoading(let isLoading):
      newState.isLoading = isLoading
    case .setError(let message):
      newState.errorMessage = message
    case .setProfileURL(let url):
      newState.profileURL = url
    case .setImageData(let data):
      newState.imageData = data
    }
    return newState
  }

  // MARK: - Function
  func transform(state: Observable<State>) -> Observable<State> {
    state.observe(on: MainScheduler.instance)
  }

  private func uploadAndSaveProfile() -> Observable<Mutation> {
    Observable.create { [weak self] observer in
      guard let self = self, let imageData = self.currentState.imageData else {
        observer.onCompleted()
        return Disposables.create()
      }

      Task {
        do {
          let session = try await self.supabase.auth.session
          let userId = session.user.id
          let fileName = "\(userId.uuidString).jpg"
          let filePath = "profiles/\(fileName)"

          _ = try await self.supabase.storage
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
          let publicURL = try self.supabase.storage
            .from("profile-image")
            .getPublicURL(path: filePath)

          do {
            _ = try await self.supabase
              .from("User_Info")
              .update(["profile": publicURL.absoluteString])
              .eq("id", value: userId.uuidString)
              .execute()
          } catch {
            observer.onNext(.setError("프로필 url 저장 실패: \(error.localizedDescription)"))
            observer.onCompleted()
            return
          }
          observer.onNext(.setProfileURL(publicURL.absoluteString))
          observer.onCompleted()
        } catch {
          observer.onNext(.setError("업로드 오류 발생: \(error.localizedDescription)"))
          observer.onCompleted()
        }
      }
      return Disposables.create()
    }
  }
}
