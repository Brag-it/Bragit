//
//  MailConfirmViewController.swift
//  Bragit
//
//  Created by luca on 9/14/25.
//

import Dependencies
import RxCocoa
import RxFlow
import RxRelay
import RxSwift
import SnapKit
import Supabase
import Then
import UIKit

// TODO: 재전송 버튼, 메일에서 버튼 누르면 바로 Bragit의 MailInfoView로 갈 수 있도록

final class MailConfirmViewController: UIViewController, UITextFieldDelegate, Stepper {
  private let disposeBag = DisposeBag()
  let steps = PublishRelay<Step>()
  @Dependency(\.supabase) private var supabase

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

  let descriptionTitleLabel = UILabel().then {
    $0.text = "입력한 메일 주소로 인증 코드를 보냈어요"
    $0.font = .pretendard(size: 20, weight: .semibold)
    $0.textColor = .grayScale900
  }

  let descriptionLabel = UILabel().then {
    $0.text = "인증 코드를 아래에 입력해 주세요"
    $0.font = .pretendard(size: 16, weight: .regular)
    $0.textColor = .grayScale700
  }

  let codeTextField = UITextField().then {
    $0.layer.borderColor = UIColor.grayScale100.cgColor
    $0.layer.borderWidth = 1
    $0.layer.cornerRadius = 14
    $0.textAlignment = .center
    $0.isEnabled = true
    $0.placeholder = "000000"
    $0.clearButtonMode = .never
    $0.font = .pretendard(size: 28, weight: .semibold)
    $0.textColor = .grayScale900
    $0.keyboardType = .numberPad
    $0.autocapitalizationType = .none
    $0.spellCheckingType = .no
    $0.autocorrectionType = .no
    $0.isSecureTextEntry = false
    $0.textContentType = .oneTimeCode
  }

  let codeCheckIcon = UIImageView().then {
    $0.contentMode = .scaleAspectFit
    $0.snp.makeConstraints { $0.size.equalTo(16) }
  }

  let codeCheckLabel = UILabel().then {
    $0.text = " "
    $0.font = .pretendard(size: 13, weight: .medium)
    $0.textColor = .systemSafe
  }

  let codeCheckStack = UIStackView().then {
    $0.axis = .horizontal
    $0.spacing = 4
    $0.alignment = .leading
  }

  let helpButton = UIButton().then {
    $0.setTitle("인증 코드가 오지 않았나요?", for: .normal)
    $0.setTitleColor(.grayScale900, for: .normal)
    $0.titleLabel?.font = .pretendard(size: 14, weight: .regular)
    $0.backgroundColor = .clear
  }

