//
//  MailConfirmViewController.swift
//  Bragit
//
//  Created by luca on 9/14/25.
//

import RxSwift
import SnapKit
import Then
import UIKit

// TODO: 재전송 버튼, 메일에서 버튼 누르면 바로 Bragit의 MailInfoView로 갈 수 있도록

final class MailConfirmViewController: UIViewController, UITextFieldDelegate {
  private let disposeBag = DisposeBag()

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

  let codeTextField = CenteredCodeTextField().then {
    $0.layer.borderColor = UIColor.grayScale100.cgColor
    $0.layer.borderWidth = 1
    $0.layer.cornerRadius = 14
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
    $0.fixedCharacterCount = 6
    $0.horizontalPadding = 8
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
    $0.setTitle("인증 메일 보내기", for: .normal)
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
      $0.leading.trailing.equalToSuperview().inset(20)
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
  }

  // Also enforce the limit at the delegate level for paste operations
  func textField(
    _ textField: UITextField,
    shouldChangeCharactersIn range: NSRange,
    replacementString string: String
  ) -> Bool {
    // Build the prospective text
    let current = textField.text ?? ""
    guard let range = Range(range, in: current) else { return true }
    let updated = current.replacingCharacters(in: range, with: string)
    // Keep only digits and cap at 6
    let filtered = updated.filter { $0.isNumber }
    if filtered.count > 6 { return false }
    // If user typed non-digits, prevent the change
    if updated != filtered { return false }
    return true
  }
}
