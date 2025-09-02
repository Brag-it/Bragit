//
//  TermsViewController.swift
//  Bragit
//
//  Created by luca on 8/25/25.
//
// 약관 동의를 받는 뷰
import UIKit

import SnapKit
import Then

final class TermsViewController: UIViewController {

  private let userInfo: UserRegistrationInfo

  private var serviceAccepted = false
  private var privacyAccepted = false
  private var marketingAccepted = false

  var onAgree: ((UserRegistrationInfo) -> Void)?

  // MARK: UI
  let descriptionLabel = UILabel().then {
    $0.text = "서비스 이용을 위해 약관 동의가 필요해요"
    $0.numberOfLines = 1
    $0.lineBreakMode = .byWordWrapping
    $0.setContentHuggingPriority(.required, for: .vertical)
    $0.setContentCompressionResistancePriority(.required, for: .vertical)
  }

  // 전체 동의
  let allAcceptCheckbox = UIButton(type: .system).then {
    $0.setImage(UIImage(systemName: "square.fill"), for: .normal)
    $0.contentHorizontalAlignment = .leading
    $0.tintColor = .orange
  }

  let allAcceptLabel = UILabel().then {
    $0.text = "전체 동의"
  }

  let allAcceptStack = UIStackView().then {
    $0.axis = .horizontal
    $0.spacing = 8
    $0.alignment = .center
  }

  let divider = UIView().then {
    $0.backgroundColor = UIColor(red: 0.851, green: 0.851, blue: 0.851, alpha: 1)
  }

  // 서비스 이용약관
  let serviceAcceptCheckbox = UIButton(type: .system).then {
    $0.setImage(UIImage(systemName: "square.fill"), for: .normal)
    $0.tintColor = .orange
  }

  let serviceAcceptLabel = UILabel().then {
    $0.text = "서비스 이용약관 (필수)"
  }

  let serviceAcceptStack = UIStackView().then {
    $0.axis = .horizontal
    $0.spacing = 8
    $0.alignment = .center
  }

  // 개인정보 수집
  let privacyAcceptCheckbox = UIButton(type: .system).then {
    $0.setImage(UIImage(systemName: "square.fill"), for: .normal)
    $0.tintColor = .orange
  }

  let privacyAcceptLabel = UILabel().then {
    $0.text = "개인정보 수집 및 처리 방침 (필수)"
  }

  let privacyAcceptStack = UIStackView().then {
    $0.axis = .horizontal
    $0.spacing = 8
    $0.alignment = .center
  }

  // 마케팅 정보
  let marketingAcceptCheckbox = UIButton(type: .system).then {
    $0.setImage(UIImage(systemName: "square.fill"), for: .normal)
    $0.tintColor = .orange
  }

  let marketingAcceptLabel = UILabel().then {
    $0.text = "마케팅 정보 수집 및 수신 (선택)"
  }

  let marketingAcceptStack = UIStackView().then {
    $0.axis = .horizontal
    $0.spacing = 8
    $0.alignment = .center
    // TODO: 마케팅 필수로 들어가야 되나? 우리 홍보도 없고, 지금 선택 허용 여부 받을 곳도 없는데
    //    $0.isHidden = true
  }

  // nextButton
  let nextButton = UIButton(type: .system).then {
    $0.setTitle("확인", for: .normal)
    $0.setTitleColor(UIColor(red: 0.315, green: 0.315, blue: 0.315, alpha: 1), for: .normal)
    $0.layer.cornerRadius = 12
    $0.backgroundColor = .orange
    $0.isEnabled = false
  }

  init(userInfo: UserRegistrationInfo) {
    self.userInfo = userInfo
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    setupLayout()
    setupActions()
    applyInitialUI()
    updateAllAcceptCheckboxImage()
    updateNextButtonState()
  }
}

