//
//  MainMapMainMapInteractorOutput.swift
//  Tinkoff Test
//
//  Created by madway94@yandex.ru on 06/10/2018.
//  Copyright © 2018 MMalatsion. All rights reserved.
//

import Foundation

protocol MainMapInteractorOutput: class {
     func interactorDidLoad(points : [DepositionPointProtocol])
}
