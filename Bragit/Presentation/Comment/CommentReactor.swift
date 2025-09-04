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

  @Dependency(\.supabase) var supabase
  let steps = PublishRelay<Step>()

  // MARK: Reactor
  enum Action {
    case refresh
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
  }

  let initialState: State
  private let postId: UUID

  // 외부에서 디버그용으로 확인만 가능하게 노출
  var postIdForDebug: UUID { postId }

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
    let userInfo: CommentUser?

    enum CodingKeys: String, CodingKey {
      case id
      case postId = "post_id"
      case content
      case date
      case commenterId = "commenter_id"
      case userInfo = "User_Info"
    }
  }

  init(postId: UUID) {
    self.postId = postId
    self.initialState = State()
    // 초기화 시점에 한 번 출력
    print("CommentReactor init with postId: \(postId.uuidString)")
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
            print("Reactor with content: \(row.content), date: \(dateString)")
          }
        }
        .map { Mutation.setComments($0) as Mutation }
        .catch { error in
          let msg = (error as NSError).localizedDescription
          return .just(.setError(msg))
        }
      let end = Observable.just(Mutation.setLoading(false))
      return .concat([start, request, end])
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

