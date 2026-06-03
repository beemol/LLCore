//
//  ExchangeRegistry.swift
//  LLCore
//
//  Created by Aleh Fiodarau on 03/12/2025.
//

import LLApiService

public protocol ExchangeRegistryProtocol: Sendable {
    // MARK: Read
    var availableExchanges: [ExchangeIdentifier] { get }
    
    func capabilities(for identifier: ExchangeIdentifier) -> ExchangeCapabilities?
    
    @available(*, deprecated, message: "Use parser(for:endpointType:) instead")
    func parser(for identifier: ExchangeIdentifier, walletType: WalletType) -> (any WalletDataParserProtocol)?
    
    func parser(for identifier: ExchangeIdentifier, endpointType: EndpointType) -> (any LLResponseParserProtocol)?
    
    func errorDetector(for identifier: ExchangeIdentifier) -> LLDomainErrorDetector?
    func requestBuilder(for config: any ExchangeType, credentials: Credentials) -> APIRequestBuilder?
    
    // MARK: - Write (for setup/testing)
    func addOrUpdateEnvironment(with url: String, for identifier: ExchangeIdentifier, environment: APIEnvironment)
    func addOrUpdateWalletType(with endpoint: String, for identifier: ExchangeIdentifier, walletType: WalletType)
    func removeEnvironment(_ environment: APIEnvironment, for identifier: ExchangeIdentifier)
    func removeWalletType(_ walletType: WalletType, for identifier: ExchangeIdentifier)
    
    func setCapabilities(_ caps: ExchangeCapabilities, for identifier: ExchangeIdentifier)
    
    func registerParserFactory(_ factory: @escaping (EndpointType) -> any LLResponseParserProtocol, for identifier: ExchangeIdentifier)
    func registerErrorDetector(_ detector: LLDomainErrorDetector, for identifier: ExchangeIdentifier)
    func registerRequestBuilderFactory(_ factory: @escaping (any ExchangeType, Credentials) -> APIRequestBuilder, for identifier: ExchangeIdentifier)
}

// TODO: make it an Actor or hanlde safe concurrency (good for now since we don't expose capabilities {get set} )
/// Usage
/// Option A: Change URL at App Startup
///   ExchangeRegistry.shared.addEnvironment(with: "https://api-demo-v2.bybit.com",  for: "bybit", environment: .demo)
/// Option B: Customize capabilities at startup (e.g., enable more wallet types)
///   ExchangeRegistry.shared.setCapabilities(ExchangeCapabilities(...))
public final class ExchangeRegistry: ExchangeRegistryProtocol, @unchecked Sendable {
    public static let shared = ExchangeRegistry()
    
    private var capabilities: [ExchangeIdentifier: ExchangeCapabilities] = [:]

    //private var parserFactories: [ExchangeIdentifier: (WalletType) -> any WalletDataParserProtocol] = [:]
    
    private var parserFactories: [ExchangeIdentifier: (EndpointType) -> any LLResponseParserProtocol] = [:]
    
    private var errorDetectors: [ExchangeIdentifier: LLDomainErrorDetector] = [:]
    private var requestBuilderFactories: [ExchangeIdentifier: (any ExchangeType, Credentials) -> APIRequestBuilder] = [:]
    
    private init() {
        // Defaults - can be overridden
        capabilities[.bybit] = defaultCapabilitiesForBybit()
        capabilities[.kucoin] = defaultCapabilitiesForKucoin()
        
        registerBybitDefaults()
        registerKuCoinDefaults()
    }
    
    // MARK: - Read
    public var availableExchanges: [ExchangeIdentifier] {
        Array(capabilities.keys)
    }
    
    public func capabilities(for identifier: ExchangeIdentifier) -> ExchangeCapabilities? {
        capabilities[identifier]
    }
    
    @available(*, deprecated, message: "Use parser(for:endpointType:) instead")
    public func parser(for identifier: ExchangeIdentifier, walletType: WalletType) -> (any WalletDataParserProtocol)? {
        return parserFactories[identifier]?(.wallet(walletType)) as? any WalletDataParserProtocol
    }
    
    public func parser(for identifier: ExchangeIdentifier, endpointType: EndpointType) -> (any LLResponseParserProtocol)? {
        parserFactories[identifier]?(endpointType)
    }
    
    public func errorDetector(for identifier: ExchangeIdentifier) -> LLDomainErrorDetector? {
        errorDetectors[identifier]
    }
    
    public func requestBuilder(for config: any ExchangeType, credentials: Credentials) -> APIRequestBuilder? {
        requestBuilderFactories[config.identifier]?(config, credentials)
    }
    
    // MARK: - Modify API (for client apps)
    public func addOrUpdateEnvironment(with url: String, for identifier: ExchangeIdentifier, environment: APIEnvironment) {
        capabilities[identifier]?.urls[environment] = url
    }

