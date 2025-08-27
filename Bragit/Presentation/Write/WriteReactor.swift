//
//  WriteReactor.swift
//  Bragit
//
//  Created by 이태윤 on 8/22/25.
//
import UIKit

import ReactorKit
import RxSwift
import RxFlow
import RxRelay

class WriteReactor: Reactor, Stepper {
  var initialState: State
  let steps = PublishRelay<Step>()
  private let disposeBag = DisposeBag()

  // 사용자 액션 정의 (사용자의 의도)
  enum Action {
    case tapDismiss
    case doneButtonTapped
    case titleDidChange(String)
    case contentDidChange(NSAttributedString)
    case boldButtonTapped
    case imageButtonTapped
    case imageDidPick(UIImage)
  }

  // 상태변경 이벤트 정의 (상태를 어떻게 바꿀 것인가)
  enum Mutation {
    case setTitle(String)
    case setContent(NSAttributedString)
    case setBoldToggled(Bool)
    case setImageToInsert(UIImage?)
    case setShouldShowImagePicker(Bool)
  }

  // View의 상태 정의 (현재 View의 상태값)
  struct State {
    var title: String = ""
    var content: NSAttributedString = NSAttributedString(string: "")
    var canPost: Bool = false

    // 일회성 이벤트를 Bool 값으로 관리합니다.
    var shouldToggleBold: Bool = false
    var imageToInsert: UIImage? = nil
    var shouldShowImagePicker: Bool = false
  }

  init() {
    self.initialState = State()
  }

  // Action이 들어왔을 때 어떤 Mutation으로 바뀔지 정의
  // 사용자 입력 → 상태 변화 신호로 변환
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .tapDismiss:
      steps.accept(AppStep.dismiss)
      return .empty()

    case .doneButtonTapped:
      steps.accept(AppStep.dismiss)
      return .empty()
    case .titleDidChange(let title):
      return .just(.setTitle(title))
    case .contentDidChange(let content):
      return .just(.setContent(content))
    case .boldButtonTapped:
      return .concat([
        .just(.setBoldToggled(true)),
        .just(.setBoldToggled(false))
      ])

    case .imageButtonTapped:
      return .concat([
        .just(.setShouldShowImagePicker(true)),
        .just(.setShouldShowImagePicker(false))
      ])

    case .imageDidPick(let image):
      return .concat([
        .just(.setImageToInsert(image)),
        .just(.setImageToInsert(nil))
      ])
    }
  }
  // Mutation이 발생했을 때 상태(State)를 실제로 바꿈
  // 상태 변화 신호 → 실제 상태 반영
  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    case .setTitle(let title):
      newState.title = title
      newState.canPost = !newState.title.isEmpty && !newState.content.string.isEmpty

    case .setContent(let content):
      newState.content = content
      newState.canPost = !newState.title.isEmpty && !newState.content.string.isEmpty

    case .setBoldToggled(let shouldToggle):
      newState.shouldToggleBold = shouldToggle

    case .setImageToInsert(let image):
      newState.imageToInsert = image

    case .setShouldShowImagePicker(let shouldShow):
      newState.shouldShowImagePicker = shouldShow
    }
    return newState
  }

  func transform(state: Observable<State>) -> Observable<State> {
    return state.observe(on: MainScheduler.instance)
  }
}
