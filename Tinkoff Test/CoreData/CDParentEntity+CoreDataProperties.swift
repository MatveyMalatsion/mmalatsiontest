//
//  CDParentEntity+CoreDataProperties.swift
//  Tinkoff Test
//
//  Created by Матвей Малацион on 09/10/2018.
//  Copyright © 2018 mmalatsion. All rights reserved.
//
//

import CoreData
import Foundation

extension CDParentEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDParentEntity> {
        return NSFetchRequest<CDParentEntity>(entityName: "CDParentEntity")
    }

    @NSManaged public var depositionDuration: String?
    @NSManaged public var descriptionString: String?
    @NSManaged public var hasLocation: Bool
    @NSManaged public var id: String?
    @NSManaged public var isMomentary: Bool
    @NSManaged public var limitations: String?
    @NSManaged public var name: String?
    @NSManaged public var picture: String?
    @NSManaged public var pointType: String?
    @NSManaged public var url: String?
    @NSManaged public var points: NSSet?
}

// MARK: Generated accessors for points

extension CDParentEntity {
    @objc(addPointsObject:)
    @NSManaged public func addToPoints(_ value: CDDepositionPointEntity)

    @objc(removePointsObject:)
    @NSManaged public func removeFromPoints(_ value: CDDepositionPointEntity)

    @objc(addPoints:)
    @NSManaged public func addToPoints(_ values: NSSet)

    @objc(removePoints:)
    @NSManaged public func removeFromPoints(_ values: NSSet)
}
