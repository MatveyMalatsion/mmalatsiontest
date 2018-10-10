//
//  MapPin.swift
//  Tinkoff Test
//
//  Created by Матвей Малацион on 10/10/2018.
//  Copyright © 2018 mmalatsion. All rights reserved.
//

import Foundation
import MapKit

struct PointHashableWrapper : Hashable {
    
    var point : DepositionPointProtocol
    var annotation : MapPin?
    
    init(point : DepositionPointProtocol, annotation: MapPin?){
        self.point = point
        self.annotation = annotation
    }
    
    init(point : DepositionPointProtocol){
        self.point = point
    }
    
    static func == (lhs: PointHashableWrapper, rhs: PointHashableWrapper) -> Bool {
        return lhs.point.hashValue == rhs.point.hashValue
    }
    
    var hashValue : Int{
        get{
            return point.hashValue
        }
    }
}

class MapPin : NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var depositionPoint : DepositionPointProtocol
    var count = 0
    var needToAnimateOnAppearance = false
    
    override var hash: Int{
        get{
            return depositionPoint.hashValue
        }
    }
    
    init(depositionPoint: DepositionPointProtocol) {
        self.coordinate = CLLocationCoordinate2D(latitude: Double(depositionPoint.location?.latitude ?? 0) , longitude: Double(depositionPoint.location?.longitude ?? 0))
        self.depositionPoint = depositionPoint
        
    }
}
