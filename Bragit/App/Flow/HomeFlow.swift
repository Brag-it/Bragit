//
//  HomeFlow.swift
//  Bragit
//
//  Created by 이태윤 on 8/26/25.
//
import UIKit

import RxFlow
import RxRelay

final class HomeFlow: Flow {
  var root: Presentable { nav }
  private let nav = UINavigationController()

  func navigate(to step: Step) -> FlowContributors {
    guard let step = step as? AppStep else { return .none }
    switch step {
    case .home:
      let reactor = HomeReactor()
      let homeVC = HomeViewController(reactor: reactor)
      nav.setViewControllers([homeVC], animated: true)
      return .one(flowContributor: .contribute(withNextPresentable: homeVC, withNextStepper: reactor))
    default:
      return .none
    }
  }
}
