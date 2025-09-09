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
    case loadNextPage
    case didTapBack
  }
  // 상태변경 이벤트 정의 (상태를 어떻게 바꿀 것인가)
  enum Mutation {
    case setText(String)
    case setSuggestions([String])
    case appendSuggestions([String], hasMore: Bool)
    case setSuggestionsPaging(Bool)
    case setSuggestionsPage(Int)
    case setRecent([String]?)
    case setResults(tags: [SearchTagItem], posts: [SearchPostItem], users: [SearchUserItem])
    case appendResults(tags: [SearchTagItem], posts: [SearchPostItem], users: [SearchUserItem])
    case setScope(SearchScope)
    case setMode(SearchMode)
    case setPaging(Bool)
    case setPage(Int)
    case setHasMore(tags: Bool, posts: Bool, users: Bool)
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
    var suggestionsPage: Int = 0
    var suggestionsPageSize: Int = 20
    var hasMoreSuggestions: Bool = false
    var isPagingSuggestions: Bool = false
    var page: Int = 0
    let pageSize: Int = 10
    var isPaging: Bool = false
    var hasMoreTags: Bool = true
    var hasMorePosts: Bool = true
    var hasMoreUsers: Bool = true
  }
  // TODO: - 검색 로직 분리(태그, 게시글, 사용자 검색)

  init() {
    self.initialState = State()
  }

  // Action이 들어왔을 때 어떤 Mutation으로 바뀔지 정의
  // 사용자 입력 → 상태 변화 신호로 변환
  // swiftlint:disable cyclomatic_complexity
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {

    case .viewDidLoad:
      // 진입 시 최근검색 불러오고 모드는 최근으로
      return .concat([
        .just(.setRecent(recentSearches)),
        .just(.setMode(.recent))
      ])

    case .updateText(let raw):
      // 공백·개행 제거
      let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)

      // 공백이면 최근 검색 모드로 복귀
      if trimmed.isEmpty {
        return .concat([
          .just(.setText("")),
          .just(.setMode(.recent)),
          .just(.setSuggestions([]))
        ])
      }

      // 입력 중
      let suggest = tagManager
        .rxSearchTags(searchText: trimmed, page: 0, pageSize: 20)
        .map { $0.map { $0.tag } }
        .map(Mutation.setSuggestions)

      return .concat([
        .just(.setText(trimmed)),
        .just(.setMode(.typingSuggestions)),
        suggest
      ])

    case .submit:
      let trimmed = currentState.text.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmed.isEmpty else { return .empty() }
      saveRecent(trimmed)

      let page = 0
      let search = searchManager.rxSearchAll(searchText: trimmed, page: page, pageSize: currentState.pageSize)
        .map { bundle -> [Mutation] in
          let tagItems  = bundle.tags.map { SearchTagItem(tag: $0) }
          let postItems = bundle.posts.map { SearchPostItem(post: $0) }
          let userItems = bundle.users.map { SearchUserItem(user: $0) }

          // 받아온 개수가 pageSize 이상이면 더 있는거~
          let hasMoreTags  = tagItems.count  >= self.currentState.pageSize
          let hasMorePosts = postItems.count >= self.currentState.pageSize
          let hasMoreUsers = userItems.count >= self.currentState.pageSize

          return [
            .setResults(tags: tagItems, posts: postItems, users: userItems),
            .setPage(page),
            .setHasMore(tags: hasMoreTags, posts: hasMorePosts, users: hasMoreUsers)
          ]
        }
        .flatMap { Observable.from($0) }

      return .concat([
        .just(.setMode(.results)),
        .just(.setSuggestions([])),
        .just(.setPaging(true)),
        search,
        .just(.setRecent(recentSearches)),
        .just(.setPaging(false))
      ])

    case let .submitWithQuery(query, shouldSave):
      let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmed.isEmpty else { return .empty() }
      if shouldSave { saveRecent(trimmed) }

      let page = 0
      let pageSize = currentState.pageSize
      let search = searchManager.rxSearchAll(searchText: trimmed, page: page, pageSize: pageSize)
        .map { bundle -> [Mutation] in
          let tagItems  = bundle.tags.map { SearchTagItem(tag: $0) }
          let postItems = bundle.posts.map { SearchPostItem(post: $0) }
          let userItems = bundle.users.map { SearchUserItem(user: $0) }

          let hasMoreTags  = tagItems.count  >= pageSize
          let hasMorePosts = postItems.count >= pageSize
          let hasMoreUsers = userItems.count >= pageSize

          return [
            .setText(trimmed),
            .setResults(tags: tagItems, posts: postItems, users: userItems),
            .setPage(page),
            .setHasMore(tags: hasMoreTags, posts: hasMorePosts, users: hasMoreUsers)
          ]
        }
        .flatMap { Observable.from($0) }

      return .concat([
        .just(.setMode(.results)),
        .just(.setSuggestions([])),
        .just(.setPaging(true)),
        search,
        .just(.setRecent(recentSearches)),
        .just(.setPaging(false))
      ])

    case .loadNextPage:
      switch currentState.mode {
      case .typingSuggestions:
        guard !currentState.isPagingSuggestions, currentState.hasMoreSuggestions else { return .empty() }

        let nextPage = currentState.suggestionsPage + 1
        let pageSize = currentState.suggestionsPageSize
        let query = currentState.text

        let load = tagManager.rxSearchTags(searchText: query, page: nextPage, pageSize: pageSize)
          .map { $0.map { $0.tag } }
          .map { list -> Mutation in
            let hasMore = list.count == pageSize
            return .appendSuggestions(list, hasMore: hasMore)
          }

        return .concat([
          .just(.setSuggestionsPaging(true)),
          load,
          .just(.setSuggestionsPage(nextPage)),
          .just(.setSuggestionsPaging(false))
        ])

      case .results:
        guard currentState.mode == .results, !currentState.isPaging,
          currentState.hasMoreTags || currentState.hasMorePosts || currentState.hasMoreUsers
        else { return .empty() }

        let next = currentState.page + 1
        let pageSize = currentState.pageSize
        let keyword = currentState.text

        let search = searchManager.rxSearchAll(searchText: keyword, page: next, pageSize: pageSize)
          .map { bundle -> [Mutation] in
            let tagItems  = bundle.tags.map { SearchTagItem(tag: $0) }
            let postItems = bundle.posts.map { SearchPostItem(post: $0) }
            let userItems = bundle.users.map { SearchUserItem(user: $0) }

            let hasMoreTags  = tagItems.count  >= pageSize
            let hasMorePosts = postItems.count >= pageSize
            let hasMoreUsers = userItems.count >= pageSize

            return [
              .appendResults(tags: tagItems, posts: postItems, users: userItems),
              .setPage(next),
              .setHasMore(tags: hasMoreTags, posts: hasMorePosts, users: hasMoreUsers)
            ]
          }
          .flatMap { Observable.from($0) }

        return .concat([
          .just(.setPaging(true)),
          search,
          .just(.setPaging(false))
        ])

      case .recent:
        return .empty()
      }

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
  // swiftlint:enable cyclomatic_complexity

  // Mutation이 발생했을 때 상태(State)를 실제로 바꿈
  // 상태 변화 신호 → 실제 상태 반영
  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    case .setText(let text):
      newState.text = text

    case .setSuggestions(let list):
      newState.suggestions = list
      newState.suggestionsPage = 0
      newState.hasMoreSuggestions = !list.isEmpty

    case let .appendSuggestions(list, hasMore):
      var set = Set(newState.suggestions)
      for suggestion in list where !set.contains(suggestion) {
        newState.suggestions.append(suggestion)
        set.insert(suggestion)
      }
      newState.hasMoreSuggestions = hasMore

    case .setSuggestionsPaging(let flag):
      newState.isPagingSuggestions = flag

    case .setSuggestionsPage(let page):
      newState.suggestionsPage = page

    case .setRecent(let recent):
      newState.recent = recent

    case let .setResults(tags, posts, users):
      newState.tagResults  = tags
      newState.postResults = posts
      newState.userResults = users

    case let .appendResults(tags, posts, users):
      newState.tagResults = Self.mergeUnique(
        existingItems: newState.tagResults,
        newItems: tags) { $0.tag.id }
      newState.postResults = Self.mergeUnique(
        existingItems: newState.postResults,
        newItems: posts) { $0.post.id }
      newState.userResults = Self.mergeUnique(
        existingItems: newState.userResults,
        newItems: users) { UUID(uuidString: $0.user.id) }

    case let .setPaging(loding):
      newState.isPaging = loding

    case let .setPage(page):
      newState.page = page

    case let .setHasMore(tags, posts, users):
      newState.hasMoreTags  = tags
      newState.hasMorePosts = posts
      newState.hasMoreUsers = users

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

extension SearchReactor {
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

    return .concat([
      .just(.setText(trimmed)),
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

  // 중복 제거
  // existingItems = 기존 배열
  // newItems = 새로 추가할 배열
  // keySelector = 식별 키를 뽑아내는 함수
  // existingKeys = 이미 본 키 집합
  // mergedItems = 최종 합쳐진 결과 배열
  // newItem, newKey
  static func mergeUnique<T, K: Hashable>(
    existingItems: [T], newItems: [T], keySelector: (T) -> K
  ) -> [T] {
    var existingKeys = Set(existingItems.map(keySelector))
    var mergedItems = existingItems

    for newItem in newItems {
      let newKey = keySelector(newItem)
      if !existingKeys.contains(newKey) {
        mergedItems.append(newItem)
        existingKeys.insert(newKey)
      }
    }
    return mergedItems
  }
}
