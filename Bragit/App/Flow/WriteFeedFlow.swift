//
//  WriteFeedFlow.swift
//  Bragit
//
//  Created by 이태윤 on 8/26/25.
//
import UIKit
import RxFlow

final class WriteFeedFlow: Flow {
  var root: Presentable { nav }
  private let nav = UINavigationController()

  func navigate(to step: Step) -> FlowContributors {
    guard let step = step as? AppStep else { return .none }
    switch step {
    case .writeFeed:
      return showWriteRoot()
    case .dismiss:
      nav.dismiss(animated: true)
      return .none
    case .preview(let draft):
      return showPreview(draft: draft)
    case .pop:
      nav.popViewController(animated: true)
      return .none
    case .writeTagSearch:
      return showSearchTagView()
    default:
      return .none
    }
  }

  private func showWriteRoot() -> FlowContributors {
    let reactor = WriteReactor()
    let writeVC = WriteViewController(reactor: reactor)
    nav.setViewControllers([writeVC], animated: true)
    return .one(flowContributor: .contribute(
      withNextPresentable: writeVC,
      withNextStepper: reactor
    ))
  }

  private func showPreview(draft: PostDraft) -> FlowContributors {
    let reactor = PreviewReactor(draft: draft)
    let previewVC = PreviewViewController(reactor: reactor)

    nav.pushViewController(previewVC, animated: true)

    return .one(flowContributor: .contribute(
      withNextPresentable: previewVC,
      withNextStepper: reactor
    ))
  }

  private func showSearchTagView() -> FlowContributors {
    let reactor = SearchTagReactor()
    let modal = SearchTagViewController(reactor: reactor)

    modal.modalPresentationStyle = .pageSheet
    if let sheet = modal.sheetPresentationController {
      sheet.detents = [.custom(identifier: .init("fixed668")) { _ in 668 }]
      sheet.prefersGrabberVisible = true // 핸들 색상 지정 불가
      sheet.preferredCornerRadius = 14
    }

    nav.topViewController?.present(modal, animated: true)

    return .one(flowContributor: .contribute(
      withNextPresentable: modal,
      withNextStepper: reactor
    ))
  }
}
