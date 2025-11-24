//
//  BBWalletData.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 13/07/2025.
//


import Foundation
import Combine
import Network
import SwiftUI

// MARK: Public data models
public struct BBWalletData {
    public let totalEquity: String
    public let walletBalance: String
    
    public init(totalEquity: String, walletBalance: String) {
        self.totalEquity = totalEquity
        self.walletBalance = walletBalance
    }
}

// MARK: - KuCoin Specific Data Models
struct KuCoinAccount {
    public let id: String
    public let currency: String
    public let type: String // "main", "trade", "margin", "futures", etc.
    public let balance: String
    public let available: String
    public let holds: String
    
    public init(id: String, currency: String, type: String, balance: String, available: String, holds: String) {
        self.id = id
        self.currency = currency
        self.type = type
        self.balance = balance
        self.available = available
        self.holds = holds
    }
}

struct KuCoinAggregatedBalance {
    public let currency: String
    public let totalBalance: Double
    public let totalAvailable: Double
    public let accounts: [KuCoinAccount]
    
    public init(currency: String, totalBalance: Double, totalAvailable: Double, accounts: [KuCoinAccount]) {
        self.currency = currency
        self.totalBalance = totalBalance
        self.totalAvailable = totalAvailable
        self.accounts = accounts
    }
}

// MARK: - Enhanced Wallet Data for Multi-Account Support
//public struct BBWalletDataEnhanced {
//    public let totalEquity: String
//    public let walletBalance: String
//    public let breakdown: [String: String] // Account type -> balance
//    public let allAssets: [String: String] // Currency -> total balance
//    
//    public init(totalEquity: String, walletBalance: String, breakdown: [String: String], allAssets: [String: String]) {
//        self.totalEquity = totalEquity
//        self.walletBalance = walletBalance
//        self.breakdown = breakdown
//        self.allAssets = allAssets
//    }
//}

public struct Credentials: Equatable, Sendable {
    public let apiKey: String
    public let apiSecret: String
    public let passphrase: String?
    
    public init(apiKey: String, apiSecret: String, passphrase: String? = nil) {
        self.apiKey = apiKey
        self.apiSecret = apiSecret
        self.passphrase = passphrase
    }
}
