//
//  SearchTagReactor.swift
//  Bragit
//
//  Created by 이태윤 on 9/1/25.
//
import UIKit

import Dependencies
import ReactorKit
import RxSwift
import RxFlow
import RxRelay

class SearchTagReactor: Reactor, Stepper {
  var initialState: State
  @Dependency(\.tagManager) var tagManager
  let steps = PublishRelay<Step>()
  private let disposeBag = DisposeBag()

  // 사용자 액션 정의 (사용자의 의도)
  enum Action {
    case updateSearchText(String)
    case didTapSearchButton
    case loadNextPage
    case selectResult(String)
  }

  // 상태변경 이벤트 정의 (상태를 어떻게 바꿀 것인가)
  enum Mutation {
    case setSearchText(String)
    case setSearchResult([String])
    case appendSearchResult([String])
    case setLoading(Bool)
    case setPage(Int)
    case setHasMore(Bool)
  }

  // View의 상태 정의 (현재 View의 상태값)
  struct State {
    var searchText: String = ""
    var searchResult: [String] = []
    var page: Int = 0
    var pageSize: Int = 10
    var isLoading: Bool = false
    var hasMore: Bool = true
  }

  init() {
    self.initialState = State()
  }

  // Action이 들어왔을 때 어떤 Mutation으로 바뀔지 정의
  // 사용자 입력 → 상태 변화 신호로 변환
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .updateSearchText(let text):
      return .just(.setSearchText(text))

    case .didTapSearchButton:
      let query = currentState.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
      // 빈 검색어면 리스트 비우고 상태 초기화
      guard !query.isEmpty else {
        return .concat(
          .just(.setPage(0)),
          .just(.setHasMore(true)),
          .just(.setSearchResult([]))
        )
      }
      return .concat(
        .just(.setLoading(true)),
        loadPage(query: query, page: 0, mode: .replace),
        .just(.setLoading(false))
      )

    case .loadNextPage:
      guard !currentState.isLoading, currentState.hasMore else { return .empty() }
      let query = currentState.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !query.isEmpty else { return .empty() }
      let next = currentState.page + 1
      return .concat(
        .just(.setLoading(true)),
        loadPage(query: query, page: next, mode: .append),
        .just(.setLoading(false))
      )

    case .selectResult(let tag):
      steps.accept(AppStep.tagPicked(tag: tag))
      return .empty()
    }
  }
  // Mutation이 발생했을 때 상태(State)를 실제로 바꿈
  // 상태 변화 신호 → 실제 상태 반영
  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    case .setSearchText(let text):
      newState.searchText = text

    case .setSearchResult(let result):
      newState.searchResult = result

    case .appendSearchResult(let more):
      newState.searchResult.append(contentsOf: more)

    case .setLoading(let flag):
      newState.isLoading = flag

    case .setPage(let value):
      newState.page = value

    case .setHasMore(let value):
      newState.hasMore = value
    }
    return newState
  }

  func transform(state: Observable<State>) -> Observable<State> {
    return state.observe(on: MainScheduler.instance)
  }

  private enum LoadMode { case replace, append }

  private func loadPage(query: String, page: Int, mode: LoadMode) -> Observable<Mutation> {
    let size = self.currentState.pageSize

    return tagManager.rxSearchTags(
      searchText: query,
      page: page,
      pageSize: size
    )
    .flatMap { rows -> Observable<Mutation> in

      // 결과가 없고, 첫페이지 일 경우에 검색어 자체를 결과를 보여주기
      if rows.isEmpty && page == 0 {
        return Observable.from([
          .setSearchResult([query]),
          .setPage(0),
          .setHasMore(false)
        ])
      }

      // DB 결과
      let tags = rows.map { $0.tag }
      let hasMore = (rows.count == size)

      var mutations: [Mutation] = []
      switch mode {
      case .replace:
        mutations.append(.setSearchResult(tags))
      case .append:
        mutations.append(.appendSearchResult(tags))
      }
      mutations.append(.setPage(page))
      mutations.append(.setHasMore(hasMore))

      return Observable.from(mutations)
    }
    .catchAndReturn(.setHasMore(false))
  }
}
