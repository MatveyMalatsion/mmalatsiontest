//
//  NetworkEntityRequestBuilder.swift
//  Tinkoff Test
//
//  Created by Матвей Малацион on 07/10/2018.
//  Copyright © 2018 mmalatsion. All rights reserved.
//

import Foundation

class NetworkEntityRequestBuilder<T : Codable>{
    
    struct TinkoffPayloadEntity : Codable {
        var resultCode : String?
        var payload : T?
    }
    
    func buildGetDataTask(with endpoint : URL, params : [String : String]?, success : @escaping (T)->(), failure : @escaping (Error?)->()) -> URLSessionDataTask{
        var completeUrl = endpoint
        if let params = params, var urlComponents = URLComponents(url: endpoint, resolvingAgainstBaseURL: false){
            urlComponents.queryItems = params.map{ keyvalue in URLQueryItem(name: keyvalue.key, value: keyvalue.value)}
            
            if let url = urlComponents.url{
                completeUrl = url
            }
        }
        let urlRequest = URLRequest(url: completeUrl)
        return URLSession.shared.dataTask(with: urlRequest, completionHandler: { data, response, error in

            if error != nil{
                failure(error)
            }else{
                
                if let data = data{
                    
                    do{
                        let result = try JSONDecoder().decode(TinkoffPayloadEntity.self, from: data)
                        if result.resultCode == "OK", let payload = result.payload{
                            success(payload)
                        }else{
                            failure(NSError(domain: "NetworkCenter", code: 0, userInfo: ["reason": "resultCode is not OK or Payload is nil"]))
                        }
                    }catch let err{
                        failure(err)
                    }
                
                }else{
                    failure(NSError(domain: "NetworkCenter", code: 1, userInfo: ["reason": "data is empty"]))
                }
            }
        })
    }
}
