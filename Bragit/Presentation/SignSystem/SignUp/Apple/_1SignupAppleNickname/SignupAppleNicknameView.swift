//
//  SignupAppleNicknameView.swift
//  Bragit
//
//  Created by luca on 9/17/25.
//

import UIKit

import SnapKit
import Then

final class SignupAppleNicknameView: UIView {
  enum StatusStyle { case none, loading, accept, reject }

  private let headerView = UIView()
  let backButton = UIButton(type: .system).then {
    $0.setImage(.back, for: .normal)
    $0.tintColor = .grayScale900
  }
  private let headerLabel = UILabel().then {
    $0.text = "회원가입"
    $0.font = .pretendard(size: 18, weight: .medium)
    $0.textColor = .grayScale900
    $0.textAlignment = .center
  }

  // MARK: UI 컴포넌트 정의

  // MARK: - Title
  private let descriptionTitleLabel = UILabel().then {
    $0.text = "브래깃에서 사용할 닉네임을 입력해 주세요"
    $0.numberOfLines = 2
    $0.lineBreakMode = .byWordWrapping
    $0.setContentHuggingPriority(.required, for: .vertical)
    $0.setContentCompressionResistancePriority(.required, for: .vertical)
    $0.font = .pretendard(size: 20, weight: .semibold)
    $0.textColor = .grayScale900
  }

  // MARK: - Nickname
  private let nicknameLabel = UILabel().then {
    $0.text = "닉네임"
    $0.font = .pretendard(size: 13, weight: .medium)
    $0.textColor = .grayScale700
  }
  let nicknameTextField = InsetTextField().then {
    $0.placeholder = "2-8글자 내로 공백 없이 입력해 주세요"
    $0.layer.borderColor = UIColor.grayScale100.cgColor
    $0.layer.borderWidth = 1
    $0.layer.cornerRadius = 14
    $0.clearButtonMode = .whileEditing
    $0.font = .pretendard(size: 14, weight: .regular)
    $0.textColor = .grayScale900
    $0.returnKeyType = .done
    $0.autocapitalizationType = .none
    $0.spellCheckingType = .no
    $0.autocorrectionType = .no
    $0.snp.makeConstraints { $0.height.equalTo(52) }
  }
  private let nicknameCheckIcon = UIImageView().then { $0.contentMode = .scaleAspectFit }
  private let nicknameCheckLabel = UILabel().then {
    $0.text = " "
    $0.font = .pretendard(size: 13, weight: .medium)
    $0.textColor = .systemSafe
  }
  private let nicknameCheckStack = UIStackView().then {
    $0.axis = .horizontal
    $0.spacing = 4
    $0.alignment = .leading
  }
  private let nicknameStack = UIStackView().then {
    $0.axis = .vertical
    $0.spacing = 8
  }

  let nextButton = UIButton(type: .system).then {
    $0.setTitle("다음", for: .normal)
    $0.setTitleColor(.grayScale900, for: .normal)
    $0.titleLabel?.font = .pretendard(size: 16, weight: .medium)
    $0.layer.cornerRadius = 12
    $0.isEnabled = true
    $0.backgroundColor = .primary400
  }

  // MARK: - Nickname Status UI API
  func setNicknameStatus(style: StatusStyle, message: String) {
    switch style {
    case .none:
      nicknameCheckIcon.isHidden = true
      nicknameCheckLabel.text = " "
    case .loading:
      nicknameCheckIcon.isHidden = false
      nicknameCheckIcon.image = UIImage.loading.withRenderingMode(.alwaysOriginal)
      nicknameCheckLabel.text = message
      nicknameCheckLabel.textColor = .systemWarning
    case .accept:
      nicknameCheckIcon.isHidden = false
      nicknameCheckIcon.image = UIImage.accept.withRenderingMode(.alwaysOriginal)
      nicknameCheckLabel.text = message
      nicknameCheckLabel.textColor = .systemSafe
    case .reject:
      nicknameCheckIcon.isHidden = false
      nicknameCheckIcon.image = UIImage.reject.withRenderingMode(.alwaysOriginal)
      nicknameCheckLabel.text = message
      nicknameCheckLabel.textColor = .systemDanger
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .white
    headerUI()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func headerUI() {
    addSubview(headerView)
    [backButton, headerLabel].forEach { headerView.addSubview($0) }

    headerView.snp.makeConstraints {
      $0.top.equalTo(safeAreaLayoutGuide.snp.top)
      $0.leading.trailing.equalToSuperview()
      $0.height.equalTo(58)
    }

    backButton.snp.makeConstraints {
      $0.leading.equalToSuperview().offset(20)
      $0.centerY.equalTo(headerView.snp.centerY)
    }

    headerLabel.snp.makeConstraints {
      $0.centerX.equalTo(headerView.snp.centerX)
      $0.centerY.equalTo(headerView.snp.centerY)
      $0.leading.greaterThanOrEqualTo(backButton.snp.trailing).offset(20)
    }

    configureUI()
  }

  private func configureUI() {
    [descriptionTitleLabel, nicknameStack, nextButton].forEach { addSubview($0) }

    [nicknameCheckIcon, nicknameCheckLabel].forEach { nicknameCheckStack.addArrangedSubview($0) }
    nicknameCheckLabel.text = " "
    nicknameCheckIcon.isHidden = true
    [nicknameLabel, nicknameTextField, nicknameCheckStack].forEach { nicknameStack.addArrangedSubview($0) }

    descriptionTitleLabel.snp.makeConstraints {
      $0.top.equalTo(headerView.snp.bottom).offset(32)
      $0.leading.trailing.equalToSuperview().inset(20)
    }
    nicknameStack.snp.makeConstraints {
      $0.top.equalTo(descriptionTitleLabel.snp.bottom).offset(24)
      $0.leading.trailing.equalToSuperview().inset(20)
    }
    nextButton.snp.makeConstraints {
      $0.bottom.equalTo(safeAreaLayoutGuide).inset(24)
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.height.equalTo(52)
    }
  }
}
