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
      let window = UIWindow(windowScene: windowScene)
      self.window = window

      // 네비게이션 로그
      coordinator.rx.didNavigate
        .subscribe(onNext: { flow, step in
          print("didNavigate → flow: \(flow), step: \(step)")
        })
        .disposed(by: disposeBag)

      let appFlow = AppFlow(window: window)
      let appStepper = AppStepper()
      coordinator.coordinate(flow: appFlow, with: appStepper)
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

//extension SceneDelegate {
//  func makeTabBarController() -> UITabBarController {
//    let homeVC = HomeViewController()
//    let favoriteVC = FavoriteViewController()
//    let writeVC = WriteViewController()
//    let myPageVC = MyPageViewController()
//
//    let tabBarController = UITabBarController()
//    tabBarController.delegate = self
//
//    homeVC.tabBarItem = UITabBarItem(
//      title: "홈",
//      image: .home,
//      tag: 0
//    )
//
//    favoriteVC.tabBarItem = UITabBarItem(
//      title: "관심",
//      image: .favorite,
//      tag: 1
//    )
//
//    writeVC.tabBarItem = UITabBarItem(
//      title: "글쓰기",
//      image: .write,
//      tag: 2
//    )
//
//    myPageVC.tabBarItem = UITabBarItem(
//      title: "마이",
//      image: .mypage,
//      tag: 3
//    )
//
//    tabBarController.viewControllers = [homeVC, favoriteVC, writeVC, myPageVC].map {
//      UINavigationController(rootViewController: $0)
//    }
//    tabBarController.tabBar.tintColor = .systemBlue
//
//    /// 하단 탭바의 경계션 표현
//    let appearance = UITabBarAppearance()
//    appearance.configureWithOpaqueBackground()
//    appearance.backgroundColor = .systemBackground
//    appearance.shadowColor = .lightGray
//
//    let fontAttributes: [NSAttributedString.Key: Any] = [
//      .font: UIFont.pretendard(size: 12, weight: .medium)
//    ]
//    appearance.stackedLayoutAppearance.normal.titleTextAttributes = fontAttributes
//    appearance.stackedLayoutAppearance.selected.titleTextAttributes = fontAttributes
//
//    tabBarController.tabBar.standardAppearance = appearance
//    tabBarController.tabBar.scrollEdgeAppearance = tabBarController.tabBar.standardAppearance
//
//    return tabBarController
//  }
//}
//
//extension SceneDelegate: UITabBarControllerDelegate {
//  func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
//    guard let index = tabBarController.viewControllers?.firstIndex(where: { $0 == viewController }), index == 2 else {
//      return true
//    }
//    tabBarController.selectedViewController?.present(WriteViewController(), animated: true)
//    return false
//  }
//}
