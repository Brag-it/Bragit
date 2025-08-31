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
    UserDefaults.standard.set("3d56b3b4-be2c-430f-a753-0abb914c5bc1", forKey: LocalStorageCase.nowUser.rawValue)
    @LocalStorage(location: .favoriteTags) var favoriteTags: [Tag]?
    // 태그 테스트 코드
    favoriteTags = [Tag(id: "6910eac9-eb3b-4ed0-9126-29f9dfa8ce40", tag: "test",count: 0),
                    Tag(id: "0d84179f-3d0f-49a4-b80f-8a2fca52fc76", tag: "test2", count: 0)]

    setBlockUsers()
    setFollowUser()
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
        @LocalStorage(location: .blockUser) var user: [String]?
        user = try await blockManager.fetchMyBlockUsers()
      } catch {
        print(error)
      }
    }
  }

  func setFollowUser() {
    let userManager = UserManager()
    Task {
      do {
        @LocalStorage(location: .followUser) var user: [String]?
        user = try await userManager.fetchFollowUsers()
        print("🌷")
        print(user)
      } catch {
        print(error)
      }
    }
  }
}
