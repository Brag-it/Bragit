//
//  LicenseReactor.swift
//  Bragit
//
//  Created by 이태윤 on 9/9/25.
//
import UIKit

import ReactorKit
import RxSwift
import RxFlow
import RxRelay

class LicenseReactor: Reactor, Stepper {
  var initialState: State
  let steps = PublishRelay<Step>()
  private let disposeBag = DisposeBag()

  // 사용자 액션 정의 (사용자의 의도)
  enum Action {
    case viewDidLoad
    case select(index: Int)
    case didTapBack
  }

  // 상태변경 이벤트 정의 (상태를 어떻게 바꿀 것인가)
  enum Mutation {
    case setItems([LicenseItem])
    case setSelected(LicenseItem?)
  }

  // View의 상태 정의 (현재 View의 상태값)
  struct State {
    var items: [LicenseItem] = []
    var selected: LicenseItem?
  }

  init() {
    self.initialState = State()
  }

  // Action이 들어왔을 때 어떤 Mutation으로 바뀔지 정의
  // 사용자 입력 → 상태 변화 신호로 변환
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .viewDidLoad:
      let items: [LicenseItem] = [
        .init(name: "RxSwift", licenseType: "MIT", bundleFileName: "LICENSE_RxSwift"),
        .init(name: "ReactorKit", licenseType: "MIT", bundleFileName: "LICENSE_ReactorKit"),
        .init(name: "SnapKit", licenseType: "MIT", bundleFileName: "LICENSE_SnapKit"),
        .init(name: "Then", licenseType: "MIT", bundleFileName: "LICENSE_Then"),
        .init(name: "Kingfisher", licenseType: "MIT", bundleFileName: "LICENSE_Kingfisher"),
        .init(name: "Lottie", licenseType: "Apache-2.0", bundleFileName: "LICENSE_Lottie"),
        .init(name: "Supabase iOS", licenseType: "Apache-2.0", bundleFileName: "LICENSE_Supabase"),
        .init(name: "Pretendard", licenseType: "OFL-1.1", bundleFileName: "LICENSE_Pretendard")
      ]
      return .just(.setItems(items))

    case let .select(index):
      guard index < currentState.items.count else { return .empty() }
      let item = currentState.items[index]
      steps.accept(AppStep.openSourceDetails(item))
      return .just(.setSelected(item))

    case .didTapBack:
      steps.accept(AppStep.pop)
      return .empty()
    }
  }

  // Mutation이 발생했을 때 상태(State)를 실제로 바꿈
  // 상태 변화 신호 → 실제 상태 반영
  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    case let .setItems(items):
      newState.items = items

    case let .setSelected(item):
      newState.selected = item
    }
    return newState
  }

  func transform(state: Observable<State>) -> Observable<State> {
    return state.observe(on: MainScheduler.instance)
  }
}
