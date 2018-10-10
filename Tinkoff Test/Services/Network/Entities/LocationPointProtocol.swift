//
//  LocationPointProtocol.swift
//  Tinkoff Test
//
//  Created by Матвей Малацион on 07/10/2018.
//  Copyright © 2018 mmalatsion. All rights reserved.
//

import Foundation

protocol LocationPointProtocol: Codable {
    var latitude: Float? { set get }
    var longitude: Float? { set get }
}

struct LocationPoint: LocationPointProtocol {
    var latitude: Float?
    var longitude: Float?
}
