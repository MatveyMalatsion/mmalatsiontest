//
//  MainMapMainMapInteractor.swift
//  Tinkoff Test
//
//  Created by madway94@yandex.ru on 06/10/2018.
//  Copyright © 2018 MMalatsion. All rights reserved.
//
import Foundation
import UIKit

class MainMapInteractor: MainMapInteractorInput {

    weak var output: MainMapInteractorOutput!
    let dataStorage : CompleateDepositionPointsStorageCacherProtocol
    
    init(dataStorage : CompleateDepositionPointsStorageCacherProtocol){
        self.dataStorage = dataStorage
    }
    
    func fetchPartner(for point : DepositionPointProtocol, compleation : @escaping (PartnerProtocol?)->()){
        self.dataStorage.getCachedPartner(of: point, success: compleation, failure: { err in compleation(nil)})
    }
    
    func updatePartnerCache(compleation : @escaping (Bool)->()){
        self.dataStorage.getPartners(type: .Credit, success: { partners in
            compleation(true)
        }, failure: { err in
            compleation(false)
        })
    }
    
    func loadPoints(lat: Double, lon: Double, radius: Double){
        var location = LocationPoint()
        location.latitude = Float(lat)
        location.longitude = Float(lon)
        
        self.dataStorage.getCachedPoints(location: location, radius: Float(radius), partners: nil, success: { points in
            DispatchQueue.main.async{
                self.output.interactorDidLoad(points : points)
            }
        }, failure: { err in
//            print(err)
            //Nothing for now
        })
        
        self.dataStorage.getDepositionPoints(location: location, radius: Float(radius), partners: nil, success: { points in
            DispatchQueue.main.async{
                self.output.interactorDidLoad(points : points)
            }
        }, failure: { err in
//            print(err)
            //Nothing for now
        })
    }
    
    func getImage(for partner: PartnerProtocol, cached: @escaping (UIImage) -> (), compleation: @escaping (UIImage) -> ()){
        if let name = partner.picture{
            
            self.dataStorage.getCachedImage(name: name, resolution: ImagesHelper().getResolutionTypeForCurrentScreen(), success: { img, err in
                if let image = img{
                    cached(image)
                }
            }, failure: {err in
//                print(err)
                //Nothing for now
            })
            
            self.dataStorage.downloadImage(name: name, cacheDate: Date(), resolution: ImagesHelper().getResolutionTypeForCurrentScreen(), success: { img, err in
                DispatchQueue.main.async {
                    if let image = img{
                        compleation(image)
                    }
                }
            }, failure: { err in
//                print(err)
                //Nothing for now
            })
        }
    }
}
