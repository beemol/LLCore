//
//  Parsers.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 20/11/2025.
//

import Foundation
import CommonCrypto

import LLApiService

// MARK: - WalletDataParser Protocol
protocol WalletDataParserProtocol: LLResponseParserProtocol where Output == BBWalletData {
    func parseWalletBalance(from data: Data) -> BBWalletData?
}

extension WalletDataParserProtocol {
    func parse(data: Data) throws -> BBWalletData {
        guard let result = parseWalletBalance(from: data) else {
            throw APIError.parseError
        }
        return result
    }
}

// MARK: - Enhanced Parser Protocol for Detailed Information
protocol EnhancedWalletDataParserProtocol: WalletDataParserProtocol {
    func parseDetailedWalletBalance(from data: Data) -> BBWalletDataEnhanced?
}

// MARK: - Bybit Parsers

// Shared helpers to avoid duplication between spot and unified parsers
private func bybitParseUSDTFromCoins(_ result: [String: Any]) -> BBWalletData? {
    if let list = result["list"] as? [[String: Any]],
       let first = list.first,
       let coins = first["coin"] as? [[String: Any]],
       let usdtCoin = coins.first(where: { $0["coin"] as? String == "USDT" }) {
        let walletBalanceValue = (usdtCoin["walletBalance"] as? String)
            ?? (usdtCoin["availableToWithdraw"] as? String)
            ?? "0"
        let totalEquityValue = (usdtCoin["equity"] as? String) ?? walletBalanceValue
        return BBWalletData(totalEquity: totalEquityValue, walletBalance: walletBalanceValue)
    }
    return nil
}

private func bybitParseTotals(_ result: [String: Any]) -> BBWalletData? {
    if let totalEquity = result["totalEquity"] as? String,
       let totalWalletBalance = result["totalWalletBalance"] as? String {
        return BBWalletData(totalEquity: totalEquity, walletBalance: totalWalletBalance)
    }
    return nil
}

struct BybitSpotWalletDataParser: WalletDataParserProtocol {
    func parseWalletBalance(from data: Data) -> BBWalletData? {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let result = json["result"] as? [String: Any] else {
                return nil
            }
            // SPOT prefers coin-level parsing, fallback to totals
            return bybitParseUSDTFromCoins(result) ?? bybitParseTotals(result)
        } catch {
            print("Bybit JSON Parse Error: \(error.localizedDescription)")
            return nil
        }
    }
}

