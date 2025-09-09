//
//  LicenseDetailViewController.swift
//  Bragit
//
//  Created by 이태윤 on 9/9/25.
//
import UIKit

import SnapKit
import Then

final class LicenseDetailViewController: UIViewController {

  // 표시할 항목
  private let item: LicenseItem

  private let headerView = UIView()

  private let titleLabel = UILabel().then {
    $0.font = .pretendard(size: 20, weight: .medium)
    $0.textColor = .grayScale900
  }

  private let subLabel = UILabel().then {
    $0.font = .pretendard(size: 14)
    $0.textColor = .grayScale700
  }

  private let backButton = UIButton().then {
    $0.setImage(.back, for: .normal)
    $0.tintColor = .grayScale900
  }

  private let labelStack = UIStackView().then {
    $0.axis = .vertical
    $0.alignment = .center
    $0.spacing = 2
  }

  // 라이선스 전문을 보여줄 텍스트뷰
  private let textView = UITextView().then {
    $0.isEditable = false
    $0.alwaysBounceVertical = true
    $0.font = .pretendard(size: 14)
    $0.textColor = .grayScale900
    $0.backgroundColor = .white
    $0.textContainerInset = .init(top: 16, left: 16, bottom: 24, right: 16)
  }

  init(item: LicenseItem) {
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
    headerView.addSubview(labelStack)
    labelStack.addArrangedSubview(titleLabel)
    labelStack.addArrangedSubview(subLabel)

    headerView.snp.makeConstraints {
      $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
      $0.leading.trailing.equalToSuperview()
      $0.height.equalTo(58)
    }

    backButton.snp.makeConstraints {
      $0.leading.equalToSuperview().offset(20)
      $0.centerY.equalTo(headerView)
    }

    labelStack.snp.makeConstraints {
      $0.centerY.equalTo(headerView)
      $0.centerX.equalToSuperview()
    }

    view.addSubview(textView)

    textView.snp.makeConstraints {
      $0.top.equalTo(headerView.snp.bottom).offset(24)
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.bottom.equalToSuperview().inset(20)
    }

    loadLicenseText()
  }

  private func loadLicenseText() {
    // 파일명과 확장자를 분리해서 안전하게 로딩
    let name = item.bundleFileName
    if let url = Bundle.main.url(forResource: name, withExtension: "txt"),
       let text = try? String(contentsOf: url, encoding: .utf8) {
      textView.text = text
    } else {
      textView.text = "라이선스 파일을 찾을 수 없습니다: \(name).txt)"
    }
  }

  private func config() {
    titleLabel.text = item.name
    subLabel.text = item.licenseType
  }
}
