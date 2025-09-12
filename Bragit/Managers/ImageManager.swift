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

      let boundary = UUID().uuidString
      request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

      var body = Data()
      body.append("--\(boundary)\r\n".data(using: .utf8)!)
      body.append("Content-Disposition: form-data; name=\"image\"; filename=\"upload.jpg\"\r\n".data(using: .utf8)!)
      body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
      body.append(data)
      body.append("\r\n".data(using: .utf8)!)
      body.append("--\(boundary)--\r\n".data(using: .utf8)!)

      request.httpBody = body

      let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
          observer.onError(error)
          return
        }

        guard let data = data else {
          observer.onError(NSError(domain: "ImageUpload", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
          return
        }

        if let responseString = String(data: data, encoding: .utf8) {
          print("📥 ImgBB 응답: \(responseString)")
        }

        guard
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
