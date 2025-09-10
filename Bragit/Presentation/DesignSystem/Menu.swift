//
//  Menu.swift
//  Bragit
//
//  Created by seongjun cho on 8/26/25.
//

import UIKit

import RxCocoa
import RxSwift
import SnapKit
import Then

final class MenuView: UIView {

  // MARK: - UI

  private let backgroundView = UIView()

  private let containerView = UIView().then {
    $0.layer.shadowColor = UIColor(red: 0.32, green: 0.32, blue: 0.32, alpha: 0.1).cgColor
    $0.layer.shadowRadius = 8
    $0.layer.shadowOpacity = 1
    $0.backgroundColor = .white
    $0.layer.cornerRadius = 14
  }

  private let stackView = UIStackView().then {
    $0.axis = .vertical
    $0.spacing = 0
    $0.distribution = .fillEqually
  }

  // MARK: - Rx Output

  let itemTap = PublishRelay<Int?>()
  private let disposeBag = DisposeBag()

  // MARK: - Properties

  private let items: [String]
  private let itemHeight: CGFloat = 45
  private let menuWidth: CGFloat

  // MARK: - Init

  init(
    items: [String],
    width: CGFloat = 120
  ) {
    self.items = items
    self.menuWidth = width
    super.init(frame: UIScreen.main.bounds)

    setupUI()
    configureMenu()
    bind()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    containerView.layer.shadowPath = UIBezierPath(roundedRect: containerView.bounds, cornerRadius: 14).cgPath
  }

  // MARK: - UI Setup

  private func setupUI() {
    addSubview(backgroundView)
    addSubview(containerView)
    containerView.addSubview(stackView)

    backgroundView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }

    stackView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }
  }

  private func configureMenu() {
    for (index, item) in items.enumerated() {
      let button = UIButton().then {
        $0.setTitle(item, for: .normal)
        $0.setTitleColor(UIColor(.grayScale700), for: .normal)
        $0.titleLabel?.font = .pretendard(size: 15)
        $0.contentHorizontalAlignment = .center
        $0.tag = index
      }

      stackView.addArrangedSubview(button)
    }
  }

  // MARK: - Binding

  private func bind() {
    let tapGesture = UITapGestureRecognizer()
    backgroundView.addGestureRecognizer(tapGesture)

    tapGesture.rx.event
      .bind(with: self) { owner, _ in
        owner.dismiss()
        owner.itemTap.accept(nil)
      }
      .disposed(by: disposeBag)

    let buttons = stackView.arrangedSubviews.compactMap { $0 as? UIButton }

    Observable
      .merge(buttons.enumerated().map { tag, button in button.rx.tap.map { tag } })
      .do { [weak self] _ in
        self?.dismiss()
      }
      .bind(to: itemTap)
      .disposed(by: disposeBag)
  }

  // MARK: - Presentation

  func show(in view: UIView, sourcePoint: CGPoint) {
    view.addSubview(self)

    containerView.snp.makeConstraints {
      $0.top.equalTo(sourcePoint.y)
      $0.leading.equalTo(sourcePoint.x)
      $0.width.equalTo(menuWidth)
      $0.height.equalTo(itemHeight * CGFloat(items.count))
    }

    containerView.alpha = 0
    self.containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)

    UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
      self.containerView.alpha = 1
      self.containerView.transform = .identity
    }
  }

  private func dismiss() {
    UIView.animate(
      withDuration: 0.2,
      delay: 0,
      options: .curveEaseOut,
      animations: {
        self.containerView.alpha = 0
        self.containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
      },
      completion: { _ in
        self.removeFromSuperview()
      }
    )
  }
}
