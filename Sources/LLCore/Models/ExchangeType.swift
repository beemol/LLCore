//
//  ExchangeType.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 30/09/2025.
//

public struct ExchangeIdentifier: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
    
    // Known exchanges - compiler-checked
    public static let bybit = ExchangeIdentifier(rawValue: "bybit")
    public static let kucoin = ExchangeIdentifier(rawValue: "kucoin")
    public static let binance = ExchangeIdentifier(rawValue: "binance")
}

public enum APIEnvironment: String, Sendable, Hashable {
    case production
    case testnet
    case demo
}

public enum WalletType: String, CaseIterable, Hashable, Sendable {
    case spot
    case futures
    case unified
}

public struct ExchangeCapabilities {
    public var urls: [APIEnvironment: String]
    public var endpoints: [WalletType: String]
    
    public var availableWalletTypes: [WalletType] {
        Array(endpoints.keys)
    }
    
    public var availableEnvironments: [APIEnvironment] {
        Array(urls.keys)
    }
    
    public init(
        urls: [APIEnvironment: String],
        endpoints: [WalletType: String]
    ) {
        self.urls = urls
        self.endpoints = endpoints
    }
}

public struct Exchange: ExchangeType, Equatable, Hashable {
    public let identifier: ExchangeIdentifier
    public let environment: APIEnvironment
    public let walletType: WalletType
    public let registry: any ExchangeRegistryProtocol
    
    public init(
        _ identifier: ExchangeIdentifier,
        environment: APIEnvironment = .production,
        wallet: WalletType,
        registry: any ExchangeRegistryProtocol = ExchangeRegistry.shared
    ) {
        self.identifier = identifier
        self.environment = environment
        self.walletType = wallet
        self.registry = registry
    }
    
    // Everything from registry - no hardcoded values!
    public var baseURL: String {
        registry.capabilities(for: identifier)?.urls[environment] ?? ""
    }
    
    public var endpoint: String {
        registry.capabilities(for: identifier)?.endpoints[walletType] ?? ""
    }
    
    public var availableWalletTypes: [WalletType] {
        registry.capabilities(for: identifier)?.availableWalletTypes ?? []
    }
    
    public var availableEnvironments: [APIEnvironment] {
        registry.capabilities(for: identifier)?.availableEnvironments ?? [.production]
    }
}

public extension Exchange {
    // MARK: - Equatable (exclude registry)
    static func == (lhs: Exchange, rhs: Exchange) -> Bool {
        lhs.identifier == rhs.identifier &&
        lhs.environment == rhs.environment &&
        lhs.walletType == rhs.walletType
    }
    
    // MARK: - Hashable (exclude registry)
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
        hasher.combine(environment)
        hasher.combine(walletType)
    }
}

/// - Parameter identifier: bybit, kucoin, bybit-demo etc
public protocol ExchangeType: Sendable {
    var identifier: ExchangeIdentifier { get }
    var environment: APIEnvironment { get }
    var walletType: WalletType { get }
    
    var registry: ExchangeRegistryProtocol { get }
    
    var baseURL: String { get }
    var endpoint: String { get }
}

public extension ExchangeType {
    var name: String {
        return identifier.rawValue
    }
}

// Convenient computed properties
public extension ExchangeType {
    // For backward compatibility with ApiRequestable
    var displayName: String { identifier.rawValue }
}

// Capabilities accessed via registry, not stored on instance
public extension ExchangeType {
    var availableWalletTypes: [WalletType] {
        registry.capabilities(for: identifier)?.availableWalletTypes ?? []
    }
    
    var availableEnvironments: [APIEnvironment] {
        registry.capabilities(for: identifier)?.availableEnvironments ?? [.production]
    }
}

// old approach
//public enum ExchangeName: String, CaseIterable, Hashable, Sendable {
//    case bybit
//    case kucoin
//    case binance
//    
//    public static var allCases: [ExchangeName] {
//        return [.bybit, .kucoin, .binance]
//    }
//}

//public struct ExchangeType: Equatable, Hashable, Sendable {
//    public let name: ExchangeName
//    public let walletType: WalletType
//    
//    public init(_ name: ExchangeName, wallet: WalletType) {
//        self.name = name
//        self.walletType = wallet
//    }
//    
//    public var availableWalletTypes: [WalletType] {
//        switch name {
//        case .bybit:
//            return [.unified]
//        case .kucoin:
//            return [.futures]
//        case .binance:
//            return [.futures]
//        }
//    }
////
////    public static func make(_ name: ExchangeName, wallet: WalletType) -> ExchangeType {
////        ExchangeType(name: name, walletType: wallet)
////    }
//}

//public extension ExchangeType {
//    static func == (lhs: ExchangeType, rhs: ExchangeType) -> Bool {
//        return lhs.name == rhs.name && lhs.walletType.rawValue == rhs.walletType.rawValue
//    }
//}

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
