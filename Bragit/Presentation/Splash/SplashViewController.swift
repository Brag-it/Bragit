//
//  SplashViewController.swift
//  Bragit
//
//  Created by 이태윤 on 9/5/25.
//
import UIKit

import Dependencies
import Lottie
import RxFlow
import RxRelay
import SnapKit
import Supabase
import Then

final class SplashViewController: UIViewController, Stepper {
  let steps = PublishRelay<Step>()
  @Dependency(\.supabase) private var supabase

  private let animationView = LottieAnimationView().then {
    $0.contentMode = .scaleAspectFit
    $0.loopMode = .playOnce
    $0.backgroundBehavior = .pauseAndRestore
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    setupLayout()
    loadDotLottie()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    view.layoutIfNeeded()
  }

  private func setupLayout() {
    view.addSubview(animationView)
    animationView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }
  }

  private func loadDotLottie() {
    DotLottieFile.named("splash", bundle: .main) { [weak self] result in
      guard let self = self else { return }
      switch result {
      case .success(let dot):
        self.animationView.loadAnimation(from: dot)
        DispatchQueue.main.async {
          self.view.layoutIfNeeded()
          self.animationView.play { [weak self] _ in
            guard let self = self else { return }
            UIView.animate(
              withDuration: 0.18,
              delay: 0.0,
              options: [.curveEaseInOut],
              animations: {
                self.animationView.alpha = 0.0
              },
              completion: { _ in
                self.decideNextStep()
              }
            )
          }
        }
      case .failure(_):
        if let anim = LottieAnimation.named("splash") {
          self.animationView.animation = anim
          DispatchQueue.main.async {
            self.view.layoutIfNeeded()
            self.animationView.play { [weak self] _ in
              guard let self = self else { return }
              UIView.animate(
                withDuration: 0.18,
                delay: 0.0,
                options: [.curveEaseInOut],
                animations: {
                  self.animationView.alpha = 0.0
                },
                completion: { _ in
                  self.decideNextStep()
                }
              )
            }
          }
        } else {
          if Bundle.main.path(forResource: "splash", ofType: "lottie") != nil {
            self.decideNextStep()
          } else {
            print("Not found via Bundle.path(forResource:ofType:)")
            self.decideNextStep()
          }
        }
      }
    }
  }

  // MARK: - Auto Login Routing
  private func decideNextStep() {
    Task { [weak self] in
      guard let self else { return }
      let nowUser = UserDefaults.standard.string(forKey: LocalStorageCase.nowUser.rawValue)

      if nowUser == nil {
        await MainActor.run {
          self.steps.accept(AppStep.login)
        }
        return
      }

      do {
        let session = try await self.supabase.auth.session
        if session.user.id.uuidString == nowUser {
          await MainActor.run {
            self.steps.accept(AppStep.home)
          }
        } else {
          UserDefaults.standard.removeObject(forKey: LocalStorageCase.nowUser.rawValue)
          await MainActor.run {
            self.steps.accept(AppStep.login)
          }
        }
      } catch {
        UserDefaults.standard.removeObject(forKey: LocalStorageCase.nowUser.rawValue)
        await MainActor.run {
          self.steps.accept(AppStep.login)
        }
      }
    }
  }
}
