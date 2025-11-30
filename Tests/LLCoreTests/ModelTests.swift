//
//  ModelTests.swift
//  LLCoreTests
//
//  Tests for data models
//

import Testing
import Foundation
@testable import LLCore

@Suite("Model Tests")
struct ModelTests {
    
    // MARK: - ExchangeType Tests
    
    @Suite("ExchangeType")
    struct ExchangeTypeTests {
        
        @Test("Bybit unified has correct properties")
        func testBybitUnifiedProperties() {
            let exchange = ExchangeType.bybit(walletType: .unified)
            
            #expect(exchange.walletType == .unified)
            #expect(exchange.displayName == "bybit")
            #expect(exchange.baseURL == "https://api.bybit.com")
            #expect(exchange.endpoint == "/v5/account/wallet-balance?accountType=UNIFIED")
            #expect(exchange.exchangeName == .bybit)
        }
        
        @Test("Bybit spot has correct properties")
        func testBybitSpotProperties() {
            let exchange = ExchangeType.bybit(walletType: .spot)
            
            #expect(exchange.walletType == .spot)
            #expect(exchange.displayName == "bybit")
            #expect(exchange.baseURL == "https://api.bybit.com")
            #expect(exchange.endpoint == "/v5/account/wallet-balance?accountType=SPOT")
        }
        
        @Test("KuCoin futures has correct properties")
        func testKuCoinFuturesProperties() {
            let exchange = ExchangeType.kucoin(walletType: .futures)
            
            #expect(exchange.walletType == .futures)
            #expect(exchange.displayName == "kucoin")
            #expect(exchange.baseURL == "https://api-futures.kucoin.com")
            #expect(exchange.endpoint == "/api/v1/account-overview?currency=USDT")
            #expect(exchange.exchangeName == .kucoin)
        }
        
        @Test("KuCoin spot has correct properties")
        func testKuCoinSpotProperties() {
            let exchange = ExchangeType.kucoin(walletType: .spot)
            
            #expect(exchange.walletType == .spot)
            #expect(exchange.displayName == "kucoin")
            #expect(exchange.baseURL == "https://api.kucoin.com")
            #expect(exchange.endpoint == "/api/v1/accounts?type=main")
        }
        
        @Test("Binance futures has correct properties")
        func testBinanceFuturesProperties() {
            let exchange = ExchangeType.binance(walletType: .futures)
            
            #expect(exchange.walletType == .futures)
            #expect(exchange.displayName == "binance")
            #expect(exchange.baseURL == "https://fapi.binance.com")
            #expect(exchange.endpoint == "/fapi/v2/account")
            #expect(exchange.exchangeName == .binance)
        }
        
        @Test("Available wallet types for Bybit")
        func testBybitAvailableWalletTypes() {
            let exchange = ExchangeType.bybit(walletType: .unified)
            
            #expect(exchange.availableWalletTypes == [.unified])
        }
        
        @Test("Available wallet types for KuCoin")
        func testKuCoinAvailableWalletTypes() {
            let exchange = ExchangeType.kucoin(walletType: .futures)
            
            #expect(exchange.availableWalletTypes == [.futures])
        }
        
        @Test("Available wallet types for Binance")
        func testBinanceAvailableWalletTypes() {
            let exchange = ExchangeType.binance(walletType: .futures)
            
            #expect(exchange.availableWalletTypes == [.futures])
        }
        
        @Test("Equality works correctly")
        func testEquality() {
            let exchange1 = ExchangeType.bybit(walletType: .unified)
            let exchange2 = ExchangeType.bybit(walletType: .unified)
            let exchange3 = ExchangeType.bybit(walletType: .spot)
            let exchange4 = ExchangeType.kucoin(walletType: .unified)
            
            #expect(exchange1 == exchange2)
            #expect(exchange1 != exchange3)
            #expect(exchange1 != exchange4)
        }
        
        @Test("Hashable works correctly")
        func testHashable() {
            let exchange1 = ExchangeType.bybit(walletType: .unified)
            let exchange2 = ExchangeType.bybit(walletType: .unified)
            let exchange3 = ExchangeType.kucoin(walletType: .futures)
            
            var set = Set<ExchangeType>()
            set.insert(exchange1)
            set.insert(exchange2) // Should not add duplicate
            set.insert(exchange3)
            
            #expect(set.count == 2)
            #expect(set.contains(exchange1))
            #expect(set.contains(exchange3))
        }
        
