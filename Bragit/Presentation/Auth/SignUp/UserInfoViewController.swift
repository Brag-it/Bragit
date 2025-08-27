//
//  UserInfoViewController.swift
//  Bragit
//
//  Created by luca on 8/25/25.
//
// 이메일, 비밀번호, 닉네임을 받는 뷰

// TODO: 키보드 내리기
// TOOD: NEXT로 다음 칸 보내기

// TODO: 라이브러리 정렬
import SnapKit
import Then
import UIKit

class UserInfoViewController: UIViewController {
  let descFont = UIFont.pretendard(size: 20, weight: .semibold)
  let textFont = UIFont.pretendard(size: 14, weight: .regular)
  let labelFont = UIFont.pretendard(size: 13, weight: .medium)
  let okFont = UIFont.pretendard(size: 16, weight: .medium)
  let acceptColor = UIColor(red: 0.208, green: 0.78, blue: 0.349, alpha: 1)
  let rejectColor = UIColor(red: 1, green: 0.224, blue: 0.235, alpha: 1)

  private let initialMail: String?
  private var isAppleLogin: Bool { initialMail != nil }

  private lazy var inputOrder: [UITextField] = [mailTextField, pwTextField, rePwTextField, nicknameTextField]

  // MARK: Validation
  private var mailValid: Bool = false
  private var passwordValid: Bool = false
  private var confirmMatched: Bool = false
  private var nicknameValid: Bool = false

  // MARK: UI
  let descriptionLabel = UILabel().then {
    $0.text = "로그인에 사용할 이메일과\n비밀번호를 입력해 주세요"
    $0.numberOfLines = 2
    $0.lineBreakMode = .byWordWrapping
    $0.setContentHuggingPriority(.required, for: .vertical)
    $0.setContentCompressionResistancePriority(.required, for: .vertical)
  }

  let mailLabel = UILabel().then { $0.text = "이메일" }

  let mailTextField = UITextField().then {
    $0.placeholder = "Bragit@bragit.com"
    $0.isEnabled = true
    $0.clearButtonMode = .whileEditing
  }

  let mailCheckLabel = UILabel().then { $0.text = " " }

  let mailStack = UIStackView().then {
    $0.axis = .vertical
    $0.spacing = 8
  }

  let pwLabel = UILabel().then { $0.text = "비밀번호" }

  let pwTextField = UITextField().then {
    $0.placeholder = "8-24자 사이 영문 소문자, 특수문자"
    // TODO: 소셜 로그인이면 false 설정
    $0.isEnabled = true
    $0.isSecureTextEntry = true
    $0.textContentType = .oneTimeCode
    $0.clearButtonMode = .whileEditing
  }

  let pwCheckLabel = UILabel().then { $0.text = " " }

  let pwStack = UIStackView().then {
    $0.axis = .vertical
    $0.spacing = 8
  }

  let rePwLabel = UILabel().then { $0.text = "비밀번호 확인" }

  let rePwTextField = UITextField().then {
    $0.placeholder = "8-24자 사이 영문 소문자, 특수문자"
    // TODO: 소셜 로그인이면 false 설정
    $0.isEnabled = true
    $0.isSecureTextEntry = true
    $0.textContentType = .oneTimeCode
    $0.clearButtonMode = .whileEditing
  }

  let rePwCheckLabel = UILabel().then { $0.text = " " }

  let rePwStack = UIStackView().then {
    $0.axis = .vertical
    $0.spacing = 8

  }

  let nicknameLabel = UILabel().then { $0.text = "닉네임" }

  let nicknameTextField = UITextField().then {
    // TODO: 닉네임 제한 설정(2-10자 등)
    $0.placeholder = "사용할 닉네임을 입력해 주세요"
    $0.clearButtonMode = .whileEditing
    $0.autocapitalizationType = .none
  }

  let nicknameCheckLabel = UILabel().then { $0.text =  " " }

  let nicknameStack = UIStackView().then {
    $0.axis = .vertical
    $0.spacing = 8
  }

