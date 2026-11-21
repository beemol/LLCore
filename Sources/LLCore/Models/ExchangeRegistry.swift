//
//  ExchangeRegistry.swift
//  LLCore
//
//  Created by Aleh Fiodarau on 03/12/2025.
//

import LLApiService

public protocol ExchangeRegistryProtocol {
    
    var availableExchanges: [ExchangeIdentifier] { get }
    
    func capabilities(for identifier: ExchangeIdentifier) -> ExchangeCapabilities?
    func configuration(for exchange: Exchange) -> ExchangeConfiguration?
    
    func parser<E: Endpoint>(for identifier: ExchangeIdentifier, endpoint: E) -> (any LLResponseParserProtocol<E.Output>)?
    func errorDetector(for identifier: ExchangeIdentifier) -> LLDomainErrorDetector?
    func requestBuilder(for identifier: ExchangeIdentifier, configuration: ExchangeConfiguration, credentials: Credentials, endpointType: EndpointID) -> LLAPIRequestBuilder?
}

extension ExchangeRegistry {
    public func configuration(for exchange: Exchange) -> ExchangeConfiguration? {
        guard let capabilities = capabilities(for: exchange.identifier),
              let baseURL = capabilities.urls[exchange.environment]
        else {
            return nil
        }

        return ExchangeConfiguration(baseURL: baseURL,
                                   endpoints: capabilities.endpoints)
    }
}

public final class ExchangeRegistry: ExchangeRegistryProtocol {
    
    private let capabilities: [ExchangeIdentifier: ExchangeCapabilities]
    private let parserFactories: [ExchangeIdentifier: @Sendable (EndpointID) -> any LLResponseParserProtocol]
    private let errorDetectors: [ExchangeIdentifier: LLDomainErrorDetector]
    private let requestBuilderFactories: [ExchangeIdentifier: @Sendable (ExchangeConfiguration, Credentials, EndpointID) -> LLAPIRequestBuilder]

    public init(
        capabilities: [ExchangeIdentifier: ExchangeCapabilities],
        parserFactories: [ExchangeIdentifier: @Sendable (EndpointID) -> any LLResponseParserProtocol],
        errorDetectors: [ExchangeIdentifier: LLDomainErrorDetector],
        requestBuilderFactories: [ExchangeIdentifier: @Sendable (ExchangeConfiguration, Credentials, EndpointID) -> LLAPIRequestBuilder]
    ) {
        self.capabilities = capabilities
        self.parserFactories = parserFactories
        self.errorDetectors = errorDetectors
        self.requestBuilderFactories = requestBuilderFactories
    }
    
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
    
    public func requestBuilder(for identifier: ExchangeIdentifier, configuration: ExchangeConfiguration, credentials: Credentials, endpointType: EndpointID) -> LLAPIRequestBuilder? {
        requestBuilderFactories[identifier]?(configuration, credentials, endpointType)
    }
    
    // MARK: - Modify API (for client apps)
//    public func addOrUpdateEnvironment(with url: String, for identifier: ExchangeIdentifier, environment: APIEnvironment) {
//        capabilities[identifier]?.urls[environment] = url
//    }
//
//    public func addOrUpdateWalletType(with endpoint: String, for identifier: ExchangeIdentifier, walletType: WalletType) {
//        capabilities[identifier]?.endpoints[.wallet(walletType)] = endpoint
//    }
//    
//    public func removeEnvironment(_ environment: APIEnvironment, for identifier: ExchangeIdentifier) {
//        capabilities[identifier]?.urls.removeValue(forKey: environment)
//    }
//
//    public func removeWalletType(_ walletType: WalletType, for identifier: ExchangeIdentifier) {
//        capabilities[identifier]?.endpoints.removeValue(forKey: .wallet(walletType))
//    }
//    
//    public func setCapabilities(_ caps: ExchangeCapabilities, for identifier: ExchangeIdentifier) {
//        capabilities[identifier] = caps
//    }
//    
//    public func registerParserFactory(_ factory: @escaping (EndpointID) -> any LLResponseParserProtocol, for identifier: ExchangeIdentifier) {
//        parserFactories[identifier] = factory
//    }
//    
//    public func registerErrorDetector(_ detector: LLDomainErrorDetector, for identifier: ExchangeIdentifier) {
//        errorDetectors[identifier] = detector
//    }
//    
//    public func registerRequestBuilderFactory(_ factory: @escaping (any Exchange, Credentials, EndpointID) -> LLAPIRequestBuilder, for identifier: ExchangeIdentifier) {
//        requestBuilderFactories[identifier] = factory
//    }
}
