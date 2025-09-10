import UIKit

import SnapKit
import Then
import ReactorKit
import RxSwift
import RxCocoa

final class UserInfoFormView: UIView {
  let descriptionLabel = UILabel()
  let scrollView = UIScrollView()
  let contentView = UIView()
  let mailLabel = UILabel()
  let mailTextField = InsetTextField()
  let mailCheckIcon = UIImageView()
  let mailCheckLabel = UILabel()
  let mailCheckStack = UIStackView()

  let pwLabel = UILabel()
  let pwTextField = InsetTextField()
  let pwCheckIcon = UIImageView()
  let pwCheckLabel = UILabel()
  let pwCheckStack = UIStackView()

  let rePwLabel = UILabel()
  let rePwTextField = InsetTextField()
  let rePwCheckIcon = UIImageView()
  let rePwCheckLabel = UILabel()
  let rePwCheckStack = UIStackView()

  let nicknameLabel = UILabel()
  let nicknameTextField = InsetTextField()
  let nicknameCheckIcon = UIImageView()
  let nicknameCheckLabel = UILabel()
  let nicknameCheckStack = UIStackView()

  let nextButton = UIButton(type: .system)

  let descFont = UIFont.pretendard(size: 20, weight: .semibold)
  let textFont = UIFont.pretendard(size: 14, weight: .regular)
  let labelFont = UIFont.pretendard(size: 13, weight: .medium)
  let okFont = UIFont.pretendard(size: 16, weight: .medium)
  let fontColor = UIColor.grayScale900
  let labelColor = UIColor.grayScale700
  let buttonColor = UIColor.primary400
  let acceptColor = UIColor.systemSafe
  let rejectColor = UIColor.systemDanger
  let warningColor = UIColor.systemWarning

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
    backgroundColor = .white
    scrollView.keyboardDismissMode = .interactive
    contentView.backgroundColor = .clear
    contentView.isUserInteractionEnabled = true
    scrollView.isUserInteractionEnabled = true
    scrollView.alwaysBounceVertical = true
    scrollView.showsVerticalScrollIndicator = true
    scrollView.delaysContentTouches = false

    descriptionLabel.do {
      $0.text = "로그인에 사용할 이메일과\n비밀번호를 입력해 주세요"
      $0.numberOfLines = 2
      $0.lineBreakMode = .byWordWrapping
      $0.setContentHuggingPriority(.required, for: .vertical)
      $0.setContentCompressionResistancePriority(.required, for: .vertical)
      $0.font = descFont
      $0.textColor = fontColor
    }

    mailLabel.do {
      $0.text = "이메일"
      $0.font = labelFont
      $0.textColor = labelColor
    }
    mailTextField.do {
      $0.placeholder = "Bragit@bragit.com"
      $0.layer.borderColor = UIColor(named: "grayScale100")?.cgColor
      $0.layer.borderWidth = 1
      $0.layer.cornerRadius = 14
      $0.isEnabled = true
      $0.clearButtonMode = .whileEditing
      $0.font = textFont
      $0.textColor = fontColor
      $0.returnKeyType = .next
      $0.autocapitalizationType = .none
      $0.spellCheckingType = .no
      $0.autocorrectionType = .no
      $0.textContentType = .username
    }
    mailCheckIcon.do {
      $0.contentMode = .scaleAspectFit
      $0.snp.makeConstraints { $0.size.equalTo(16) }
    }
    mailCheckLabel.do {
      $0.text = " "
      $0.font = labelFont
      $0.textColor = labelColor
    }
    mailCheckStack.do {
      $0.axis = .horizontal
      $0.spacing = 4
      $0.alignment = .leading
      $0.addArrangedSubview(mailCheckIcon)
      $0.addArrangedSubview(mailCheckLabel)
    }

    pwLabel.do {
      $0.text = "비밀번호"
      $0.font = labelFont
      $0.textColor = labelColor
    }
    pwTextField.do {
      $0.placeholder = "8-24자 사이 영문, 숫자, 특수문자"
      $0.layer.borderColor = UIColor(named: "grayScale100")?.cgColor
      $0.layer.borderWidth = 1
      $0.layer.cornerRadius = 14
      $0.isEnabled = true
      $0.isSecureTextEntry = true
      $0.textContentType = .password
      $0.clearButtonMode = .whileEditing
      $0.font = textFont
      $0.textColor = fontColor
      $0.returnKeyType = .next
      $0.spellCheckingType = .no
      $0.autocorrectionType = .no
      $0.autocapitalizationType = .none
    }
    pwCheckIcon.do {
      $0.contentMode = .scaleAspectFit
      $0.snp.makeConstraints { $0.size.equalTo(16) }
    }
    pwCheckLabel.do {
      $0.text = " "
      $0.font = labelFont
      $0.textColor = labelColor
    }
    pwCheckStack.do {
      $0.axis = .horizontal
      $0.spacing = 4
      $0.alignment = .leading
      $0.addArrangedSubview(pwCheckIcon)
      $0.addArrangedSubview(pwCheckLabel)
    }