// MARK: - Layout & UI setup
private extension TermsViewController {
  func setupLayout() {
    // TODO: Font Setting
    // all accept stack
    [allAcceptCheckbox, allAcceptLabel].forEach { allAcceptStack.addArrangedSubview($0) }

    // service accept stack
    [serviceAcceptCheckbox, serviceAcceptLabel].forEach { serviceAcceptStack.addArrangedSubview($0) }

    // privacy accept stack
    [privacyAcceptCheckbox, privacyAcceptLabel].forEach { privacyAcceptStack.addArrangedSubview($0) }

    // marketing accept stack
    [marketingAcceptCheckbox, marketingAcceptLabel].forEach { marketingAcceptStack.addArrangedSubview($0) }

    // add view
    [
      descriptionLabel,
      allAcceptStack,
      divider,
      serviceAcceptStack,
      privacyAcceptStack,
      marketingAcceptStack,
      nextButton
    ].forEach {
      view.addSubview($0)
    }

    // 체크박스 크기 고정
    [allAcceptCheckbox, serviceAcceptCheckbox, privacyAcceptCheckbox, marketingAcceptCheckbox].forEach {
      $0.snp.makeConstraints { make in
        make.width.height.equalTo(24)
      }
    }

    // snapkit
    descriptionLabel.snp.makeConstraints {
      $0.top.equalTo(view.safeAreaLayoutGuide).offset(32)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    allAcceptStack.snp.makeConstraints {
      $0.top.equalTo(descriptionLabel.snp.bottom).offset(32)
      $0.leading.equalToSuperview().offset(20)
      $0.trailing.equalToSuperview().inset(20)
    }

    divider.snp.makeConstraints {
      $0.top.equalTo(allAcceptStack.snp.bottom).offset(16)
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.height.equalTo(1)
    }

    serviceAcceptStack.snp.makeConstraints {
      $0.top.equalTo(divider.snp.bottom).offset(16)
      $0.leading.equalToSuperview().offset(20)
      $0.trailing.equalToSuperview().inset(20)
    }

    privacyAcceptStack.snp.makeConstraints {
      $0.top.equalTo(serviceAcceptStack.snp.bottom).offset(16)
      $0.leading.equalToSuperview().offset(20)
      $0.trailing.equalToSuperview().inset(20)
    }

    marketingAcceptStack.snp.makeConstraints {
      $0.top.equalTo(privacyAcceptStack.snp.bottom).offset(16)
      $0.leading.equalToSuperview().offset(20)
      $0.trailing.equalToSuperview().inset(20)
    }

    nextButton.snp.makeConstraints {
      $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(24)
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.height.equalTo(52)
    }
  }

  func setupActions() {
    allAcceptCheckbox.addTarget(self, action: #selector(didTapAllAccept), for: .touchUpInside)
    serviceAcceptCheckbox.addTarget(self, action: #selector(didTapService), for: .touchUpInside)
    privacyAcceptCheckbox.addTarget(self, action: #selector(didTapPrivacy), for: .touchUpInside)
    marketingAcceptCheckbox.addTarget(self, action: #selector(didTapMarketing), for: .touchUpInside)
    nextButton.addTarget(self, action: #selector(didTapNext), for: .touchUpInside)
  }

  func applyInitialUI() {
    setCheckboxImage(allAcceptCheckbox, checked: false)
    setCheckboxImage(serviceAcceptCheckbox, checked: false)
    setCheckboxImage(privacyAcceptCheckbox, checked: false)
    setCheckboxImage(marketingAcceptCheckbox, checked: false)

    [serviceAcceptCheckbox, privacyAcceptCheckbox, marketingAcceptCheckbox].forEach {
      $0.contentHorizontalAlignment = .leading
    }
  }

  func setCheckboxImage(_ button: UIButton, checked: Bool) {
    let name = checked ? "checkmark.square.fill" : "square.fill"
    button.setImage(UIImage(systemName: name), for: .normal)
  }

  func updateAllAcceptCheckboxImage() {
    let allOn = serviceAccepted && privacyAccepted && marketingAccepted
    let allOff = !serviceAccepted && !privacyAccepted && !marketingAccepted
    let imageName: String = allOn ? "checkmark.square.fill" : (allOff ? "square.fill" : "minus.square.fill")
    allAcceptCheckbox.setImage(UIImage(systemName: imageName), for: .normal)
  }

  func updateNextButtonState() {
    let enabled = serviceAccepted && privacyAccepted
    nextButton.isEnabled = enabled
    nextButton.backgroundColor = enabled ? .orange : .gray
  }
}

// MARK: - Actions
private extension TermsViewController {
  @objc func didTapAllAccept() {
    let shouldCheckAll = !(serviceAccepted && privacyAccepted && marketingAccepted)
    serviceAccepted = shouldCheckAll
    privacyAccepted = shouldCheckAll
    marketingAccepted = shouldCheckAll

    setCheckboxImage(serviceAcceptCheckbox, checked: serviceAccepted)
    setCheckboxImage(privacyAcceptCheckbox, checked: privacyAccepted)
    setCheckboxImage(marketingAcceptCheckbox, checked: marketingAccepted)
    updateAllAcceptCheckboxImage()
    updateNextButtonState()
  }

  @objc func didTapService() {
    serviceAccepted.toggle()
    setCheckboxImage(serviceAcceptCheckbox, checked: serviceAccepted)
    updateAllAcceptCheckboxImage()
    updateNextButtonState()
  }

  @objc func didTapPrivacy() {
    privacyAccepted.toggle()
    setCheckboxImage(privacyAcceptCheckbox, checked: privacyAccepted)
    updateAllAcceptCheckboxImage()
    updateNextButtonState()
  }

  @objc func didTapMarketing() {
    marketingAccepted.toggle()
    setCheckboxImage(marketingAcceptCheckbox, checked: marketingAccepted)
    updateAllAcceptCheckboxImage()
    updateNextButtonState()
  }

  @objc func didTapNext() {
    guard serviceAccepted && privacyAccepted else { return }
    onAgree?(userInfo)
  }
}

struct UserRegistrationInfo {
  let mail: String
  let password: String?
  let nickname: String
  let isAppleLogin: Bool
}