        @Test("Make factory method works")
        func testMakeFactoryMethod() {
            let bybit = ExchangeType.make(.bybit, wallet: .unified)
            let kucoin = ExchangeType.make(.kucoin, wallet: .futures)
            let binance = ExchangeType.make(.binance, wallet: .futures)
            
            #expect(bybit == .bybit(walletType: .unified))
            #expect(kucoin == .kucoin(walletType: .futures))
            #expect(binance == .binance(walletType: .futures))
        }
        
        @Test("AllCases returns correct exchanges")
        func testAllCases() {
            let allCases = ExchangeType.allCases
            
            #expect(allCases.count == 3)
            #expect(allCases.contains(.bybit(walletType: .spot)))
            #expect(allCases.contains(.kucoin(walletType: .spot)))
            #expect(allCases.contains(.binance(walletType: .spot)))
        }
        
        @Test("ExchangeType is Sendable")
        func testExchangeTypeIsSendable() {
            let exchange = ExchangeType.bybit(walletType: .unified)
            
            // Should compile without warnings about Sendable
            Task {
                let _ = exchange
            }
        }
    }
    
    // MARK: - ExchangeName Tests
    
    @Suite("ExchangeName")
    struct ExchangeNameTests {
        
        @Test("All exchange names are defined")
        func testAllExchangeNames() {
            let names = ExchangeName.allCases
            
            #expect(names.contains(.bybit))
            #expect(names.contains(.kucoin))
            #expect(names.contains(.binance))
            #expect(names.count == 3)
        }
        
        @Test("Exchange name raw values")
        func testRawValues() {
            #expect(ExchangeName.bybit.rawValue == "bybit")
            #expect(ExchangeName.kucoin.rawValue == "kucoin")
            #expect(ExchangeName.binance.rawValue == "binance")
        }
        
        @Test("Exchange name is hashable")
        func testHashable() {
            var set = Set<ExchangeName>()
            set.insert(.bybit)
            set.insert(.kucoin)
            set.insert(.binance)
            
            #expect(set.count == 3)
        }
    }
    
    // MARK: - WalletType Tests
    
    @Suite("WalletType")
    struct WalletTypeTests {
        
        @Test("All wallet types are defined")
        func testAllWalletTypes() {
            let types = WalletType.allCases
            
            #expect(types.contains(.spot))
            #expect(types.contains(.futures))
            #expect(types.contains(.unified))
            #expect(types.count == 3)
        }
        
        @Test("Wallet type raw values")
        func testRawValues() {
            #expect(WalletType.spot.rawValue == "spot")
            #expect(WalletType.futures.rawValue == "futures")
            #expect(WalletType.unified.rawValue == "unified")
        }
        
        @Test("Wallet type is hashable")
        func testHashable() {
            var set = Set<WalletType>()
            set.insert(.spot)
            set.insert(.futures)
            set.insert(.unified)
            
            #expect(set.count == 3)
        }
        
        @Test("WalletType is Sendable")
        func testWalletTypeIsSendable() {
            let walletType = WalletType.unified
            
            // Should compile without warnings about Sendable
            Task {
                let _ = walletType
            }
        }
    }
    
    // MARK: - WalletData Tests
    
    @Suite("WalletData")
    struct WalletDataTests {
        
        @Test("Initializes with values")
        func testInitialization() {
            let data = WalletData(totalEquity: "1000.00", walletBalance: "900.00")
            
            #expect(data.totalEquity == "1000.00")
            #expect(data.walletBalance == "900.00")
            #expect(data.maintenanceMargin == WalletData.valueNotAvailable) // Default value
        }
        
        @Test("Initializes with maintenance margin")
        func testInitializationWithMaintenanceMargin() {
            let data = WalletData(totalEquity: "1000.00", walletBalance: "900.00", maintenanceMargin: "50.00")
            
            #expect(data.totalEquity == "1000.00")
            #expect(data.walletBalance == "900.00")
            #expect(data.maintenanceMargin == "50.00")
        }
        
        @Test("Value not available constant")
        func testValueNotAvailableConstant() {
            #expect(WalletData.valueNotAvailable == "n/a")
        }
        
