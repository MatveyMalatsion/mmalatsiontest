//
//  ParentEntity+CoreData.swift
//  Tinkoff Test
//
//  Created by Матвей Малацион on 08/10/2018.
//  Copyright © 2018 mmalatsion. All rights reserved.
//

import CoreData
import Foundation

extension PartnerEntity: CoreDataConvertable {
    func fillCoreData(object: CDParentEntity) -> CDParentEntity {
        object.depositionDuration = depositionDuration
        object.descriptionString = description
        object.hasLocation = hasLocations ?? false
        object.id = id
        object.isMomentary = isMomentary ?? false
        object.limitations = limitations
        object.name = name
        object.picture = picture
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
