//
//  NickNameChangeViewController.swift
//  Bragit
//
//  Created by seongjun cho on 9/2/25.
//

import UIKit

import SnapKit
import Then
import RxSwift
import RxCocoa
import Dependencies

final class NickNameChangeViewController: UIViewController {

  var completion: (() -> Void)?

  var disposeBag = DisposeBag()

  private let grabBar = UIView().then {
    $0.backgroundColor = .grayScale600
  }

  private let titleLabel = UILabel().then {
    $0.font = .pretendard(size: 18, weight: .semibold)
    $0.text = "사용할 닉네임을 입력해주세요"
    $0.textColor = .grayScale900
  }

  private let nicknameTextField = SearchBar().then {
    let image = UIImage.exclude.withRenderingMode(.alwaysOriginal)
    $0.searchButton.snp.remakeConstraints {
      $0.width.height.equalTo(15)
    }
    $0.searchButton.setImage(image.withTintColor(.grayScale700), for: .normal)
    $0.textField.autocapitalizationType = .none
    $0.textField.font = .pretendard(size: 14)
    $0.textField.returnKeyType = .done
    $0.textField.placeholder = "2-8글자 내로 입력해주세요"
  }

  private let nicknameCheckImageView = UIImageView()

  private let nicknameCheckLabel = UILabel().then {
    $0.font = .pretendard(size: 13, weight: .medium)
  }

  private let changeButton = UIButton().then {
    var config = UIButton.Configuration.filled()
    $0.isEnabled = false

    config.background.cornerRadius = 12
    config.title = "변경하기"
    $0.configuration = config
    $0.configurationUpdateHandler = { button in
      switch button.state {
      case .disabled:
        button.configuration?.baseBackgroundColor = .grayScale100
        button.configuration?.baseForegroundColor = .grayScale400
      default:
        button.configuration?.baseBackgroundColor = .primary400
        button.configuration?.baseForegroundColor = .grayScale900
      }
    }
  }

