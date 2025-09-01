//
//  LoginFlow.swift
//  Bragit
//
//  Created by 이태윤 on 8/25/25.
//
import RxFlow
import RxRelay
import UIKit

// 로그인 화면 네비게이션 전담
final class LoginFlow: Flow, Stepper {
  var root: Presentable { nav }
  private let nav = UINavigationController()
  let steps = PublishRelay<Step>()
  private var pendingUserInfo: UserRegistrationInfo?

  func navigate(to step: Step) -> FlowContributors {
    guard let step = step as? AppStep else { return .none }
    switch step {
    case .login:
      return showLogin()
    case .signup(let initialMail):
      return showSignup(initialMail: initialMail)
    case .signServiceConsent:
      return showSignServiceConsent()
    case .signupPhoto:
      return showSignupPhoto()
    case .home:
      return .end(forwardToParentFlowWithStep: AppStep.home)
    default:
      return .none
    }
  }

  private func showLogin() -> FlowContributors {
    let reactor = LoginReactor()
    let loginVC = LoginViewController(reactor: reactor)
    nav.setViewControllers([loginVC], animated: true)

    // 로그인 성공 시 reactor가 .home Step을 방출
    return .one(
      flowContributor: .contribute(
        withNextPresentable: loginVC,
        withNextStepper: reactor
      )
    )
  }

  private func showSignup(initialMail: String?) -> FlowContributors {
    let userInfoVC = UserInfoViewController(initialMail: initialMail)
    userInfoVC.onNext = { [weak self] (info: UserRegistrationInfo) in
      print("[Flow]: \(initialMail as Any)")
      self?.pendingUserInfo = info
      self?.steps.accept(AppStep.signServiceConsent)
    }
    nav.pushViewController(userInfoVC, animated: true)
    return .one(
      flowContributor:
        .contribute(withNextPresentable: userInfoVC, withNextStepper: self)
    )
  }

  private func showSignServiceConsent() -> FlowContributors {
    guard let info = pendingUserInfo else { return .none }
    let termsVC = TermsViewController(userInfo: info)
    termsVC.onAgree = { [weak self] agreed in
      self?.pendingUserInfo = agreed
      self?.steps.accept(AppStep.signupPhoto)
    }
    nav.pushViewController(termsVC, animated: true)
    return .one(
      flowContributor: .contribute(withNextPresentable: termsVC, withNextStepper: self)
    )
  }

  private func showSignupPhoto() -> FlowContributors {
    guard let info = pendingUserInfo else { return .none }
    let reactor = ImageUploadReactor(userInfo: info)
    let photoVC = ImageUploadViewController(userInfo: info, reactor: reactor)
    nav.pushViewController(photoVC, animated: true)
    return .one(flowContributor: .contribute(withNextPresentable: photoVC, withNextStepper: reactor))
  }
}
