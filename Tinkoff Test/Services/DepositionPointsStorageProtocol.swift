//
//  DepositionPointsStorageProtocol.swift
//  Tinkoff Test
//
//  Created by Матвей Малацион on 08/10/2018.
//  Copyright © 2018 mmalatsion. All rights reserved.
//

import Foundation

protocol DepositionPointsStorageProtocol {
    func getDepositionPoints(location: LocationPointProtocol, radius: Float, partners: [PartnerProtocol]?, success: @escaping ([DepositionPointProtocol]) -> Void, failure: @escaping (Error?) -> Void)
    func getPartners(type: PartnerType, success: @escaping ([PartnerProtocol]) -> Void, failure: @escaping (Error?) -> Void)
}
