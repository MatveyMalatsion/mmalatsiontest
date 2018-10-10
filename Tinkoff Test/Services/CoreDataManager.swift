//
//  CoreDataManager.swift
//  Tinkoff Test
//
//  Created by Матвей Малацион on 07/10/2018.
//  Copyright © 2018 mmalatsion. All rights reserved.
//

import Foundation
import CoreData

enum CoreDataManagerError : Error {
    case stackNotReady
    case persistentContainerNotAvailable
    case asyncFetchRequestError(error : Error)
}

protocol CoreDataManagerProtocol {
    func raiseStack(success : @escaping () -> (), failure : ((Error) -> ())?)
    func asyncFetch<T , C : CoreDataConvertable>(fetchRequest : NSFetchRequest<T>, converter : @escaping (T)->(C), result: @escaping ([C])->(), failure: ((CoreDataManagerError)->())?)
    func perform(task : @escaping (NSManagedObjectContext)->(), failure : ((CoreDataManagerError) -> ())?)
    
}

class CoreDataManager : CoreDataManagerProtocol{
    
    let modelName : String
    var isReady : Bool
    var persistentContainer : NSPersistentContainer?
    
    
    required init(modelName : String){
        self.modelName = modelName
        self.isReady = false
    }
    
    func raiseStack(success : @escaping () -> (), failure : ((Error) -> ())?){
    
        if self.isReady{
            success()
        }
        
        let persistentContainer = NSPersistentContainer(name : modelName)
        
        persistentContainer.loadPersistentStores{ stores, error in
            if let error = error {
                failure?(error)
            }else{
                self.isReady = true
                persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
                self.persistentContainer = persistentContainer
                success()
            }
        }
    }
    
    func asyncFetch<T , C : CoreDataConvertable>(fetchRequest : NSFetchRequest<T>, converter : @escaping (T)->(C), result: @escaping ([C])->(), failure: ((CoreDataManagerError)->())?){
        
        guard let privateManagedObjectContext = self.persistentContainer?.newBackgroundContext() else {
            failure?(.persistentContainerNotAvailable)
            return
        }
        privateManagedObjectContext.automaticallyMergesChangesFromParent = true
        fetchRequest.returnsObjectsAsFaults = false
        let asynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { asynchronousFetchResult in
            
            guard let finalResult = asynchronousFetchResult.finalResult else {
                result([])
                return
            }
            
            let converted = finalResult.map { converter($0) }
            
            DispatchQueue.main.async {
                result(converted)
            }
        }
        
        do {
            try privateManagedObjectContext.execute(asynchronousFetchRequest)
        } catch let error {
            failure?(.asyncFetchRequestError(error: error))
        }
    }
    
    func perform(task : @escaping (NSManagedObjectContext)->(), failure : ((CoreDataManagerError) -> ())?){
        
        if !isReady{
            failure?(.stackNotReady)
            return
        }
        
        guard let persistentContainer = self.persistentContainer else{
            failure?(.persistentContainerNotAvailable)
            return
        }
        
        persistentContainer.performBackgroundTask(task)
    }
    
}
