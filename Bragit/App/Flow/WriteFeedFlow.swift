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
}
