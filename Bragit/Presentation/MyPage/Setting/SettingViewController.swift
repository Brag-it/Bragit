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
  }
}
