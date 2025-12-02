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

/// Wallet data model - only created when data is valid
/// If parsing fails, parsers return nil instead of creating invalid WalletData
public struct WalletData {
    /// Total equity value (in currency units, e.g., USDT)
    public let totalEquity: Double
    /// Wallet balance (in currency units, e.g., USDT)
    public let walletBalance: Double
    /// Absolute maintenance margin value (in currency units, e.g., USDT)
    /// Value of 0 means no maintenance margin or not applicable (e.g., spot accounts)
    public let maintenanceMargin: Double
    
    public init(totalEquity: Double, walletBalance: Double, maintenanceMargin: Double = 0) {
        self.totalEquity = totalEquity
        self.walletBalance = walletBalance
        self.maintenanceMargin = max(0, maintenanceMargin) // Ensure non-negative
    }
    
    /// Calculates the maintenance margin as a percentage of total equity
    /// Returns 0 if total equity is zero (avoids division by zero)
    /// Formula: (maintenanceMargin / totalEquity) × 100
    public var maintenanceMarginPercentage: Double {
        guard totalEquity > 0 else {
            return 0
        }
        return (maintenanceMargin / totalEquity) * 100.0
    }
    
    /// Returns the maintenance margin percentage formatted as a string with specified decimal places
    /// - Parameter decimalPlaces: Number of decimal places (default: 2)
    /// - Returns: Formatted percentage string (e.g., "5.00%")
    public func maintenanceMarginPercentageFormatted(decimalPlaces: Int = 2) -> String {
        return String(format: "%.\(decimalPlaces)f%%", maintenanceMarginPercentage)
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
