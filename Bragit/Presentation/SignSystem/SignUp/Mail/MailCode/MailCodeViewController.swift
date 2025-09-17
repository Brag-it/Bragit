//
//  MailCodeViewController.swift
//  Bragit
//
//  Created by luca on 9/15/25.
//

import Dependencies
import RxCocoa
import RxSwift
import SnapKit
import Supabase
import Then
import UIKit

final class MailCodeViewController: UIViewController {
  private let headerView = UIView()
  private let backButton = UIButton(type: .system).then {
    $0.setImage(.back, for: .normal)
    $0.tintColor = .grayScale900
  }
  private let headerLabel = UILabel().then {
    $0.text = "회원가입"
    $0.font = .pretendard(size: 18, weight: .medium)
    $0.textColor = .grayScale900
    $0.textAlignment = .center
  }

  private let disposeBag = DisposeBag()
  @Dependency(\.supabase) private var supabase

  let descriptionLabel = UILabel().then {
    $0.text = "로그인에 사용할 이메일과\n비밀번호를 입력해 주세요"
    $0.numberOfLines = 2
    $0.lineBreakMode = .byWordWrapping
    $0.setContentHuggingPriority(.required, for: .vertical)
    $0.setContentCompressionResistancePriority(.required, for: .vertical)
    $0.font = .pretendard(size: 20, weight: .semibold)
    $0.textColor = .grayScale900
  }

  let codeLabel = UILabel().then {
    $0.text = "인증 코드"
    $0.font = .pretendard(size: 18, weight: .medium)
    $0.textAlignment = .center
  }

  let codeTextField = InsetTextField().then {
    $0.layer.borderColor = UIColor.grayScale100.cgColor
    $0.layer.borderWidth = 1
    $0.layer.cornerRadius = 14
    $0.isEnabled = true
    $0.clearButtonMode = .whileEditing
    $0.font = .pretendard(size: 24, weight: .bold)
    $0.textColor = .grayScale900
    $0.returnKeyType = .done
    $0.autocapitalizationType = .none
    $0.spellCheckingType = .no
    $0.autocorrectionType = .no
    $0.keyboardType = .numberPad
    $0.textAlignment = .center
    $0.textContentType = .oneTimeCode
  }

  let codeStack = UIStackView().then {
    $0.axis = .vertical
    $0.spacing = 8
  }

  let helpButton = UIButton(type: .system).then {
    $0.setTitle("메일이 오지 않았나요?", for: .normal)
    $0.setTitleColor(.grayScale900, for: .normal)
    $0.titleLabel?.font = .pretendard(size: 14, weight: .regular)
    $0.isHidden = true
  }

  let nextButton = UIButton(type: .system).then {
    $0.setTitle("다음", for: .normal)
    $0.setTitleColor(.grayScale900, for: .normal)
    $0.titleLabel?.font = .pretendard(size: 16, weight: .medium)
    $0.layer.cornerRadius = 12
    $0.isEnabled = false
    $0.alpha = 0.5
    $0.backgroundColor = .primary400
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(true, animated: false)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    headerConfigureUI()
    bindActions()
  }

  private func headerConfigureUI() {
    view.addSubview(headerView)
    headerView.addSubview(backButton)
    headerView.addSubview(headerLabel)

    headerView.snp.makeConstraints {
      $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
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

    backButton.rx.tap
      .bind(with: self) { owner, _ in
        owner.navigationController?.popViewController(animated: true)
      }
      .disposed(by: disposeBag)
  }

  private func configureUI() {
    [codeLabel, codeTextField].forEach { codeStack.addArrangedSubview($0) }
    [descriptionLabel, codeStack, helpButton, nextButton].forEach { view.addSubview($0) }

    descriptionLabel.snp.makeConstraints {
      $0.top.equalTo(headerView.snp.bottom).offset(32)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    codeStack.snp.makeConstraints {
      $0.top.equalTo(descriptionLabel.snp.bottom).offset(48)
      $0.leading.trailing.equalToSuperview().inset(40)
    }

    helpButton.snp.makeConstraints {
      $0.bottom.equalTo(nextButton.snp.top).offset(-8)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    nextButton.snp.makeConstraints {
      $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(24)
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.height.equalTo(52)
    }

  }

  private func bindActions() {
    codeTextField.rx.text.orEmpty
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .map { $0.count == 6 }
      .distinctUntilChanged()
      .bind(with: self) { owner, enabled in
        owner.nextButton.isEnabled = enabled
        owner.nextButton.alpha = enabled ? 1.0 : 0.5
      }
      .disposed(by: disposeBag)

    nextButton.rx.tap
      .bind(with: self) { owner, _ in
        guard let email = KeychainMailStore.load(), !email.isEmpty else {
          print("[MailCode] 이메일이 없습니다")
          return
        }
        guard let code = owner.codeTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
          code.count == 6
        else { return }

        owner.view.isUserInteractionEnabled = false
        owner.nextButton.alpha = 0.5

        Task {
          defer {
            DispatchQueue.main.async {
              owner.view.isUserInteractionEnabled = true
              owner.nextButton.alpha = 1.0
            }
          }
          do {
            try await owner.supabase.auth.verifyOTP(email: email, token: code, type: .email)
            print("확인완료")
          } catch {
            print("확인실패")
          }
        }
      }
      .disposed(by: disposeBag)
  }
}
