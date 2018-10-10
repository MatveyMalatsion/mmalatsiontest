//
//  PartnerEntity.swift
//  Tinkoff Test
//
//  Created by Матвей Малацион on 07/10/2018.
//  Copyright © 2018 mmalatsion. All rights reserved.
//

import Foundation

protocol PartnerProtocol: Codable {
    var id: String? { set get }
    var name: String? { set get }
    var picture: String? { set get }
    var url: String? { set get }
    var hasLocations: Bool? { set get }
    var isMomentary: Bool? { set get }
    var depositionDuration: String? { set get }
    var limitations: String? { set get }
    var pointType: String? { set get }
    var description: String? { set get }
}

struct PartnerEntity: PartnerProtocol {
    var id: String?
    var name: String?
    var picture: String?
    var url: String?
    var hasLocations: Bool?
    var isMomentary: Bool?
    var depositionDuration: String?
    var limitations: String?
    var pointType: String?
    var description: String?

    init() {}

    init(object: PartnerProtocol) {
        id = object.id
        name = object.name
        picture = object.picture
        url = object.url
        hasLocations = object.hasLocations
        isMomentary = object.isMomentary
        depositionDuration = object.depositionDuration
        limitations = object.limitations
        pointType = object.pointType
        description = object.description
    }
}
