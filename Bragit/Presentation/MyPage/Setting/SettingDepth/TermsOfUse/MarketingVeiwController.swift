//
//  MarketingVeiwController.swift
//  Bragit
//
//  Created by 이태윤 on 9/9/25.
//
import UIKit

import SnapKit
import Then
import RxSwift
import RxCocoa
import RxFlow

final class MarketingVeiwController: UIViewController, Stepper {
  let steps = PublishRelay<Step>()
  var disposeBag = DisposeBag()
  
  private let headerView = UIView().then {
    $0.backgroundColor = .white
  }

  private let titleLabel = UILabel().then {
    $0.text = "오픈소스 라이선스"
    $0.font = .pretendard(size: 18, weight: .medium)
    $0.textColor = .grayScale900
  }

  private let backButton = UIButton().then {
    $0.setImage(.back, for: .normal)
    $0.tintColor = .grayScale900
  }

  private lazy var collectionView: UICollectionView = {
    // 리스트 형태의 컴포지셔널 레이아웃 구성
    var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
    config.showsSeparators = true
    let layout = UICollectionViewCompositionalLayout.list(using: config)

    let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
    cv.backgroundColor = .white
    cv.register(LicenseCell.self, forCellWithReuseIdentifier: LicenseCell.identifier)
    return cv
  }()

  init() {
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white

    view.addSubview(headerView)
    headerView.addSubview(backButton)
    headerView.addSubview(titleLabel)
    headerView.snp.makeConstraints {
      $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
      $0.leading.trailing.equalToSuperview()
      $0.height.equalTo(58)
    }

    backButton.snp.makeConstraints {
      $0.leading.equalToSuperview().offset(20)
      $0.centerY.equalTo(headerView.snp.centerY)
    }

    titleLabel.snp.makeConstraints {
      $0.centerX.equalTo(headerView.snp.centerX)
      $0.centerY.equalTo(headerView.snp.centerY)
      $0.leading.greaterThanOrEqualTo(backButton.snp.trailing).offset(20)
    }
    view.addSubview(collectionView)
    collectionView.snp.makeConstraints {
      $0.top.equalTo(headerView.snp.bottom)
      $0.leading.trailing.bottom.equalToSuperview()
    }
  }
}