  @Dependency(\.userManager) var userManager

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    setupUI()
    bind()
  }

  private func setupUI() {
    view.addSubview(grabBar)
    view.addSubview(titleLabel)
    view.addSubview(nicknameTextField)
    view.addSubview(nicknameCheckImageView)
    view.addSubview(nicknameCheckLabel)
    view.addSubview(changeButton)

    grabBar.snp.makeConstraints {
      $0.top.equalToSuperview().offset(16)
      $0.height.equalTo(4)
      $0.width.equalTo(48)
      $0.centerX.equalToSuperview()
    }

    titleLabel.snp.makeConstraints {
      $0.top.equalTo(grabBar.snp.bottom).offset(28)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    nicknameTextField.snp.makeConstraints {
      $0.top.equalTo(titleLabel.snp.bottom).offset(20)
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.height.equalTo(52)
    }

    nicknameCheckImageView.snp.makeConstraints {
      $0.top.equalTo(nicknameTextField.snp.bottom).offset(12)
      $0.leading.equalToSuperview().inset(20)
      $0.width.height.equalTo(20)
    }

    nicknameCheckLabel.snp.makeConstraints {
      $0.centerY.equalTo(nicknameCheckImageView)
      $0.leading.equalTo(nicknameCheckImageView.snp.trailing).offset(8)
      $0.trailing.equalToSuperview().inset(20)
    }

    changeButton.snp.makeConstraints {
      $0.top.equalTo(nicknameCheckLabel.snp.bottom).offset(24)
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.height.equalTo(52)
    }
  }

  // swiftlint:disable cyclomatic_complexity
  private func bind() {
    nicknameTextField.textField.rx.text
      .orEmpty
      .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
      .distinctUntilChanged()
      .flatMapLatest { [weak self] nickname -> Observable<Bool?> in
        guard let self = self else { return .empty() }

        if nickname.isEmpty {
          return .just(nil)
        }

        if AppleInfoValidator.isValidNickname(nickname) == false {
          return .just(false)
        }

        return self.userManager.rxhasNickName(nickName: nickname)
          .map { !$0 as Bool? }
          .catchAndReturn(false)
      }
      .observe(on: MainScheduler.instance)
      .bind { [weak self] isValid in
        guard let self = self else { return }

        self.changeButton.isEnabled = (isValid == true)

        if let isValid = isValid {
          self.nicknameCheckImageView.isHidden = false
          self.nicknameCheckLabel.isHidden = false

          if isValid {
            self.nicknameCheckImageView.image = .accept
            self.nicknameCheckLabel.text = "사용가능한 닉네임입니다!"
            self.nicknameCheckLabel.textColor = .systemGreen
            self.nicknameCheckImageView.tintColor = .systemGreen
          } else {
            self.nicknameCheckImageView.image = .reject
            self.nicknameCheckLabel.text = "사용할 수 없는 닉네임입니다"
            self.nicknameCheckImageView.tintColor = .systemRed
            self.nicknameCheckLabel.textColor = .systemRed
          }
        } else {
          self.nicknameCheckImageView.isHidden = true
          self.nicknameCheckLabel.isHidden = true
        }
      }
      .disposed(by: disposeBag)

    nicknameTextField.searchButton.rx.tap
      .bind { [weak self] in
        guard let self = self else { return }
        self.nicknameTextField.textField.text = ""
        self.nicknameCheckLabel.isHidden = true
        self.nicknameCheckImageView.isHidden = true
        self.changeButton.isEnabled = false
      }.disposed(by: disposeBag)

    // MARK: - 버튼 탭 액션 스트림
    changeButton.rx.tap
      .withLatestFrom(nicknameTextField.textField.rx.text.orEmpty
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) })
      .filter { !$0.isEmpty }
      .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
      .flatMapLatest { [weak self] nickname -> Observable<Void> in
        guard let self = self else { return .empty() }

        if nickname.isEmpty {
          let error = NSError(
            domain: "NicknameError",
            code: 410,
            userInfo: [NSLocalizedDescriptionKey: "닉네임이 비어있습니다."])
          return .error(error)
        }

        if nickname.count < 2 || nickname.count > 8 {
          let error = NSError(
            domain: "NicknameError",
            code: 411,
            userInfo: [NSLocalizedDescriptionKey: "1~8자리 닉네임이 아닙니다."])
          return .error(error)
        }

        if AppleInfoValidator.isValidNickname(nickname) == false {
          let error = NSError(
            domain: "NicknameError",
            code: 412,
            userInfo: [NSLocalizedDescriptionKey: "적합한 닉네임이 아닙니다."])
          return .error(error)
        }

        return self.userManager.rxhasNickName(nickName: nickname)
          .flatMap { isOverlap -> Observable<Void> in
            if isOverlap {
              let error = NSError(
                domain: "NicknameError",
                code: 409,
                userInfo: [NSLocalizedDescriptionKey: "이미 사용 중인 닉네임입니다."])
              return .error(error)
            } else {
              return self.userManager.rxChangeNickName(nickName: nickname)
                .asObservable()
            }
          }
      }
      .observe(on: MainScheduler.instance)
      .subscribe(
        onNext: { [weak self] in
          self?.completion?()
          self?.dismiss(animated: true)
        },
        onError: { [weak self] error in
          guard let self else { return }
          let alert = AlertView(
            title: "닉네임 변경 실패",
            message: error.localizedDescription,
            leftButtonTitle: "확인",
            rightButtonTitle: "닫기"
          )
          alert.rightTap.bind {
            self.dismiss(animated: true)
          }.disposed(by: self.disposeBag)
          self.view.addSubview(alert)
        })
      .disposed(by: disposeBag)
  }
  // swiftlint:enable cyclomatic_complexity
}

@available(iOS 18.0, *)
#Preview {
  NickNameChangeViewController()
}
