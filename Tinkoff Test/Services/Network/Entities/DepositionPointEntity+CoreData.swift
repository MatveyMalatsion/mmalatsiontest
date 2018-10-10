//
//  DepositionPointEntity+CoreData.swift
//  Tinkoff Test
//
//  Created by Матвей Малацион on 08/10/2018.
//  Copyright © 2018 mmalatsion. All rights reserved.
//

import Foundation

extension DepositionPointEntity : CoreDataConvertable{
    
    typealias T = CDDepositionPointEntity
    
    static func objectFromCoreData(object: CDDepositionPointEntity) -> DepositionPointEntity {
        var entity = DepositionPointEntity()
        entity.partnerName = object.partnerName
        entity.addressInfo = object.addressInfo
        entity.fullAddress = object.fullAddress
        entity.location = LocationPoint()
        entity.location?.latitude = Float(object.lat)
        entity.location?.longitude = Float(object.lon)
        entity.phones = object.phones
        entity.workHours = object.workHours
        entity.externalId = object.externalId
        return entity
    }
    
    func fillCoreData(object: CDDepositionPointEntity) -> CDDepositionPointEntity {
        object.partnerName = self.partnerName
        object.addressInfo = self.addressInfo
        object.fullAddress = self.fullAddress
        object.lat = Double(self.location?.latitude ?? 0)
        object.lon = Double(self.location?.longitude ?? 0)
        object.phones = self.phones
        object.externalId = self.externalId
        object.workHours = self.workHours
        return object
    }
    
}
