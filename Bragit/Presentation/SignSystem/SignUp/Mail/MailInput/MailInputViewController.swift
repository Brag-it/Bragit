//
//  MailOnlyViewController.swift
//  Bragit
//
//  Created by luca on 9/15/25.
//

import Dependencies
import RxCocoa
import RxSwift
import Then
import UIKit
import Supabase
import Functions

// Edge Function name used to check if an auth user exists by email
private let checkAuthUserFunctionName = "check-auth-user" // Change this if your deployed function name differs

// Minimal response model for the edge function
private struct CheckAuthUserResponse: Decodable {
  let exists: Bool
  let status: String
}

final class MailInputViewController: UIViewController, UITextFieldDelegate {
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

  let descriptionTitleLabel = UILabel().then {
    $0.text = "로그인에 사용할 이메일을 입력해 주세요"
    $0.font = .pretendard(size: 20, weight: .semibold)
    $0.textColor = .grayScale900
  }

  let descriptionLabel = UILabel().then {
    $0.text = "입력한 메일 주소로 인증 메일을 보내 드려요"
    $0.font = .pretendard(size: 16, weight: .regular)
    $0.textColor = .grayScale700
  }

  let mailLabel = UILabel().then {
    $0.text = "이메일"
    $0.font = .pretendard(size: 13, weight: .medium)
    $0.textColor = .grayScale700
  }

  let mailTextField = InsetTextField().then {
    $0.placeholder = "bragit@bragit.com"
    $0.layer.borderColor = UIColor.grayScale100.cgColor
    $0.layer.borderWidth = 1
    $0.layer.cornerRadius = 14
    $0.isEnabled = true
    $0.clearButtonMode = .whileEditing
    $0.font = .pretendard(size: 14, weight: .regular)
    $0.textColor = .grayScale900
    $0.returnKeyType = .done
    $0.autocapitalizationType = .none
    $0.spellCheckingType = .no
    $0.autocorrectionType = .no
    $0.textContentType = .emailAddress
  }

  let mailCheckIcon = UIImageView().then {
    $0.contentMode = .scaleAspectFit
    $0.snp.makeConstraints { $0.size.equalTo(16) }
  }

  let mailCheckLabel = UILabel().then {
    $0.text = " "
    $0.font = .pretendard(size: 13, weight: .medium)
    $0.textColor = .systemSafe
  }

  let mailCheckStack = UIStackView().then {
    $0.axis = .horizontal
    $0.spacing = 4
    $0.alignment = .leading
  }

  let nextButton = UIButton(type: .system).then {
    $0.setTitle("인증 메일 보내기", for: .normal)
    $0.setTitleColor(.grayScale900, for: .normal)
    $0.titleLabel?.font = .pretendard(size: 16, weight: .medium)
    $0.layer.cornerRadius = 12
    $0.isEnabled = false
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
    setupKeyboardDismiss()
    mailTextField.delegate = self
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
      .bind(with: self) { (owner: MailInputViewController, _: Void) in
        owner.navigationController?.popViewController(animated: true)
      }
      .disposed(by: disposeBag)
  }

