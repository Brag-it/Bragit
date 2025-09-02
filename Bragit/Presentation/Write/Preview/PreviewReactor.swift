//
//  PreviewReactor.swift
//  Bragit
//
//  Created by 이태윤 on 8/27/25.
//
import UIKit

import Dependencies
import ReactorKit
import RxSwift
import RxFlow
import RxRelay

class PreviewReactor: Reactor, Stepper {
  var initialState: State
  @Dependency(\.postManager) var postManager
  let draft: PostDraft
  let steps = PublishRelay<Step>()
  private let disposeBag = DisposeBag()

  // 사용자 액션 정의 (사용자의 의도)
  enum Action {
    case tapDismiss
    case tapPop
    case tapAddTag
    case addTag(String)
    case tapRemoveTag(String)
    case appendThumbnail(UIImage)
    case tapThumbnail(UIImage)
    case tapDone
  }

  // 상태변경 이벤트 정의 (상태를 어떻게 바꿀 것인가)
  enum Mutation {
    case appendTag(String)
    case removeTag(String)
    case appendThumbnail(UIImage)
    case setRepresentative(UIImage?)
    case setResized(thumbnail: Data?, attachments: [Data]) // 리사이즈된 결과 (썸네일/본문 첨부)
    case setLoading(Bool)       // 로딩 스피너용
    case setUploaded(Post)      // 업로드된 게시글 반환
  }

  // View의 상태 정의 (현재 View의 상태값)
  struct State {
    var title: String
    var content: NSAttributedString
    var thumbnails: [UIImage]
    var representativeImage: UIImage?
    var description: String
    var tags: [String] = []
    var isLoading: Bool = false                 // 로딩 상태
    var resizedThumbnailData: Data?       // 리사이즈된 썸네일 JPEG 데이터
    var resizedAttachmentDatas: [Data] = []     // 리사이즈된 본문 첨부 JPEG 데이터 목록
    @Pulse var presentTagModal = false
  }

  init(draft: PostDraft) {
    self.draft = draft
    let images = PreviewReactor.extractImages(from: draft.content)
    let decription = PreviewReactor.extractDecription(from: draft.content, limit: 80)
    self.initialState = State(title: draft.title, content: draft.content, thumbnails: images, description: decription)
  }

  // Action이 들어왔을 때 어떤 Mutation으로 바뀔지 정의
  // 사용자 입력 → 상태 변화 신호로 변환
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .tapDismiss:
      steps.accept(AppStep.dismiss)
      return .empty()

    case .tapPop:
      steps.accept(AppStep.pop)
      return .empty()

    case .tapAddTag:
      steps.accept(AppStep.writeTagSearch)
      return .empty()

    case .addTag(let tag):
      return .just(.appendTag(tag))

    case .tapRemoveTag(let tag):
      return .just(.removeTag(tag))

    case .appendThumbnail(let image):
      return .just(.appendThumbnail(image))

    case .tapThumbnail(let image):
      let nextRep: UIImage?
      if let current = currentState.representativeImage, current === image {
        nextRep = nil
      } else {
        nextRep = image
      }
      return .just(.setRepresentative(nextRep))

    case .tapDone:
      // 이미지 리사이즈
      return Observable.concat([
        .just(.setLoading(true)),
        Observable<Mutation>.create { [weak self] observer in
          guard let self else {
            observer.onCompleted()
            return Disposables.create()
          }
          // 메인 스레드를 막지 않도록 백그라운드에서 리사이즈
          DispatchQueue.global(qos: .userInitiated).async {
            // 대표 이미지 리사이즈/압축
            let thumbnailData = self.currentState.representativeImage?.compress(for: .thumbnail)
            print("썸네일 리사이즈 크기: \((thumbnailData?.count ?? 0) / 1024) KB")
            // 본문 이미지 컨텐츠 규격으로 리사이즈/압축
            let attachments: [UIImage] = PreviewReactor.extractImages(from: self.currentState.content)
            let attachmentDatas: [Data] = attachments.compactMap { $0.compress(for: .content) }
            print("본문 이미지 리사이즈 개수: \(attachmentDatas.count)")
            attachmentDatas.enumerated().forEach { index, data in
              print("   - 이미지 \(index) 크기: \(data.count / 1024) KB")
            }
            observer.onNext(.setResized(thumbnail: thumbnailData, attachments: attachmentDatas))
            observer.onCompleted()
          }
          return Disposables.create()
        },
        .just(.setLoading(false))
      ])
    }
  }
  // Mutation이 발생했을 때 상태(State)를 실제로 바꿈
  // 상태 변화 신호 → 실제 상태 반영
  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    case .appendTag(let tag):
      if !state.tags.contains(tag) {
        newState.tags.append(tag)
      }

    case .removeTag(let tag):
      newState.tags.removeAll { $0 == tag }

    case .appendThumbnail(let thumbnil):
      newState.thumbnails.insert(thumbnil, at: 0)

    case .setRepresentative(let image):
      newState.representativeImage = image

    case .setResized(let thumbnail, let attachments):
      // 리사이즈 결과를 상태에 보관 (다음 단계: 업로드/DB 저장에서 사용)
      newState.resizedThumbnailData = thumbnail
      newState.resizedAttachmentDatas = attachments

    case .setLoading(let flag):
      newState.isLoading = flag

    case .setUploaded(_):
      // 이후 단계에서 업로드 완료 상태를 활용하도록 남겨둠
      break
    }

    return newState
  }

  func transform(state: Observable<State>) -> Observable<State> {
    return state.observe(on: MainScheduler.instance)
  }

  // NSAttributedString에서 이미지 뽑아 내기
  static func extractImages(from attributedString: NSAttributedString) -> [UIImage] {
    var images: [UIImage] = []

    attributedString.enumerateAttribute(
      .attachment, in: NSRange(location: 0, length: attributedString.length)
    ) { value, _, _ in
      if let attachment = value as? NSTextAttachment, let image = attachment.image {
        images.append(image)
      }
    }
    return images
  }

  // 요약
  static func extractDecription(from attributedString: NSAttributedString, limit: Int = 80) -> String {
    let plainText = attributedString.string
    let cleanedText = plainText
      .replacingOccurrences(of: "^\n+", with: "", options: .regularExpression) // 맨 앞 줄바꿈 제거
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let preview = String(cleanedText.prefix(limit))
    return preview
  }

}
