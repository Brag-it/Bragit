//
//  SignupMailInfoView.swift
//  Bragit
//
//  Created by luca on 9/17/25.
//

import SnapKit
import Then
import UIKit

final class SignupMailInfoView: UIView {

  // MARK: - Header
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

  // MARK: - Scroll
  private let scrollView = UIScrollView().then {
    $0.keyboardDismissMode = .interactive
    $0.alwaysBounceVertical = true
    $0.showsVerticalScrollIndicator = true
    $0.delaysContentTouches = false
  }
  private let contentView = UIView().then { $0.backgroundColor = .clear }

  // MARK: - Title
  private let descriptionTitleLabel = UILabel().then {
    $0.text = "로그인에 사용할 이메일과\n비밀번호를 입력해 주세요"
    $0.numberOfLines = 2
    $0.lineBreakMode = .byWordWrapping
    $0.setContentHuggingPriority(.required, for: .vertical)
    $0.setContentCompressionResistancePriority(.required, for: .vertical)
    $0.font = .pretendard(size: 20, weight: .semibold)
    $0.textColor = .grayScale900
  }

  // MARK: - Email
  private let mailLabel = UILabel().then {
    $0.text = "이메일"
    $0.font = .pretendard(size: 13, weight: .medium)
    $0.textColor = .grayScale700
  }
  let mailTextField = InsetTextField().then {
    $0.placeholder = "bragit@bragit.com"
    $0.layer.borderColor = UIColor.grayScale100.cgColor
    $0.layer.borderWidth = 1
    $0.layer.cornerRadius = 14
    $0.clearButtonMode = .whileEditing
    $0.font = .pretendard(size: 14, weight: .regular)
    $0.textColor = .grayScale900
    $0.returnKeyType = .next
    $0.autocapitalizationType = .none
    $0.spellCheckingType = .no
    $0.autocorrectionType = .no
    $0.textContentType = .emailAddress
  }
  private let mailCheckIcon = UIImageView().then {
    $0.contentMode = .scaleAspectFit
  }
  private let mailCheckLabel = UILabel().then {
    $0.text = "인증 완료된 이메일입니다"
    $0.font = .pretendard(size: 13, weight: .medium)
    $0.textColor = .systemSafe
  }
  private let mailCheckStack = UIStackView().then {
    $0.axis = .horizontal
    $0.spacing = 4
    $0.alignment = .leading
  }
  private let mailStack = UIStackView()

  // MARK: - Password
  private let pwLabel = UILabel().then {
    $0.text = "비밀번호"
    $0.font = .pretendard(size: 13, weight: .medium)
    $0.textColor = .grayScale700
  }
  let pwTextField = InsetTextField().then {
    $0.placeholder = "8-24자 사이 영문, 숫자, 특수문자"
    $0.layer.borderColor = UIColor.grayScale100.cgColor
    $0.layer.borderWidth = 1
    $0.layer.cornerRadius = 14
    $0.isSecureTextEntry = true
    $0.textContentType = .password
    $0.clearButtonMode = .whileEditing
    $0.font = .pretendard(size: 14, weight: .regular)
    $0.textColor = .grayScale900
    $0.returnKeyType = .next
    $0.spellCheckingType = .no
    $0.autocorrectionType = .no
    $0.autocapitalizationType = .none
  }
  private let pwCheckIcon = UIImageView().then { $0.contentMode = .scaleAspectFit }
  private let pwCheckLabel = UILabel().then {
    $0.text = " "
    $0.font = .pretendard(size: 13, weight: .medium)
    $0.textColor = .systemSafe
  }
  private let pwCheckStack = UIStackView().then {
    $0.axis = .horizontal
    $0.spacing = 4
    $0.alignment = .leading
  }
  private let pwStack = UIStackView()

  // MARK: - Re-Password
  private let rePwLabel = UILabel().then {
    $0.text = "비밀번호 확인"
    $0.font = .pretendard(size: 13, weight: .medium)
    $0.textColor = .grayScale700
  }
  let rePwTextField = InsetTextField().then {
    $0.placeholder = "8-24자 사이 영문, 숫자, 특수문자"
    $0.layer.borderColor = UIColor.grayScale100.cgColor
    $0.layer.borderWidth = 1
    $0.layer.cornerRadius = 14
    $0.isSecureTextEntry = true
    $0.textContentType = .password
    $0.clearButtonMode = .whileEditing
    $0.font = .pretendard(size: 14, weight: .regular)
    $0.textColor = .grayScale900
    $0.returnKeyType = .next
    $0.spellCheckingType = .no
    $0.autocorrectionType = .no
    $0.autocapitalizationType = .none
  }
  private let rePwCheckIcon = UIImageView().then { $0.contentMode = .scaleAspectFit }
  private let rePwCheckLabel = UILabel().then {
    $0.text = " "
    $0.font = .pretendard(size: 13, weight: .medium)
    $0.textColor = .systemSafe
  }
  private let rePwCheckStack = UIStackView().then {
    $0.axis = .horizontal
    $0.spacing = 4
    $0.alignment = .leading
  }
  private let rePwStack = UIStackView()

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
  private let nicknameStack = UIStackView()

