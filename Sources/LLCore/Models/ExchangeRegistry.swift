//
//  ExchangeRegistry.swift
//  LLCore
//
//  Created by Aleh Fiodarau on 03/12/2025.
//

import LLApiService

//public protocol ExchangeCapabilitiesProviding: Sendable {
//    func capabilities(for identifier: ExchangeIdentifier) -> ExchangeCapabilities?
//}

public protocol ExchangeRegistryProtocol: Sendable {
    // MARK: Read
    var availableExchanges: [ExchangeIdentifier] { get }
    
    func capabilities(for identifier: ExchangeIdentifier) -> ExchangeCapabilities?
    
    func parser<E: Endpoint>(for identifier: ExchangeIdentifier, endpoint: E) -> (any LLResponseParserProtocol<E.Output>)?
    
    func errorDetector(for identifier: ExchangeIdentifier) -> LLDomainErrorDetector?
    func requestBuilder(for config: any ExchangeType, credentials: Credentials, endpointType: EndpointID) -> LLAPIRequestBuilder?
    
    // MARK: - Write (for setup/testing)
    func addOrUpdateEnvironment(with url: String, for identifier: ExchangeIdentifier, environment: APIEnvironment)
    func addOrUpdateWalletType(with endpoint: String, for identifier: ExchangeIdentifier, walletType: WalletType)
    func removeEnvironment(_ environment: APIEnvironment, for identifier: ExchangeIdentifier)
    func removeWalletType(_ walletType: WalletType, for identifier: ExchangeIdentifier)
    
    func setCapabilities(_ caps: ExchangeCapabilities, for identifier: ExchangeIdentifier)
    
    func registerParserFactory(_ factory: @escaping (EndpointID) -> any LLResponseParserProtocol, for identifier: ExchangeIdentifier)
    func registerErrorDetector(_ detector: LLDomainErrorDetector, for identifier: ExchangeIdentifier)
    func registerRequestBuilderFactory(_ factory: @escaping (any ExchangeType, Credentials, EndpointID) -> LLAPIRequestBuilder, for identifier: ExchangeIdentifier)
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
    
    private var parserFactories: [ExchangeIdentifier: (EndpointID) -> any LLResponseParserProtocol] = [:]
    
    private var errorDetectors: [ExchangeIdentifier: LLDomainErrorDetector] = [:]
    private var requestBuilderFactories: [ExchangeIdentifier: (any ExchangeType, Credentials, EndpointID) -> LLAPIRequestBuilder] = [:]
    
    // MARK: - Read
    public var availableExchanges: [ExchangeIdentifier] {
        Array(capabilities.keys)
    }
    
    public func capabilities(for identifier: ExchangeIdentifier) -> ExchangeCapabilities? {
        capabilities[identifier]
    }
    
    public func parser<E: Endpoint>(for identifier: ExchangeIdentifier, endpoint: E) -> (any LLResponseParserProtocol<E.Output>)? {
        parserFactories[identifier]?(endpoint.id) as? any LLResponseParserProtocol<E.Output>
    }
    
    public func errorDetector(for identifier: ExchangeIdentifier) -> LLDomainErrorDetector? {
        errorDetectors[identifier]
    }
    
    public func requestBuilder(for config: any ExchangeType, credentials: Credentials, endpointType: EndpointID) -> LLAPIRequestBuilder? {
        requestBuilderFactories[config.identifier]?(config, credentials, endpointType)
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
    
    public func registerParserFactory(_ factory: @escaping (EndpointID) -> any LLResponseParserProtocol, for identifier: ExchangeIdentifier) {
        parserFactories[identifier] = factory
    }
    
    public func registerErrorDetector(_ detector: LLDomainErrorDetector, for identifier: ExchangeIdentifier) {
        errorDetectors[identifier] = detector
    }
    
    public func registerRequestBuilderFactory(_ factory: @escaping (any ExchangeType, Credentials, EndpointID) -> LLAPIRequestBuilder,
                                              for identifier: ExchangeIdentifier) {
        requestBuilderFactories[identifier] = factory
    }
}
