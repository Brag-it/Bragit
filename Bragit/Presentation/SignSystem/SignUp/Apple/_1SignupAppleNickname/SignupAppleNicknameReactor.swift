//
//  SignupAppleNicknameReactor.swift
//  Bragit
//
//  Created by luca on 9/18/25.
//

import Dependencies
import ReactorKit
import RxFlow
import RxRelay
import RxSwift
import Supabase

final class SignupAppleNicknameReactor: Reactor, Stepper {
  // MARK: - Reactor
  enum Action {
    case tapBack
    case tapNext(String)
    case validateNickname(String)
  }

  enum Mutation {
    case setStatusText(String)
    case setStatusStyle(StatusStyle)
    case setNextEnabled(Bool)
  }

  enum StatusStyle {
    case none
    case loading
    case accept
    case reject
  }

  struct State {
    var statusText: String = " "
    var statusStyle: StatusStyle = .none
    var nextEnabled: Bool = false
  }

  let initialState: State

  @Dependency(\.supabase) var supabase

  // MARK: - Stepper
  let steps = PublishRelay<Step>()

  private let refreshToken: String?
  private var currentNickname: String?
  private var nicknameCheckTask: Task<Void, Never>?
  private var nicknameCheckGeneration: Int = 0

  // MARK: - Init
  init(refreshToken: String?) {
    self.refreshToken = refreshToken
    self.initialState = State()
  }

  // MARK: - Mutate
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .tapBack:
      steps.accept(AppStep.pop)
      return .empty()

    case .tapNext(let nickname):
      steps.accept(AppStep.signupAppleTerms(nickname: nickname, refreshToken: self.refreshToken))
      return .empty()

    case .validateNickname(let raw):
      let nickname = raw.trimmingCharacters(in: .whitespacesAndNewlines)

      if nickname.isEmpty {
        return .concat([
          .just(Mutation.setStatusText(" ")),
          .just(Mutation.setStatusStyle(.none)),
          .just(Mutation.setNextEnabled(false)),
        ])
      }

      // Regex validation: 2-8 characters, no spaces
      guard AppleInfoValidator.isValidNickname(nickname) else {
        return .concat([
          .just(Mutation.setStatusText("형식에 맞지 않는 닉네임입니다")),
          .just(Mutation.setStatusStyle(.reject)),
          .just(Mutation.setNextEnabled(false)),
        ])
      }

      // Loading state
      let start = Observable.concat([
        .just(Mutation.setStatusText("닉네임 확인 중...")),
        .just(Mutation.setStatusStyle(.loading)),
        .just(Mutation.setNextEnabled(false)),
      ])

      // Cancel previous check and increment generation (MailInfo style)
      nicknameCheckTask?.cancel()
      nicknameCheckGeneration &+= 1
      let currentGen = nicknameCheckGeneration

      // Supabase duplication check
      let check = Observable<Mutation>.create { [weak self] observer in
        guard let self = self else { return Disposables.create() }
        // Start a cancellable Task and store it (MailInfo style)
        let task = Task { [weak self] in
          guard let self = self else { return }
          do {
            struct Row: Decodable { let nickname: String }
            let rows: [Row] = try await self.supabase
              .from("User_Info")
              .select("nickname")
              .eq("nickname", value: nickname)
              .limit(1)
              .execute()
              .value

            // Ensure this result is still relevant
            guard !Task.isCancelled, currentGen == self.nicknameCheckGeneration else {
              observer.onCompleted()
              return
            }

            let isDuplicate = !rows.isEmpty
            if isDuplicate {
              observer.onNext(Mutation.setStatusText("이미 사용 중인 닉네임입니다"))
              observer.onNext(Mutation.setStatusStyle(.reject))
              observer.onNext(Mutation.setNextEnabled(false))
            } else {
              observer.onNext(Mutation.setStatusText("사용할 수 있는 닉네임입니다"))
              observer.onNext(Mutation.setStatusStyle(.accept))
              observer.onNext(Mutation.setNextEnabled(true))
              self.currentNickname = nickname
            }
            observer.onCompleted()
          } catch {
            // Ensure this error is still relevant
            guard !Task.isCancelled, currentGen == self.nicknameCheckGeneration else {
              observer.onCompleted()
              return
            }
            print("[Signup][Nickname] check failed: \(error)")
            observer.onNext(Mutation.setStatusText("닉네임 확인 실패"))
            observer.onNext(Mutation.setStatusStyle(.reject))
            observer.onNext(Mutation.setNextEnabled(false))
            observer.onCompleted()
          }
        }
        self.nicknameCheckTask = task
        return Disposables.create { task.cancel() }
      }

      return .concat([start, check])
    }
  }

  // MARK: - Reduce
  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    case .setStatusText(let text):
      newState.statusText = text
    case .setStatusStyle(let style):
      newState.statusStyle = style
    case .setNextEnabled(let enabled):
      newState.nextEnabled = enabled
    }
    return newState
  }
}