  let nextButton = UIButton().then {
    $0.setTitle("확인", for: .normal)
    $0.setTitleColor(UIColor(red: 0.315, green: 0.315, blue: 0.315, alpha: 1), for: .normal)
    $0.layer.cornerRadius = 12
    $0.isEnabled = false
    $0.backgroundColor = .orange
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
    view.backgroundColor = .systemBackground
    title = "회원가입"

    // TODO: 텍스트 회색으로 처리
    let prefill = initialMail
    if let initialMail = prefill {
      mailTextField.text = initialMail
      [mailTextField, pwTextField, rePwTextField].forEach {
        $0.isEnabled = false
      }
      [pwTextField, rePwTextField].forEach {
        $0.placeholder = "social User"
      }
      mailCheckLabel.text = "사용 가능한 이메일입니다"
      mailCheckLabel.textColor = acceptColor
      pwCheckLabel.text = "사용 가능한 비밀번호입니다"
      pwCheckLabel.textColor = acceptColor
      rePwCheckLabel.text = "비밀번호가 일치합니다"
      rePwCheckLabel.textColor = acceptColor
      mailValid = true
      passwordValid = true
      confirmMatched = true
    } else {
      mailCheckLabel.text = " "
      pwCheckLabel.text = " "
    }
    nicknameCheckLabel.text = " "

    setupLayout()
    bindValidationHandlers()
    updateNextButton()
    nextButton.addTarget(self, action: #selector(onTapNext), for: .touchUpInside)

    configureReturnKeysAndDelegates()
    addKeyboardDismissGesture()
  }

  // MARK: LAYOUT
  private func setupLayout() {
    descriptionLabel.font = descFont
    nextButton.titleLabel?.font = okFont

    [
      mailLabel, mailCheckLabel,
      pwLabel, pwCheckLabel,
      rePwLabel, rePwCheckLabel,
      nicknameLabel, nicknameCheckLabel
    ].forEach {
      $0.font = labelFont
    }

    [mailTextField, pwTextField, rePwTextField].forEach {
      $0.font = textFont
    }

    [mailLabel, mailTextField, mailCheckLabel].forEach {
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

    [descriptionLabel, mailStack, pwStack, rePwStack, nicknameStack, nextButton].forEach {
      view.addSubview($0)
    }

    // snapkit
    descriptionLabel.snp.makeConstraints {
      $0.top.equalTo(view.safeAreaLayoutGuide).offset(32)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    mailTextField.snp.makeConstraints {
      $0.height.equalTo(52)
    }

    mailStack.snp.makeConstraints {
      $0.top.equalTo(descriptionLabel.snp.bottom).offset(24)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    pwTextField.snp.makeConstraints {
      $0.height.equalTo(52)
    }

    pwStack.snp.makeConstraints {
      $0.top.equalTo(mailStack.snp.bottom).offset(24)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    rePwTextField.snp.makeConstraints {
      $0.height.equalTo(52)
    }

    rePwStack.snp.makeConstraints {
      $0.top.equalTo(pwStack.snp.bottom).offset(24)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    nicknameTextField.snp.makeConstraints {
      $0.height.equalTo(52)
    }

    nicknameStack.snp.makeConstraints {
      $0.top.equalTo(rePwStack.snp.bottom).offset(24)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    nextButton.snp.makeConstraints {
      $0.height.equalTo(52)
      $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(24)
      $0.leading.trailing.equalToSuperview().inset(20)
    }
  }

  // MARK: 편집 종료 후 유효 확인
  private func bindValidationHandlers() {
    mailTextField.addTarget(self, action: #selector(onMailEditingEnd), for: .editingDidEnd)
    pwTextField.addTarget(self, action: #selector(onPasswordEditingEnd), for: .editingDidEnd)
    rePwTextField.addTarget(self, action: #selector(onConfirmEditingEnd), for: .editingDidEnd)
    nicknameTextField.addTarget(self, action: #selector(onNicknameEditingEnd), for: .editingDidEnd)
  }

  @objc private func onMailEditingEnd() {
    if isAppleLogin {
      mailValid = true
      mailCheckLabel.text = "사용 가능한 이메일입니다"
      mailCheckLabel.textColor = acceptColor
    } else {
      let text = mailTextField.text ?? ""
      mailValid = UserInfoValidator.isValidMail(text)
      mailCheckLabel.text = mailValid ? "사용 가능한 이메일입니다" : "사용 불가한 이메일입니다"
      mailCheckLabel.textColor = mailValid ? acceptColor : rejectColor
    }
    updateNextButton()
  }

  @objc private func onPasswordEditingEnd() {
    if isAppleLogin {
      passwordValid = true
      confirmMatched = true
      pwCheckLabel.text = "비밀번호가 일치합니다"
      pwCheckLabel.textColor = acceptColor
    } else {
      let pwd = pwTextField.text ?? ""
      passwordValid = UserInfoValidator.isValidPassword(pwd)
      let confirm = rePwTextField.text ?? ""
      confirmMatched = (pwd == confirm) && !pwd.isEmpty
      pwCheckLabel.text = confirmMatched ? "사용 가능한 비밀번호입니다" : "사용 불가한 비밀번호입니다"
      pwCheckLabel.textColor = mailValid ? acceptColor : rejectColor
    }
    updateNextButton()
  }

  @objc private func onConfirmEditingEnd() {
    if isAppleLogin {
      confirmMatched = true
      rePwCheckLabel.text = "비밀번호가 일치합니다"
      rePwCheckLabel.textColor = acceptColor
    } else {
      let pwd = pwTextField.text ?? ""
      let confirm = rePwTextField.text ?? ""
      confirmMatched = (pwd == confirm) && !pwd.isEmpty
      rePwCheckLabel.text = confirmMatched ? "비밀번호가 일치합니다" : "비밀번호가 불일치합니다"
      rePwCheckLabel.textColor = mailValid ? acceptColor : rejectColor
    }
    updateNextButton()
  }

  @objc private func onNicknameEditingEnd() {
    let name = nicknameTextField.text ?? ""
    nicknameValid = UserInfoValidator.isValidNickname(name)
    nicknameCheckLabel.text = nicknameValid ? "사용 가능한 닉네임입니다" : "사용 불가한 닉네임입니다"
    nicknameCheckLabel.textColor = mailValid ? acceptColor : rejectColor
    updateNextButton()
  }

  // MARK: Button State
  private func updateNextButton() {
    let enabled: Bool = isAppleLogin ? nicknameValid : (mailValid && passwordValid && confirmMatched && nicknameValid)
    nextButton.isEnabled = enabled
    nextButton.backgroundColor = enabled ? .orange : .gray
  }

  private func configureReturnKeysAndDelegates() {
    [mailTextField, pwTextField, rePwTextField].forEach { $0.returnKeyType = .next }
    nicknameTextField.returnKeyType = .done
    [mailTextField, pwTextField, rePwTextField, nicknameTextField].forEach {
      $0.delegate = self
    }
  }

  private func addKeyboardDismissGesture() {
    let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
    tap.cancelsTouchesInView = false
    view.addGestureRecognizer(tap)
  }

  @objc private func onTapNext() {
    view.endEditing(true)
    let nextVC = TermsViewController()
    navigationController?.pushViewController(nextVC, animated: true)
  }

  @objc private func dismissKeyboard() {
    view.endEditing(true)
  }
}

extension UserInfoViewController: UITextFieldDelegate {
  public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    if textField === nicknameTextField {
      textField.resignFirstResponder()
      return true
    }

    if let next = nextFocusable(after: textField) {
      next.becomeFirstResponder()
    } else {
      textField.resignFirstResponder()
    }
    return true
  }

  private func nextFocusable(after textField: UITextField) -> UITextField? {
    guard let idx = inputOrder.firstIndex(of: textField) else { return nil }
    for cnt in (idx + 1)..<inputOrder.count {
      let candidate = inputOrder[cnt]
      if candidate.isEnabled && candidate.isUserInteractionEnabled && candidate.alpha > 0.01 { return candidate
      }
    }
    return nil
  }
}
