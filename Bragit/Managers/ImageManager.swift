//
//  ImageManager.swift
//  Bragit
//
//  Created by 이태윤 on 9/11/25.
//
import UIKit
import RxSwift
import Dependencies

protocol ImageManagerProtocol {
  func rxUploadImage(data: Data) -> Observable<URL>
  func rxUploadImages(datas: [Data]) -> Observable<[URL]>
}

final class ImageManager: ImageManagerProtocol {

  @Dependency(\.imgBBApiKey) var apiKey

  func rxUploadImage(data: Data) -> Observable<URL> {
    return Observable.create { observer in
      let url = URL(string: "https://api.imgbb.com/1/upload?key=\(self.apiKey)")!
      var request = URLRequest(url: url)
      request.httpMethod = "POST"

      // Base64 인코딩
      let base64String = data.base64EncodedString()
      let bodyString = "image=\(base64String)"
      request.httpBody = bodyString.data(using: .utf8)
      request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

      let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
          observer.onError(error)
          return
        }

        guard
          let data = data,
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let dataField = json["data"] as? [String: Any],
          let urlString = dataField["url"] as? String,
          let url = URL(string: urlString)
        else {
          observer.onError(NSError(domain: "ImageUpload", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
          return
        }

        observer.onNext(url)
        observer.onCompleted()
      }

      task.resume()

      return Disposables.create {
        task.cancel()
      }
    }
  }

  func rxUploadImages(datas: [Data]) -> Observable<[URL]> {
    return Observable.zip(datas.map { self.rxUploadImage(data: $0) })
  }
}