  private func configureUI() {
    view.addSubview(descriptionTitleLabel)
    view.addSubview(descriptionLabel)
    view.addSubview(mailLabel)
    view.addSubview(mailTextField)
    view.addSubview(mailCheckStack)
    view.addSubview(nextButton)

    nextButton.alpha = 0.5

    [mailCheckIcon, mailCheckLabel].forEach { mailCheckStack.addArrangedSubview($0) }

    descriptionTitleLabel.snp.makeConstraints {
      $0.top.equalTo(headerView.snp.bottom).offset(32)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    descriptionLabel.snp.makeConstraints {
      $0.top.equalTo(descriptionTitleLabel.snp.bottom).offset(8)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    mailLabel.snp.makeConstraints {
      $0.top.equalTo(descriptionLabel.snp.bottom).offset(32)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    mailTextField.snp.makeConstraints {
      $0.top.equalTo(mailLabel.snp.bottom).offset(8)
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.height.equalTo(52)
    }

    mailCheckStack.snp.makeConstraints {
      $0.top.equalTo(mailTextField.snp.bottom).offset(8)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    nextButton.snp.makeConstraints {
      $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(24)
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.height.equalTo(52)
    }
  }

  private func setupKeyboardDismiss() {
    let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
    tap.cancelsTouchesInView = false
    view.addGestureRecognizer(tap)
  }

  private func bindActions() {
    mailTextField.rx.text.orEmpty
      .map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
      .map { [weak self] in self?.isValidEmail($0) == true }
      .distinctUntilChanged()
      .bind(with: self) { (owner: MailInputViewController, isValid: Bool) in
        owner.nextButton.isEnabled = isValid
        owner.nextButton.alpha = isValid ? 1.0 : 0.5
      }
      .disposed(by: disposeBag)

    mailTextField.rx.controlEvent(.editingDidEnd)
      .bind(with: self) { (owner: MailInputViewController, _: Void) in
        owner.dismissKeyboard()
        let raw = owner.mailTextField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) ?? ""
        guard !raw.isEmpty else {
          owner.mailCheckLabel.text = "이메일을 입력해 주세요"
          owner.mailCheckLabel.textColor = .grayScale700
          owner.mailCheckIcon.image = nil
          owner.nextButton.isEnabled = false
          owner.nextButton.alpha = 0.5
          return
        }
        guard owner.isValidEmail(raw) else {
          owner.mailCheckLabel.text = "유효하지 않은 이메일 형식입니다"
          owner.mailCheckLabel.textColor = .systemDanger
          owner.mailCheckIcon.image = .reject
          owner.nextButton.isEnabled = false
          owner.nextButton.alpha = 0.5
          return
        }
        owner.mailCheckLabel.text = "사용 가능한 형식의 이메일입니다"
        owner.mailCheckLabel.textColor = .systemSafe
        owner.mailCheckIcon.image = .accept
      }
      .disposed(by: disposeBag)

    nextButton.rx.tap
      .bind(with: self) { (owner: MailInputViewController, _: Void) in
        // Prepare normalized email
        let raw = owner.mailTextField.text?
          .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
          .lowercased() ?? ""

        guard owner.isValidEmail(raw) else {
          owner.showWarningAlert(message: "유효한 이메일을 입력해 주세요.")
          return
        }

        struct CheckEmailPayload: Encodable { let email: String }
        let payload = CheckEmailPayload(email: raw)

        Task {
          do {
            let data = try JSONEncoder().encode(payload)
            let options = FunctionInvokeOptions(
              method: .post,
              headers: [
                "Content-Type": "application/json"
              ],
              body: data
            )
            let resp: CheckAuthUserResponse = try await owner.supabase.functions.invoke(
              checkAuthUserFunctionName,
              options: options
            )
            print("[check-auth-user] exists=\(resp.exists), status=\(resp.status)")
          } catch {
            // Try to extract HTTP error details if available
            if let fnError = error as? FunctionsError {
              switch fnError {
              case let .httpError(code, data):
                let bodyText = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
                print("[check-auth-user] httpError code=\(code), body=\(bodyText)")
              default:
                print("[check-auth-user] functions error: \(fnError)")
              }
            } else {
              print("[check-auth-user] error: \(error)")
            }
            owner.showWarningAlert(message: "서버 통신 중 오류가 발생했어요. 잠시 후 다시 시도해 주세요.")
          }
        }
      }
      .disposed(by: disposeBag)
  }

  @objc private func dismissKeyboard() {
    view.endEditing(true)
  }

  private func showWarningAlert(message: String) {
    let alert = UIAlertController(title: "경고", message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
    present(alert, animated: true)
  }

  private func isValidEmail(_ email: String) -> Bool {
    let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
    let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
    return predicate.evaluate(with: email)
  }

  // MARK: - UITextFieldDelegate
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
}
