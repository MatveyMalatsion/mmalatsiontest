//
//  MainMapMainMapConfigurator.swift
//  Tinkoff Test
//
//  Created by madway94@yandex.ru on 06/10/2018.
//  Copyright © 2018 MMalatsion. All rights reserved.
//

import UIKit

class MainMapModuleConfigurator {
    let dataStorage: CompleateDepositionPointsStorageCacherProtocol

    init(dataStorage: CompleateDepositionPointsStorageCacherProtocol) {
        self.dataStorage = dataStorage
    }

    func configureModuleForViewInput<UIViewController>(viewInput: UIViewController) {
        if let viewController = viewInput as? MainMapViewController {
            configure(viewController: viewController)
        }
    }

    private func configure(viewController: MainMapViewController) {
        let router = MainMapRouter()

        let presenter = MainMapPresenter()
        presenter.view = viewController
        presenter.router = router

        let interactor = MainMapInteractor(dataStorage: dataStorage)
        interactor.output = presenter

        presenter.interactor = interactor
        viewController.output = presenter
    }
}
