//
//  LocalDepositionPointsStorage.swift
//  Tinkoff Test
//
//  Created by Матвей Малацион on 08/10/2018.
//  Copyright © 2018 mmalatsion. All rights reserved.
//

import CoreData
import CoreLocation
import Foundation
import UIKit

protocol DepositionPointsStorageCacherProtocol: DepositionPointsStorageProtocol {
    func cache(depositionPoints: [DepositionPointProtocol], success: @escaping () -> Void, failure: @escaping (Error) -> Void)
    func getCachedPoints(location: LocationPointProtocol, radius: Float, partners: [PartnerProtocol]?, success: @escaping ([DepositionPointProtocol]) -> Void, failure: @escaping (Error?) -> Void)
    
    func cache(partners: [PartnerProtocol], success: @escaping () -> Void, failure: @escaping (Error) -> Void)
    func getCachedPartner(of point: DepositionPointProtocol, success: @escaping (PartnerProtocol?) -> Void, failure: @escaping (Error?) -> Void)
    
    func cache(image: UIImage, name: String, date: Date, resolution: ImageResolutionType, success: @escaping () -> Void, failure: @escaping (Error) -> Void)
    
    func getCachedImage(name: String, resolution: ImageResolutionType, success: @escaping (UIImage?, Date?) -> Void, failure: @escaping (Error) -> Void)
}

class LocalDepositionPointsStorage: DepositionPointsStorageCacherProtocol {
    let dataManager: CoreDataManagerProtocol
    let imagesCache: NSCache<NSString, UIImage>
    let boundary = "%1$2%1"
    let operationQueue : OperationQueue
    
    required init(coreDataManager: CoreDataManagerProtocol) {
        dataManager = coreDataManager
        imagesCache = NSCache<NSString, UIImage>()
        operationQueue = OperationQueue()
    }
    
    func getDepositionPoints(location: LocationPointProtocol, radius: Float, partners _: [PartnerProtocol]?, success: @escaping ([DepositionPointProtocol]) -> Void, failure: @escaping (Error?) -> Void) {
        let request = NSFetchRequest<CDDepositionPointEntity>(entityName: String(describing: CDDepositionPointEntity.self))
        
        dataManager.asyncFetch(fetchRequest: request, converter: { object in
            DepositionPointEntity.objectFromCoreData(object: object)
        }, result: { points in
            success(points.filter { point in
                
                guard let lat1 = point.location?.latitude,
                    let lon1 = point.location?.longitude,
                    let lat2 = location.latitude,
                    let lon2 = location.longitude else {
                        return false
                }
                
                let pointLocation = CLLocation(latitude: Double(lat1), longitude: Double(lon1))
                let cameraLocation = CLLocation(latitude: Double(lat2), longitude: Double(lon2))
                let distance = pointLocation.distance(from: cameraLocation)
                
                return distance <= Double(radius)
            })
        }, failure: failure)
    }
    
    func getPartners(type _: PartnerType, success: @escaping ([PartnerProtocol]) -> Void, failure: @escaping (Error?) -> Void) {
        let request = NSFetchRequest<CDParentEntity>(entityName: String(describing: CDParentEntity.self))
        
        dataManager.asyncFetch(fetchRequest: request, converter: { object in
            PartnerEntity.objectFromCoreData(object: object)
        }, result: { partners in
            success(partners)
        }, failure: failure)
    }
    
    func cache(depositionPoints: [DepositionPointProtocol], success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        dataManager.perform(task: { context in
            context.automaticallyMergesChangesFromParent = true
            depositionPoints.forEach { point in
                var object: CDDepositionPointEntity?
                
                let request = NSFetchRequest<CDDepositionPointEntity>(entityName: String(describing: CDDepositionPointEntity.self))
                request.predicate = NSPredicate(format: "externalId = %@", point.externalId ?? "")
                
                if let result = try? context.fetch(request) {
                    if result.count > 0 {
                        object = result[0]
                    } else {
                        object = CDDepositionPointEntity(context: context)
                    }
                } else {
                    object = CDDepositionPointEntity(context: context)
                }
                // Sad, but Swift protocols has limitation: i can use only cocrete types
                // and cant't cast point to CoreDataConvertable. Maybe there is better solution,
                // but now i'll just copy point's data to object of concrete type and then
                // fill managed object to sabe
                if var object = object {
                    let depositionPoint = DepositionPointEntity(object: point)
                    object = depositionPoint.fillCoreData(object: object)
                }
            }
            
            do {
                try context.save()
                DispatchQueue.main.async {
                    success()
                }
            } catch let err {
                // TODO: understand how to solve merge conflicts in async core data
                print("FAILE TO SAVE CONTEXT")
                failure(err)
            }
        }, failure: failure)
    }
    
