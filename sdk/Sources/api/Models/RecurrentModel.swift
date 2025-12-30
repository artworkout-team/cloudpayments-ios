//
//  RecurrentModel.swift
//  Cloudpayments
//
//  Created by Cloudpayments on 10.07.2023.
//

import Foundation

public struct Recurrent {
    public let amount: Double?
    public let interval: String
    public let period: Int
    public let startDate: String?
    public let maxPeriods: Int?
    public let customerReceipt: [String: Any]?
    
    public init(interval: String, period: Int, customerReceipt: [String: Any]? = nil, amount: Double? = nil, startDate: String? = nil, maxPeriods: Int? = nil) {
        self.interval = interval
        self.period = period
        self.customerReceipt = customerReceipt
        self.amount = amount
        self.startDate = startDate
        self.maxPeriods = maxPeriods
    }
}

extension Recurrent {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "interval": interval,
            "period": period
        ]
        
        if let customerReceipt = customerReceipt {
            dict["customerReceipt"] = customerReceipt
        }
        if let amount = amount {
            dict["amount"] = amount
        }
        if let startDate = startDate {
            dict["startDate"] = startDate
        }
        if let maxPeriods = maxPeriods {
            dict["maxPeriods"] = maxPeriods
        }
        
        return dict
    }
}