struct BybitUnifiedWalletDataParser: WalletDataParserProtocol {
    func parseWalletBalance(from data: Data) -> BBWalletData? {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let result = json["result"] as? [String: Any] else {
                return nil
            }
            // UNIFIED prefers totals, fallback to coin-level if present
            return bybitParseTotals(result) ?? bybitParseUSDTFromCoins(result)
        } catch {
            print("Bybit JSON Parse Error: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - KuCoin Parser
struct KuCoinWalletDataParser: WalletDataParserProtocol, EnhancedWalletDataParserProtocol {
    let walletType: WalletType
    
    init(walletType: WalletType = .spot) {
        self.walletType = walletType
    }
    
    func parseWalletBalance(from data: Data) -> BBWalletData? {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                print("KuCoin JSON Parse Error: Invalid data structure")
                return nil
            }
            
            switch walletType {
            case .spot:
                return parseSpotWalletBalance(from: json)
            case .futures:
                return parseFuturesWalletBalance(from: json)
            case .unified:
                return parseFuturesWalletBalance(from: json) // Kucoin does not have unified wallet
            }
            
        } catch {
            print("KuCoin JSON Parse Error: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Spot Wallet Parsing
    
    private func parseSpotWalletBalance(from json: [String: Any]) -> BBWalletData? {
        guard let dataArray = json["data"] as? [[String: Any]] else {
            print("KuCoin Spot: Invalid data structure")
            return nil
        }
        
        // Parse all accounts
        let accounts = parseKuCoinAccounts(from: dataArray)
        
        // Aggregate balances by currency
        let aggregatedBalances = aggregateBalances(accounts: accounts)
        
        // Find USDT balance (primary focus)
        let usdtBalance = aggregatedBalances.first { $0.currency == "USDT" }
        
        // Calculate total portfolio value in USDT
        let totalPortfolioValue = calculateTotalPortfolioValue(aggregatedBalances: aggregatedBalances)
        
        // Use USDT available balance as wallet balance, total portfolio as equity
        let walletBalance = usdtBalance?.totalAvailable.description ?? "0.00"
        let totalEquity = totalPortfolioValue.description
        
        return BBWalletData(totalEquity: totalEquity, walletBalance: walletBalance)
    }
    
    // MARK: - Futures Wallet Parsing
    
    private func parseFuturesWalletBalance(from json: [String: Any]) -> BBWalletData? {
        // Parse the actual futures response structure
        if let data = json["data"] as? [String: Any],
           let accountEquity = data["accountEquity"] as? Double,
           let availableBalance = data["availableBalance"] as? Double,
           let currency = data["currency"] as? String {
            
            // Convert to strings for consistency
            let totalEquity = String(format: "%.8f", accountEquity)
            let walletBalance = String(format: "%.8f", availableBalance)
            
            print("KuCoin  Currency: \(currency)")
            print("KuCoin  Account Equity: \(totalEquity)")
            print("KuCoin  Available Balance: \(walletBalance)")
            
            return BBWalletData(totalEquity: totalEquity, walletBalance: walletBalance)
        }
        
        // Fallback: try to parse as spot format if futures uses similar structure
        print("KuCoin Futures: Trying fallback parsing")
        return parseSpotWalletBalance(from: json)
    }
    
    func parseDetailedWalletBalance(from data: Data) -> BBWalletDataEnhanced? {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let dataArray = json["data"] as? [[String: Any]] else {
                print("KuCoin JSON Parse Error: Invalid data structure")
                return nil
            }
            
            // Parse all accounts
            let accounts = parseKuCoinAccounts(from: dataArray)
            
            // Aggregate balances by currency
            let aggregatedBalances = aggregateBalances(accounts: accounts)
            
            // Calculate total portfolio value
            let totalPortfolioValue = calculateTotalPortfolioValue(aggregatedBalances: aggregatedBalances)
            
            // Create breakdown by account type
            var breakdown: [String: String] = [:]
            var allAssets: [String: String] = [:]
            
            // Group by account type
            var accountTypeMap: [String: [KuCoinAccount]] = [:]
            for account in accounts {
                if accountTypeMap[account.type] == nil {
                    accountTypeMap[account.type] = []
                }
                accountTypeMap[account.type]?.append(account)
            }
            
            // Calculate totals by account type
            for (accountType, typeAccounts) in accountTypeMap {
                let totalBalance = typeAccounts.compactMap { Double($0.balance) }.reduce(0, +)
                breakdown[accountType] = String(format: "%.2f", totalBalance)
            }
            
            // Create asset summary
            for balance in aggregatedBalances {
                allAssets[balance.currency] = String(format: "%.2f", balance.totalBalance)
            }
            
            // Find USDT balance for wallet balance
            let usdtBalance = aggregatedBalances.first { $0.currency == "USDT" }
            let walletBalance = usdtBalance?.totalAvailable.description ?? "0.00"
            
            return BBWalletDataEnhanced(
                totalEquity: String(format: "%.2f", totalPortfolioValue),
                walletBalance: walletBalance,
                breakdown: breakdown,
                allAssets: allAssets
            )
            
        } catch {
            print("KuCoin JSON Parse Error: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Helper Methods
    
    private func parseKuCoinAccounts(from dataArray: [[String: Any]]) -> [KuCoinAccount] {
        var accounts: [KuCoinAccount] = []
        
        for accountData in dataArray {
            guard let id = accountData["id"] as? String,
                  let currency = accountData["currency"] as? String,
                  let type = accountData["type"] as? String,
                  let balance = accountData["balance"] as? String,
                  let available = accountData["available"] as? String,
                  let holds = accountData["holds"] as? String else {
                continue
            }
            
            let account = KuCoinAccount(
                id: id,
                currency: currency,
                type: type,
                balance: balance,
                available: available,
                holds: holds
            )
            accounts.append(account)
        }
        
        return accounts
    }
    
    private func aggregateBalances(accounts: [KuCoinAccount]) -> [KuCoinAggregatedBalance] {
        var balanceMap: [String: [KuCoinAccount]] = [:]
        
        // Group accounts by currency
        for account in accounts {
            if balanceMap[account.currency] == nil {
                balanceMap[account.currency] = []
            }
            balanceMap[account.currency]?.append(account)
        }
        
        // Calculate totals for each currency
        var aggregatedBalances: [KuCoinAggregatedBalance] = []
        
        for (currency, currencyAccounts) in balanceMap {
            let totalBalance = currencyAccounts.compactMap { Double($0.balance) }.reduce(0, +)
            let totalAvailable = currencyAccounts.compactMap { Double($0.available) }.reduce(0, +)
            
            let aggregatedBalance = KuCoinAggregatedBalance(
                currency: currency,
                totalBalance: totalBalance,
                totalAvailable: totalAvailable,
                accounts: currencyAccounts
            )
            aggregatedBalances.append(aggregatedBalance)
        }
        
        return aggregatedBalances
    }
    
    private func calculateTotalPortfolioValue(aggregatedBalances: [KuCoinAggregatedBalance]) -> Double {
        // For now, we'll focus on major currencies and estimate USDT value
        // In a production app, you'd want to fetch current exchange rates
        
        var totalValue: Double = 0
        
        for balance in aggregatedBalances {
            switch balance.currency {
            case "USDT", "USDC", "TUSD", "BUSD":
                // Stablecoins - 1:1 with USD
                totalValue += balance.totalBalance
            case "BTC", "ETH":
                // Major cryptocurrencies - rough estimate (you'd want real-time rates)
                // For now, we'll use a conservative estimate
                let estimatedRate: Double = balance.currency == "BTC" ? 40000 : 2000
                totalValue += balance.totalBalance * estimatedRate
            default:
                // Other currencies - could be worth significant amounts
                // For now, we'll include them but with a note
                print("KuCoin: Including \(balance.currency) balance: \(balance.totalBalance) (consider fetching real-time rates)")
                totalValue += balance.totalBalance * 0.1 // Conservative estimate
            }
        }
        
        return totalValue
    }
}

// MARK: - Binance Parser
struct BinanceWalletDataParser: WalletDataParserProtocol {
    func parseWalletBalance(from data: Data) -> BBWalletData? {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                return nil
            }

            // Prefer USDT-M Futures account response fields (GET /fapi/v2/account)
            // totalMarginBalance = equity (wallet balance + unrealized PnL)
            // totalWalletBalance = wallet balance (excludes unrealized PnL)
            if let totalMarginBalance = valueAsString(json["totalMarginBalance"]),
               let totalWalletBalance = valueAsString(json["totalWalletBalance"]) {
                return BBWalletData(totalEquity: totalMarginBalance, walletBalance: totalWalletBalance)
            }

            // Fallback: spot account structure (GET /api/v3/account)
//            if let balances = json["balances"] as? [[String: Any]] {
//                if let usdt = balances.first(where: { $0["asset"] as? String == "USDT" }),
//                   let freeStr = valueAsString(usdt["free"]),
//                   let lockedStr = valueAsString(usdt["locked"]) {
//                    if let freeVal = Double(freeStr), let lockedVal = Double(lockedStr) {
//                        let totalEquity = String(format: "%.2f", freeVal + lockedVal)
//                        return BBWalletData(totalEquity: totalEquity, walletBalance: freeStr, marginWalletBalance: freeStr)
//                    } else {
//                        return BBWalletData(totalEquity: freeStr, walletBalance: freeStr, marginWalletBalance: freeStr)
//                    }
//                }
//            }

            return nil
        } catch {
            print("Binance JSON Parse Error: \(error.localizedDescription)")
            return nil
        }
    }

    private func valueAsString(_ value: Any?) -> String? {
        if let str = value as? String { return str }
        if let num = value as? NSNumber { return String(format: "%.8f", num.doubleValue) }
        if let dbl = value as? Double { return String(format: "%.8f", dbl) }
        if let intVal = value as? Int { return String(intVal) }
        return nil
    }
}

struct WalletDataParserFactory {
    static func parser(for exchange: ExchangeType) -> any WalletDataParserProtocol {
        switch exchange {
        case .bybit(let walletType):
            switch walletType {
            case .spot:
                return BybitSpotWalletDataParser()
            case .unified:
                return BybitUnifiedWalletDataParser()
            case .futures:
                return BybitUnifiedWalletDataParser()
            }
        case .kucoin(let walletType):
            return KuCoinWalletDataParser(walletType: walletType)
        case .binance:
            return BinanceWalletDataParser()
        }
    }
}

extension String {
    func hmacSHA256(key: String) -> String {
        guard let keyData = key.data(using: .utf8),
              let messageData = self.data(using: .utf8) else {
            return ""
        }

        let keyBytes = keyData.withUnsafeBytes { $0.baseAddress!.assumingMemoryBound(to: UInt8.self) }
        let messageBytes = messageData.withUnsafeBytes { $0.baseAddress!.assumingMemoryBound(to: UInt8.self) }

        var hmac = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), keyBytes, keyData.count, messageBytes, messageData.count, &hmac)

        let hmacData = Data(hmac)
        return hmacData.map { String(format: "%02hhx", $0) }.joined()
    }
}