        @Test("Handles zero values")
        func testHandlesZeroValues() {
            let data = WalletData(totalEquity: "0.00", walletBalance: "0.00")
            
            #expect(data.totalEquity == "0.00")
            #expect(data.walletBalance == "0.00")
            #expect(data.maintenanceMargin == WalletData.valueNotAvailable)
        }
        
        @Test("Handles large values")
        func testHandlesLargeValues() {
            let data = WalletData(
                totalEquity: "123456789.12345678",
                walletBalance: "987654321.87654321"
            )
            
            #expect(data.totalEquity == "123456789.12345678")
            #expect(data.walletBalance == "987654321.87654321")
        }
        
        @Test("Handles empty strings")
        func testHandlesEmptyStrings() {
            let data = WalletData(totalEquity: "", walletBalance: "")
            
            #expect(data.totalEquity == "")
            #expect(data.walletBalance == "")
        }
    }
    
    // MARK: - Credentials Tests
    
    @Suite("Credentials")
    struct CredentialsTests {
        
        @Test("Initializes with all fields")
        func testInitializationWithAllFields() {
            let creds = Credentials(
                apiKey: "test-key",
                apiSecret: "test-secret",
                passphrase: "test-passphrase"
            )
            
            #expect(creds.apiKey == "test-key")
            #expect(creds.apiSecret == "test-secret")
            #expect(creds.passphrase == "test-passphrase")
        }
        
        @Test("Initializes without passphrase")
        func testInitializationWithoutPassphrase() {
            let creds = Credentials(
                apiKey: "test-key",
                apiSecret: "test-secret"
            )
            
            #expect(creds.apiKey == "test-key")
            #expect(creds.apiSecret == "test-secret")
            #expect(creds.passphrase == nil)
        }
        
        @Test("Credentials are equatable")
        func testEquatable() {
            let creds1 = Credentials(apiKey: "key1", apiSecret: "secret1", passphrase: "pass1")
            let creds2 = Credentials(apiKey: "key1", apiSecret: "secret1", passphrase: "pass1")
            let creds3 = Credentials(apiKey: "key2", apiSecret: "secret2", passphrase: "pass2")
            
            #expect(creds1 == creds2)
            #expect(creds1 != creds3)
        }
        
        @Test("Credentials with nil passphrase are equal")
        func testEquatableWithNilPassphrase() {
            let creds1 = Credentials(apiKey: "key1", apiSecret: "secret1", passphrase: nil)
            let creds2 = Credentials(apiKey: "key1", apiSecret: "secret1", passphrase: nil)
            
            #expect(creds1 == creds2)
        }
        
        @Test("Credentials are Sendable")
        func testCredentialsAreSendable() {
            let creds = Credentials(apiKey: "key", apiSecret: "secret")
            
            // Should compile without warnings about Sendable
            Task {
                let _ = creds
            }
        }
    }
    
    // MARK: - APIError Tests
    
    @Suite("APIError")
    struct APIErrorTests {
        
        @Test("All error cases are defined")
        func testAllErrorCases() {
            let error1: APIError = .invalidRequest
            let error2: APIError = .noData
            let error3: APIError = .parseError
            
            #expect(error1 == .invalidRequest)
            #expect(error2 == .noData)
            #expect(error3 == .parseError)
        }
        
        @Test("Localized descriptions are provided")
        func testLocalizedDescriptions() {
            #expect(APIError.invalidRequest.localizedDescription == "Invalid API request")
            #expect(APIError.noData.localizedDescription == "No data received from API")
            #expect(APIError.parseError.localizedDescription == "Failed to parse API response")
        }
        
        @Test("APIError is Error")
        func testIsError() {
            let error: Error = APIError.invalidRequest
            
            #expect(error is APIError)
        }
    }
    
    // MARK: - APIDomainError Tests
    
    @Suite("APIDomainError")
    struct APIDomainErrorTests {
        
