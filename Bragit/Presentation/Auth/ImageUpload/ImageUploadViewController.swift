//
//  ImageUploadViewController.swift
//  Bragit
//
//  Created by luca on 8/27/25.
//

import UIKit

class ImageUploadViewController: UIViewController {
  // MARK: UI

  let nextButton = UIButton().then {
    $0.setTitle("확인", for: .normal)
    $0.setTitleColor(UIColor(red: 0.315, green: 0.315, blue: 0.315, alpha: 1), for: .normal)
    $0.layer.cornerRadius = 12
    $0.backgroundColor = .orange
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupLayout()
  }

  private func setupLayout() {
    //
  }
}
