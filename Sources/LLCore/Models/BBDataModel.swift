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

struct BBWalletData {
    let totalEquity: String
    let walletBalance: String
}

// MARK: - KuCoin Specific Data Models
struct KuCoinAccount {
    let id: String
    let currency: String
    let type: String // "main", "trade", "margin", "futures", etc.
    let balance: String
    let available: String
    let holds: String
}

struct KuCoinAggregatedBalance {
    let currency: String
    let totalBalance: Double
    let totalAvailable: Double
    let accounts: [KuCoinAccount]
}

// MARK: - Enhanced Wallet Data for Multi-Account Support
struct BBWalletDataEnhanced {
    let totalEquity: String
    let walletBalance: String
    let breakdown: [String: String] // Account type -> balance
    let allAssets: [String: String] // Currency -> total balance
}

struct Credentials: Equatable {
    let apiKey: String
    let apiSecret: String
    let passphrase: String?
}
