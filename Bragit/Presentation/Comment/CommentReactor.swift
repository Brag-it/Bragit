//
//  CommentReactor.swift
//  Bragit
//
//  Created by luca on 9/4/25.
//

import Dependencies
import Foundation
import ReactorKit
import RxFlow
import RxRelay
import RxSwift
import Supabase

final class CommentReactor: Reactor, Stepper {
  let initialState: State
  private let postId: UUID
  @Dependency(\.supabase) var supabase
  let steps = PublishRelay<Step>()

  @LocalStorage(location: .nowUser) private var storedUserId: String?

  // MARK: Reactor
  enum Action {
    case refresh
    case didTapBack
    case sendComment(String)
    case didTapKebab(IndexPath)
  }

  enum Mutation {
    case setLoading(Bool)
    case setComments([CommentRow])
    case setError(String?)
    case setCommentSent(Bool)
    case setCurrentUserId(String?)
  }

  struct State {
    var isLoading: Bool = false
    var comments: [CommentRow] = []
    var errorMessage: String?
    let viewer: Bool
    var commentSent: Bool = false
    var currentUserId: String?
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
    let commenterId: String?  // null/빈 값 허용
    let user: CommentUser?  // 조인 결과가 없을 수 있음

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
    let currentUser = LocalStorage<String?>(location: .nowUser).wrappedValue
    var state = State(viewer: viewer)
    state.currentUserId = currentUser
    self.initialState = state
  }

  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .refresh:
      print("CommentReactor refresh for postId: \(postId.uuidString)")
      let start = Observable.just(Mutation.setLoading(true))
      let setUser = Observable.just(Mutation.setCurrentUserId(storedUserId))
      let request = rxFetchComments(postId: postId)
        // 콘솔 출력
        .do { rows in
          let formatter = DateFormatter()
          formatter.locale = Locale(identifier: "ko_KR")
          formatter.timeZone = .current
          formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
          rows.forEach { row in
            let dateString = formatter.string(from: row.date)
            let nick = row.user?.nickname?.isEmpty == false ? row.user!.nickname! : "탈퇴한 회원"
            print("Reactor with nick: \(nick), content: \(row.content), date: \(dateString)")
          }
        }
        .map { Mutation.setComments($0) as Mutation }
        .catch { error in
          let msg = (error as NSError).localizedDescription
          return .just(.setError(msg))
        }
      let end = Observable.just(Mutation.setLoading(false))
      return .concat([start, setUser, request, end])

    case .didTapBack:
      steps.accept(AppStep.pop)
      return .empty()

    case .sendComment(let content):
      // 댓글 전송 처리
      let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmedContent.isEmpty else {
        return .empty()
      }

      let start = Observable.just(Mutation.setLoading(true))
      let send = rxSendComment(content: trimmedContent)
        .flatMap { [weak self] _ -> Observable<Mutation> in
          guard let self else { return .empty() }
          // 댓글 전송 성공 후 목록 새로고침
          return self.rxFetchComments(postId: self.postId)
            .map { Mutation.setComments($0) }
            .catch { error in
              let msg = (error as NSError).localizedDescription
              return .just(.setError(msg))
            }
        }
      let setSent = Observable.just(Mutation.setCommentSent(true))
      let resetSent = Observable.just(Mutation.setCommentSent(false))
        .delay(.milliseconds(100), scheduler: MainScheduler.instance)
      let end = Observable.just(Mutation.setLoading(false))

      return .concat([start, send, setSent, resetSent, end])

    case .didTapKebab(_):
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
    case .setCommentSent(let sent):
      newState.commentSent = sent
    case .setCurrentUserId(let id):
      newState.currentUserId = id
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
          let rows: [CommentRow] = try await self.supabase
            .from("Comment")
            .select("id, post_id, content, date, commenter_id, User_Info!left(nickname, profile)")
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

  private func rxSendComment(content: String) -> Observable<Void> {
    .create { [weak self] observer in
      guard let self else {
        observer.onCompleted()
        return Disposables.create()
      }

      let task = Task {
        do {
          // 현재 유저 ID 가져오기
          guard let userId = self.storedUserId, userId.isEmpty == false else {
            throw NSError(
              domain: "CommentReactor", code: -1, userInfo: [NSLocalizedDescriptionKey: "로그인 필요"]
            )
          }

          let newCommentId = UUID()
          let currentDate = Date()
          let dateFormatter = DateFormatter()
          dateFormatter.locale = Locale(identifier: "ko_KR")
          dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

          // 댓글 전송
          let newComment = Comment(
            id: newCommentId,
            postId: self.postId,
            commenterId: userId,
            content: content,
            date: currentDate
          )

          print("[Comment] Sending...")
          try await self.supabase
            .from("Comment")
            .insert(newComment)
            .execute()
          print("[Comment] Success!")

          observer.onNext(())
          observer.onCompleted()
        } catch {
          observer.onError(error)
        }
      }
      return Disposables.create { task.cancel() }
    }
  }
}
