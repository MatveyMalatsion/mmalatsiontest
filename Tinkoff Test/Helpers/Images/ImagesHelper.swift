//
//  ImagesHelper.swift
//  Tinkoff Test
//
//  Created by Матвей Малацион on 10/10/2018.
//  Copyright © 2018 mmalatsion. All rights reserved.
//

import Foundation
import UIKit

enum ImageResolutionType : String {
    case mdpi
    case xhdpi
    case xxhdpi
}

class ImagesHelper{
    
    func getResolutionTypeForCurrentScreen() -> ImageResolutionType{
       let scale =  UIScreen.main.scale
        
        if scale >= 3{
            return .xxhdpi
        }else if scale >= 2{
            return .xxhdpi
        }else{
            return .mdpi
        }
    }
    
}