    func cache(partners: [PartnerProtocol], success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        dataManager.perform(task: { context in
            context.automaticallyMergesChangesFromParent = true
            partners.forEach { partner in
                var object: CDParentEntity?
                
                let request = NSFetchRequest<CDParentEntity>(entityName: String(describing: CDParentEntity.self))
                request.predicate = NSPredicate(format: "id = %@", partner.id ?? "")
                
                if let result = try? context.fetch(request) {
                    if result.count > 0 {
                        object = result[0]
                    } else {
                        object = CDParentEntity(context: context)
                    }
                } else {
                    object = CDParentEntity(context: context)
                }
                // Sad, but Swift protocols has limitation: i can use only cocrete types
                // and cant't cast point to CoreDataConvertable. Maybe there is better solution,
                // but now i'll just copy point's data to object of concrete type and then
                // fill managed object to sabe
                if var object = object {
                    let tempPartner = PartnerEntity(object: partner)
                    object = tempPartner.fillCoreData(object: object)
                }
            }
            
            do {
                try context.save()
                DispatchQueue.main.async {
                    success()
                }
            } catch let err {
                // TODO: understand how to solve merge conflicts in async core data
                print("FAILE TO SAVE CONTEXT")
                failure(err)
            }
        }, failure: failure)
    }
    
    func getCachedPartner(of point: DepositionPointProtocol, success: @escaping (PartnerProtocol?) -> Void, failure: @escaping (Error?) -> Void) {
        guard let id = point.partnerName else {
            success(nil)
            return
        }
        
        let request = NSFetchRequest<CDParentEntity>(entityName: String(describing: CDParentEntity.self))
        request.predicate = NSPredicate(format: "id = %@", id)
        
        dataManager.asyncFetch(fetchRequest: request, converter: { object in
            PartnerEntity.objectFromCoreData(object: object)
        }, result: { partners in
            success(partners.first)
        }, failure: failure)
    }
    
    private func nameString(for imageName: String, date: Date, resolutuion: ImageResolutionType) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, dd LLL yyyy hh:mm:ss z"
        return [imageName, resolutuion.rawValue, dateFormatter.string(from: date)].joined(separator: boundary)
    }
    
    func cache(image: UIImage, name: String, date: Date, resolution: ImageResolutionType, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        let nameString = self.nameString(for: name, date: date, resolutuion: resolution)
        imagesCache.setObject(image, forKey: name as NSString)
        
        operationQueue.addOperation {
            do {
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let fileURL = documentsURL.appendingPathComponent("\(nameString)")
                if let pngImageData = image.pngData() {
                    try pngImageData.write(to: fileURL, options: .atomic)
                    DispatchQueue.main.async {
                        success()
                    }
                }
            } catch let err {
                failure(err)
            }
        }
    }
    
    func getCachedImage(name: String, resolution: ImageResolutionType, success: @escaping (UIImage?, Date?) -> Void, failure: @escaping (Error) -> Void) {
        operationQueue.addOperation {
            do {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "EEEE, dd LLL yyyy hh:mm:ss z"
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let fileURL = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil).first(where: { url in
                    url.lastPathComponent.contains(name) && url.lastPathComponent.contains(resolution.rawValue)
                })
                
                if let filePath = fileURL {
                    let rawNameComponents = filePath.lastPathComponent.components(separatedBy: self.boundary)
                    let date = dateFormatter.date(from: rawNameComponents[2])
                    
                    if let image = self.imagesCache.object(forKey: name as NSString) {
                        DispatchQueue.main.async {
                            success(image, date)
                        }
                        return
                    }
                    
                    if FileManager.default.fileExists(atPath: filePath.path) {
                        let image = UIImage(contentsOfFile: filePath.path)
                        
                        if image != nil {
                            self.imagesCache.setObject(image!, forKey: name as NSString)
                        }
                        DispatchQueue.main.async {
                            success(image, date)
                        }
                        
                    } else {
                        DispatchQueue.main.async {
                            success(nil, date)
                        }
                    }
                }
            } catch let err {
                DispatchQueue.main.async {
                    failure(err)
                }
            }
        }
    }
    
    func getCachedPoints(location: LocationPointProtocol, radius: Float, partners: [PartnerProtocol]?, success: @escaping ([DepositionPointProtocol]) -> Void, failure: @escaping (Error?) -> Void) {
        getDepositionPoints(location: location, radius: radius, partners: partners, success: success, failure: failure)
    }
}

