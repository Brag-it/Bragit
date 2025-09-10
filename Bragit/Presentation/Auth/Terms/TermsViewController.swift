//
//  TermsViewController.swift
//  Bragit
//
//  Created by luca on 8/25/25.
//
// 약관 동의를 받는 뷰
import UIKit

import ReactorKit
import RxCocoa
import RxSwift
import SnapKit
import Then

final class TermsViewController: UIViewController, View {

  // ReactorKit
  var disposeBag = DisposeBag()

  private let userInfo: UserRegistrationInfo

  let descFont = UIFont.pretendard(size: 20, weight: .semibold)
  let allLabelFont = UIFont.pretendard(size: 16, weight: .medium)
  let checkboxFont = UIFont.pretendard(size: 16, weight: .regular)

  let descColor = UIColor(named: "grayScale900")
  let labelColor = UIColor(named: "grayScale700")
  let primaryColor = UIColor(named: "primary400")

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
    $0.isEnabled = false
  }

  // MARK: - Initializers
  init(userInfo: UserRegistrationInfo) {
    self.userInfo = userInfo
    super.init(nibName: nil, bundle: nil)
    // 기본 패턴을 유지하기 위해 내부에서 Reactor를 생성해 주입
    self.reactor = SignTermsReactor()
  }

  // Reactor를 외부에서 주입하고 싶을 때 사용할 수 있는 초기화 메서드
  init(userInfo: UserRegistrationInfo, reactor: SignTermsReactor) {
    self.userInfo = userInfo
    super.init(nibName: nil, bundle: nil)
    self.reactor = reactor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    title = "회원가입"
    setupLayout()
    applyInitialUI()
  }
}

// MARK: - Layout & UI setup
private extension TermsViewController {
  func setupLayout() {
    // TODO: Font Setting
    descriptionLabel.textColor = descColor
    descriptionLabel.font = descFont
    [allAcceptCheckbox, privacyAcceptCheckbox, serviceAcceptCheckbox, marketingAcceptCheckbox, nextButton].forEach {
      $0.tintColor = primaryColor
    }
    allAcceptLabel.font = allLabelFont
    nextButton.titleLabel?.font = allLabelFont
    [privacyAcceptLabel, serviceAcceptLabel, marketingAcceptLabel].forEach {
      $0.font = checkboxFont
    }

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

  func updateAllAcceptCheckboxImage(service: Bool, privacy: Bool, marketing: Bool) {
    let allOn = service && privacy && marketing
    let allOff = !service && !privacy && !marketing
    let imageName: String = allOn ? "checkmark.square.fill" : (allOff ? "square.fill" : "minus.square.fill")
    allAcceptCheckbox.setImage(UIImage(systemName: imageName), for: .normal)
  }

  func updateNextButtonState(enabled: Bool) {
    nextButton.isEnabled = enabled
    nextButton.backgroundColor = primaryColor
    nextButton.alpha = enabled ? 1.0 : 0.5
  }
}

// MARK: - Reactor Binding
extension TermsViewController {
  func bind(reactor: SignTermsReactor) {
    // Actions
    allAcceptCheckbox.rx.tap
      .map { SignTermsReactor.Action.tapAll }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    serviceAcceptCheckbox.rx.tap
      .map { SignTermsReactor.Action.tapService }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    privacyAcceptCheckbox.rx.tap
      .map { SignTermsReactor.Action.tapPrivacy }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    marketingAcceptCheckbox.rx.tap
      .map { SignTermsReactor.Action.tapMarketing }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    nextButton.rx.tap
      .map { SignTermsReactor.Action.tapNext }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    // State -> UI: individual checkboxes
    reactor.state.map(\.serviceAccepted)
      .distinctUntilChanged()
      .subscribe(with: self) { owner, accepted in
        owner.setCheckboxImage(owner.serviceAcceptCheckbox, checked: accepted)
      }
      .disposed(by: disposeBag)

    reactor.state.map(\.privacyAccepted)
      .distinctUntilChanged()
      .subscribe(with: self) { owner, accepted in
        owner.setCheckboxImage(owner.privacyAcceptCheckbox, checked: accepted)
      }
      .disposed(by: disposeBag)

    reactor.state.map(\.marketingAccepted)
      .distinctUntilChanged()
      .subscribe(with: self) { owner, accepted in
        owner.setCheckboxImage(owner.marketingAcceptCheckbox, checked: accepted)
      }
      .disposed(by: disposeBag)

    // State -> UI: all-accept image
    Observable
      .combineLatest(
        reactor.state.map(\.serviceAccepted).distinctUntilChanged(),
        reactor.state.map(\.privacyAccepted).distinctUntilChanged(),
        reactor.state.map(\.marketingAccepted).distinctUntilChanged()
      )
      .subscribe(with: self) { owner, tuple in
        owner.updateAllAcceptCheckboxImage(service: tuple.0, privacy: tuple.1, marketing: tuple.2)
      }
      .disposed(by: disposeBag)

    // State -> UI: next button enable
    reactor.state.map { $0.serviceAccepted && $0.privacyAccepted }
      .distinctUntilChanged()
      .subscribe(with: self) { owner, enabled in
        owner.updateNextButtonState(enabled: enabled)
      }
      .disposed(by: disposeBag)

    // Proceed to next step (bridge to existing onAgree closure)
    reactor.state.map(\.proceed)
      .distinctUntilChanged()
      .filter { $0 == true }
      .subscribe(with: self) { owner, _ in
        owner.onAgree?(owner.userInfo)
      }
      .disposed(by: disposeBag)
  }
}

struct UserRegistrationInfo {
  let mail: String
  let password: String?
  let nickname: String
  let isAppleLogin: Bool
  let refreshToken: String?
}

