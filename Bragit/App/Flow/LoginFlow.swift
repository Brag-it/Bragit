//
//  LoginFlow.swift
//  Bragit
//
//  Created by 이태윤 on 8/25/25.
//
import UIKit

import RxFlow
import RxRelay

// 로그인 화면 네비게이션 전담
final class LoginFlow: Flow, Stepper {
  var root: Presentable { nav }
  private let nav = UINavigationController()
  let steps = PublishRelay<Step>()
  private var pendingUserInfo: UserRegistrationInfo?

  // Sets the first screen as root, then pushes subsequent screens
  private func setOrPush(_ viewController: UIViewController, animated: Bool = true) {
    if nav.viewControllers.isEmpty {
      nav.setViewControllers([viewController], animated: false)
    } else {
      nav.pushViewController(viewController, animated: animated)
    }
  }

  func navigate(to step: Step) -> FlowContributors {
    guard let step = step as? AppStep else { return .none }
    switch step {
    case .login:
      return showLogin()
    case .signupApple(let refreshToken, let isAppleLogin):
      return showSignupApple(refreshToken: refreshToken, isAppleLogin: isAppleLogin)
    case .signupAppleNickname(let refreshToken):
      return showSignupAppleNickname(refreshToken: refreshToken)
    case .signupAppleTerms(let nickname, let refreshToken):
      return showSignupAppleTerms(nickname: nickname, refreshToken: refreshToken)
    case .signupMailInfo:
      return showSignupMailInfo()
    case .signupMailTerms(let info):
      return showSignupMailTerms(info: info)
    case .signupMailConfirm(let info):
      return showSignupMailConfirm(info: info)
    case .signupImageUpload:
      return showSignupImageUpload()
    case .signupTagSelect:
      return showSignupTagSelect()
    case .signInMail:
      return showMailLogin()
    case .home:
      return .end(forwardToParentFlowWithStep: AppStep.home)

    // 추가: 뒤로 가기(pop) / dismiss 처리
    case .pop:
      if nav.viewControllers.count > 1 {
        nav.popViewController(animated: true)
        return .none
      } else {
        // No previous screen to pop to; return to login root
        return showLogin()
      }
    case .dismiss:
      nav.dismiss(animated: true)
      return .none

    default:
      return .none
    }
  }

  private func showLogin() -> FlowContributors {
    let reactor = MainLoginReactor()
    let loginVC = LoginViewController(reactor: reactor)
    nav.setViewControllers([loginVC], animated: true)
    return .one(
      flowContributor: .contribute(
        withNextPresentable: loginVC,
        withNextStepper: reactor
      )
    )
  }

  private func showSignupApple(refreshToken: String?, isAppleLogin: Bool) -> FlowContributors {
    let reactor = AppleInfoReactor()
    let appleInfoVC = AppleInfoViewController(
      refreshToken: refreshToken,
      isAppleLogin: isAppleLogin
    )
    appleInfoVC.onNext = { [weak self] (info: UserRegistrationInfo) in
      self?.pendingUserInfo = info
      // self?.steps.accept(AppStep.signTermsConset)
    }
    setOrPush(appleInfoVC)
    return .one(
      flowContributor:
        .contribute(
          withNextPresentable: appleInfoVC,
          withNextStepper: reactor
        )
    )
  }

  private func showSignupAppleNickname(refreshToken: String?) -> FlowContributors {
    let reactor = SignupAppleNicknameReactor(refreshToken: refreshToken)
    let signupAppleNicknameVC = SignupAppleNicknameViewController(reactor: reactor)
    setOrPush(signupAppleNicknameVC)
    return .one(
      flowContributor:
        .contribute(
          withNextPresentable: signupAppleNicknameVC,
          withNextStepper: reactor
        )
    )
  }

  private func showSignupAppleTerms(nickname: String, refreshToken: String?) -> FlowContributors {
    let reactor = SignupAppleTermsReactor(nickname: nickname, refreshToken: refreshToken)
    let signupAppleTermsVC = SignupAppleTermsViewController(reactor: reactor)
    setOrPush(signupAppleTermsVC)
    return .one(
      flowContributor:
        .contribute(
          withNextPresentable: signupAppleTermsVC,
          withNextStepper: reactor
        )
    )
  }

  private func showSignupMailInfo() -> FlowContributors {
    print("[LoginFlow] showSignupMailInfo(): creating reactor and pushing SignupMailInfoViewController")
    let reactor = SignupMailInfoReactor()
    let signupMailInfoVC = SignupMailInfoViewController(reactor: reactor)
    setOrPush(signupMailInfoVC)
    return .one(
      flowContributor:
        .contribute(
          withNextPresentable: signupMailInfoVC,
          withNextStepper: reactor
        )
    )
  }

  private func showSignupMailTerms(info: UserRegistrationInfo) -> FlowContributors {
    let reactor = SignupMailTermsReactor(info: info)
    let signupMailTermsVC = SignupMailTermsViewController(reactor: reactor)
    setOrPush(signupMailTermsVC)
    return .one(
      flowContributor:
        .contribute(
          withNextPresentable: signupMailTermsVC,
          withNextStepper: reactor
        )
    )
  }

  private func showSignupMailConfirm(info: UserRegistrationInfo) -> FlowContributors {
    let reactor = SignupMailConfirmReactor(info: info)
    let signupMailConfirmVC = SignupMailConfirmViewController(reactor: reactor)
    setOrPush(signupMailConfirmVC)
    return .one(
      flowContributor:
        .contribute(
          withNextPresentable: signupMailConfirmVC,
          withNextStepper: reactor
        )
    )
  }

  private func showSignupImageUpload() -> FlowContributors {
    let reactor = SignupImageUploadReactor()
    let signupImageUploadVC = SignupImageUploadViewController(reactor: reactor)
    setOrPush(signupImageUploadVC)
    return .one(
      flowContributor:
        .contribute(
          withNextPresentable: signupImageUploadVC,
          withNextStepper: reactor
        )
    )
  }

  private func showSignupTagSelect() -> FlowContributors {
    let reactor = SignupTagSelectReactor()
    let signupTagSelectVC = SignupTagSelectViewController(reactor: reactor)
    setOrPush(signupTagSelectVC)
    return .one(
      flowContributor:
        .contribute(
          withNextPresentable: signupTagSelectVC,
          withNextStepper: reactor
        )
    )
  }

  private func showMailLogin() -> FlowContributors {
    let reactor = MailLoginReactor()
    let mailLoginVC = MailLoginViewController(reactor: reactor)

    nav.setViewControllers([mailLoginVC], animated: true)
    return .one(
      flowContributor:
        .contribute(
          withNextPresentable: mailLoginVC,
          withNextStepper: reactor
        )
    )
  }
}
