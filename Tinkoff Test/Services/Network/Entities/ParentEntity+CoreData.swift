//
//  ParentEntity+CoreData.swift
//  Tinkoff Test
//
//  Created by Матвей Малацион on 08/10/2018.
//  Copyright © 2018 mmalatsion. All rights reserved.
//

import Foundation
import CoreData



extension PartnerEntity : CoreDataConvertable{
    func fillCoreData(object : CDParentEntity) -> CDParentEntity {
        object.depositionDuration = self.depositionDuration
        object.descriptionString = self.description
        object.hasLocation = self.hasLocations ?? false
        object.id = self.id
        object.isMomentary = self.isMomentary ?? false
        object.limitations = self.limitations
        object.name = self.name
        object.picture = self.picture
        return object
    }
    
    static func objectFromCoreData(object: CDParentEntity) -> PartnerEntity {
        var entity = PartnerEntity()
        entity.depositionDuration = object.depositionDuration
        entity.description = object.descriptionString
        entity.hasLocations = object.hasLocation
        entity.id = object.id
        entity.isMomentary = object.isMomentary
        entity.limitations = object.limitations
        entity.name = object.name
        entity.picture = object.picture
        return entity
    }
    
    typealias T = CDParentEntity
    
    
}
