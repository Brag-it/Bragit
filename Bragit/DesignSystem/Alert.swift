//
//  Alert.swift
//  Bragit
//
//  Created by 이태윤 on 8/22/25.
//
import UIKit

import SnapKit
import Then
import RxSwift
import RxCocoa

final class CustomAlertView: UIView {

  // MARK: - UI
  private let dimmedView = UIView().then {
    $0.backgroundColor = UIColor.black.withAlphaComponent(0.4)
  }

  private let containerView = UIView().then {
    $0.backgroundColor = .white
    $0.layer.cornerRadius = 12
    $0.clipsToBounds = true
  }

  private let titleLabel = UILabel().then {
    $0.textColor = .black
    $0.font = UIFont.pretendard(size: 16, weight: .semibold)
    $0.textAlignment = .left
    $0.numberOfLines = 0
  }

  private let messageLabel = UILabel().then {
    $0.textColor = .lightGray
    $0.font = UIFont.pretendard(size: 15, weight: .regular)
    $0.textAlignment = .left
    $0.numberOfLines = 0
  }

  private let leftButton = UIButton().then {
    $0.setTitleColor(.black, for: .normal)
    $0.titleLabel?.font = UIFont.pretendard(size: 15, weight: .medium)
  }

  private let rightButton = UIButton().then {
    $0.setTitleColor(.black, for: .normal)
    $0.titleLabel?.font = UIFont.pretendard(size: 15, weight: .medium)
  }

  private let buttonStackView = UIStackView().then {
    $0.axis = .horizontal
    $0.spacing = 0
    $0.distribution = .fillEqually
  }

  // MARK: - Rx Output
  let leftTap = PublishRelay<Void>()
  let rightTap = PublishRelay<Void>()
  private let disposeBag = DisposeBag()

  // MARK: - Init
  init(
    title: String,
    message: String,
    leftButtonTitle: String? = nil,
    rightButtonTitle: String? = nil
  ) {
    super.init(frame: UIScreen.main.bounds)
    setUIConstraints()

    titleLabel.text = title
    messageLabel.text = message
    leftButton.setTitle(leftButtonTitle, for: .normal)
    rightButton.setTitle(rightButtonTitle, for: .normal)

    bind()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Layout
  private func setUIConstraints() {
    addSubview(dimmedView)
    addSubview(containerView)

    containerView.addSubview(titleLabel)
    containerView.addSubview(messageLabel)
    containerView.addSubview(buttonStackView)

    buttonStackView.addArrangedSubview(leftButton)
    buttonStackView.addArrangedSubview(rightButton)


    dimmedView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }

    containerView.snp.makeConstraints {
      $0.center.equalToSuperview()
      $0.width.equalTo(280)
    }

    titleLabel.snp.makeConstraints {
      $0.top.equalToSuperview().offset(20)
      $0.leading.trailing.equalToSuperview().inset(24)
    }

    messageLabel.snp.makeConstraints {
      $0.top.equalTo(titleLabel.snp.bottom).offset(16)
      $0.leading.trailing.equalToSuperview().inset(24)
    }

    buttonStackView.snp.makeConstraints {
      $0.top.equalTo(messageLabel.snp.bottom)
      $0.leading.trailing.bottom.equalToSuperview()
      $0.height.equalTo(48)
    }
  }

  // MARK: - 바인딩
  private func bind() {
    leftButton.rx.tap
      .bind(with: self) { owner, _ in
        owner.removeFromSuperview()
        owner.leftTap.accept(())
      }
      .disposed(by: disposeBag)

    rightButton.rx.tap
      .bind(with: self) { owner, _ in
        owner.removeFromSuperview()
        owner.rightTap.accept(())
      }
      .disposed(by: disposeBag)
  }

  // MARK: - 화면에 띄우기
  func show(in view: UIView) {
    view.addSubview(self)
  }
}
