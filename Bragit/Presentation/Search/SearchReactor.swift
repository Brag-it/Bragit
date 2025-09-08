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
  @Dependency(\.tagManager) var tagManager
  let steps = PublishRelay<Step>()
  private let disposeBag = DisposeBag()
  @LocalStorage(location: .recentSearches) var recentSearches: [String]?

  // 사용자 액션 정의 (사용자의 의도)
  enum Action {
    case viewDidLoad
    case updateText(String)
    case submit
    case submitWithQuery(String, Bool)
    case clearAllRecent
    case deleteRecent(String)
    case changeScope(SearchScope)
    case didTapTag(Tag)
    case didTapPost(Post)
    case didTapUser(User)
    case didTapBack
  }
  // 상태변경 이벤트 정의 (상태를 어떻게 바꿀 것인가)
  enum Mutation {
    case setText(String)
    case setSuggestions([String])
    case setRecent([String]?)
    case setResults(tags: [SearchTagItem], posts: [SearchPostItem], users: [SearchUserItem])
    case setScope(SearchScope)
    case setMode(SearchMode)
  }

  // View의 상태 정의 (현재 View의 상태값)
  struct State {
    var text: String = ""                      // 검색창 텍스트
    var suggestions: [String] = []             // 입력 중 연관어
    var recent: [String]?                      // 최근 검색어
    var tagResults: [SearchTagItem] = []       // 태그 결과
    var postResults: [SearchPostItem] = []     // 게시글 결과
    var userResults: [SearchUserItem] = []     // 사용자 결과
    var scope: SearchScope = .tag              // 현재 결과 탭
    var mode: SearchMode = .recent             // 화면 모드 (최근/입력중/결과)
  }

  init() {
    self.initialState = State()
  }

  // Action이 들어왔을 때 어떤 Mutation으로 바뀔지 정의
  // 사용자 입력 → 상태 변화 신호로 변환
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {

    case .viewDidLoad:
      // 진입 시 최근검색 불러오고 모드는 '최근'으로
      return .concat([
        .just(.setRecent(recentSearches)),
        .just(.setMode(.recent))
      ])

    case .updateText(let raw):
      // 공백·개행 제거
      let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)

      // 공백이면 최근 검색 모드로 복귀 + 추천 비우기
      if trimmed.isEmpty {
        return .concat([
          .just(.setText("")),
          .just(.setMode(.recent)),
          .just(.setSuggestions([]))
        ])
      }

      // 입력 중: 텍스트 반영 → 모드 전환(typing) → 태그 추천 조회
      let suggest = tagManager
        .rxSearchTags(searchText: trimmed, page: 0, pageSize: 10)
        .map { $0.map { $0.tag } }
        .map(Mutation.setSuggestions)

      return .concat([
        .just(.setText(trimmed)),
        .just(.setMode(.typingSuggestions)),
        suggest
      ])

    case .submit:
      let trimmed = currentState.text.trimmingCharacters(in: .whitespacesAndNewlines)
      return performSearch(for: trimmed, saveToRecent: true)

    case let .submitWithQuery(query, save):
      return performSearch(for: query, saveToRecent: save)

    case .clearAllRecent:
      recentSearches = []
      return .just(.setRecent(recentSearches))

    case .deleteRecent(let keyword):
      var list = recentSearches ?? []
      list.removeAll { $0.caseInsensitiveCompare(keyword) == .orderedSame }
      recentSearches = list
      return .just(.setRecent(recentSearches))

    case .changeScope(let scope):
      return .just(.setScope(scope))

    case .didTapTag(let tag):
      steps.accept(AppStep.tagInform(tag))
      return .empty()

    case .didTapPost(let post):
      steps.accept(AppStep.feedDetail(post: post))
      return .empty()

    case .didTapUser(let user):
      steps.accept(AppStep.userProfile(user: user))
      return .empty()

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

    case .setSuggestions(let list):
      newState.suggestions = list

    case .setRecent(let recent):
      newState.recent = recent

    case let .setResults(tags, posts, users):
      newState.tagResults = tags
      newState.postResults = posts
      newState.userResults = users

    case .setScope(let scope):
      newState.scope = scope

    case .setMode(let mode):
      newState.mode = mode
    }
    return newState
  }

  // 검색어 입력 액션만 디바운스
  func transform(action: Observable<Action>) -> Observable<Action> {
    let typing = action
      .compactMap { act -> String? in
        if case let .updateText(text) = act { return text } else { return nil }
      }
      .debounce(.milliseconds(250), scheduler: MainScheduler.instance)
      .distinctUntilChanged()
      .map(Action.updateText)

    let others = action.filter { act in
      if case .updateText = act { return false } else { return true }
    }

    return Observable.merge(typing, others)
  }

  func transform(state: Observable<State>) -> Observable<State> {
    return state.observe(on: MainScheduler.instance)
  }
}

private extension SearchReactor {
  func performSearch(for query: String, saveToRecent: Bool) -> Observable<Mutation> {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return .empty() }
    if saveToRecent {
      saveRecent(trimmed)
    }

    let search = searchManager.rxSearchAll(searchText: trimmed, page: 0, pageSize: 20)
      .map { bundle -> Mutation in
        let tagItems = bundle.tags.map { SearchTagItem(tag: $0) }
        let postItems = bundle.posts.map { SearchPostItem(post: $0) }
        let userItems = bundle.users.map { SearchUserItem(user: $0) }
        return .setResults(tags: tagItems, posts: postItems, users: userItems)
      }

    // 모드 전환 → 결과 세팅 → 추천 비우기 → 최근검색 재반영
    return .concat([
      .just(.setMode(.results)),
      search,
      .just(.setSuggestions([])),
      .just(.setRecent(recentSearches))
    ])
  }

  // 최근검색 저장
  func saveRecent(_ raw: String) {
    let trimmedQuery = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedQuery.isEmpty else { return }

    var list = recentSearches ?? []
    // 대소문자 무시 중복 제거
    list.removeAll { $0.caseInsensitiveCompare(trimmedQuery) == .orderedSame }
    // 맨 앞에 삽입
    list.insert(trimmedQuery, at: 0)
    // 최대 20개 유지
    if list.count > 20 {
      list.removeLast(list.count - 20)
    }
    recentSearches = list
  }
}