  let nextButton = UIButton(type: .system).then {
    $0.setTitle("확인", for: .normal)
    $0.setTitleColor(.grayScale900, for: .normal)
    $0.titleLabel?.font = .pretendard(size: 16, weight: .medium)
    $0.layer.cornerRadius = 12
    $0.isEnabled = false
    $0.backgroundColor = .primary400
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    headerConfigureUI()

    codeTextField.delegate = self
    codeTextField.addTarget(self, action: #selector(codeEditingChanged), for: .editingChanged)
    bindActions()
  }

  private func bindActions() {
    // Enable/disable button alpha to reflect state
    nextButton.rx.observe(Bool.self, "enabled")
      .compactMap { $0 }
      .bind(with: self) { owner, isEnabled in
        owner.nextButton.alpha = isEnabled ? 1.0 : 0.5
      }
      .disposed(by: disposeBag)

    nextButton.rx.tap
      .bind(with: self) { owner, _ in
        let code = owner.codeTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard code.count == 6 else { return }
        guard let email = KeychainMailStore.load(), !email.isEmpty else {
          owner.updateCodeValidation(success: false, message: "이메일 정보를 불러올 수 없어요")
          return
        }

        // Show loading state while verifying
        owner.setLoadingState()
        owner.view.isUserInteractionEnabled = false
        owner.nextButton.alpha = 0.5

        Task {
          defer {
            DispatchQueue.main.async {
              owner.view.isUserInteractionEnabled = true
              owner.nextButton.alpha = owner.nextButton.isEnabled ? 1.0 : 0.5
            }
          }
          do {
            try await owner.supabase.auth.verifyOTP(email: email, token: code, type: .email)
            await MainActor.run {
              print("[MailConfirm] 인증 완료")
              owner.steps.accept(AppStep.signupMail)
            }
          } catch {
            await MainActor.run {
              owner.setFailureState()
            }
          }
        }
      }
      .disposed(by: disposeBag)

    helpButton.rx.tap
      .bind(with: self) { owner, _ in
        ConfirmPopupView.present(
          on: owner.view,
          title: "인증 메일을 찾을 수 없나요?",
          message: "인증 메일을 찾을 수 없다면 사용 중인 메일 서비스의 스팸함을 확인해 주세요. 확인 후 메일이 오지 않았다면 재전송을 눌러 주세요",
          leftTitle: "재전송",
          rightTitle: "닫기",
          leftAction: {},
          rightAction: {}
        )
      }
      .disposed(by: disposeBag)
  }

  private func updateCodeValidation(success: Bool, message: String) {
    codeCheckLabel.text = message
    codeCheckLabel.textColor = success ? .systemSafe : .systemDanger
    codeTextField.layer.borderColor = (success ? UIColor.systemSafe : UIColor.systemDanger).cgColor
  }

  private func setLoadingState() {
    codeCheckIcon.image = .loading
    codeCheckIcon.tintColor = .systemWarning
    codeCheckLabel.text = "코드 확인 중..."
    codeCheckLabel.textColor = .systemWarning
  }

  private func setFailureState() {
    codeCheckIcon.image = .reject
    codeCheckIcon.tintColor = .systemDanger
    codeCheckLabel.text = "코드가 불일치합니다"
    codeCheckLabel.textColor = .systemDanger
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
    [descriptionTitleLabel, descriptionLabel, codeTextField, codeCheckStack, helpButton, nextButton].forEach {
      view.addSubview($0)
    }

    [codeCheckIcon, codeCheckLabel].forEach {
      codeCheckStack.addArrangedSubview($0)
    }

    descriptionTitleLabel.snp.makeConstraints {
      $0.top.equalTo(headerView.snp.bottom).offset(32)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    descriptionLabel.snp.makeConstraints {
      $0.top.equalTo(descriptionTitleLabel.snp.bottom).offset(8)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    codeTextField.snp.makeConstraints {
      $0.top.equalTo(descriptionLabel.snp.bottom).offset(40)
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.height.equalTo(64)
    }

    codeCheckStack.snp.makeConstraints {
      $0.top.equalTo(codeTextField.snp.bottom).offset(8)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    helpButton.snp.makeConstraints {
      $0.top.equalTo(codeCheckStack.snp.bottom).offset(18)
      $0.leading.equalToSuperview().inset(20)
    }

    nextButton.snp.makeConstraints {
      $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(24)
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.height.equalTo(52)
    }
  }

  @objc private func codeEditingChanged() {
    // Allow only digits and limit to 6 characters
    let digits = codeTextField.text?.filter { $0.isNumber } ?? ""
    if digits != codeTextField.text {
      codeTextField.text = String(digits.prefix(6))
    } else if digits.count > 6 {
      codeTextField.text = String(digits.prefix(6))
    }

    let isComplete = (codeTextField.text?.count ?? 0) == 6
    nextButton.isEnabled = isComplete
    nextButton.alpha = isComplete ? 1.0 : 0.5
  }

  func textField(
    _ textField: UITextField,
    shouldChangeCharactersIn range: NSRange,
    replacementString string: String
  ) -> Bool {
    let current = textField.text ?? ""
    guard let range = Range(range, in: current) else { return true }
    let updated = current.replacingCharacters(in: range, with: string)
    let filtered = updated.filter { $0.isNumber }
    if filtered.count > 6 { return false }
    if updated != filtered { return false }
    return true
  }
}
