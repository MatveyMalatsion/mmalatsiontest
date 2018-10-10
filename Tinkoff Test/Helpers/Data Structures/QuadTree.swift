//
//  QuadTree.swift
//  Tinkoff Test
//
//  Created by Матвей Малацион on 08/10/2018.
//  Copyright © 2018 mmalatsion. All rights reserved.
//

import MapKit
import Foundation

struct QuadTreeNodeData<T>{
    var x : Double
    var y : Double
    var data : T
    
    init(x : Double, y : Double, data : T) {
        self.x = x
        self.y = y
        self.data = data
    }
}

struct BoundingBox {
    var x0, y0, xf, yf : Double
    
    init(x0 : Double, y0 : Double, xf : Double, yf : Double){
        self.x0 = x0
        self.y0 = y0
        self.xf = xf
        self.yf = yf
    }
    
    func intersects(box : BoundingBox) -> Bool{
        return (self.x0 <= box.xf && self.xf >= box.x0 && self.y0 <= box.yf && self.yf >= box.y0)
    }
    
    func boxContains<T>(data: QuadTreeNodeData<T>) -> Bool{
        let containsX = self.x0 <= data.x && data.x <= self.xf
        let containsY = self.y0 <= data.y && data.y <= self.yf
        return containsX && containsY
    }
}

// Structures can not contains recursive fields
class QuadTreeNode<T> {
    var nWest, nEast, sWest, sEast : QuadTreeNode<T>?
    var boundingBox : BoundingBox
    var capacity : Int
    var count : Int = 0
    var dataPoints : [QuadTreeNodeData<T>?]
    
    init(boundary : BoundingBox, capacity : Int) {
        self.boundingBox = boundary
        self.capacity = capacity
        self.dataPoints = Array<QuadTreeNodeData<T>?>(repeating: nil, count: self.capacity)
    }
    
    init(data : [QuadTreeNodeData<T>], box : BoundingBox, capacity : Int){
        self.boundingBox = box
        self.capacity = capacity
        self.count = 0
        self.dataPoints = Array<QuadTreeNodeData<T>?>(repeating: nil, count: self.capacity)
        for d in data{
            _ = self.insert(data: d)
        }
    }
    
    func subdivide(){
        let box = self.boundingBox
        
        let xMid = (box.xf + box.x0) / 2
        let yMid = (box.yf + box.y0) / 2
        
        let nWest = BoundingBox(x0: box.x0, y0: box.y0, xf: xMid, yf: yMid)
        self.nWest = QuadTreeNode(boundary: nWest, capacity: self.capacity)
        
        let nEast = BoundingBox(x0: xMid, y0: box.y0, xf: box.xf, yf: yMid)
        self.nEast = QuadTreeNode(boundary: nEast, capacity: self.capacity)
        
        let sWest = BoundingBox(x0: box.x0, y0: yMid, xf: xMid, yf: box.yf)
        self.sWest = QuadTreeNode(boundary: sWest, capacity: self.capacity)
        
        let sEast = BoundingBox(x0: xMid, y0: yMid, xf: box.xf, yf: box.yf)
        self.sEast = QuadTreeNode(boundary: sEast, capacity: self.capacity)
    }
    
    func insert(data : QuadTreeNodeData<T>) -> Bool{
        if !self.boundingBox.boxContains(data: data){
            return false
        }
        
        if count < capacity{
           dataPoints[self.count] = data
           self.count = self.count + 1
            return true
        }
        
        if self.nWest == nil{
            self.subdivide()
        }
        
        if nWest?.insert(data: data) ?? false{
            return true
        }
        
        if nEast?.insert(data: data) ?? false{
            return true
        }
        
        if sWest?.insert(data: data) ?? false{
            return true
        }
        
        if sEast?.insert(data: data) ?? false{
            return true
        }
        
        return false
    }
    
    func gatherData(in range: BoundingBox, resultBlock : @escaping (QuadTreeNodeData<T>) -> ()){
        if !range.intersects(box: self.boundingBox){
            return
        }
        
        for i in 0 ..< self.count{
            if i < self.dataPoints.count{
                if range.boxContains(data: dataPoints[i]!){
                    resultBlock(dataPoints[i]!)
                }
            }
        }
        
        if nWest == nil{
            return
        }
        
        nWest?.gatherData(in: range, resultBlock: resultBlock)
        sEast?.gatherData(in: range, resultBlock: resultBlock)
        nEast?.gatherData(in: range, resultBlock: resultBlock)
        sWest?.gatherData(in: range, resultBlock: resultBlock)
    }
    
