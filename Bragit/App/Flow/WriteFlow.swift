//
//  WriteFlow.swift
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
      let reactor = WriteReactor()
      let writeVC = WriteViewController(reactor: reactor)
      nav.setViewControllers([writeVC], animated: true)
      return .one(flowContributor: .contribute(withNextPresentable: writeVC, withNextStepper: reactor))
    default:
      return .none
    }
  }
}