    rePwLabel.do {
      $0.text = "비밀번호 확인"
      $0.font = labelFont
      $0.textColor = labelColor
    }
    rePwTextField.do {
      $0.placeholder = "8-24자 사이 영문, 숫자, 특수문자"
      $0.layer.borderColor = UIColor(named: "grayScale100")?.cgColor
      $0.layer.borderWidth = 1
      $0.layer.cornerRadius = 14
      $0.isEnabled = true
      $0.isSecureTextEntry = true
      $0.textContentType = .password
      $0.clearButtonMode = .whileEditing
      $0.font = textFont
      $0.textColor = fontColor
      $0.returnKeyType = .next
      $0.spellCheckingType = .no
      $0.autocorrectionType = .no
      $0.autocapitalizationType = .none
    }
    rePwCheckIcon.do {
      $0.contentMode = .scaleAspectFit
      $0.snp.makeConstraints { $0.size.equalTo(16) }
    }
    rePwCheckLabel.do {
      $0.text = " "
      $0.font = labelFont
      $0.textColor = labelColor
    }
    rePwCheckStack.do {
      $0.axis = .horizontal
      $0.spacing = 4
      $0.alignment = .leading
      $0.addArrangedSubview(rePwCheckIcon)
      $0.addArrangedSubview(rePwCheckLabel)
    }

    nicknameLabel.do {
      $0.text = "닉네임"
      $0.font = labelFont
      $0.textColor = labelColor
    }
    nicknameTextField.do {
      $0.placeholder = "2-8자 사이 영문, 숫자"
      $0.layer.borderColor = UIColor(named: "grayScale100")?.cgColor
      $0.layer.borderWidth = 1
      $0.layer.cornerRadius = 14
      $0.clearButtonMode = .whileEditing
      $0.font = textFont
      $0.textColor = fontColor
      $0.returnKeyType = .done
      $0.autocapitalizationType = .none
      $0.spellCheckingType = .no
      $0.autocorrectionType = .no
    }
    nicknameCheckIcon.do {
      $0.contentMode = .scaleAspectFit
      $0.snp.makeConstraints { $0.size.equalTo(16) }
    }
    nicknameCheckLabel.do {
      $0.text = " "
      $0.font = labelFont
      $0.textColor = labelColor
    }
    nicknameCheckStack.do {
      $0.axis = .horizontal
      $0.spacing = 4
      $0.alignment = .leading
      $0.addArrangedSubview(nicknameCheckIcon)
      $0.addArrangedSubview(nicknameCheckLabel)
    }

    nextButton.do {
      $0.setTitle("다음", for: .normal)
      $0.setTitleColor(fontColor, for: .normal)
      $0.titleLabel?.font = okFont
      $0.layer.cornerRadius = 12
      $0.isEnabled = false
      $0.backgroundColor = buttonColor
    }

    [mailLabel, mailTextField, mailCheckStack].forEach { mailStack.addArrangedSubview($0) }
    [pwLabel, pwTextField, pwCheckStack].forEach { pwStack.addArrangedSubview($0) }
    [rePwLabel, rePwTextField, rePwCheckStack].forEach { rePwStack.addArrangedSubview($0) }
    [nicknameLabel, nicknameTextField, nicknameCheckStack].forEach { nicknameStack.addArrangedSubview($0) }

    [mailStack, pwStack, rePwStack, nicknameStack].forEach {
      $0.axis = .vertical
      $0.spacing = 8
    }
  }

  private func setupLayout() {
    addSubview(descriptionLabel)
    addSubview(scrollView)
    scrollView.addSubview(contentView)

    [mailStack, pwStack, rePwStack, nicknameStack, nextButton]
      .forEach { contentView.addSubview($0) }

    [mailTextField, pwTextField, rePwTextField, nicknameTextField].forEach {
      $0.snp.makeConstraints { $0.height.equalTo(52) }
    }

    scrollView.snp.makeConstraints {
      $0.top.equalTo(descriptionLabel.snp.bottom)
      $0.leading.trailing.equalToSuperview()
      $0.bottom.equalTo(safeAreaLayoutGuide)
    }

    contentView.snp.makeConstraints {
      $0.edges.equalTo(scrollView.contentLayoutGuide)
      $0.width.equalTo(scrollView.frameLayoutGuide)
      $0.height.greaterThanOrEqualTo(scrollView.frameLayoutGuide)
    }

    descriptionLabel.snp.makeConstraints {
      $0.top.equalTo(safeAreaLayoutGuide).offset(32)
      $0.leading.trailing.equalToSuperview().inset(20)
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
  }
}

