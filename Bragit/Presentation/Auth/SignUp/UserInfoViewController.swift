//
//  UserInfoScreen.swift
//  Bragit
//
//  Created by luca on 8/25/25.
//

import SnapKit
import Then
import UIKit

// MARK: - 1) 단일 파일 내 분리 타입: UI 전담
final class UserInfoFormView: UIView {

  // Public UI (VC에서 접근)
  let descriptionLabel = UILabel()
  let mailLabel = UILabel()
  let mailTextField = UITextField()
  let mailCheckLabel = UILabel()

  let pwLabel = UILabel()
  let pwTextField = UITextField()
  let pwCheckLabel = UILabel()

  let rePwLabel = UILabel()
  let rePwTextField = UITextField()
  let rePwCheckLabel = UILabel()

  let nicknameLabel = UILabel()
  let nicknameTextField = UITextField()
  let nicknameCheckLabel = UILabel()

  let nextButton = UIButton(type: .system)

  // Style tokens
  let descFont = UIFont.pretendard(size: 20, weight: .semibold)
  let textFont = UIFont.pretendard(size: 14, weight: .regular)
  let labelFont = UIFont.pretendard(size: 13, weight: .medium)
  let okFont = UIFont.pretendard(size: 16, weight: .medium)
  let acceptColor = UIColor(red: 0.208, green: 0.78, blue: 0.349, alpha: 1)
  let rejectColor = UIColor(red: 1, green: 0.224, blue: 0.235, alpha: 1)

  // Private stacks
  private let mailStack = UIStackView()
  private let pwStack = UIStackView()
  private let rePwStack = UIStackView()
  private let nicknameStack = UIStackView()

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureUI()
    setupLayout()
  }
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  private func configureUI() {
    backgroundColor = .systemBackground

    descriptionLabel.do {
      $0.text = "로그인에 사용할 이메일과\n비밀번호를 입력해 주세요"
      $0.numberOfLines = 2
      $0.lineBreakMode = .byWordWrapping
      $0.setContentHuggingPriority(.required, for: .vertical)
      $0.setContentCompressionResistancePriority(.required, for: .vertical)
      $0.font = descFont
    }

    mailLabel.do {
      $0.text = "이메일"
      $0.font = labelFont
    }
    mailTextField.do {
      $0.placeholder = "Bragit@bragit.com"
      $0.isEnabled = true
      $0.clearButtonMode = .whileEditing
      $0.font = textFont
      $0.returnKeyType = .next
      $0.autocapitalizationType = .none
    }
    mailCheckLabel.do {
      $0.text = " "
      $0.font = labelFont
    }

    pwLabel.do {
      $0.text = "비밀번호"
      $0.font = labelFont
    }
    pwTextField.do {
      $0.placeholder = "8-24자 사이 영문 소문자, 특수문자"
      $0.isEnabled = true
      $0.isSecureTextEntry = true
      $0.textContentType = .oneTimeCode
      $0.clearButtonMode = .whileEditing
      $0.font = textFont
      $0.returnKeyType = .next
    }
    pwCheckLabel.do {
      $0.text = " "
      $0.font = labelFont
    }

    rePwLabel.do {
      $0.text = "비밀번호 확인"
      $0.font = labelFont
    }
    rePwTextField.do {
      $0.placeholder = "8-24자 사이 영문 소문자, 특수문자"
      $0.isEnabled = true
      $0.isSecureTextEntry = true
      $0.textContentType = .oneTimeCode
      $0.clearButtonMode = .whileEditing
      $0.font = textFont
      $0.returnKeyType = .next
    }
    rePwCheckLabel.do {
      $0.text = " "
      $0.font = labelFont
    }

    nicknameLabel.do {
      $0.text = "닉네임"
      $0.font = labelFont
    }
    nicknameTextField.do {
      $0.placeholder = "사용할 닉네임을 입력해 주세요"
      $0.clearButtonMode = .whileEditing
      $0.autocapitalizationType = .none
      $0.font = textFont
      $0.returnKeyType = .done
    }
    nicknameCheckLabel.do {
      $0.text = " "
      $0.font = labelFont
    }

    nextButton.do {
      $0.setTitle("확인", for: .normal)
      $0.setTitleColor(UIColor(red: 0.315, green: 0.315, blue: 0.315, alpha: 1), for: .normal)
      $0.titleLabel?.font = okFont
      $0.layer.cornerRadius = 12
      $0.isEnabled = false
      $0.backgroundColor = .gray
    }

    [mailLabel, mailTextField, mailCheckLabel].forEach { mailStack.addArrangedSubview($0) }
    [pwLabel, pwTextField, pwCheckLabel].forEach { pwStack.addArrangedSubview($0) }
    [rePwLabel, rePwTextField, rePwCheckLabel].forEach { rePwStack.addArrangedSubview($0) }
    [nicknameLabel, nicknameTextField, nicknameCheckLabel].forEach { nicknameStack.addArrangedSubview($0) }

    [mailStack, pwStack, rePwStack, nicknameStack].forEach {
      $0.axis = .vertical
      $0.spacing = 8
    }
  }

  private func setupLayout() {
    [descriptionLabel, mailStack, pwStack, rePwStack, nicknameStack, nextButton]
      .forEach { addSubview($0) }

    descriptionLabel.snp.makeConstraints {
      $0.top.equalTo(safeAreaLayoutGuide).offset(32)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    [mailTextField, pwTextField, rePwTextField, nicknameTextField].forEach {
      $0.snp.makeConstraints { $0.height.equalTo(52) }
    }

    mailStack.snp.makeConstraints {
      $0.top.equalTo(descriptionLabel.snp.bottom).offset(24)
      $0.leading.trailing.equalToSuperview().inset(20)
    }
    pwStack.snp.makeConstraints {
      $0.top.equalTo(mailStack.snp.bottom).offset(24)
      $0.leading.trailing.equalToSuperview().inset(20)
    }
    rePwStack.snp.makeConstraints {
      $0.top.equalTo(pwStack.snp.bottom).offset(24)
      $0.leading.trailing.equalToSuperview().inset(20)
    }
    nicknameStack.snp.makeConstraints {
      $0.top.equalTo(rePwStack.snp.bottom).offset(24)
      $0.leading.trailing.equalToSuperview().inset(20)
    }
    nextButton.snp.makeConstraints {
      $0.height.equalTo(52)
      $0.bottom.equalTo(safeAreaLayoutGuide).inset(24)
      $0.leading.trailing.equalToSuperview().inset(20)
    }
  }
}

