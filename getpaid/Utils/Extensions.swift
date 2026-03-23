//
//  Extensions.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/16.
//

import Foundation

extension Decimal {
    var doubleValue: Double {
        return NSDecimalNumber(decimal: self).doubleValue
    }
    
    init?(string: String) {
        let formatter = NumberFormatter()
        formatter.generatesDecimalNumbers = true
        if let decimal = formatter.number(from: string) as? NSDecimalNumber {
            self = decimal as Decimal
        } else {
            return nil
        }
    }
}
