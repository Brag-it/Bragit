//
//  AppFlow.swift
//  Bragit
//
//  Created by 이태윤 on 8/25/25.
//
import UIKit

import RxFlow
import RxRelay

// 앱 최상위 Flow: 로그인 화면을 보여줄지, 메인 탭을 보여줄지 "루트 교체"만 담당
final class AppFlow: Flow {
  var root: Presentable { window }
  private let window: UIWindow

  init(window: UIWindow) { self.window = window }

  func navigate(to step: Step) -> FlowContributors {
    guard let step = step as? AppStep else { return .none }

    switch step {
    case .splash:
      return showSplash()
    case .login:
      // 최초 진입/로그인 화면 요청
      return showLoginFlow()
    case .home:
      // 로그인 성공시 보여줄 화면
      return showTabFlow(forward: step)
    default:
      return .none
    }
  }

  private func showSplash() -> FlowContributors {
    let splashVC = SplashViewController()

    window.rootViewController = splashVC
    window.makeKeyAndVisible()

    return .one(flowContributor: .contribute(
      withNextPresentable: splashVC,
      withNextStepper: splashVC
    ))
  }

  private func showLoginFlow() -> FlowContributors {
    let flow = LoginFlow()
    Flows.use(flow, when: .ready) { [weak self] root in
      self?.window.rootViewController = root
      self?.window.makeKeyAndVisible()
    }

    return .one(flowContributor: .contribute(
      withNextPresentable: flow,
      withNextStepper: OneStepper(withSingleStep: AppStep.login)
    ))
  }

  // 로그인 성공시 탭 플로우로 이동
  private func showTabFlow(forward step: AppStep) -> FlowContributors {
    let flow = TabFlow()
    Flows.use(flow, when: .ready) { [weak self] root in
      self?.window.rootViewController = root
      self?.window.makeKeyAndVisible()
    }
    // home 탭 플로우로 넘김
    return .one(flowContributor: .contribute(
      withNextPresentable: flow,
      withNextStepper: CompositeStepper(steppers: [OneStepper(withSingleStep: step), flow] )
    ))
  }
}

// 앱 전역에서 Step(이동 명령)을 방출하는 주체
// - initialStep: 앱 시작 시 가장 먼저 보낼 Step
// - steps: 외부에서 accept()하여 라우팅을 트리거하는 "공용 채널"
final class AppStepper: Stepper {
  // 코디네이터가 구독하는 이동 명령 스트림
  let steps = PublishRelay<Step>()

  // 앱 시작시 가장 먼저 보여줄 목적지
  var initialStep: Step { AppStep.splash }
}
