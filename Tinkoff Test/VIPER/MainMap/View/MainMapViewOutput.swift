//
//  MainMapMainMapViewOutput.swift
//  Tinkoff Test
//
//  Created by madway94@yandex.ru on 06/10/2018.
//  Copyright © 2018 MMalatsion. All rights reserved.
//
import UIKit

protocol MainMapViewOutput {

    /**
        @author madway94@yandex.ru
        Notify presenter that view is ready
    */

    func viewIsReady()
    func userDidChangeMapConfiguration(lat : Double, lon : Double, radius : Double)
    func fetchPartner(for point : DepositionPointProtocol, compleation : @escaping (PartnerProtocol?)->())
    func getImage(for partner: PartnerProtocol, cached: @escaping (UIImage) -> (), compleation: @escaping (UIImage) -> ())
}