// MARK: - 2) VC 본체(줄 수 최소화)
final class UserInfoViewController: UIViewController {
  var onNext: ((UserRegistrationInfo) -> Void)?

  // 초기 상태
  private let initialMail: String?
  private var isAppleLogin: Bool { initialMail?.isEmpty == false }

  // 검증 상태
  fileprivate var mailValid = false
  fileprivate var passwordValid = false
  fileprivate var confirmMatched = false
  fileprivate var nicknameValid = false

  // 폼 뷰
  private let formView = UserInfoFormView()

  // 포커스 순서
  private lazy var inputOrder: [UITextField] = [
    formView.mailTextField,
    formView.pwTextField,
    formView.rePwTextField,
    formView.nicknameTextField
  ]

  init(initialMail: String?) {
    //    self.initialMail = initialMail
    if let space = initialMail?.trimmingCharacters(
      in: .whitespacesAndNewlines
    ), !space.isEmpty {
      self.initialMail = space
    } else {
      self.initialMail = nil
    }
    super.init(nibName: nil, bundle: nil)
  }
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func loadView() { view = formView }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "회원가입"
    configureInitialState()
    configureTargets()
    configureDelegates()
    addKeyboardDismissGesture()
  }

  private func configureInitialState() {
    if let mail = initialMail {
      formView.mailTextField.text = mail
      [formView.mailTextField, formView.pwTextField, formView.rePwTextField].forEach { $0.isEnabled = false }
      [formView.pwTextField, formView.rePwTextField].forEach { $0.placeholder = "social User" }

      formView.mailCheckLabel.text = "사용 가능한 이메일입니다"
      formView.mailCheckLabel.textColor = formView.acceptColor
      formView.pwCheckLabel.text = "사용 가능한 비밀번호입니다"
      formView.pwCheckLabel.textColor = formView.acceptColor
      formView.rePwCheckLabel.text = "비밀번호가 일치합니다"
      formView.rePwCheckLabel.textColor = formView.acceptColor

      mailValid = true
      passwordValid = true
      confirmMatched = true
    } else {
      formView.mailCheckLabel.text = " "
      formView.pwCheckLabel.text = " "
    }
    print("[UserInfoVC]: \(initialMail as Any)")
    formView.nicknameCheckLabel.text = " "
    updateNextButton()
  }

  private func configureTargets() {
    formView.mailTextField.addTarget(self, action: #selector(onMailEditingEnd), for: .editingDidEnd)
    formView.pwTextField.addTarget(self, action: #selector(onPasswordEditingEnd), for: .editingDidEnd)
    formView.rePwTextField.addTarget(self, action: #selector(onConfirmEditingEnd), for: .editingDidEnd)
    formView.nicknameTextField.addTarget(self, action: #selector(onNicknameEditingEnd), for: .editingDidEnd)
    formView.nextButton.addTarget(self, action: #selector(onTapNext), for: .touchUpInside)
  }

  private func configureDelegates() {
    [formView.mailTextField, formView.pwTextField, formView.rePwTextField, formView.nicknameTextField]
      .forEach { $0.delegate = self }
  }

  private func addKeyboardDismissGesture() {
    let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
    tap.cancelsTouchesInView = false
    view.addGestureRecognizer(tap)
  }

  fileprivate func updateNextButton() {
    let enabled = isAppleLogin ? nicknameValid : (mailValid && passwordValid && confirmMatched && nicknameValid)
    formView.nextButton.isEnabled = enabled
    formView.nextButton.backgroundColor = enabled ? .orange : .gray
  }

  @objc private func onTapNext() {
    let info = UserRegistrationInfo(
      mail: formView.mailTextField.text ?? "",
      password: isAppleLogin ? nil : formView.pwTextField.text,
      nickname: formView.nicknameTextField.text ?? "",
      isAppleLogin: isAppleLogin
    )
    onNext?(info)
  }

  @objc private func dismissKeyboard() { view.endEditing(true) }
}

// MARK: - 3) 같은 파일 내 익스텐션: Validation(본체 줄 수에서 제외)
extension UserInfoViewController {

  @objc func onMailEditingEnd() {
    if isAppleLogin {
      mailValid = true
      formView.mailCheckLabel.text = "사용 가능한 이메일입니다"
      formView.mailCheckLabel.textColor = formView.acceptColor
    } else {
      let text = formView.mailTextField.text ?? ""
      mailValid = UserInfoValidator.isValidMail(text)
      formView.mailCheckLabel.text = mailValid ? "사용 가능한 이메일입니다" : "사용 불가한 이메일입니다"
      formView.mailCheckLabel.textColor = mailValid ? formView.acceptColor : formView.rejectColor
    }
    updateNextButton()
  }

  @objc func onPasswordEditingEnd() {
    if isAppleLogin {
      passwordValid = true
      confirmMatched = true
      formView.pwCheckLabel.text = "비밀번호가 일치합니다"
      formView.pwCheckLabel.textColor = formView.acceptColor
    } else {
      let pwd = formView.pwTextField.text ?? ""
      passwordValid = UserInfoValidator.isValidPassword(pwd)
      let confirm = formView.rePwTextField.text ?? ""
      confirmMatched = (pwd == confirm) && !pwd.isEmpty
      formView.pwCheckLabel.text = (confirmMatched && passwordValid) ? "사용 가능한 비밀번호입니다" : "사용 불가한 비밀번호입니다"
      formView.pwCheckLabel.textColor = (confirmMatched && passwordValid) ? formView.acceptColor : formView.rejectColor
    }
    updateNextButton()
  }

  @objc func onConfirmEditingEnd() {
    if isAppleLogin {
      confirmMatched = true
      formView.rePwCheckLabel.text = "비밀번호가 일치합니다"
      formView.rePwCheckLabel.textColor = formView.acceptColor
    } else {
      let pwd = formView.pwTextField.text ?? ""
      let confirm = formView.rePwTextField.text ?? ""
      confirmMatched = (pwd == confirm) && !pwd.isEmpty
      formView.rePwCheckLabel.text = confirmMatched ? "비밀번호가 일치합니다" : "비밀번호가 불일치합니다"
      formView.rePwCheckLabel.textColor = confirmMatched ? formView.acceptColor : formView.rejectColor
    }
    updateNextButton()
  }

  @objc func onNicknameEditingEnd() {
    let name = formView.nicknameTextField.text ?? ""
    nicknameValid = UserInfoValidator.isValidNickname(name)
    formView.nicknameCheckLabel.text = nicknameValid ? "사용 가능한 닉네임입니다" : "사용 불가한 닉네임입니다"
    formView.nicknameCheckLabel.textColor = nicknameValid ? formView.acceptColor : formView.rejectColor
    updateNextButton()
  }
}

// MARK: - 4) 같은 파일 내 익스텐션: Delegate(본체 줄 수에서 제외)
extension UserInfoViewController: UITextFieldDelegate {
  public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    if textField === formView.nicknameTextField {
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
    for index in (idx + 1)..<inputOrder.count {
      let cnt = inputOrder[index]
      if cnt.isEnabled && cnt.isUserInteractionEnabled && cnt.alpha > 0.01 { return cnt }
    }
    return nil
  }
}