    func traverse(block : (QuadTreeNode<T>) -> ()){
        block(self)
        
        if self.nWest == nil{
            return
        }
        
        nWest?.traverse(block: block)
        nEast?.traverse(block: block)
        sWest?.traverse(block: block)
        sEast?.traverse(block: block)
    }
}

class CoordinateTreeNode{
    
    let root : QuadTreeNode<DepositionPointProtocol>
    
    init(root : QuadTreeNode<DepositionPointProtocol>){
        self.root = root
    }
    
    func boundingBox(mapRect : MKMapRect) -> BoundingBox{
        
        let topLeft = mapRect.origin.coordinate
        let botRight = MKMapPoint(x: mapRect.maxX, y: mapRect.maxY).coordinate
        let minLat = botRight.latitude
        let maxLat = topLeft.latitude
        let minLon = topLeft.longitude
        let maxLon = botRight.longitude
        
        return BoundingBox(x0: minLat, y0: minLon, xf: maxLat, yf: maxLon)
    }
    
    func rectFor(box : BoundingBox) -> MKMapRect{
        let topLeft = MKMapPoint(CLLocationCoordinate2D(latitude: box.x0, longitude: box.y0))
        let botRight = MKMapPoint(CLLocationCoordinate2D(latitude: box.xf, longitude: box.yf))
        
        return MKMapRect(x: topLeft.x, y: botRight.y, width: fabs(botRight.x - topLeft.x), height: fabs(botRight.y - topLeft.y))
    }
    
    func zoomLevel(from zoomScale : MKZoomScale) -> Int{
        let totalTilesAtMaxZoom = MKMapSize.world.width / 256.0
        let zoomLevelAtMaxZoom = log2(totalTilesAtMaxZoom)
        let zoomLevel = Int(max(0, zoomLevelAtMaxZoom + Double(floor(log2f(Float(zoomScale)) + 0.5))))
        return zoomLevel
    }
    
    func cellSize(for zoomScale : MKZoomScale) -> Double{
        let zoomLevel = self.zoomLevel(from: zoomScale)
        
        switch (zoomLevel) {
        case 13:
            return 64
        case 14:
            return 64
        case 15:
            return 64
        case 16:
            return 32
        case 17:
            return 32
        case 18:
            return 32
        case 19:
            return 16
        default:
            return 88
        }
    }
    
    
    
    func clusteredAnnotations(with mapRect : MKMapRect, zoomScale : MKZoomScale) -> [MapPin]{
        let cellSize = self.cellSize(for: zoomScale)
        let scaleFactor = Double(zoomScale) / cellSize
        
        let minX = Int(floor(mapRect.minX * scaleFactor))
        let maxX = Int(floor(mapRect.maxX * scaleFactor))
        let minY = Int(floor(mapRect.minY * scaleFactor))
        let maxY = Int(floor(mapRect.maxY * scaleFactor))
        
        var annotations : [MapPin] = []
        
        for x in minX...maxX{
            for y in minY...maxY{
                let rect = MKMapRect(x: Double(x) / scaleFactor, y: Double(y) / scaleFactor, width: 1.0 / scaleFactor, height: 1 / scaleFactor)
                
                var totalX : Double = 0
                var totalY : Double = 0
                var count : Int = 0
                
                var locations : [DepositionPointProtocol] = []
                
                root.gatherData(in: self.boundingBox(mapRect: rect), resultBlock: { result in
                    totalX = totalX + result.x
                    totalY = totalY + result.y
                    count = count + 1
                    locations.append(result.data)
                })
                
                if count == 1{
                    let coordinate = CLLocationCoordinate2D(latitude: totalX, longitude: totalY)
                    let annotation = MapPin(depositionPoint: locations.last!)
                    annotation.coordinate = coordinate
                    annotation.count = count
                    annotations.append(annotation)
                } else if count > 1{
                    let coordinate = CLLocationCoordinate2D(latitude: totalX / Double(count), longitude: totalY / Double(count))
                    let annotation = MapPin(depositionPoint: locations.last!)
                    annotation.coordinate = coordinate
                    annotation.count = count
                    annotations.append(annotation)
                }
                
                
            }
        }
        
        return annotations
    }
    
}

