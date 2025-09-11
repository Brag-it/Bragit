//
//  ImageModel.swift
//  Bragit
//
//  Created by 이태윤 on 9/11/25.
//
import UIKit

enum UploadError: Error {
  case invalidImageData
  case serverError
  case parsingError
}

struct ImgBBResponse: Decodable {
  let data: ImgBBData
}

struct ImgBBData: Decodable {
  let url: URL
}
