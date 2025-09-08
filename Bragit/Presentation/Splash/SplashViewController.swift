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

final class SplashViewController: UIViewController, Stepper {
  let steps = PublishRelay<Step>()

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
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
                self.steps.accept(AppStep.login)
              }
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
                  self.steps.accept(AppStep.login)
                }
              })
            }
          }
        } else {
          if Bundle.main.path(forResource: "splash", ofType: "lottie") != nil {
          } else {
            print("Not found via Bundle.path(forResource:ofType:)")
          }
        }
      }
    }
  }

}
