//
//  ExchangeType.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 30/09/2025.
//

public enum ExchangeName: String, CaseIterable, Hashable {
    case bybit
    case kucoin
    case binance
    // Add new exchanges here
}

// keep this for mapping ExchangeType to ExchangeName and to make sure we have a single source of truth
public extension ExchangeType {
    var exchangeName: ExchangeName {
        switch self {
        case .bybit: return .bybit
        case .kucoin: return .kucoin
        case .binance: return .binance
        }
    }
}

public enum WalletType: String, CaseIterable, Hashable {
    case spot, futures, unified
}

public enum ExchangeType: Hashable, CaseIterable {
    public static var allCases: [ExchangeType] {
        return [
            .bybit(walletType: .spot),
            .kucoin(walletType: .spot),
            .binance(walletType: .spot)
        ]
    }
    
    case bybit (walletType: WalletType)
    case kucoin (walletType: WalletType)
    case binance (walletType: WalletType) //, coinbase, kraken
    
    public var walletType: WalletType {
        switch self {
        case .bybit(let w), .kucoin(let w), .binance(let w): return w
        }
    }
    
    public var availableWalletTypes: [WalletType] {
        switch self {
        case .bybit:
            return [.unified]
        case .kucoin:
            return [.futures]
        case .binance:
            return [.futures]
        }
    }
    
    public var displayName: String {
        switch self {
        case .bybit:
            return "bybit"
        case .kucoin:
            return "kucoin"
        case .binance:
            return "binance"
        }
    }
    
    public var baseURL: String {
        switch self {
        case .bybit (let walletType):
            switch walletType {
            case .spot:
                return "https://api.bybit.com"
            case .futures:
                return "xxx" 
            case .unified:
                return "https://api.bybit.com"
            }
        case .kucoin (let walletType):
            switch walletType {
            case .spot:
                return "https://api.kucoin.com"
            case .futures:
                return "https://api-futures.kucoin.com"
            case .unified:
                return "xxx" // TODO: Placeholder, KuCoin doesn't have a unified wallet type
            }
        case .binance:
            switch walletType {
            case .spot:
                return "xxx"
            case .futures:
                return "https://fapi.binance.com"
            case .unified:
                return "xxx" // TODO: Placeholder, binance doesn't have a unified wallet type
            }
        }
    }
    
    public var endpoint: String {
        switch self {
        case .bybit:
            switch walletType {
            case .spot:
                return "/v5/account/wallet-balance?accountType=SPOT"
            case .futures:
                return "xxx"
            case .unified:
                return "/v5/account/wallet-balance?accountType=UNIFIED"
            }
        case .kucoin (let walletType):
            switch walletType {
            case .spot:
                return "/api/v1/accounts?type=main"
            case .futures:
                return "/api/v1/account-overview?currency=USDT"
            case .unified:
                return "xxx" // TODO: Placeholder, KuCoin doesn't have a unified wallet type
            }
        case .binance:
            switch walletType {
            case .spot:
                return "xxx"
            case .futures:
                return "/fapi/v2/account"
            case .unified:
                return "xxx"
            }
        }
    }
    
    public static func make(_ name: ExchangeName, wallet: WalletType) -> ExchangeType {
        switch name {
        case .bybit:   return .bybit(walletType: wallet)
        case .kucoin:  return .kucoin(walletType: wallet)
        case .binance: return .binance(walletType: wallet)
        }
    }
}


public extension ExchangeType {
    static func == (lhs: ExchangeType, rhs: ExchangeType) -> Bool {
        switch (lhs, rhs) {
        case let (.bybit(a),   .bybit(b)),
             let (.kucoin(a),  .kucoin(b)),
             let (.binance(a), .binance(b)):
            return a == b
        default:
            return false
        }
    }
}
