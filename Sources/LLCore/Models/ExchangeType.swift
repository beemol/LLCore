//
//  ExchangeType.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 30/09/2025.
//

public enum ExchangeName: String, CaseIterable, Hashable, Sendable {
    case bybit
    case kucoin
    case binance
    
    public static var allCases: [ExchangeName] {
        return [.bybit, .kucoin, .binance]
    }
}

public struct ExchangeType: Equatable, Hashable, Sendable {
    public let name: ExchangeName
    public let walletType: WalletType
    
    public init(_ name: ExchangeName, wallet: WalletType) {
        self.name = name
        self.walletType = wallet
    }
    
    public var availableWalletTypes: [WalletType] {
        switch name {
        case .bybit:
            return [.unified]
        case .kucoin:
            return [.futures]
        case .binance:
            return [.futures]
        }
    }
//
//    public static func make(_ name: ExchangeName, wallet: WalletType) -> ExchangeType {
//        ExchangeType(name: name, walletType: wallet)
//    }
}

public extension ExchangeType {
    static func == (lhs: ExchangeType, rhs: ExchangeType) -> Bool {
        return lhs.name == rhs.name && lhs.walletType.rawValue == rhs.walletType.rawValue
    }
}

// keep this for mapping ExchangeType to ExchangeName and to make sure we have a single source of truth
//public extension ExchangeType {
//    var name: ExchangeName {
//        switch self {
//        case .bybit: return .bybit
//        case .kucoin: return .kucoin
//        case .binance: return .binance
//        }
//    }
//}

public enum WalletType: String, CaseIterable, Hashable, Sendable {
    case spot, futures, unified
}

//public enum ExchangeType: Hashable, CaseIterable, Sendable {
//    public static var allCases: [ExchangeType] {
//        return [
//            .bybit(walletType: .spot),
//            .kucoin(walletType: .spot),
//            .binance(walletType: .spot)
//        ]
//    }
//    
//    case bybit (walletType: WalletType)
//    case kucoin (walletType: WalletType)
//    case binance (walletType: WalletType) //, coinbase, kraken
//    
//    public var walletType: WalletType {
//        switch self {
//        case .bybit(let w), .kucoin(let w), .binance(let w): return w
//        }
//    }
//    
//    public var availableWalletTypes: [WalletType] {
//        switch self {
//        case .bybit:
//            return [.unified]
//        case .kucoin:
//            return [.futures]
//        case .binance:
//            return [.futures]
//        }
//    }
//    
//    public static func make(_ name: ExchangeName, wallet: WalletType) -> ExchangeType {
//        switch name {
//        case .bybit:   return .bybit(walletType: wallet)
//        case .kucoin:  return .kucoin(walletType: wallet)
//        case .binance: return .binance(walletType: wallet)
//        }
//    }
//}
//
//
//public extension ExchangeType {
//    static func == (lhs: ExchangeType, rhs: ExchangeType) -> Bool {
//        switch (lhs, rhs) {
//        case let (.bybit(a),   .bybit(b)),
//             let (.kucoin(a),  .kucoin(b)),
//             let (.binance(a), .binance(b)):
//            return a == b
//        default:
//            return false
//        }
//    }
//}
