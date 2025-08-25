//
//  UserInfoViewController.swift
//  Bragit
//
//  Created by luca on 8/25/25.
//
// 이메일, 비밀번호, 닉네임을 받는 뷰

import SnapKit
import Then
// TODO: 라이브러리 정렬
import UIKit

class UserInfoViewController: UIViewController {
  let descFont = UIFont.pretendard(size: 20, weight: .semibold)
  let textFont = UIFont.pretendard(size: 13, weight: .medium)

  private let initialMail: String?

  // MAKR: UI
  let descriptionLabel = UILabel().then {
    $0.text = "로그인에 사용할 이메일과\n비밀번호를 입력해 주세요"
    $0.numberOfLines = 2
  }

  let mailLabel = UILabel().then {
    $0.text = "이메일"
  }

  let mailTextField = UITextField().then {
    $0.placeholder = "Bragit@bragit.com"
    // TODO: 소셜 로그인이면 false 설정 및 소셜 이메일 넣기
    $0.isEnabled = true
    $0.clearButtonMode = .whileEditing
  }

  let mailChekcLabel = UILabel().then {
    $0.text = "dd"
  }

  let mailStack = UIStackView().then {
    $0.axis = .vertical
    $0.spacing = 8
  }

  let pwLabel = UILabel().then {
    $0.text = "비밀번호"
  }

  let pwTextField = UITextField().then {
    $0.placeholder = "8-24자 사이 영문 소문자, 특수문자"
    // TODO: 소셜 로그인이면 false 설정
    $0.isEnabled = true
    $0.clearButtonMode = .whileEditing
  }

  let pwCheckLabel = UILabel().then {
    $0.text = "dd"
  }

  let pwStack = UIStackView().then {
    $0.axis = .vertical
    $0.spacing = 8
  }

  let rePwLabel = UILabel().then {
    $0.text = "비밀번호 확인"
  }

  let rePwTextField = UITextField().then {
    $0.placeholder = "8-24자 사이 영문 소문자, 특수문자"
    // TODO: 소셜 로그인이면 false 설정
    $0.isEnabled = true
    $0.clearButtonMode = .whileEditing
  }

  let rePwCheckLabel = UILabel().then {
    $0.text = "dd"
  }

  let rePwStack = UIStackView().then {
    $0.axis = .vertical
    $0.spacing = 8

  }

  let nicknameLabel = UILabel().then {
    $0.text = "닉네임"
  }

  let nicknameTextField = UITextField().then {
    // TODO: 닉네임 제한 설정(2-10자 등)
    $0.placeholder = "사용할 닉네임을 입력해 주세요"
    $0.clearButtonMode = .whileEditing
  }

  let nicknameCheckLabel = UILabel().then {
    $0.text = "dd"
  }

  let nicknameStack = UIStackView().then {
    $0.axis = .vertical
    $0.spacing = 8
  }

  init(initialMail: String?) {
    self.initialMail = initialMail
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    title = "회원가입"

    // 소셜 로그인이면 메일 입력
    if let initialMail {
      mailTextField.text = initialMail
      [mailTextField, pwTextField, rePwTextField].forEach {
        $0.isEnabled = false
      }
    }

    setupLayout()
  }

  // MARK: LAYOUT
  private func setupLayout() {
    view.backgroundColor = .systemBackground
    descriptionLabel.font = descFont

    [
      mailLabel, mailChekcLabel,
      pwLabel, pwCheckLabel,
      rePwLabel, rePwCheckLabel,
      nicknameLabel, nicknameCheckLabel
    ].forEach {
      $0.font = textFont
    }

    [mailLabel, mailTextField, mailChekcLabel].forEach {
      mailStack.addArrangedSubview($0)
    }

    [pwLabel, pwTextField, pwCheckLabel].forEach {
      pwStack.addArrangedSubview($0)
    }

    [rePwLabel, rePwTextField, rePwCheckLabel].forEach {
      rePwStack.addArrangedSubview($0)
    }

    [nicknameLabel, nicknameTextField, nicknameCheckLabel].forEach {
      nicknameStack.addArrangedSubview($0)
    }

    [descriptionLabel, mailStack, pwStack, rePwStack, nicknameStack].forEach {
      view.addSubview($0)
    }

    // snapkit
    descriptionLabel.snp.makeConstraints {
      $0.top.equalTo(view.safeAreaLayoutGuide).offset(32)
      $0.leading.equalToSuperview().inset(20)
    }
    
    mailTextField.snp.makeConstraints {
      $0.height.equalTo(52)
    }
    
    mailStack.snp.makeConstraints {
      $0.top.equalTo(descriptionLabel.snp.bottom).offset(32)
      $0.leading.trailing.equalToSuperview().inset(20)
    }
    
    pwTextField.snp.makeConstraints {
      $0.height.equalTo(52)
    }
    
    pwStack.snp.makeConstraints {
      $0.top.equalTo(mailStack.snp.bottom).offset(32)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    rePwTextField.snp.makeConstraints {
      $0.height.equalTo(52)
    }
    
    rePwStack.snp.makeConstraints {
      $0.top.equalTo(pwStack.snp.bottom).offset(32)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    nicknameTextField.snp.makeConstraints {
      $0.height.equalTo(52)
    }
    
    nicknameStack.snp.makeConstraints {
      $0.top.equalTo(rePwStack.snp.bottom).offset(32)
      $0.leading.trailing.equalToSuperview().inset(20)
    }
  }

  // MARK: PRIVATE

}
