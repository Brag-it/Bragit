//
//  AppFlow.swift
//  Bragit
//
//  Created by 이태윤 on 8/25/25.
//
import UIKit

import RxFlow

final class AppFlow: Flow {
  var root: Presentable { window }
  private let window: UIWindow
  init(window: UIWindow) { self.window = window }

  func navigate(to step: Step) -> FlowContributors {
    guard let step = step as? AppStep else { return .none }
    switch step {
    case .login:
      // LoginFlow로 전환
      // return .one(flowContributor: .contribute(withNextPresentable: loginFlow, withNextStepper: OneStepper(withSingleStep: .login)))
      return .none

    case .tabBarSelected:
      // MainTabFlow로 전환(첫 진입 시) 혹은 forward
      // 보통은 MainTabFlow가 이미 세팅되어 있으면 forward, 없으면 전환
      return .none

    default:
      return .none
    }
  }
}
