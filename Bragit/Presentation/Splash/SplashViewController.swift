//
//  SplashViewController.swift
//  Bragit
//
//  Created by 이태윤 on 9/5/25.
//
import UIKit

import Lottie
import SnapKit
import Then
import RxFlow
import RxRelay
import Dependencies
import Supabase

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
            UIView.animate(withDuration: 0.18, delay: 0.0, options: [.curveEaseInOut], animations: {
              self.animationView.alpha = 0.0
            }, completion: { _ in
              // 애니메이션 종료 후 자동 로그인 분기
              self.decideNextStep()
            })
          }
        }
      case .failure(_):
        if let anim = LottieAnimation.named("splash") {
          self.animationView.animation = anim
          DispatchQueue.main.async {
            self.view.layoutIfNeeded()
            self.animationView.play { [weak self] _ in
              guard let self = self else { return }
              UIView.animate(withDuration: 0.18, delay: 0.0, options: [.curveEaseInOut], animations: {
                self.animationView.alpha = 0.0
              }, completion: { _ in
                // 애니메이션 종료 후 자동 로그인 분기
                self.decideNextStep()
              })
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
      do {
        // 세션이 유효하면 자동 로그인 처리
        let session = try await self.supabase.auth.session
        let userId = session.user.id.uuidString

        UserDefaults.standard.set(userId, forKey: LocalStorageCase.nowUser.rawValue)

        await MainActor.run {
          self.steps.accept(AppStep.home)
        }
      } catch {
        // 세션이 없거나 만료된 경우 로그인 화면으로
        await MainActor.run {
          self.steps.accept(AppStep.login)
        }
      }
    }
  }
}