final class UserInfoViewController: UIViewController {
  var onNext: ((UserRegistrationInfo) -> Void)?

  private let initialMail: String?
  private var isAppleLogin: Bool
  private let refreshToken: String?

  fileprivate var mailValid = false
  fileprivate var passwordValid = false
  fileprivate var confirmMatched = false
  fileprivate var nicknameValid = false

  private let headerView = UIView()
  private let backButton = UIButton(type: .system).then {
    $0.setImage(.back, for: .normal)
    $0.tintColor = .grayScale900
  }
  private let headerLabel = UILabel().then {
    $0.text = "회원가입"
    $0.font = UIFont.systemFont(ofSize: 16)
    $0.textColor = .grayScale900
    $0.textAlignment = .center
  }

  private let formView = UserInfoFormView()
  private var inputOrder: [UITextField] = []
  private var keyboardBottomInset: CGFloat = 0
  private weak var currentFirstResponder: UITextField?

  private let reactorBag = DisposeBag()
  private let nicknameReactor = UserInfoReactor()

  init(initialMail: String?, refreshToken: String?, isAppleLogin: Bool) {
    if let space = initialMail?.trimmingCharacters(in: .whitespacesAndNewlines), !space.isEmpty {
      self.initialMail = space
    } else {
      self.initialMail = nil
    }
    self.refreshToken = refreshToken
    self.isAppleLogin = isAppleLogin
    super.init(nibName: nil, bundle: nil)
  }
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(true, animated: false)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white

    setupHeaderAndContentLayout()

    title = "회원가입"
    configureInitialState()
    configureInputOrder()
    configureTargets()
    configureDelegates()
    addKeyboardDismissGesture()
    registerKeyboardNotifications()
    bindNicknameReactor()

