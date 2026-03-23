//
//  Constants.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/16.
//

import Foundation

enum AppConstants {
    static let appName = "GetPaid"
    static let appVersion = "1.0.0"
    static let buildNumber = "1"
    
    enum Email {
        static let defaultSender = "noreply@getpaid.app"
        static let sendGridEndpoint = "https://api.sendgrid.com/v3/mail/send"
    }
    
    enum Subscription {
        static let proMonthlyID = "getpaid_pro_monthly"
        static let proYearlyID = "getpaid_pro_yearly"
        static let businessMonthlyID = "getpaid_business_monthly"
        static let businessYearlyID = "getpaid_business_yearly"
    }
    
    enum Escalation {
        static let friendlyReminderDays = 1
        static let formalFollowupDays = 7
        static let finalNoticeDays = 14
        static let legalActionDays = 30
    }
    
    enum PaymentTerms {
        static let net15 = 15
        static let net30 = 30
        static let net45 = 45
        static let net60 = 60
    }
}
