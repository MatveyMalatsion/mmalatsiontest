//
//  DepositionPoint.swift
//  Tinkoff Test
//
//  Created by Матвей Малацион on 07/10/2018.
//  Copyright © 2018 mmalatsion. All rights reserved.
//

import Foundation

protocol DepositionPointProtocol : LocatedProtocol, Codable{
    var partnerName : String? { set get }
    var workHours : String? { set get }
    var phones : String? { set get }
    var addressInfo : String? { set get }
    var fullAddress : String? { set get }
    var externalId : String? { set get}
    var hashValue : Int { get }
}

struct DepositionPointEntity : DepositionPointProtocol{
    
    var hashValue : Int {
        get{
            return externalId.hashValue
        }
    }
    
    var partnerName : String?
    var workHours : String?
    var phones : String?
    var addressInfo : String?
    var fullAddress : String?
    var location : LocationPointProtocol?
    var externalId: String?
    
    enum CodingKeys : String, CodingKey{
        case partnerName
        case workHours
        case phones
        case addressInfo
        case fullAddress
        case location
        case externalId
    }
    
    init(){}
    
    init(from decoder: Decoder) throws{
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        partnerName     = try? values.decode(String.self, forKey: .partnerName)
        workHours       = try? values.decode(String.self, forKey: .workHours)
        phones          = try? values.decode(String.self, forKey: .phones)
        addressInfo     = try? values.decode(String.self, forKey: .addressInfo)
        fullAddress     = try? values.decode(String.self, forKey: .fullAddress)
        location        = try? values.decode(LocationPoint.self, forKey: .location)
        externalId      = try? values.decode(String.self, forKey: .externalId)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try? container.encode(partnerName, forKey: .partnerName)
        try? container.encode(workHours, forKey: .workHours)
        try? container.encode(phones, forKey: .phones)
        try? container.encode(addressInfo, forKey: .addressInfo)
        try? container.encode(fullAddress, forKey: .fullAddress)
        try? container.encode(location as? LocationPoint, forKey: .location)
        try? container.encode(externalId, forKey: .externalId)
    }
    
    
    
    init(object : DepositionPointProtocol){
        self.partnerName     = object.partnerName
        self.workHours       = object.workHours
        self.phones          = object.phones
        self.addressInfo     = object.addressInfo
        self.fullAddress     = object.fullAddress
        self.location        = object.location
        self.externalId      = object.externalId
    }
}
