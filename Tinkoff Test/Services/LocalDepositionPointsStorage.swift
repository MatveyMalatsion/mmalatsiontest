//
//  LocalDepositionPointsStorage.swift
//  Tinkoff Test
//
//  Created by Матвей Малацион on 08/10/2018.
//  Copyright © 2018 mmalatsion. All rights reserved.
//

import Foundation
import CoreLocation
import CoreData
import UIKit

protocol DepositionPointsStorageCacherProtocol : DepositionPointsStorageProtocol {
    func cache(depositionPoints: [DepositionPointProtocol], success: @escaping () -> (), failure : @escaping (Error) -> ())
    func getCachedPoints(location: LocationPointProtocol, radius: Float, partners: [PartnerProtocol]?, success: @escaping ([DepositionPointProtocol]) -> (), failure: @escaping (Error?) -> ())
    
    func cache(partners : [PartnerProtocol], success: @escaping () -> (), failure : @escaping (Error) -> ())
    func getCachedPartner(of point : DepositionPointProtocol, success: @escaping (PartnerProtocol?)->(), failure : @escaping (Error?)->())
    
    
    func cache(image : UIImage, name : String, date: Date, resolution: ImageResolutionType, success: @escaping () -> (), failure : @escaping (Error) -> ())
    
    func getCachedImage(name : String, resolution: ImageResolutionType, success: @escaping (UIImage?, Date?) -> (), failure : @escaping (Error) -> ())
}

class LocalDepositionPointsStorage : DepositionPointsStorageCacherProtocol{
    

    let dataManager : CoreDataManagerProtocol
    let imagesCache : NSCache<NSString, UIImage>
    let boundary = "%1$2%1"
    
    required init(coreDataManager : CoreDataManagerProtocol){
        self.dataManager = coreDataManager
        self.imagesCache = NSCache<NSString, UIImage>()
    }
    
    func getDepositionPoints(location: LocationPointProtocol, radius: Float, partners: [PartnerProtocol]?, success: @escaping ([DepositionPointProtocol]) -> (), failure: @escaping (Error?) -> ()) {
        
        let request = NSFetchRequest<CDDepositionPointEntity>(entityName: String(describing: CDDepositionPointEntity.self))
        
        dataManager.asyncFetch(fetchRequest: request, converter: { object in
            return DepositionPointEntity.objectFromCoreData(object: object)
        }, result: { points in
            success(points.filter{ point in
                
                guard let lat1 = point.location?.latitude,
                    let lon1 = point.location?.longitude,
                    let lat2 = location.latitude,
                    let lon2 = location.longitude else{
                        return false
                }
                
                let pointLocation = CLLocation(latitude: Double(lat1), longitude: Double(lon1))
                let cameraLocation = CLLocation(latitude: Double(lat2), longitude: Double(lon2))
                let distance = pointLocation.distance(from: cameraLocation)
                
                return  distance <= Double(radius)
            })
        }, failure: failure)
    }
    
    func getPartners(type: PartnerType, success: @escaping ([PartnerProtocol]) -> (), failure: @escaping (Error?) -> ()) {
        let request = NSFetchRequest<CDParentEntity>(entityName: String(describing: CDParentEntity.self))
        
        dataManager.asyncFetch(fetchRequest: request, converter: { object in
            return PartnerEntity.objectFromCoreData(object: object)
        }, result: { partners in
            success(partners)
        }, failure: failure)
    }
    
