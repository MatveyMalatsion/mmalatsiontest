//
//  NetworkService.swift
//  Tinkoff Test
//
//  Created by Матвей Малацион on 06/10/2018.
//  Copyright © 2018 mmalatsion. All rights reserved.
//

import Foundation
import UIKit

enum PartnerType : String{
    case Credit
    case Save
}

protocol ImageFetcherProtocol{
    func downloadImage(name : String, cacheDate: Date?, resolution: ImageResolutionType, success : @escaping (UIImage?, Date) -> (), failure : @escaping (Error?)->())
    func checkLastModified(name : String, resolution: ImageResolutionType, date : Date, shouldLoadBlock: @escaping (Bool)->())
}
protocol NetworkFetcherProtocol : DepositionPointsStorageProtocol, ImageFetcherProtocol {}

class NetworkService :  NetworkFetcherProtocol{
    
    let baseUrl : String
    let staticUrl : String
    var currentDepositionPointTask : URLSessionDataTask?
    
    required init(baseUrl : String, staticUrl : String){
        self.baseUrl = baseUrl
        self.staticUrl = staticUrl
    }
    
    enum NetworkEndpoints : String{
        case getPoints = "/v1/deposition_points"
        case getPartners = "/v1/deposition_partners"
        case getImage = "/icons/deposition-partners-v3"
    }
    
    
    func getPartners(type: PartnerType, success: @escaping ([PartnerProtocol])->(), failure : @escaping (Error?)->()){
        
        let params = ["accountType" : type.rawValue]
        let url = URL(string: "\(baseUrl)\(NetworkEndpoints.getPartners.rawValue)")!
        
        let successBlock : ([PartnerEntity])->() = { partners in
            success(partners)
        }
        let task : URLSessionDataTask = NetworkEntityRequestBuilder<[PartnerEntity]>().buildGetDataTask(with: url, params: params, success: successBlock, failure: failure)
        task.resume()
    }
    
    func getDepositionPoints(location : LocationPointProtocol, radius: Float, partners: [PartnerProtocol]?, success: @escaping ([DepositionPointProtocol])->(), failure : @escaping (Error?)->()) {
        
        guard let lat = location.latitude, let lon = location.longitude, radius >= 0 else{
            failure(NSError(domain: "NetworkCenter", code: 3, userInfo: ["reason": "invalid params"]))
            return
        }
        
        let partnersToPass = (partners ?? []).compactMap{$0.name}
        
        var params : [String : String] = [
            "latitude" : String(lat),
            "longitude" : String(lon),
            "radius" : String(Int(radius))
        ]
        
        if partnersToPass.count > 0{
            params["partners"] = partnersToPass.joined(separator: ",")
        }
        
        let url = URL(string: "\(baseUrl)\(NetworkEndpoints.getPoints.rawValue)")!
        
        let successBlock : ([DepositionPointEntity]) -> () = { objects in
            success(objects)
        }
        
        self.currentDepositionPointTask?.cancel()
        let task : URLSessionDataTask = NetworkEntityRequestBuilder<[DepositionPointEntity]>().buildGetDataTask(with: url, params: params, success: successBlock, failure: failure)
        self.currentDepositionPointTask = task
        task.resume()
    }
    
    func downloadImage(name : String, cacheDate: Date?, resolution: ImageResolutionType, success : @escaping (UIImage?, Date) -> (), failure : @escaping (Error?)->()){
        
        let url = URL(string: "\(self.staticUrl)\(NetworkEndpoints.getImage.rawValue)/\(resolution.rawValue)/\(name)")!
        let urlRequest = URLRequest(url: url)
        
        URLSession.shared.dataTask(with: urlRequest, completionHandler: { data, response, error in
            if error != nil{
                failure(error)
            }else{
                if let data = data{
                    success(UIImage(data: data), Date())
                }
            }
            
        }).resume()
        
    }
    
    
    func checkLastModified(name : String, resolution: ImageResolutionType, date : Date, shouldLoadBlock: @escaping (Bool)->()){
        let url = URL(string: "\(self.staticUrl)\(NetworkEndpoints.getImage.rawValue)/\(resolution.rawValue)/\(name)")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "HEAD"
        
        URLSession.shared.dataTask(with: urlRequest, completionHandler: { data, response, error in
            if let httpResp: HTTPURLResponse = response as? HTTPURLResponse {
                if let dateString = httpResp.allHeaderFields["Last-Modified"] as? String{
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
                    if let serverDate = dateFormatter.date(from: dateString){
                        shouldLoadBlock(serverDate > date)
                    }else{
                        shouldLoadBlock(true)
                    }
                }
            }
            shouldLoadBlock(true)
                
        }).resume()
    }
}
