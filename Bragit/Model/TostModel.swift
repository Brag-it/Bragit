//
//  TostModel.swift
//  Bragit
//
//  Created by 이태윤 on 9/15/25.
//
enum ToastPurpose: Equatable {
  case deleted
  case reported
  case blocked
  case error(String)
}

struct ToastEvent: Equatable {
  let purpose: ToastPurpose
}
