import RxFlow
import RxRelay
//
//  LoginFlow.swift
//  Bragit
//
//  Created by 이태윤 on 8/25/25.
//
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
    case .signup(let initialMail, let refreshToken, let isAppleLogin):
      return showSignup(initialMail: initialMail, refreshToken: refreshToken, isAppleLogin: isAppleLogin)
    case .signTermsConset:
      return showTermsConsent()
    case .signupPhoto:
      return showSignupPhoto()
    case .signSelectTag(let profileURL):
      return showSignSelectTag(profileURL: profileURL)
    case .signInMail:
      return showMailLogin()
    case .home:
      return .end(forwardToParentFlowWithStep: AppStep.home)

    // 추가: 뒤로 가기(pop) / dismiss 처리
    case .pop:
      nav.popViewController(animated: true)
      return .none
    case .dismiss:
      nav.dismiss(animated: true)
      return .none

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

  private func showSignup(initialMail: String?, refreshToken: String?, isAppleLogin: Bool) -> FlowContributors {
    let userInfoVC = UserInfoViewController(
      initialMail: initialMail,
      refreshToken: refreshToken,
      isAppleLogin: isAppleLogin
    )
    userInfoVC.onNext = { [weak self] (info: UserRegistrationInfo) in
      print("[Flow]: \(initialMail as Any)")
      self?.pendingUserInfo = info
      self?.steps.accept(AppStep.signTermsConset)
    }
    nav.pushViewController(userInfoVC, animated: true)
    return .one(
      flowContributor:
        .contribute(withNextPresentable: userInfoVC, withNextStepper: self)
    )
  }

  private func showTermsConsent() -> FlowContributors {
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

  private func showSignSelectTag(profileURL: String?) -> FlowContributors {
    guard let info = pendingUserInfo else { return .none }
    let reactor = TagCheckReactor(userInfo: info, profileURL: profileURL)
    let tagVC = TagCheckViewController(userInfo: info, reactor: reactor)
    nav.pushViewController(tagVC, animated: true)
    return .one(
      flowContributor:
        .contribute(
          withNextPresentable: tagVC,
          withNextStepper: reactor
        )
    )
  }

  private func showMailLogin() -> FlowContributors {
    let reactor = MailLoginReactor()
    let mailLoginVC = MailLoginViewController(reactor: reactor)

    // 시스템 내비게이션 바의 뒤로가기 버튼 숨김
    mailLoginVC.navigationItem.hidesBackButton = true
    mailLoginVC.navigationItem.leftBarButtonItem = nil
    mailLoginVC.navigationItem.title = ""

    nav.pushViewController(mailLoginVC, animated: true)
    return .one(
      flowContributor: .contribute(
        withNextPresentable: mailLoginVC,
        withNextStepper: reactor
      )
    )
  }
}
