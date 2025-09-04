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
      return showHomeRoot()
    case .feedDetail(let post):
      return showDetailPost(post: post)
    default:
      return .none
    }
  }

  private func showHomeRoot() -> FlowContributors {
    let reactor = HomeReactor()
    let homeVC = HomeViewController(reactor: reactor)
    nav.setViewControllers([homeVC], animated: true)
    return .one(flowContributor: .contribute(
      withNextPresentable: homeVC,
      withNextStepper: reactor
    ))
  }

  public func showDetailPost(post: Post) -> FlowContributors {
    let reactor = DetailPostReactor(post: post)
    let detailPostVC = DetailPostViewController(reactor: reactor)

    nav.pushViewController(detailPostVC, animated: true)

    return .one(flowContributor: .contribute(
      withNextPresentable: detailPostVC,
      withNextStepper: reactor
    ))
  }
}
