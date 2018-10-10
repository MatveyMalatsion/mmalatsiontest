//
//  MainMapMainMapViewInput.swift
//  Tinkoff Test
//
//  Created by madway94@yandex.ru on 06/10/2018.
//  Copyright © 2018 MMalatsion. All rights reserved.
//
import UIKit

protocol MainMapViewInput: class {

    /**
        @author madway94@yandex.ru
        Setup initial state of the view
    */

    func setupInitialState()
    func showRegularAnnotations(for locations: [DepositionPointProtocol])
    func reloadPins()
    
}
