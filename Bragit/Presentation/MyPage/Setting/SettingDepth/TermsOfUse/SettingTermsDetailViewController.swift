//
//  SettingTermsDetailViewController.swift
//  Bragit
//
//  Created by 이태윤 on 9/9/25.
//
import UIKit

import SnapKit
import Then
import RxSwift
import RxCocoa
import RxFlow

final class SettingTermsDetailViewController: UIViewController, Stepper {
  let steps = PublishRelay<Step>()
  var disposeBag = DisposeBag()

  private let item: TermsItem

  private let headerView = UIView()

  private let backButton = UIButton().then {
    $0.setImage(.back, for: .normal)
    $0.tintColor = .grayScale900
  }

  private let titleLabel = UILabel().then {
    $0.font = .pretendard(size: 18, weight: .medium)
    $0.textColor = .grayScale900
  }

  private let textView = UITextView().then {
    $0.isEditable = false
    $0.alwaysBounceVertical = true
    $0.font = .pretendard(size: 15)
    $0.textColor = .grayScale900
    $0.backgroundColor = .white
  }

  init(item: TermsItem) {
    self.item = item
    super.init(nibName: nil, bundle: nil)
    self.title = item.name
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    config()
    view.addSubview(headerView)
    headerView.addSubview(backButton)
    headerView.addSubview(titleLabel)

    headerView.snp.makeConstraints {
      $0.top.equalTo(view.safeAreaLayoutGuide)
      $0.leading.trailing.equalToSuperview()
      $0.height.equalTo(58)
    }

    backButton.snp.makeConstraints {
      $0.leading.equalToSuperview().offset(20)
      $0.centerY.equalTo(headerView)
    }

    titleLabel.snp.makeConstraints {
      $0.center.equalToSuperview()
    }

    view.addSubview(textView)

    textView.snp.makeConstraints {
      $0.top.equalTo(headerView.snp.bottom).offset(24)
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.bottom.equalToSuperview().inset(20)
    }

    loadLicenseText()

    // 직접 네비게이션 pop (RxFlow 미연동 상황에서도 동작하도록)
    backButton.rx.tap
      .bind(with: self) { owner, _ in
        if let nav = owner.navigationController {
          nav.popViewController(animated: true)
        } else {
          // 네비게이션이 없을 경우 RxFlow로 전달 (옵션)
          owner.steps.accept(AppStep.pop)
        }
      }
      .disposed(by: disposeBag)
  }

  private func loadLicenseText() {
    let name = item.bundleFileName
    let bundle = Bundle.main

    if let url = bundle.url(forResource: name, withExtension: "txt"),
       let text = try? String(contentsOf: url, encoding: .utf8) {
      textView.text = text
      return
    }
    textView.text = "라이선스 파일을 찾을 수 없습니다: \(name) (.txt)"
  }

  private func config() {
    titleLabel.text = item.name
  }
}

