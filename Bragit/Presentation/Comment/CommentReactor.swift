//
//  CommentReactor.swift
//  Bragit
//
//  Created by luca on 9/4/25.
//

import Foundation

import ReactorKit
import RxSwift
import RxRelay
import Dependencies
import Supabase
import RxFlow

final class CommentReactor: Reactor, Stepper {
  let initialState: State
  private let postId: UUID
  @Dependency(\.supabase) var supabase
  let steps = PublishRelay<Step>()

  // MARK: Reactor
  enum Action {
    case refresh
    case didTapBack
  }

  enum Mutation {
    case setLoading(Bool)
    case setComments([CommentRow])
    case setError(String?)
  }

  struct State {
    var isLoading: Bool = false
    var comments: [CommentRow] = []
    var errorMessage: String?
    let viewer: Bool
  }

  // MARK: Model for decoding Comment rows
  struct CommentRow: Codable, Equatable, Hashable {
    struct CommentUser: Codable, Equatable, Hashable {
      let nickname: String?
      let profile: String?
    }

    let id: UUID
    let postId: UUID
    let content: String
    let date: Date
    let commenterId: String
    let user: CommentUser?

    enum CodingKeys: String, CodingKey {
      case id
      case postId = "post_id"
      case content
      case date
      case commenterId = "commenter_id"
      case user = "User_Info"
    }
  }

  init(postId: UUID, viewer: Bool = false) {
    self.postId = postId
    self.initialState = State(viewer: viewer)
  }

  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .refresh:
      print("CommentReactor refresh for postId: \(postId.uuidString)")
      let start = Observable.just(Mutation.setLoading(true))
      let request = rxFetchComments(postId: postId)
        // 콘솔 출력
        .do { rows in
          let formatter = DateFormatter()
          formatter.locale = Locale(identifier: "ko_KR")
          formatter.timeZone = .current
          formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
          rows.forEach { row in
            let dateString = formatter.string(from: row.date)
            let nick = row.user?.nickname ?? "탈퇴한 회원"
            print("Reactor with nick: \(nick), content: \(row.content), date: \(dateString)")
          }
        }
        .map { Mutation.setComments($0) as Mutation }
        .catch { error in
          let msg = (error as NSError).localizedDescription
          return .just(.setError(msg))
        }
      let end = Observable.just(Mutation.setLoading(false))
      return .concat([start, request, end])
    case .didTapBack:
      steps.accept(AppStep.pop)
      return .empty()
    }
  }

  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    case .setLoading(let loading):
      newState.isLoading = loading
      if loading { newState.errorMessage = nil }
    case .setComments(let rows):
      newState.comments = rows
    case .setError(let message):
      newState.errorMessage = message
    }
    return newState
  }

  func transform(state: Observable<State>) -> Observable<State> {
    state.observe(on: MainScheduler.instance)
  }

  // MARK: Data
  private func rxFetchComments(postId: UUID) -> Observable<[CommentRow]> {
    .create { [weak self] observer in
      guard let self else {
        observer.onCompleted()
        return Disposables.create()
      }
      let task = Task {
        do {
          // 작성자 정보(User_Info)까지 조인해서 가져오기
          let rows: [CommentRow] = try await self.supabase
            .from("Comment")
            .select("id, post_id, content, date, commenter_id, User_Info(nickname, profile)")
            .eq("post_id", value: postId)
            .order("date", ascending: true)
            .execute()
            .value

          observer.onNext(rows)
          observer.onCompleted()
        } catch {
          observer.onError(error)
        }
      }
      return Disposables.create { task.cancel() }
    }
  }
}

