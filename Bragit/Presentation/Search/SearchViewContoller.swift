//
//  SearchViewContoller.swift
//  Bragit
//
//  Created by 이태윤 on 9/6/25.
//
import UIKit

import SnapKit
import Then
import ReactorKit
import RxSwift
import RxCocoa

final class SearchViewController: UIViewController, View {
  var disposeBag = DisposeBag()

  private let headerView = UIView()

  private let backButton = UIButton(type: .system).then {
    $0.setImage(.back, for: .normal)
    $0.tintColor = .grayScale900
  }

  private let searchBar = SearchBar()

  private lazy var dataSource = setupDataSource(self.searchResultCollectionView)

  init(reactor: SearchReactor) {
    super.init(nibName: nil, bundle: nil)
    self.reactor = reactor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white

    setUIConstraints()
  }

  // UI 설정
  private func setUIConstraints() {
    view.addSubview(headerView)
    headerView.addSubview(backButton)
    headerView.addSubview(searchBar)

    headerView.snp.makeConstraints {
      $0.top.equalTo(view.safeAreaLayoutGuide)
      $0.leading.trailing.equalToSuperview()
      $0.height.equalTo(64)
    }

    backButton.snp.makeConstraints {
      $0.leading.equalToSuperview().inset(20)
      $0.centerY.equalTo(headerView.snp.centerY)
      $0.width.equalTo(24)
    }

    searchBar.snp.makeConstraints {
      $0.leading.equalTo(backButton.snp.trailing).offset(16)
      $0.centerY.equalTo(headerView.snp.centerY)
      $0.trailing.equalToSuperview().inset(20)
    }
  }

  func bind(reactor: SearchReactor) {
    backButton.rx.tap
      .map { SearchReactor.Action.didTapBack }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    rx.viewDidAppear
      .take(1)
      .map { _ in SearchReactor.Action.viewDidLoad }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)
  }
}
