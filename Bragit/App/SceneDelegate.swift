//
//  SceneDelegate.swift
//  Bragit
//
//  Created by 이태윤 on 8/20/25.
//

import UIKit

import RxFlow
import RxSwift

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

  var window: UIWindow?

  private let coordinator = FlowCoordinator() // 중앙 코디네이터
  private let disposeBag = DisposeBag()

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions) {
      guard let windowScene = (scene as? UIWindowScene) else { return }

      window = UIWindow(windowScene: windowScene)

      // 네비게이션 로그
      coordinator.rx.didNavigate
        .subscribe { flow, step in
          print("didNavigate → flow: \(flow), step: \(step)")
        }
        .disposed(by: disposeBag)

      guard let window = window else { return }
      let appFlow = AppFlow(window: window)
      let appStepper = AppStepper()
      coordinator.coordinate(flow: appFlow, with: appStepper)

      // TODO: 로그인한 유저 UUID 등록하기
      // example
      // nowUser의 set은 UserDefaults를 사용해야함
      UserDefaults.standard.set("e2f38754-f46b-4e3d-9347-b1ce68dc57ba", forKey: LocalStorageCase.nowUser.rawValue)

      setBlockUsers()
    }

  func sceneDidDisconnect(_ scene: UIScene) {
  }

  func sceneDidBecomeActive(_ scene: UIScene) {
  }

  func sceneWillResignActive(_ scene: UIScene) {
  }

  func sceneWillEnterForeground(_ scene: UIScene) {
  }

  func sceneDidEnterBackground(_ scene: UIScene) {
  }
}

extension SceneDelegate {
  func setBlockUsers() {
    let blockManager = BlockManager()
    Task {
      do {
        @LocalStorage(location: .blockUser) var user = try await blockManager.fetchMyBlockUsers()
      } catch {
        print(error)
      }
    }
  }
}
