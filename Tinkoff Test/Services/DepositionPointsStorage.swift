//
//  DepositionPointsStorage.swift
//  Tinkoff Test
//
//  Created by Матвей Малацион on 08/10/2018.
//  Copyright © 2018 mmalatsion. All rights reserved.
//

import Foundation
import UIKit

protocol CompleateDepositionPointsStorageCacherProtocol : DepositionPointsStorageCacherProtocol, ImageFetcherProtocol{}

class DepositionPointsStorage : CompleateDepositionPointsStorageCacherProtocol{
    
    let localStorage : DepositionPointsStorageCacherProtocol
    let remoteStorage : NetworkFetcherProtocol
    
    init(remoteStorage : NetworkFetcherProtocol, localStorage : DepositionPointsStorageCacherProtocol){
        self.localStorage = localStorage
        self.remoteStorage = remoteStorage
    }
    
    func cache(depositionPoints: [DepositionPointProtocol], success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        self.localStorage.cache(depositionPoints: depositionPoints, success: success, failure: failure)
    }
    
    func getDepositionPoints(location: LocationPointProtocol, radius: Float, partners: [PartnerProtocol]?, success: @escaping ([DepositionPointProtocol]) -> (), failure: @escaping (Error?) -> ()) {
        
        if Reachability.isConnectedToNetwork(){
            self.remoteStorage.getDepositionPoints(location: location, radius: radius, partners: partners, success: { points in
                
                self.localStorage.cache(depositionPoints: points, success: {
                    success(points)
                }, failure: failure)
                
            }, failure: failure)
        }else{
            self.localStorage.getDepositionPoints(location: location, radius: radius, partners: partners, success: success, failure: failure)
        }
    }
    
    func cache(partners: [PartnerProtocol], success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        self.localStorage.cache(partners: partners, success: success, failure: failure)
    }
    
    func getCachedPartner(of point: DepositionPointProtocol, success: @escaping (PartnerProtocol?) -> (), failure: @escaping (Error?) -> ()) {
        self.localStorage.getCachedPartner(of: point, success: success, failure: failure)
    }
    
    func getPartners(type: PartnerType, success: @escaping ([PartnerProtocol]) -> (), failure: @escaping (Error?) -> ()) {
        self.remoteStorage.getPartners(type: type, success: { partners in
            self.cache(partners: partners, success: {
                success(partners)
            }, failure: failure)
        }, failure: failure)
    }
    
    func downloadImage(name: String, cacheDate: Date?, resolution: ImageResolutionType, success: @escaping (UIImage?, Date) -> (), failure: @escaping (Error?) -> ()) {
        
        let getCachedBlock = {
            self.getCachedImage(name: name, resolution: resolution, success: { image, date in
                guard let image = image, let date = date else{
                    success(nil, Date())
                    return
                }
                
                success(image, date)
            }, failure: failure)
        }
        
        let loadBlock = {
            self.remoteStorage.downloadImage(name: name, cacheDate: nil, resolution: resolution, success: { image, date in
                guard let image = image else{
                    success(nil, date)
                    return
                }
                self.cache(image: image, name: name, date: date, resolution: resolution, success: {
                    success(image, date)
                }, failure: failure)
            }, failure: failure)
        }
        
        if Reachability.isConnectedToNetwork(){
            if let date = cacheDate{
                self.checkLastModified(name: name, resolution: resolution, date: date, shouldLoadBlock: { shouldLoad in
                    if shouldLoad{
                        loadBlock()
                    }else{
                        getCachedBlock()
                    }
                })
            }else{
                loadBlock()
            }
        }else{
            getCachedBlock()
        }
    }
    
    func checkLastModified(name: String, resolution: ImageResolutionType, date: Date, shouldLoadBlock: @escaping (Bool) -> ()) {
        self.remoteStorage.checkLastModified(name: name, resolution: resolution, date: date, shouldLoadBlock: shouldLoadBlock)
    }
    
    
    func cache(image: UIImage, name: String, date: Date, resolution: ImageResolutionType, success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        self.localStorage.cache(image: image, name: name, date: date, resolution: resolution, success: success, failure: failure)
        
    }
    
    func getCachedImage(name: String, resolution: ImageResolutionType, success: @escaping (UIImage?, Date?) -> (), failure: @escaping (Error) -> ()) {
        self.localStorage.getCachedImage(name: name, resolution: resolution, success: success, failure: failure)
    }
    
    func getCachedPoints(location: LocationPointProtocol, radius: Float, partners: [PartnerProtocol]?, success: @escaping ([DepositionPointProtocol]) -> (), failure: @escaping (Error?) -> ()) {
        self.localStorage.getDepositionPoints(location: location, radius: radius, partners: partners, success: success, failure: failure)
    }
}