        @Test("All domain error cases have message keys")
        func testMessageKeys() {
            let context = APIErrorContext(exchange: .bybit(walletType: .unified))
            
            #expect(APIDomainError.invalidCredentials(context: context).messageKey == "api.invalidCredentials.message")
            #expect(APIDomainError.permissionDenied(context: context).messageKey == "api.permissionDenied.message")
            #expect(APIDomainError.ipNotAllowed(context: context).messageKey == "api.ipNotAllowed.message")
            #expect(APIDomainError.keyRevokedOrInactive(context: context).messageKey == "api.keyRevokedOrInactive.message")
            #expect(APIDomainError.signatureInvalid(context: context).messageKey == "api.signatureInvalid.message")
            #expect(APIDomainError.timestampOutOfRange(context: context).messageKey == "api.timestampOutOfRange.message")
            #expect(APIDomainError.missingOrInvalidParams(context: context).messageKey == "api.missingOrInvalidParams.message")
            #expect(APIDomainError.rateLimited(context: context).messageKey == "api.rateLimited.message")
            #expect(APIDomainError.maintenance(context: context).messageKey == "api.maintenance.message")
            #expect(APIDomainError.server(context: context).messageKey == "api.server.message")
            #expect(APIDomainError.network(context: context).messageKey == "api.network.message")
            #expect(APIDomainError.unknown(context: context).messageKey == "api.unknown.message")
        }
        
        @Test("All domain errors have user messages")
        func testUserMessages() {
            let context = APIErrorContext(exchange: .bybit(walletType: .unified))
            
            #expect(!APIDomainError.invalidCredentials(context: context).userMessage.isEmpty)
            #expect(!APIDomainError.permissionDenied(context: context).userMessage.isEmpty)
            #expect(!APIDomainError.ipNotAllowed(context: context).userMessage.isEmpty)
            #expect(!APIDomainError.keyRevokedOrInactive(context: context).userMessage.isEmpty)
            #expect(!APIDomainError.signatureInvalid(context: context).userMessage.isEmpty)
            #expect(!APIDomainError.timestampOutOfRange(context: context).userMessage.isEmpty)
            #expect(!APIDomainError.rateLimited(context: context).userMessage.isEmpty)
            #expect(!APIDomainError.maintenance(context: context).userMessage.isEmpty)
            #expect(!APIDomainError.server(context: context).userMessage.isEmpty)
            #expect(!APIDomainError.network(context: context).userMessage.isEmpty)
            #expect(!APIDomainError.unknown(context: context).userMessage.isEmpty)
        }
        
        @Test("User messages include exchange name")
        func testUserMessagesIncludeExchangeName() {
            let bybitContext = APIErrorContext(exchange: .bybit(walletType: .unified))
            let kucoinContext = APIErrorContext(exchange: .kucoin(walletType: .futures))
            
            let bybitError = APIDomainError.maintenance(context: bybitContext)
            let kucoinError = APIDomainError.maintenance(context: kucoinContext)
            
            #expect(bybitError.userMessage.lowercased().contains("bybit"))
            #expect(kucoinError.userMessage.lowercased().contains("kucoin"))
        }
        
        @Test("Context property returns correct context")
        func testContextProperty() {
            let context = APIErrorContext(
                exchange: .bybit(walletType: .unified),
                httpStatus: 401,
                apiCode: "10004",
                requestId: "test-id",
                endpoint: "/test",
                rawMessage: "Error"
            )
            
            let error = APIDomainError.invalidCredentials(context: context)
            
            #expect(error.context == context)
        }
        
        @Test("APIDomainError is equatable")
        func testEquatable() {
            let context1 = APIErrorContext(exchange: .bybit(walletType: .unified))
            let context2 = APIErrorContext(exchange: .bybit(walletType: .unified))
            let context3 = APIErrorContext(exchange: .kucoin(walletType: .futures))
            
            let error1 = APIDomainError.invalidCredentials(context: context1)
            let error2 = APIDomainError.invalidCredentials(context: context2)
            let error3 = APIDomainError.invalidCredentials(context: context3)
            let error4 = APIDomainError.permissionDenied(context: context1)
            
            #expect(error1 == error2)
            #expect(error1 != error3)
            #expect(error1 != error4)
        }
        
        @Test("Unknown error includes request ID in message")
        func testUnknownErrorWithRequestID() {
            let context = APIErrorContext(
                exchange: .bybit(walletType: .unified),
                requestId: "abc-123"
            )
            
            let error = APIDomainError.unknown(context: context)
            
            #expect(error.userMessage.contains("abc-123"))
        }
    }
}

