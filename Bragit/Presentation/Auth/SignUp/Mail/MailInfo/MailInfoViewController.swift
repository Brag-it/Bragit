//
//  MailInfoViewController.swift
//  Bragit
//
//  Created by luca on 9/14/25.
//

import ReactorKit
import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit
// TODO: 이메일은 앞에서 끌어오기
// TODO: 비밀번호, 비밀번호 확인, 닉네임 TextField
// TODO: Validate, 닉네임 중복 체크

final class MailInfoViewController: UIViewController {
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
  private let nicknameReactor = MailInfoReactor()

  private var passwordValid = false
  private var confirmMatched = false
  private var nicknameValid = false

  private func updateNextButton() {
    let enabled = passwordValid && confirmMatched && nicknameValid
    nextButton.isEnabled = enabled
    nextButton.backgroundColor = .primary400
    nextButton.alpha = enabled ? 1.0 : 0.5
  }

  private func applyCheckState(icon: UIImageView, label: UILabel, okStatus: Bool, okText: String, failText: String) {
    let image = (okStatus ? UIImage.accept : UIImage.reject).withRenderingMode(.alwaysOriginal)
    icon.image = image
    icon.isHidden = false
    label.text = okStatus ? okText : failText
    label.textColor = okStatus ? .systemSafe : .systemDanger
  }

  let descriptionLabel = UILabel().then {
    $0.text = "로그인에 사용할 이메일과\n비밀번호를 입력해 주세요"
    $0.numberOfLines = 2
    $0.lineBreakMode = .byWordWrapping
    $0.setContentHuggingPriority(.required, for: .vertical)
    $0.setContentCompressionResistancePriority(.required, for: .vertical)
    $0.font = .pretendard(size: 20, weight: .semibold)
    $0.textColor = .grayScale900
  }

  let scrollView = UIScrollView().then {
    $0.keyboardDismissMode = .interactive
    $0.isUserInteractionEnabled = true
    $0.alwaysBounceVertical = true
    $0.showsVerticalScrollIndicator = true
    $0.delaysContentTouches = false
  }

  let contentView = UIView().then {
    $0.backgroundColor = .clear
    $0.isUserInteractionEnabled = true
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
    $0.returnKeyType = .next
    $0.autocapitalizationType = .none
    $0.spellCheckingType = .no
    $0.autocorrectionType = .no
    $0.textContentType = .username
  }

  let mailCheckIcon = UIImageView().then {
    $0.contentMode = .scaleAspectFit
    $0.snp.makeConstraints { $0.size.equalTo(16) }
  }

  let mailCheckLabel = UILabel().then {
    $0.text = "인증 완료된 이메일입니다"
    $0.font = .pretendard(size: 13, weight: .medium)
    $0.textColor = .systemSafe
  }

  let mailCheckStack = UIStackView().then {
    $0.axis = .horizontal
    $0.spacing = 4
    $0.alignment = .leading
  }

  let mailStack = UIStackView()

  let pwLabel = UILabel().then {
    $0.text = "비밀번호"
    $0.font = .pretendard(size: 13, weight: .medium)
    $0.textColor = .grayScale700
  }