    backButton.rx.tap
      .bind(with: self) { owner, _ in
        owner.navigationController?.popViewController(animated: true)
      }
      .disposed(by: reactorBag)
  }

  private func setupHeaderAndContentLayout() {
    view.addSubview(headerView)
    headerView.addSubview(backButton)
    headerView.addSubview(headerLabel)
    view.addSubview(formView)

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

    formView.snp.makeConstraints {
      $0.top.equalTo(headerView.snp.bottom)
      $0.leading.trailing.bottom.equalToSuperview()
    }
  }

  private func bindNicknameReactor() {
    nicknameReactor.state
      .map(\.nicknameStatusText)
      .distinctUntilChanged()
      .observe(on: MainScheduler.instance)
      .subscribe(with: self) { owner, text in
        owner.formView.nicknameCheckLabel.text = text
        switch text {
        case "사용 가능한 닉네임입니다":
          owner.formView.nicknameCheckLabel.textColor = owner.formView.acceptColor
          owner.formView.nicknameCheckIcon.image = UIImage.accept.withRenderingMode(.alwaysOriginal)
        case "사용 중인 닉네임입니다", "닉네임 확인 실패", "사용 불가한 닉네임입니다":
          owner.formView.nicknameCheckLabel.textColor = owner.formView.rejectColor
          owner.formView.nicknameCheckIcon.image = UIImage.reject.withRenderingMode(.alwaysOriginal)
        case "중복 확인 중...":
          owner.formView.nicknameCheckLabel.textColor = owner.formView.warningColor
          owner.formView.nicknameCheckIcon.image = nil
        default:
          break
        }
      }
      .disposed(by: reactorBag)

    nicknameReactor.state
      .map(\.nicknameValid)
      .distinctUntilChanged()
      .observe(on: MainScheduler.instance)
      .subscribe(with: self) { owner, valid in
        owner.nicknameValid = valid
        owner.updateNextButton()
      }
      .disposed(by: reactorBag)
  }

  private func registerKeyboardNotifications() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(onKeyboardWillChange(_:)),
      name: UIResponder.keyboardWillChangeFrameNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(onKeyboardWillHide(_:)),
      name: UIResponder.keyboardWillHideNotification,
      object: nil
    )
  }

  private func updateScrollInsets(bottom: CGFloat, duration: TimeInterval, curve: UIView.AnimationCurve) {
    keyboardBottomInset = bottom
    let options = UIView.AnimationOptions(rawValue: UInt(curve.rawValue << 16))
    UIView.animate(
      withDuration: duration,
      delay: 0,
      options: options,
      animations: {
        self.formView.scrollView.contentInset.bottom = bottom
        var indicatorInsets = self.formView.scrollView.verticalScrollIndicatorInsets
        indicatorInsets.bottom = bottom
        self.formView.scrollView.verticalScrollIndicatorInsets = indicatorInsets
      },
      completion: nil
    )
  }

  @objc private func onKeyboardWillChange(_ note: Notification) {
    guard
      let userInfo = note.userInfo,
      let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
      let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
      let curveRaw = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int,
      let curve = UIView.AnimationCurve(rawValue: curveRaw)
    else { return }

    let kbFrameInView = view.convert(endFrame, from: nil)
    let overlap = max(0, view.bounds.intersection(kbFrameInView).height - view.safeAreaInsets.bottom)
    let bottomInset = overlap + 8

    updateScrollInsets(bottom: bottomInset, duration: duration, curve: curve)

    if let field = currentFirstResponder {
      let target = field.convert(field.bounds, to: formView.scrollView)
      formView.scrollView.scrollRectToVisible(target.insetBy(dx: 0, dy: -24), animated: true)
    }
  }

  @objc private func onKeyboardWillHide(_ note: Notification) {
    guard
      let userInfo = note.userInfo,
      let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
      let curveRaw = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int,
      let curve = UIView.AnimationCurve(rawValue: curveRaw)
    else { return }
    updateScrollInsets(bottom: 0, duration: duration, curve: curve)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  private func setFieldDisabled(_ textField: UITextField, dim: Bool = true) {
    textField.isEnabled = false
    textField.isUserInteractionEnabled = false
    if dim { textField.alpha = 0.5 }
  }

  private func configureInitialState() {
    if isAppleLogin {
      formView.mailTextField.text = "Apple Social Account"

      [formView.mailTextField, formView.pwTextField, formView.rePwTextField].forEach {
        setFieldDisabled($0, dim: true)
      }

      [formView.pwTextField, formView.rePwTextField].forEach {
        $0.text = String(repeating: "•", count: 8)
        $0.isSecureTextEntry = true
      }

      let appleInfoText = "Apple 계정을 이용 중입니다"
      formView.mailCheckLabel.text = appleInfoText
      formView.pwCheckLabel.text = appleInfoText
      formView.rePwCheckLabel.text = appleInfoText

      formView.mailCheckLabel.textColor = formView.acceptColor
      formView.mailCheckIcon.image = .accept
      formView.pwCheckLabel.textColor = formView.acceptColor
      formView.pwCheckIcon.image = .accept
      formView.rePwCheckLabel.textColor = formView.acceptColor
      formView.rePwCheckIcon.image = .accept

      mailValid = true
      passwordValid = true
      confirmMatched = true
    } else {
      formView.mailCheckLabel.text = " "
      formView.mailCheckIcon.image = nil
      formView.pwCheckLabel.text = " "
      formView.pwCheckIcon.image = nil
      formView.rePwCheckLabel.text = " "
      formView.rePwCheckIcon.image = nil

      if let mail = initialMail {
        formView.mailTextField.text = mail
      }
    }

    formView.nicknameCheckLabel.text = " "
    formView.nicknameCheckIcon.image = nil

    updateNextButton()
  }

  private func configureInputOrder() {
    if isAppleLogin {
      inputOrder = [formView.nicknameTextField]
    } else {
      inputOrder = [
        formView.mailTextField,
        formView.pwTextField,
        formView.rePwTextField,
        formView.nicknameTextField
      ]
    }
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
    formView.nextButton.backgroundColor = UIColor(named: "primary400")
    formView.nextButton.alpha = enabled ? 1.0 : 0.5
  }

  private func applyCheckState(
    icon: UIImageView,
    label: UILabel,
    okStatus: Bool,
    okText: String,
    failText: String
  ) {
    let imageName = okStatus ? UIImage.accept : UIImage.reject
    let image = imageName.withRenderingMode(.alwaysOriginal)
    icon.image = image
    icon.isHidden = false
    label.text = okStatus ? okText : failText
    label.textColor = okStatus ? formView.acceptColor : formView.rejectColor
  }

  @objc private func onTapNext() {
    // 메일 가입 외에는 메일을 무시
    let mailValue = isAppleLogin ? "" : (formView.mailTextField.text ?? "")
    let info = UserRegistrationInfo(
      mail: mailValue,
      password: isAppleLogin ? nil : formView.pwTextField.text,
      nickname: formView.nicknameTextField.text ?? "",
      isAppleLogin: isAppleLogin,
      refreshToken: refreshToken
    )
    onNext?(info)
  }

  @objc private func dismissKeyboard() { view.endEditing(true) }
}

