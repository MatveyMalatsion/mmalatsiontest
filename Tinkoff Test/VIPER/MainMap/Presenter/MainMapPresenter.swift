//
//  MainMapMainMapPresenter.swift
//  Tinkoff Test
//
//  Created by madway94@yandex.ru on 06/10/2018.
//  Copyright © 2018 MMalatsion. All rights reserved.
//
import UIKit

class MainMapPresenter: MainMapModuleInput, MainMapViewOutput, MainMapInteractorOutput {
    weak var view: MainMapViewInput!
    var interactor: MainMapInteractorInput!
    var router: MainMapRouterInput!

    func viewIsReady() {
        self.interactor.updatePartnerCache(compleation: { success in
            if success{
                self.view.reloadPins()
            }
        })
    }
    
    func fetchPartner(for point : DepositionPointProtocol, compleation : @escaping (PartnerProtocol?)->()){
        self.interactor.fetchPartner(for: point, compleation: compleation)
    }
    
    func interactorDidLoad(points: [DepositionPointProtocol]) {
        self.view.showRegularAnnotations(for: points)
    }
    
    func userDidChangeMapConfiguration(lat: Double, lon: Double, radius: Double) {
        self.interactor.loadPoints(lat: lat, lon: lon, radius: radius)
    }
    
    func getImage(for partner: PartnerProtocol, cached: @escaping (UIImage) -> (), compleation: @escaping (UIImage) -> ()){
        self.interactor.getImage(for: partner, cached: cached, compleation: compleation)
    }
}
