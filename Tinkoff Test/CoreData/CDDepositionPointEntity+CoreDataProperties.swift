//
//  CDDepositionPointEntity+CoreDataProperties.swift
//  Tinkoff Test
//
//  Created by Матвей Малацион on 09/10/2018.
//  Copyright © 2018 mmalatsion. All rights reserved.
//
//

import CoreData
import Foundation

extension CDDepositionPointEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDDepositionPointEntity> {
        return NSFetchRequest<CDDepositionPointEntity>(entityName: "CDDepositionPointEntity")
    }

    @NSManaged public var addressInfo: String?
    @NSManaged public var externalId: String?
    @NSManaged public var fullAddress: String?
    @NSManaged public var lat: Double
    @NSManaged public var lon: Double
    @NSManaged public var partnerName: String?
    @NSManaged public var phones: String?
    @NSManaged public var workHours: String?
    @NSManaged public var parent: CDParentEntity?
}
