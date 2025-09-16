//
//  MailOnlyViewController.swift
//  Bragit
//
//  Created by luca on 9/15/25.
//

import UIKit

import Dependencies
import Functions
import ReactorKit
import RxCocoa
import RxSwift
import Supabase
import Then

final class MailOnlyViewController: UIViewController, UITextFieldDelegate, View {
  typealias Reactor = MailOnlyReactor
  var disposeBag = DisposeBag()
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
    $0.setTitle("인증 코드 보내기", for: .normal)
    $0.setTitleColor(.grayScale900, for: .normal)
    $0.titleLabel?.font = .pretendard(size: 16, weight: .medium)
    $0.layer.cornerRadius = 12
    $0.isEnabled = false
    $0.backgroundColor = .primary400
  }

  // Edge Function name used to check if an auth user exists by email
  private let checkAuthUserFunctionName = "check-auth-user"

  private struct CheckAuthUserResponse: Decodable {
    let exists: Bool
    let status: String
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(true, animated: false)
    nextButton.isEnabled = false
    nextButton.alpha = 0.5
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    headerConfigureUI()
    setupKeyboardDismiss()
    mailTextField.delegate = self
    bindActions()
    if reactor == nil { reactor = MailOnlyReactor() }
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
    view.addSubview(descriptionTitleLabel)
    view.addSubview(descriptionLabel)
    view.addSubview(mailLabel)
    view.addSubview(mailTextField)
    view.addSubview(mailCheckStack)
    view.addSubview(nextButton)

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
    let tap = UITapGestureRecognizer()
    tap.cancelsTouchesInView = false
    view.addGestureRecognizer(tap)

    tap.rx.event
      .bind(with: self) { owner, _ in
        owner.view.endEditing(true)
      }
      .disposed(by: disposeBag)
  }

  private func bindActions() {
    let emailText = mailTextField.rx.text.orEmpty
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .share(replay: 1)

    // let isValid = emailText
    //   .map { [weak self] in self?.isValidEmail($0) == true }
    //   .distinctUntilChanged()
    //   .share(replay: 1)

    emailText
      .distinctUntilChanged()
      .bind(with: self) { owner, _ in
        owner.nextButton.isEnabled = false
        owner.nextButton.alpha = 0.5
      }
      .disposed(by: disposeBag)

    mailTextField.rx.controlEvent(.editingDidEnd)
      .withLatestFrom(emailText)
      .bind(with: self) { owner, email in
        if owner.isValidEmail(email) {
          owner.mailCheckLabel.text = "이메일 확인 중..."
          owner.mailCheckLabel.textColor = .systemWarning
          owner.mailCheckIcon.image = .loading
          owner.mailCheckIcon.tintColor = .systemWarning

          struct CheckEmailPayload: Encodable { let email: String }
          let payload = CheckEmailPayload(email: email.lowercased())
          Task {
            do {
              let data = try JSONEncoder().encode(payload)
              let options = FunctionInvokeOptions(
                method: .post,
                headers: ["Content-Type": "application/json"],
                body: data
              )
              let resp: CheckAuthUserResponse = try await owner.supabase.functions.invoke(
                owner.checkAuthUserFunctionName,
                options: options
              )
              print("[check-auth-user] exists=\(resp.exists), status=\(resp.status)")
              switch resp.status {
              case "confirmed":
                await MainActor.run {
                  owner.mailCheckLabel.text = "이미 가입된 이메일입니다"
                  owner.mailCheckLabel.textColor = .systemDanger
                  owner.mailCheckIcon.image = .reject
                  owner.mailCheckIcon.tintColor = .systemDanger
                  owner.nextButton.isEnabled = false
                  owner.nextButton.alpha = 0.5
                }
              case "not_found":
                await MainActor.run {
                  owner.mailCheckLabel.text = "사용 가능한 이메일입니다"
                  owner.mailCheckLabel.textColor = .systemSafe
                  owner.mailCheckIcon.image = .accept
                  owner.mailCheckIcon.tintColor = .systemSafe
                  owner.nextButton.isEnabled = true
                  owner.nextButton.alpha = 1.0
                }
              case "waiting":
                await MainActor.run {
                  owner.mailCheckLabel.text = "사용 가능한 이메일입니다"
                  owner.mailCheckLabel.textColor = .systemSafe
                  owner.mailCheckIcon.image = .accept
                  owner.mailCheckIcon.tintColor = .systemSafe
                  owner.nextButton.isEnabled = true
                  owner.nextButton.alpha = 1.0
                }
              case "banned":
                await MainActor.run {
                  owner.mailCheckLabel.text = "사용이 제한된 이메일입니다"
                  owner.mailCheckLabel.textColor = .systemDanger
                  owner.mailCheckIcon.image = .reject
                  owner.mailCheckIcon.tintColor = .systemDanger
                  owner.nextButton.isEnabled = false
                  owner.nextButton.alpha = 0.5
                }
              default:
                break
              }
            } catch {
              if let fnError = error as? FunctionsError {
                switch fnError {
                case .httpError(let code, let data):
                  let bodyText = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
                  print("[check-auth-user] httpError code=\(code), body=\(bodyText)")
                default:
                  print("[check-auth-user] functions error: \(fnError)")
                }
              } else {
                print("[check-auth-user] error: \(error)")
              }
            }
          }
        } else {
          owner.mailCheckLabel.text = "유효하지 않은 메일 형식입니다"
          owner.mailCheckLabel.textColor = .systemDanger
          owner.mailCheckIcon.image = .reject
          owner.mailCheckIcon.tintColor = .systemDanger
          owner.nextButton.isEnabled = false
          owner.nextButton.alpha = 0.5
        }
      }
      .disposed(by: disposeBag)
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

extension MailOnlyViewController {
  func bind(reactor: MailOnlyReactor) {
    nextButton.rx.tap
      .withLatestFrom(
        mailTextField.rx.text.orEmpty.map {
          $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
      )
      .bind(with: self) { owner, email in
        owner.view.endEditing(true)
        guard owner.isValidEmail(email) else { return }
        reactor.action.onNext(.tapNext(email: email))
      }
      .disposed(by: disposeBag)

    reactor.state.map(\.isLoading)
      .distinctUntilChanged()
      .observe(on: MainScheduler.instance)
      .bind(with: self) { owner, loading in
        owner.view.isUserInteractionEnabled = !loading
        owner.nextButton.alpha = loading ? 0.5 : 1.0
      }
      .disposed(by: disposeBag)

    reactor.state.compactMap(\.errorMessage)
      .observe(on: MainScheduler.instance)
      .bind(with: self) { owner, message in
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "확인", style: .default))
        owner.present(alert, animated: true)
      }
      .disposed(by: disposeBag)
  }
}