    func cache(depositionPoints: [DepositionPointProtocol], success: @escaping () -> (), failure : @escaping (Error) -> ()){
        
        self.dataManager.perform(task: { context in
            context.automaticallyMergesChangesFromParent = true
            depositionPoints.forEach{ point in
                var object : CDDepositionPointEntity? = nil
                
                let request = NSFetchRequest<CDDepositionPointEntity>(entityName: String.init(describing:CDDepositionPointEntity.self))
                request.predicate = NSPredicate(format: "externalId = %@",  point.externalId ?? "")

                if let result = try? context.fetch(request){
                    if result.count > 0{
                        object = result[0]
                    }else{
                         object = CDDepositionPointEntity(context: context)
                    }
                }else{
                    object = CDDepositionPointEntity(context: context)
                }
                //Sad, but Swift protocols has limitation: i can use only cocrete types
                //and cant't cast point to CoreDataConvertable. Maybe there is better solution,
                //but now i'll just copy point's data to object of concrete type and then
                //fill managed object to sabe
                if var object = object{
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
                //TODO: understand how to solve merge conflicts in async core data
                print("FAILE TO SAVE CONTEXT")
                failure(err)
            }
        }, failure: failure)
    }
    
    func cache(partners: [PartnerProtocol], success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        
        self.dataManager.perform(task: { context in
            context.automaticallyMergesChangesFromParent = true
            partners.forEach{ partner in
                var object : CDParentEntity? = nil
                
                let request = NSFetchRequest<CDParentEntity>(entityName: String.init(describing: CDParentEntity.self))
                request.predicate = NSPredicate(format: "id = %@",  partner.id ?? "")
                
                if let result = try? context.fetch(request){
                    if result.count > 0{
                        object = result[0]
                    }else{
                        object = CDParentEntity(context: context)
                    }
                }else{
                    object = CDParentEntity(context: context)
                }
                //Sad, but Swift protocols has limitation: i can use only cocrete types
                //and cant't cast point to CoreDataConvertable. Maybe there is better solution,
                //but now i'll just copy point's data to object of concrete type and then
                //fill managed object to sabe
                if var object = object{
                    let tempPartner = PartnerEntity(object: partner)
                    object = tempPartner.fillCoreData(object: object)
                }
            }
            
            do {
                try context.save()
                DispatchQueue.main.async {
                    success()
                }
            } catch let err{
                //TODO: understand how to solve merge conflicts in async core data
                print("FAILE TO SAVE CONTEXT")
                failure(err)
            }
        }, failure: failure)
    }
    
    func getCachedPartner(of point: DepositionPointProtocol, success: @escaping (PartnerProtocol?) -> (), failure: @escaping (Error?) -> ()) {
        
        guard let id = point.partnerName else{
            success(nil)
            return
        }
        
        let request = NSFetchRequest<CDParentEntity>(entityName: String(describing: CDParentEntity.self))
        request.predicate = NSPredicate(format: "id = %@", id)
        
        dataManager.asyncFetch(fetchRequest: request, converter: { object in
            return PartnerEntity.objectFromCoreData(object: object)
        }, result: { partners in
            success(partners.first)
        }, failure: failure)
    }
    
    private func nameString(for imageName : String, date: Date, resolutuion : ImageResolutionType) -> String{
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, dd LLL yyyy hh:mm:ss z"
        return [imageName, resolutuion.rawValue, dateFormatter.string(from: date)].joined(separator: boundary)
    }
    
    func cache(image: UIImage, name: String, date: Date, resolution: ImageResolutionType, success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        
        let nameString = self.nameString(for: name, date: date, resolutuion: resolution)
        self.imagesCache.setObject(image, forKey: nameString as NSString)
        do {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsURL.appendingPathComponent("\(nameString)")
            if let pngImageData = image.pngData() {
                try pngImageData.write(to: fileURL, options: .atomic)
                success()
            }
        } catch let err{
            failure(err)
        }
        
    }
    
    func getCachedImage(name: String, resolution: ImageResolutionType, success: @escaping (UIImage?, Date?) -> (), failure: @escaping (Error) -> ()) {
        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE, dd LLL yyyy hh:mm:ss z"
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil).first(where: { url in
                return url.lastPathComponent.contains(name) || url.lastPathComponent.contains(resolution.rawValue)
            })
            
            if let filePath = fileURL{
                
                let rawNameComponents = filePath.lastPathComponent.components(separatedBy: self.boundary)
                let date = dateFormatter.date(from: rawNameComponents[2])
                
                if let image = self.imagesCache.object(forKey: filePath.lastPathComponent as NSString){
                    success(image, date)
                }
                
                if FileManager.default.fileExists(atPath: filePath.path) {
                    let image = UIImage(contentsOfFile: filePath.path)
                    
                    if image != nil{
                        self.imagesCache.setObject(image!, forKey: name as NSString)
                    }
                    success(image, date)
                }else{
                    success(nil, date)
                }
            }
        } catch let err{
            failure(err)
        }
    }
    
    func getCachedPoints(location: LocationPointProtocol, radius: Float, partners: [PartnerProtocol]?, success: @escaping ([DepositionPointProtocol]) -> (), failure: @escaping (Error?) -> ()){
        self.getDepositionPoints(location: location, radius: radius, partners: partners, success: success, failure: failure)
    }
    
}