    public func addOrUpdateWalletType(with endpoint: String, for identifier: ExchangeIdentifier, walletType: WalletType) {
        capabilities[identifier]?.endpoints[.wallet(walletType)] = endpoint
        //capabilities[identifier]?.walletEndpoints[walletType] = endpoint
    }
    
    public func removeEnvironment(_ environment: APIEnvironment, for identifier: ExchangeIdentifier) {
        capabilities[identifier]?.urls.removeValue(forKey: environment)
    }

    public func removeWalletType(_ walletType: WalletType, for identifier: ExchangeIdentifier) {
        capabilities[identifier]?.endpoints.removeValue(forKey: .wallet(walletType))
        //capabilities[identifier]?.walletEndpoints.removeValue(forKey: walletType)
    }
    
    public func setCapabilities(_ caps: ExchangeCapabilities, for identifier: ExchangeIdentifier) {
        capabilities[identifier] = caps
    }
    
    public func registerParserFactory(_ factory: @escaping (EndpointType) -> any LLResponseParserProtocol, for identifier: ExchangeIdentifier) {
        parserFactories[identifier] = factory
    }
    
    public func registerErrorDetector(_ detector: LLDomainErrorDetector, for identifier: ExchangeIdentifier) {
        errorDetectors[identifier] = detector
    }
    
    public func registerRequestBuilderFactory(_ factory: @escaping (any ExchangeType, Credentials) -> APIRequestBuilder, for identifier: ExchangeIdentifier) {
        requestBuilderFactories[identifier] = factory
    }
    
    // MARK: - Default Registrations
    private func registerBybitDefaults() {
        capabilities[.bybit] = defaultCapabilitiesForBybit()
        
        registerParserFactory({ endpointType in
            switch endpointType {
            case .wallet(_):
                return BybitUnifiedWalletDataParser()
            case .apiKeyInfo:
                // TODO: Create BybitApiKeyInfoParser
                return BybitUnifiedWalletDataParser() // temporary fallback
            }
        }, for: .bybit)
        
        registerErrorDetector(BybitErrorDetector(), for: .bybit)
        
        registerRequestBuilderFactory({ config, creds in
            BybitAPIRequestBuilder(exchangeType: config, creds: creds)
        }, for: .bybit)
    }
    
    private func registerKuCoinDefaults() {
        capabilities[.kucoin] = defaultCapabilitiesForKucoin()
        
        registerParserFactory({ endpointType in
            switch endpointType {
            case .wallet(let walletType):
                return KuCoinWalletDataParser(walletType: walletType)
            case .apiKeyInfo:
                // TODO:
                return KuCoinWalletDataParser() // temporary fallback
            }
        }, for: .kucoin)
        
        registerErrorDetector(KucoinErrorDetector(), for: .kucoin)
        
        registerRequestBuilderFactory({ config, creds in
            KuCoinAPIRequestBuilder(exchangeType: config, creds: creds)
        }, for: .kucoin)
    }
    
    // helpers
    private func defaultCapabilitiesForBybit() -> ExchangeCapabilities {
        ExchangeCapabilities(
            urls: [
                .production: "https://api.bybit.com",
                .testnet: "https://api-testnet.bybit.com",
                .demo: "https://api-demo.bybit.com"
            ],
//            walletEndpoints: [
//                .unified: "/v5/account/wallet-balance?accountType=UNIFIED",
//                .spot: "/v5/account/wallet-balance?accountType=SPOT",
//                .futures: "/v5/account/wallet-balance?accountType=CONTRACT"
//            ],
            endpoints: [
                .wallet(.unified): "/v5/account/wallet-balance?accountType=UNIFIED",
                .wallet(.spot): "/v5/account/wallet-balance?accountType=SPOT",
                .wallet(.futures): "/v5/account/wallet-balance?accountType=CONTRACT",
                .apiKeyInfo: "/v5/user/query-api"
            ]
        )
    }
    
    private func defaultCapabilitiesForKucoin() -> ExchangeCapabilities {
        ExchangeCapabilities(
            urls: [
                .production: "https://api-futures.kucoin.com",
                .testnet: "https://api-sandbox-futures.kucoin.com",
                .demo: "https://api-sandbox-futures.kucoin.com"
            ],
//            walletEndpoints: [
//                .futures: "/api/v1/account-overview?currency=USDT",
//                .spot: "/api/v1/accounts?type=main",
//                .unified: "/api/v1/accounts",
//            ],
            endpoints: [
                .wallet(.unified): "/api/v1/accounts",
                .wallet(.spot): "/api/v1/accounts?type=main",
                .wallet(.futures): "/api/v1/account-overview?currency=USDT",
                .apiKeyInfo: "/api/v1/user-info/all-sub-users"
            ]
        )
    }
}
