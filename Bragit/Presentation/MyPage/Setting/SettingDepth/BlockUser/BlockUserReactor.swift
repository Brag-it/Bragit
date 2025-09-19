//
//  BlockUserReactor.swift
//  Bragit
//
//  Created by seongjun cho on 9/18/25.
//

import ReactorKit
import RxSwift
import RxFlow
import RxRelay
import Then
import Dependencies

class BlockUserReactor: Reactor, Stepper {
  var initialState: State
  let steps = PublishRelay<Step>()
  @Dependency(\.blockManager) var blockManager
  @Dependency(\.userManager) var userManager

  private let disposeBag = DisposeBag()
  // 사용자 액션 정의 (사용자의 의도)
  enum Action {
    case backButtonTap
    case blockButtonTap(User)
    case userDidTap(User)
    case dataLoad
  }

  // 상태변경 이벤트 정의 (상태를 어떻게 바꿀 것인가)
  enum Mutation {
    case setUsers([User])
  }

  // View의 상태 정의 (현재 View의 상태값)
  struct State: Then {
    var users: [User] = []
  }

  init() {
    self.initialState = State()
  }

  // Action이 들어왔을 때 어떤 Mutation으로 바뀔지 정의
  // 사용자 입력 → 상태 변화 신호로 변환
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .backButtonTap:
      steps.accept(AppStep.dismiss)
      return .empty()
    case .blockButtonTap(let user):
      @LocalStorage(location: .blockUser) var blockUser: [String]?
      @LocalStorage(location: .followUser) var followUser: [String]?

      if blockUser?.contains(user.id) == true {
        return blockManager.rxUnBlockUser(blockId: user.id)
          .flatMap { _ -> Observable<Mutation> in
            blockUser = blockUser?.filter { $0 != user.id }
            return .empty()
          }
      } else {
        blockUser = (blockUser ?? []) + [user.id]
        return blockManager.rxBlockUser(blockId: user.id)
          .flatMap { _ -> Observable<Mutation> in
            blockUser = (blockUser ?? []) + [user.id]
            followUser = followUser?.filter { $0 != user.id }
            return .empty()
          }
      }
    case .userDidTap(let user):
      steps.accept(AppStep.userProfile(user: user))
      return .empty()
    case .dataLoad:
      @LocalStorage(location: .blockUser) var blockUsers: [String]?
      return userManager.rxfetchUsersBy(ids: blockUsers ?? [])
        .map { .setUsers($0) }
    }
  }

  // Mutation이 발생했을 때 상태(State)를 실제로 바꿈
  // 상태 변화 신호 → 실제 상태 반영
  func reduce(state: State, mutation: Mutation) -> State {
    switch mutation {
    case .setUsers(let user):
      return state.with {
        $0.users = user
      }
    }
  }

  func transform(state: Observable<State>) -> Observable<State> {
    return state.observe(on: MainScheduler.instance)
  }
}
