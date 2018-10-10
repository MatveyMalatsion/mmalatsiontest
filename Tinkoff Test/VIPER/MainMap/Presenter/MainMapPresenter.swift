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
        interactor.updatePartnerCache(completion: { success in
            if success {
                self.view.reloadPins()
            }
        })
    }

    func fetchPartner(for point: DepositionPointProtocol, completion: @escaping (PartnerProtocol?) -> Void) {
        interactor.fetchPartner(for: point, completion: completion)
    }

    func interactorDidLoad(points: [DepositionPointProtocol]) {
        view.showRegularAnnotations(for: points)
    }

    func userDidChangeMapConfiguration(lat: Double, lon: Double, radius: Double) {
        interactor.loadPoints(lat: lat, lon: lon, radius: radius)
    }

    func getImage(for partner: PartnerProtocol, cached: @escaping (UIImage) -> Void, completion: @escaping (UIImage) -> Void) {
        interactor.getImage(for: partner, cached: cached, completion: completion)
    }
}
