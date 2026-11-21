//
//  Exchange.swift
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
}

public struct ExchangeConfiguration {
    public let baseURL: String
    public let endpoints: [EndpointID: String]

    public func endpoint(for id: EndpointID) -> String? {
        endpoints[id]
    }
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

public enum EndpointID: Hashable, Sendable {
    case wallet(WalletType)
    case apiKeyInfo
}

public protocol Endpoint: Sendable {
    associatedtype Output: Sendable

    var id: EndpointID { get }
}

public struct ExchangeCapabilities: Sendable {
    public var urls: [APIEnvironment: String]
    public var endpoints: [EndpointID: String]
    
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
    
    public init(urls: [APIEnvironment: String], endpoints: [EndpointID: String] = [:]) {
        self.urls = urls
        self.endpoints = endpoints
    }
}

public struct Exchange: Sendable, Equatable, Hashable {
    public let identifier: ExchangeIdentifier
    public let environment: APIEnvironment
    public let walletType: WalletType
    
    public init(
        _ identifier: ExchangeIdentifier,
        environment: APIEnvironment = .production,
        wallet: WalletType
    ) {
        self.identifier = identifier
        self.environment = environment
        self.walletType = wallet
    }
}

public extension Exchange {
    static func == (lhs: Exchange, rhs: Exchange) -> Bool {
        lhs.identifier == rhs.identifier &&
        lhs.environment == rhs.environment &&
        lhs.walletType == rhs.walletType
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
        hasher.combine(environment)
        hasher.combine(walletType)
    }
}
