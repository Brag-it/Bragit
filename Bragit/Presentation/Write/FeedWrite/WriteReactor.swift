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
  @LocalStorage(location: .postTemporary) var postTemporary: PostTemporary?
  private let disposeBag = DisposeBag()

  // 사용자 액션 정의 (사용자의 의도)
  enum Action {
    case tapDismiss // 탭 닫기
    case tapDone    // 완료 버튼
    case isLoadPost
    case tapTemporary   // 임시저장
    case tapLoadPost    // 불러오기
    case updateTitle(String)
    case updateContent(NSAttributedString)
    case boldTapped
    case underlineTapped
    case strikethroughTapped
  }

  // 상태변경 이벤트 정의 (상태를 어떻게 바꿀 것인가)
  enum Mutation {
    case setTitle(String)
    case setContent(NSAttributedString)
    case setBoldActive(Bool)
    case setUnderlineActive(Bool)
    case setStrikethroughActive(Bool)
    case setPost(Bool)
  }

  // View의 상태 정의 (현재 View의 상태값)
  struct State {
    var title: String = ""                                    // 제목
    var content: NSAttributedString = NSAttributedString("")  // 내용
    var isBoldActive = false
    var isUnderlineActive = false
    var isStrikethroughActive = false
    var isLoadPost = false
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
    case .tapDone:
      let draft = PostDraft(
        title: currentState.title,
        content: currentState.content,
      )
      steps.accept(AppStep.preview(draft: draft))
      return .empty()
    case .updateTitle(let title):
      return .just(.setTitle(title))

    case .updateContent(let content):
      return .just(.setContent(content))

    case .boldTapped:
      return .just(.setBoldActive(!currentState.isBoldActive))

    case .underlineTapped:
      return .just(.setUnderlineActive(!currentState.isUnderlineActive))

    case .strikethroughTapped:
      return .just(.setStrikethroughActive(!currentState.isStrikethroughActive))

    case .tapTemporary:
      let temporary = PostTemporary(
        title: currentState.title,
        content: currentState.content
      )
      postTemporary = temporary

      steps.accept(AppStep.dismiss)
      return .empty()

    case .isLoadPost:
      if postTemporary != nil {
        return .just(.setPost(true))
      } else {
        return .empty()
      }

    case .tapLoadPost:
      guard let temporary = postTemporary else {
        return .empty()
      }
      guard let attributed = try? NSKeyedUnarchiver.unarchivedObject(
        ofClass: NSAttributedString.self,
        from: temporary.contentData) else {
        return .empty()
      }
      let mutable = NSMutableAttributedString(attributedString: attributed)
      fixAttachmentBounds(in: mutable, containerWidth: UIScreen.main.bounds.width)

      postTemporary = nil
      return .concat(
        .just(.setTitle(temporary.title)),
        .just(.setContent(mutable)),
        .just(.setPost(false))
      )
    }
  }
  // Mutation이 발생했을 때 상태(State)를 실제로 바꿈
  // 상태 변화 신호 → 실제 상태 반영
  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    case .setTitle(let title):
      newState.title = title
    case .setContent(let content):
      newState.content = content
    case .setBoldActive(let isActive):
      newState.isBoldActive = isActive
    case .setUnderlineActive(let isActive):
      newState.isUnderlineActive = isActive
    case .setStrikethroughActive(let isActive):
      newState.isStrikethroughActive = isActive
    case .setPost(let loadPost):
      newState.isLoadPost = loadPost
    }
    return newState
  }

  func transform(state: Observable<State>) -> Observable<State> {
    return state.observe(on: MainScheduler.instance)
  }

  private func fixAttachmentBounds(
    in attributedString: NSMutableAttributedString,
    containerWidth: CGFloat,
    textInsets: UIEdgeInsets = .init(top: 0, left: 8, bottom: 0, right: 8)
  ) {
    let imageWidth = containerWidth - (textInsets.left + textInsets.right)

    attributedString.enumerateAttribute(
      .attachment, in: NSRange(location: 0, length: attributedString.length)) { value, _, _ in
        guard let attachment = value as? NSTextAttachment, let image = attachment.image else { return }

        let aspectRatio = image.size.height / image.size.width
        let imageHeight = imageWidth * aspectRatio

        attachment.bounds = CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight)
      }
  }
}
