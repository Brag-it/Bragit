//
//  SettingViewController.swift
//  Bragit
//
//  Created by seongjun cho on 9/2/25.
//

import UIKit

import SnapKit
import Then
import RxCocoa
import RxSwift
import ReactorKit

final class SettingViewController: UIViewController, View {

  var disposeBag = DisposeBag()

  private let settingView = SettingView()

  let alert = AlertView(
    title: "로그아웃하시겠습니까?",
    message: "로그인 화면으로 돌아갑니다",
    leftButtonTitle: "예",
    rightButtonTitle: "아니요"
  )

  init(reactor: SettingReactor) {
    super.init(nibName: nil, bundle: nil)
    self.reactor = reactor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    self.view = settingView
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationController?.navigationBar.isHidden = true
  }

  func bind(reactor: SettingReactor) {
    settingView.backButton.rx.tap
      .map { .backButtonTap }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    settingView.cancelAccountButton.rx.tap
      .map { .cancelAccountButtonTap }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    settingView.logoutButton.rx.tap
      .bind { [weak view, alert] in view?.addSubview(alert) }
      .disposed(by: disposeBag)

    alert.leftTap
      .map { .logoutButtonTap }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    settingView.itemSelected
      .compactMap { item -> SettingReactor.Action? in
        switch item.title {
        case "이용 약관":
          return .tapTerms
        case "오픈소스 라이선스":
          return .tapLicenses
        default:
          return nil
        }
      }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)
  }
}