  private let nextButton = UIButton(type: .system).then {
    $0.setTitle("다음", for: .normal)
    $0.setTitleColor(.grayScale900, for: .normal)
    $0.titleLabel?.font = .pretendard(size: 16, weight: .medium)
    $0.layer.cornerRadius = 12
    $0.isEnabled = false
    $0.backgroundColor = .primary400
  }

  // MARK: - Init
  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .white
    headerUI()
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  // MARK: - Header UI
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
    otherUI()
  }

  private func otherUI() {
    [descriptionTitleLabel, scrollView].forEach { addSubview($0) }
    scrollView.addSubview(contentView)

    [mailCheckIcon, mailCheckLabel].forEach { mailCheckStack.addArrangedSubview($0) }
    [pwCheckIcon, pwCheckLabel].forEach { pwCheckStack.addArrangedSubview($0) }
    [rePwCheckIcon, rePwCheckLabel].forEach { rePwCheckStack.addArrangedSubview($0) }
    [nicknameCheckIcon, nicknameCheckLabel].forEach { nicknameCheckStack.addArrangedSubview($0) }

    mailCheckLabel.text = " "
    pwCheckLabel.text = " "
    rePwCheckLabel.text = " "
    nicknameCheckLabel.text = " "

    mailCheckIcon.isHidden = true
    pwCheckIcon.isHidden = true
    rePwCheckIcon.isHidden = true
    nicknameCheckIcon.isHidden = true

    [mailLabel, mailTextField, mailCheckStack].forEach { mailStack.addArrangedSubview($0) }
    [pwLabel, pwTextField, pwCheckStack].forEach { pwStack.addArrangedSubview($0) }
    [rePwLabel, rePwTextField, rePwCheckStack].forEach { rePwStack.addArrangedSubview($0) }
    [nicknameLabel, nicknameTextField, nicknameCheckStack].forEach { nicknameStack.addArrangedSubview($0) }

    [mailStack, pwStack, rePwStack, nicknameStack, nextButton].forEach { contentView.addSubview($0) }

    [mailTextField, pwTextField, rePwTextField, nicknameTextField].forEach {
      $0.snp.makeConstraints { $0.height.equalTo(52) }
    }

    descriptionTitleLabel.snp.makeConstraints {
      $0.top.equalTo(headerView.snp.bottom).offset(32)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    scrollView.snp.makeConstraints {
      $0.top.equalTo(descriptionTitleLabel.snp.bottom)
      $0.leading.trailing.equalToSuperview()
      $0.bottom.equalTo(safeAreaLayoutGuide)
    }

    contentView.snp.makeConstraints {
      $0.edges.equalTo(scrollView.contentLayoutGuide)
      $0.width.equalTo(scrollView.frameLayoutGuide)
      $0.height.greaterThanOrEqualTo(scrollView.frameLayoutGuide)
    }

    mailStack.snp.makeConstraints {
      $0.top.equalTo(contentView.snp.top).offset(24)
      $0.leading.trailing.equalTo(contentView).inset(20)
    }

    pwStack.snp.makeConstraints {
      $0.top.equalTo(mailStack.snp.bottom).offset(24)
      $0.leading.trailing.equalTo(contentView).inset(20)
    }

    rePwStack.snp.makeConstraints {
      $0.top.equalTo(pwStack.snp.bottom).offset(24)
      $0.leading.trailing.equalTo(contentView).inset(20)
    }

    nicknameStack.snp.makeConstraints {
      $0.top.equalTo(rePwStack.snp.bottom).offset(24)
      $0.leading.trailing.equalTo(contentView).inset(20)
    }

    nextButton.snp.makeConstraints {
      $0.top.greaterThanOrEqualTo(nicknameStack.snp.bottom).offset(24)
      $0.leading.trailing.equalTo(contentView).inset(20)
      $0.height.equalTo(52)
      $0.bottom.equalTo(contentView.safeAreaLayoutGuide).inset(24)
    }

    nextButton.alpha = 0.5
  }
}
