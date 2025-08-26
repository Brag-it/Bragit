//
//  LoginFlow.swift
//  Bragit
//
//  Created by 이태윤 on 8/25/25.
//
import UIKit

import RxFlow

// 로그인 화면 네비게이션 전담
final class LoginFlow: Flow {
  var root: Presentable { nav }
  private let nav = UINavigationController()

  func navigate(to step: Step) -> FlowContributors {
    guard let step = step as? AppStep else { return .none }
    switch step {
    case .login:
      return showLogin()
    default:
      return .none
    }
  }

  private func showLogin() -> FlowContributors {
    let reactor = LoginReactor()
    let loginVC = LoginViewController(reactor: LoginReactor())
    nav.setViewControllers([loginVC], animated: true)

    // 로그인 성공 시 reactor가 .home Step을 방출
    return .one(flowContributor: .contribute(
      withNextPresentable: loginVC,
      withNextStepper: reactor
    ))
  }
}
