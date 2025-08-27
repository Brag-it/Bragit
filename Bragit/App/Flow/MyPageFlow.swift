//
//  MyPageFlow.swift
//  Bragit
//
//  Created by 이태윤 on 8/26/25.
//
import UIKit

import RxFlow

final class MyPageFlow: Flow {
  var root: Presentable { nav }
  private let nav = UINavigationController()

  func navigate(to step: Step) -> FlowContributors {
    guard let step = step as? AppStep else { return .none }
    switch step {
    case .myPage:
      return showMyPageRoot()
    default:
      return .none
    }
  }

  private func showMyPageRoot() -> FlowContributors {
    let reactor = MyPageReactor()
    let mypageVC = MyPageViewController(reactor: reactor)
    nav.setViewControllers([mypageVC], animated: true)
    return .one(flowContributor: .contribute(
      withNextPresentable: mypageVC,
      withNextStepper: reactor
    ))
  }
}
