//
//  NetworkService.swift
//  Tinkoff Test
//
//  Created by Матвей Малацион on 06/10/2018.
//  Copyright © 2018 mmalatsion. All rights reserved.
//

import Foundation
import UIKit

enum PartnerType: String {
    case сredit = "Credit"
    case save = "Save"
}

protocol ImageFetcherProtocol {
    func downloadImage(name: String, cacheDate: Date?, resolution: ImageResolutionType, success: @escaping (UIImage?, Date) -> Void, failure: @escaping (Error?) -> Void)
    func checkLastModified(name: String, resolution: ImageResolutionType, date: Date, shouldLoadBlock: @escaping (Bool) -> Void)
}

protocol NetworkFetcherProtocol: DepositionPointsStorageProtocol, ImageFetcherProtocol {}

class NetworkService: NetworkFetcherProtocol {
    let baseUrl: String
    let staticUrl: String
    var currentDepositionPointTask: URLSessionDataTask?

    required init(baseUrl: String, staticUrl: String) {
        self.baseUrl = baseUrl
        self.staticUrl = staticUrl
    }

    enum NetworkEndpoints: String {
        case getPoints = "/v1/deposition_points"
        case getPartners = "/v1/deposition_partners"
        case getImage = "/icons/deposition-partners-v3"
    }

    func getPartners(type: PartnerType, success: @escaping ([PartnerProtocol]) -> Void, failure: @escaping (Error?) -> Void) {
        let params = ["accountType": type.rawValue]
        let url = URL(string: "\(baseUrl)\(NetworkEndpoints.getPartners.rawValue)")!

        let successBlock: ([PartnerEntity]) -> Void = { partners in
            DispatchQueue.main.async {
                success(partners)
            }
        }
        let task: URLSessionDataTask = NetworkEntityRequestBuilder<[PartnerEntity]>().buildGetDataTask(with: url, params: params, success: successBlock, failure: failure)
        task.resume()
    }

    func getDepositionPoints(location: LocationPointProtocol, radius: Float, partners: [PartnerProtocol]?, success: @escaping ([DepositionPointProtocol]) -> Void, failure: @escaping (Error?) -> Void) {
        guard let lat = location.latitude, let lon = location.longitude, radius >= 0 else {
            failure(NSError(domain: "NetworkCenter", code: 3, userInfo: ["reason": "invalid params"]))
            return
        }

        let partnersToPass = (partners ?? []).compactMap { $0.name }

        var params: [String: String] = [
            "latitude": String(lat),
            "longitude": String(lon),
            "radius": String(Int(radius)),
        ]

        if partnersToPass.count > 0 {
            params["partners"] = partnersToPass.joined(separator: ",")
        }

        let url = URL(string: "\(baseUrl)\(NetworkEndpoints.getPoints.rawValue)")!

        let successBlock: ([DepositionPointEntity]) -> Void = { objects in
            DispatchQueue.main.async {
                success(objects)
            }
        }

        currentDepositionPointTask?.cancel()
        let task: URLSessionDataTask = NetworkEntityRequestBuilder<[DepositionPointEntity]>().buildGetDataTask(with: url, params: params, success: successBlock, failure: failure)
        currentDepositionPointTask = task
        task.resume()
    }

    func downloadImage(name: String, cacheDate _: Date?, resolution: ImageResolutionType, success: @escaping (UIImage?, Date) -> Void, failure: @escaping (Error?) -> Void) {
        let url = URL(string: "\(staticUrl)\(NetworkEndpoints.getImage.rawValue)/\(resolution.rawValue)/\(name)")!
        let urlRequest = URLRequest(url: url)

        URLSession.shared.dataTask(with: urlRequest, completionHandler: { data, _, error in
            if error != nil {
                failure(error)
            } else {
                if let data = data {
                    DispatchQueue.main.async {
                        success(UIImage(data: data), Date())
                    }
                }
            }

        }).resume()
    }

    func checkLastModified(name: String, resolution: ImageResolutionType, date: Date, shouldLoadBlock: @escaping (Bool) -> Void) {
        let url = URL(string: "\(staticUrl)\(NetworkEndpoints.getImage.rawValue)/\(resolution.rawValue)/\(name)")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "HEAD"

        URLSession.shared.dataTask(with: urlRequest, completionHandler: { _, response, _ in
            if let httpResp: HTTPURLResponse = response as? HTTPURLResponse {
                if let dateString = httpResp.allHeaderFields["Last-Modified"] as? String {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
                    if let serverDate = dateFormatter.date(from: dateString) {
//                        print("\(date) -- \(serverDate) -- \(serverDate > date)")
                        shouldLoadBlock(serverDate > date)
                    } else {
//                        print("FAILED TO PARSE")
                        shouldLoadBlock(true)
                    }
                }
            }else{
                shouldLoadBlock(true)
            }

        }).resume()
    }
}
