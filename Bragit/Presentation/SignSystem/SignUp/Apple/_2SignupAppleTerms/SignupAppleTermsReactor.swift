//
//  SignupAppleTermsReactor.swift
//  Bragit
//
//  Created by luca on 9/18/25.
//

import Foundation

import Dependencies
import ReactorKit
import RxFlow
import RxRelay
import RxSwift
import Supabase

final class SignupAppleTermsReactor: Reactor, Stepper {
  @Dependency(\.supabase) var supabase
  @LocalStorage(location: .nowUser) var nowUserId: String?

  let nickname: String
  let refreshToken: String?

  // MARK: - Reactor
  enum Action {
    case tapNext
    case tapBack
  }

  enum Mutation {
    // Define state mutations if needed later
  }

  struct State {
    // Define view state properties if needed later
  }

  let initialState: State = State()

  let steps = PublishRelay<Step>()

  init(nickname: String, refreshToken: String?) {
    self.nickname = nickname
    self.refreshToken = refreshToken
  }

  // MARK: - Mutate
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .tapNext:
      return Observable.create { [weak self] observer in
        Task {
          do {
            guard let self = self else {
              observer.onCompleted()
              return
            }

            struct InsertUserRow: Encodable {
              let id: String
              let nickname: String
              let provider: String
              let appleRefreshToken: String

              enum CodingKeys: String, CodingKey {
                case id
                case nickname
                case provider
                case appleRefreshToken = "apple_refresh_token"
              }
            }

            print("[SignupAppleTerms] Fetching session...")
            let session = try await self.supabase.auth.session
            let userId = session.user.id.uuidString
            print("[SignupAppleTerms] Got session. userId=\(userId)")

            let row = InsertUserRow(
              id: userId.lowercased(),
              nickname: self.nickname,
              provider: "apple",
              appleRefreshToken: self.refreshToken ?? ""
            )

            print("[SignupAppleTerms] Inserting User_Info row for id=\(userId.lowercased()) nickname=\(self.nickname)")
            _ = try await self.supabase
              .from("User_Info")
              .upsert(row, onConflict: "id")
              .execute()
            print("[SignupAppleTerms] Upsert success")

            self.nowUserId = userId
            UserDefaults.standard.set(userId, forKey: LocalStorageCase.nowUser.rawValue)
            self.steps.accept(AppStep.signupImageUpload)
            observer.onCompleted()
          } catch {
            print("[SignupAppleTermsReactor] Error inserting User_Info: \(error)")
            print("[SignupAppleTerms] Failure, popping to previous screen")
            // self?.steps.accept(AppStep.pop)
            observer.onCompleted()
          }
        }
        return Disposables.create()
      }
    case .tapBack:
      steps.accept(AppStep.pop)
      return .empty()
    }
  }

  // MARK: - Reduce
  func reduce(state: State, mutation: Mutation) -> State {}
}
