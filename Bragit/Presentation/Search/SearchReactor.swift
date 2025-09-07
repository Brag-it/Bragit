//
//  SearchReactor.swift
//  Bragit
//
//  Created by 이태윤 on 9/6/25.
//
import UIKit

import Dependencies
import ReactorKit
import RxSwift
import RxFlow
import RxRelay

class SearchReactor: Reactor, Stepper {
  var initialState: State
  @Dependency(\.searchManager) var searchManager
  let steps = PublishRelay<Step>()
  private let disposeBag = DisposeBag()
  @LocalStorage(location: .recentSearches) var recentSearches: [String]?

  // 사용자 액션 정의 (사용자의 의도)
  enum Action {
    case viewDidLoad
    case updateText(String)         // 입력중
    case submit                     // 리턴키/ 검색 버튼
    case changeScope(SearchScope)   // 결과 탭 전환
    case tapRecent(String)          // 최근결과 탭
    case deleteRecent(String)       // 최근결과 삭제
    case clearAllRecent             // 전체 삭제
    case didTapBack
  }
  // 상태변경 이벤트 정의 (상태를 어떻게 바꿀 것인가)
  enum Mutation {
    case setText(String)
    case setRecent([String]?)
  }

  // View의 상태 정의 (현재 View의 상태값)
  struct State {
    var text: String = ""
    var recent: [String]?
  }

  init() {
    self.initialState = State()
  }

  // Action이 들어왔을 때 어떤 Mutation으로 바뀔지 정의
  // 사용자 입력 → 상태 변화 신호로 변환
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .viewDidLoad:
      return .just(.setRecent(recentSearches))

    case .updateText(let raw):
      let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
      return .just(.setText(trimmed))

    case .submit:
      let trimmed = currentState.text.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmed.isEmpty else { return .empty() }
      saveRecent(trimmed)
      return .just(.setRecent(recentSearches)) // 저장 후 최신 목록 반영

    case .changeScope:
      // TODO: 스코프 전환 시 결과 재조회가 필요하면 여기에서 처리
      return .empty()

    case .tapRecent(let keyword):
      // 필요 시 바로 검색 트리거를 여기서 이어가도 됨
      return .from([.setText(keyword)])

    case .deleteRecent(let keyword):
      removeRecent(keyword)
      return .just(.setRecent(recentSearches))

    case .clearAllRecent:
      clearAllRecent()
      return .just(.setRecent(recentSearches))

    case .didTapBack:
      steps.accept(AppStep.dismiss)
      return .empty()
    }
  }
  // Mutation이 발생했을 때 상태(State)를 실제로 바꿈
  // 상태 변화 신호 → 실제 상태 반영
  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    case .setText(let text):
      newState.text = text
    case .setRecent(let recent):
      newState.recent = recent
    }
    return newState
  }

  func transform(state: Observable<State>) -> Observable<State> {
    return state.observe(on: MainScheduler.instance)
  }

  private func saveRecent(_ raw: String) {
    let trimmedQuery = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedQuery.isEmpty else { return }

    var list = recentSearches ?? []
    list.removeAll { $0.caseInsensitiveCompare(trimmedQuery) == .orderedSame }
    list.insert(trimmedQuery, at: 0)
    // 최근 검색어 20개만 저장
    if list.count > 20 {
      list.removeLast(list.count - 20)
    }
    recentSearches = list
  }

  private func removeRecent(_ keyword: String) {
    var list = recentSearches ?? []
    list.removeAll { $0.caseInsensitiveCompare(keyword) == .orderedSame }
    recentSearches = list
  }

  private func clearAllRecent() {
    recentSearches = []
  }
}
