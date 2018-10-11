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
    let dataStorage: CompleateDepositionPointsStorageCacherProtocol

    init(dataStorage: CompleateDepositionPointsStorageCacherProtocol) {
        self.dataStorage = dataStorage
    }

    func fetchPartner(for point: DepositionPointProtocol, completion: @escaping (PartnerProtocol?) -> Void) {
        dataStorage.getCachedPartner(of: point, success: completion, failure: { _ in completion(nil) })
    }

    func updatePartnerCache(completion: @escaping (Bool) -> Void) {
        dataStorage.getPartners(type: .сredit, success: { _ in
            completion(true)
        }, failure: { _ in
            completion(false)
        })
    }

    func loadPoints(lat: Double, lon: Double, radius: Double) {
        var location = LocationPoint()
        location.latitude = Float(lat)
        location.longitude = Float(lon)

        // TODO: Show cached points first when diffing of annotations will done
//        self.dataStorage.getCachedPoints(location: location, radius: Float(radius), partners: nil, success: { points in
//            DispatchQueue.main.async{
//                self.output.interactorDidLoad(points : points)
//            }
//        }, failure: { err in
        ////            print(err)
//            //Nothing for now
//        })
//
        dataStorage.getDepositionPoints(location: location, radius: Float(radius), partners: nil, success: { points in
            DispatchQueue.main.async {
                self.output.interactorDidLoad(points: points)
            }
        }, failure: { _ in
//            print(err)
            // Nothing for now
        })
    }

    func getImage(for partner: PartnerProtocol, cached: @escaping (UIImage) -> Void, completion: @escaping (UIImage) -> Void) {
        if let name = partner.picture {
            
            let loadBlock : (Date?) -> Void = { date in
                self.dataStorage.downloadImage(name: name, cacheDate: date, resolution: ImagesHelper().getResolutionTypeForCurrentScreen(), success: { img, _ in
                    DispatchQueue.main.async {
                        if let image = img {
                            completion(image)
                        }
                    }
                }, failure: { _ in
                    //                print(err)
                    // Nothing for now
                })
            }
            
            print(name)
            dataStorage.getCachedImage(name: name, resolution: ImagesHelper().getResolutionTypeForCurrentScreen(), success: { img, date in
                if let image = img {
                    cached(image)
                }
                
                loadBlock(date)
            }, failure: { _ in
                loadBlock(nil)
            })
            
        }
    }
}
