//
//  InvoiceItem.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/16.
//

import Foundation
import SwiftData

@Model
final class InvoiceItem {
    var id: UUID
    var itemDescription: String
    var quantity: Decimal
    var unitPrice: Decimal
    var total: Decimal
    
    init(
        id: UUID = UUID(),
        itemDescription: String = "",
        quantity: Decimal = 1,
        unitPrice: Decimal = 0
    ) {
        self.id = id
        self.itemDescription = itemDescription
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.total = quantity * unitPrice
    }
    
    func updateTotal() {
        total = quantity * unitPrice
    }
}