extension UserInfoViewController {

  @objc func onMailEditingEnd() {
    if isAppleLogin {
      mailValid = true

      applyCheckState(
        icon: formView.mailCheckIcon,
        label: formView.mailCheckLabel,
        okStatus: true,
        okText: "Apple 계정을 이용 중입니다",
        failText: "Apple 계정을 이용 중입니다"
      )
    } else {
      let text = formView.mailTextField.text ?? ""
      mailValid = UserInfoValidator.isValidMail(text)

      applyCheckState(
        icon: formView.mailCheckIcon,
        label: formView.mailCheckLabel,
        okStatus: mailValid,
        okText: "사용 가능한 이메일입니다",
        failText: "사용 불가한 이메일입니다"
      )
    }
    updateNextButton()
  }

  @objc func onPasswordEditingEnd() {
    if isAppleLogin {
      passwordValid = true
      confirmMatched = true

      applyCheckState(
        icon: formView.pwCheckIcon,
        label: formView.pwCheckLabel,
        okStatus: true,
        okText: "Apple 계정을 이용 중입니다",
        failText: "Apple 계정을 이용 중입니다"
      )

      applyCheckState(
        icon: formView.rePwCheckIcon,
        label: formView.rePwCheckLabel,
        okStatus: true,
        okText: "Apple 계정을 이용 중입니다",
        failText: "Apple 계정을 이용 중입니다"
      )
    } else {
      let pwdRaw = formView.pwTextField.text ?? ""
      let confirmRaw = formView.rePwTextField.text ?? ""
      let pwd = pwdRaw.trimmingCharacters(in: .whitespacesAndNewlines)
      let confirm = confirmRaw.trimmingCharacters(in: .whitespacesAndNewlines)

      passwordValid = UserInfoValidator.isValidPassword(pwd)

      if !confirm.isEmpty {
        confirmMatched = (pwd == confirm)
      }

      applyCheckState(
        icon: formView.pwCheckIcon,
        label: formView.pwCheckLabel,
        okStatus: passwordValid,
        okText: "사용 가능한 비밀번호입니다",
        failText: "사용 불가한 비밀번호입니다"
      )

      if !confirm.isEmpty {
        applyCheckState(
          icon: formView.rePwCheckIcon,
          label: formView.rePwCheckLabel,
          okStatus: confirmMatched,
          okText: "비밀번호가 일치합니다",
          failText: "비밀번호가 불일치합니다"
        )
      }
    }
    updateNextButton()
  }

  @objc func onConfirmEditingEnd() {
    if isAppleLogin {
      confirmMatched = true

      applyCheckState(
        icon: formView.rePwCheckIcon,
        label: formView.rePwCheckLabel,
        okStatus: true,
        okText: "Apple 계정을 이용 중입니다",
        failText: "Apple 계정을 이용 중입니다"
      )
    } else {
      let pwd = (formView.pwTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      let confirm = (formView.rePwTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      confirmMatched = (pwd == confirm) && !pwd.isEmpty

      applyCheckState(
        icon: formView.rePwCheckIcon,
        label: formView.rePwCheckLabel,
        okStatus: confirmMatched,
        okText: "비밀번호가 일치합니다",
        failText: "비밀번호가 불일치합니다"
      )
    }
    updateNextButton()
  }

  @objc func onNicknameEditingEnd() {
    let name = formView.nicknameTextField.text ?? ""
    nicknameReactor.action.onNext(.validateNickname(name))
  }
}

class InsetTextField: UITextField {
  var textInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
  override func textRect(forBounds bounds: CGRect) -> CGRect {
    return bounds.inset(by: textInsets)
  }
  override func editingRect(forBounds bounds: CGRect) -> CGRect {
    return bounds.inset(by: textInsets)
  }
  override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
    return bounds.inset(by: textInsets)
  }
}

extension UserInfoViewController: UITextFieldDelegate {
  public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    if isAppleLogin,
      textField === formView.mailTextField
        || textField === formView.pwTextField
        || textField === formView.rePwTextField {
      return false
    }
    return true
  }

  public func textFieldDidBeginEditing(_ textField: UITextField) {
    currentFirstResponder = textField
    let target = textField.convert(textField.bounds, to: formView.scrollView)
    formView.scrollView.scrollRectToVisible(target.insetBy(dx: 0, dy: -24), animated: true)
  }

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
