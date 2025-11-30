//
//  BBWalletData.swift
//  LLCore
//
//  Created by Aleh Fiodarau on 13/07/2025.
//


import Foundation
import Combine
import Network
import SwiftUI

// MARK: Public data models
public struct WalletData {
    /// Constant representing unavailable or not applicable value for any wallet data field
    public static let valueNotAvailable = "n/a"
    
    public let totalEquity: String
    public let walletBalance: String
    /// Absolute maintenance margin value (in currency units, e.g., USDT)
    public let maintenanceMargin: String
    
    public init(totalEquity: String, walletBalance: String, maintenanceMargin: String = WalletData.valueNotAvailable) {
        self.totalEquity = totalEquity
        self.walletBalance = walletBalance
        self.maintenanceMargin = maintenanceMargin
    }
    
    /// Calculates the maintenance margin as a percentage of total equity
    /// Returns nil if values are not available or cannot be parsed
    /// Formula: (maintenanceMargin / totalEquity) × 100
    public var maintenanceMarginPercentage: Double? {
        guard maintenanceMargin != WalletData.valueNotAvailable,
              totalEquity != WalletData.valueNotAvailable,
              let mmValue = Double(maintenanceMargin),
              let equityValue = Double(totalEquity),
              equityValue > 0 else {
            return nil
        }
        
        return (mmValue / equityValue) * 100.0
    }
    
    /// Returns the maintenance margin percentage formatted as a string with specified decimal places
    /// - Parameter decimalPlaces: Number of decimal places (default: 2)
    /// - Returns: Formatted percentage string (e.g., "5.00%") or "n/a" if unavailable
    public func maintenanceMarginPercentageFormatted(decimalPlaces: Int = 2) -> String {
        guard let percentage = maintenanceMarginPercentage else {
            return WalletData.valueNotAvailable
        }
        return String(format: "%.\(decimalPlaces)f%%", percentage)
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
