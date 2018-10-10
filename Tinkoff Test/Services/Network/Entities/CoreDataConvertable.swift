//
//  CoreDataConvertable.swift
//  Tinkoff Test
//
//  Created by Матвей Малацион on 08/10/2018.
//  Copyright © 2018 mmalatsion. All rights reserved.
//

import CoreData
import Foundation

protocol CoreDataConvertable {
    associatedtype T: NSManagedObject

    static func objectFromCoreData(object: T) -> Self
    func fillCoreData(object: T) -> T
}
