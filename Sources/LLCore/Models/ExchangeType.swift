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

public enum EndpointType: Hashable, Sendable {
    case wallet(WalletType)
    case apiKeyInfo
    // Future: accountInfo, orders, positions, etc.
}

public struct ExchangeCapabilities {
    public var urls: [APIEnvironment: String]
    
    public var endpoints: [EndpointType: String]
    
    public var availableWalletTypes: [WalletType] {
        
        return endpoints.reduce([]) { (result, element) in
            if case .wallet(let wType) = element.key {
                return result + [wType]
            }
            return result
        }
    }
    
    public var availableEnvironments: [APIEnvironment] {
        Array(urls.keys)
    }
    
    public init(
        urls: [APIEnvironment: String],
        endpoints: [EndpointType: String] = [:]
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
    
    public func getEndpointString(for endpointType: EndpointType) -> String {
        registry.capabilities(for: identifier)?.endpoints[endpointType] ?? ""
    }
    
    @available(*, deprecated, message: "Use getEndpointString(for endpointType:) instead")
    public var endpoint: String {
        return getEndpointString(for: .wallet(walletType))
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
    
    @available(*, deprecated, message: "Use getEndpointString(for endpointType:) instead")
    var endpoint: String { get }
    
    func getEndpointString(for endpointType: EndpointType) -> String
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
