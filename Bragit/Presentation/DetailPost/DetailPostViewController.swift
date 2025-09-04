//
//  DetailPostViewController.swift
//  Bragit
//
//  Created by 이태윤 on 9/4/25.
//
import UIKit
import PhotosUI

import ReactorKit
import RxSwift
import RxCocoa
import SnapKit
import Then

class DetailPostViewController: UIViewController, View {
  var disposeBag = DisposeBag()

  init(reactor: DetailPostReactor) {
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
    print("넘겨받은 데이터 : \(String(describing: reactor?.post ?? nil))")
  }

  // UI 설정
  private func setUIConstraints() {

  }

  func bind(reactor: DetailPostReactor) {

  }
}