  let pwTextField = InsetTextField().then {
    $0.placeholder = "8-24자 사이 영문, 숫자, 특수문자"
    $0.layer.borderColor = UIColor.grayScale100.cgColor
    $0.layer.borderWidth = 1
    $0.layer.cornerRadius = 14
    $0.isEnabled = true
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

  let pwCheckIcon = UIImageView().then {
    $0.contentMode = .scaleAspectFit
    $0.snp.makeConstraints { $0.size.equalTo(16) }
  }

  let pwCheckLabel = UILabel().then {
    $0.text = " "
    $0.font = .pretendard(size: 13, weight: .medium)
    $0.textColor = .systemSafe
  }

  let pwCheckStack = UIStackView().then {
    $0.axis = .horizontal
    $0.spacing = 4
    $0.alignment = .leading
  }

  let pwStack = UIStackView()

  let rePwLabel = UILabel().then {
    $0.text = "비밀번호 확인"
    $0.font = .pretendard(size: 13, weight: .medium)
    $0.textColor = .grayScale700
  }

  let rePwTextField = InsetTextField().then {
    $0.placeholder = "8-24자 사이 영문, 숫자, 특수문자"
    $0.layer.borderColor = UIColor.grayScale100.cgColor
    $0.layer.borderWidth = 1
    $0.layer.cornerRadius = 14
    $0.isEnabled = true
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

  let rePwCheckIcon = UIImageView().then {
    $0.contentMode = .scaleAspectFit
    $0.snp.makeConstraints { $0.size.equalTo(16) }
  }

  let rePwCheckLabel = UILabel().then {
    $0.text = " "
    $0.font = .pretendard(size: 13, weight: .medium)
    $0.textColor = .systemSafe
  }

  let rePwCheckStack = UIStackView().then {
    $0.axis = .horizontal
    $0.spacing = 4
    $0.alignment = .leading
  }

  let rePwStack = UIStackView()

  let nicknameLabel = UILabel().then {
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

  let nicknameCheckIcon = UIImageView().then {
    $0.contentMode = .scaleAspectFit
    $0.snp.makeConstraints { $0.size.equalTo(16) }
  }

  let nicknameCheckLabel = UILabel().then {
    $0.text = " "
    $0.font = .pretendard(size: 13, weight: .medium)
    $0.textColor = .systemSafe
  }

  let nicknameCheckStack = UIStackView().then {
    $0.axis = .horizontal
    $0.spacing = 4
    $0.alignment = .leading
  }

  let nicknameStack = UIStackView()

  // Configure stacks
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    [mailStack, pwStack, rePwStack, nicknameStack].forEach {
      $0.axis = .vertical
      $0.spacing = 8
      $0.alignment = .fill
      $0.distribution = .fill
    }
  }

  let nextButton = UIButton(type: .system).then {
    $0.setTitle("다음", for: .normal)
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
    configureTargets()
    bindNicknameReactor()
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
    view.addSubview(descriptionLabel)
    view.addSubview(scrollView)
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

    descriptionLabel.snp.makeConstraints {
      $0.top.equalTo(headerView.snp.bottom).offset(32)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    scrollView.snp.makeConstraints {
      $0.top.equalTo(descriptionLabel.snp.bottom)
      $0.leading.trailing.equalToSuperview()
      $0.bottom.equalTo(view.safeAreaLayoutGuide)
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

  private func configureTargets() {
    pwTextField.addTarget(self, action: #selector(onPasswordEditingEnd), for: .editingDidEnd)
    rePwTextField.addTarget(self, action: #selector(onConfirmEditingEnd), for: .editingDidEnd)
    nicknameTextField.addTarget(self, action: #selector(onNicknameEditingEnd), for: .editingDidEnd)
  }

  private func bindNicknameReactor() {
    nicknameReactor.state
      .map(\.nicknameStatusText)
      .distinctUntilChanged()
      .observe(on: MainScheduler.instance)
      .subscribe(with: self) { owner, text in
        owner.nicknameCheckLabel.text = text
        owner.nicknameCheckIcon.isHidden = false
        switch text {
        case "사용 가능한 닉네임입니다":
          owner.nicknameCheckLabel.textColor = .systemSafe
          owner.nicknameCheckIcon.image = UIImage.accept.withRenderingMode(.alwaysTemplate)
          owner.nicknameCheckIcon.tintColor = .systemSafe
        case "사용 중인 닉네임입니다", "닉네임 확인 실패", "사용 불가한 닉네임입니다":
          owner.nicknameCheckLabel.textColor = .systemDanger
          owner.nicknameCheckIcon.image = UIImage.reject.withRenderingMode(.alwaysTemplate)
          owner.nicknameCheckIcon.tintColor = .systemDanger
        case "중복 확인 중...":
          owner.nicknameCheckLabel.textColor = .systemWarning
          owner.nicknameCheckIcon.image = UIImage.loading.withRenderingMode(.alwaysOriginal)
          owner.nicknameCheckIcon.tintColor = .systemWarning
        default:
          owner.nicknameCheckIcon.image = nil
        }
      }
      .disposed(by: disposeBag)

    nicknameReactor.state
      .map(\.nicknameValid)
      .distinctUntilChanged()
      .observe(on: MainScheduler.instance)
      .subscribe(with: self) { owner, valid in
        owner.nicknameValid = valid
        owner.updateNextButton()
      }
      .disposed(by: disposeBag)
  }

  @objc private func onPasswordEditingEnd() {
    let pwdRaw = pwTextField.text ?? ""
    let confirmRaw = rePwTextField.text ?? ""
    let pwd = pwdRaw.trimmingCharacters(in: .whitespacesAndNewlines)
    let confirm = confirmRaw.trimmingCharacters(in: .whitespacesAndNewlines)

    passwordValid = AppleInfoValidator.isValidPassword(pwd)
    if !confirm.isEmpty { confirmMatched = (pwd == confirm) }

    applyCheckState(
      icon: pwCheckIcon,
      label: pwCheckLabel,
      okStatus: passwordValid,
      okText: "사용 가능한 비밀번호입니다",
      failText: "사용 불가한 비밀번호입니다"
    )

    if !confirm.isEmpty {
      applyCheckState(
        icon: rePwCheckIcon,
        label: rePwCheckLabel,
        okStatus: confirmMatched,
        okText: "비밀번호가 일치합니다",
        failText: "비밀번호가 불일치합니다"
      )
    }
    updateNextButton()
  }

  @objc private func onConfirmEditingEnd() {
    let pwd = (pwTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let confirm = (rePwTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    confirmMatched = (pwd == confirm) && !pwd.isEmpty

    applyCheckState(
      icon: rePwCheckIcon,
      label: rePwCheckLabel,
      okStatus: confirmMatched,
      okText: "비밀번호가 일치합니다",
      failText: "비밀번호가 불일치합니다"
    )
    updateNextButton()
  }

  @objc private func onNicknameEditingEnd() {
    let name = nicknameTextField.text ?? ""
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
