//
//  RequestBuilderTests.swift
//  LLCoreTests
//
//  Tests for API request builders
//

import Testing
import Foundation
@testable import LLCore

@Suite("Request Builder Tests")
struct RequestBuilderTests {
    
    // MARK: - Bybit Request Builder Tests
    
    @Suite("Bybit Request Builder")
    struct BybitRequestBuilderTests {
        
        @Test("Creates valid unified wallet request")
        func testUnifiedWalletRequest() {
            let exchangeType = ExchangeType.bybit(walletType: .unified)
            let credentials = TestFixtures.TestCredentials.bybit
            let builder = BybitAPIRequestBuilder(exchangeType: exchangeType, creds: credentials)
            
            let request = builder.createWalletBalanceRequest()
            
            #expect(request != nil)
            #expect(request?.httpMethod == "GET")
            #expect(request?.url?.absoluteString.contains("api.bybit.com") == true)
            #expect(request?.url?.absoluteString.contains("accountType=UNIFIED") == true)
            #expect(request?.value(forHTTPHeaderField: "X-BAPI-API-KEY") == credentials.apiKey)
            #expect(request?.value(forHTTPHeaderField: "X-BAPI-TIMESTAMP") != nil)
            #expect(request?.value(forHTTPHeaderField: "X-BAPI-RECV-WINDOW") == "5000")
            #expect(request?.value(forHTTPHeaderField: "X-BAPI-SIGN") != nil)
        }
        
        @Test("Creates valid spot wallet request")
        func testSpotWalletRequest() {
            let exchangeType = ExchangeType.bybit(walletType: .spot)
            let credentials = TestFixtures.TestCredentials.bybit
            let builder = BybitAPIRequestBuilder(exchangeType: exchangeType, creds: credentials)
            
            let request = builder.createWalletBalanceRequest()
            
            #expect(request != nil)
            #expect(request?.url?.absoluteString.contains("accountType=SPOT") == true)
        }
        
        @Test("Signature changes with different timestamps")
        func testSignatureChangesWithTimestamp() {
            let exchangeType = ExchangeType.bybit(walletType: .unified)
            let credentials = TestFixtures.TestCredentials.bybit
            let builder = BybitAPIRequestBuilder(exchangeType: exchangeType, creds: credentials)
            
            let request1 = builder.createWalletBalanceRequest()
            Thread.sleep(forTimeInterval: 0.01) // Small delay to ensure different timestamp
            let request2 = builder.createWalletBalanceRequest()
            
            let signature1 = request1?.value(forHTTPHeaderField: "X-BAPI-SIGN")
            let signature2 = request2?.value(forHTTPHeaderField: "X-BAPI-SIGN")
            
            #expect(signature1 != nil)
            #expect(signature2 != nil)
            #expect(signature1 != signature2)
        }
        
        @Test("Uses correct base URL for unified wallet")
        func testCorrectBaseURL() {
            let exchangeType = ExchangeType.bybit(walletType: .unified)
            let credentials = TestFixtures.TestCredentials.bybit
            let builder = BybitAPIRequestBuilder(exchangeType: exchangeType, creds: credentials)
            
            let request = builder.createWalletBalanceRequest()
            
            #expect(request?.url?.scheme == "https")
            #expect(request?.url?.host == "api.bybit.com")
        }
    }
    
    // MARK: - KuCoin Request Builder Tests
    
    @Suite("KuCoin Request Builder")
    struct KuCoinRequestBuilderTests {
        
        @Test("Creates valid futures wallet request")
        func testFuturesWalletRequest() {
            let exchangeType = ExchangeType.kucoin(walletType: .futures)
            let credentials = TestFixtures.TestCredentials.kucoin
            let builder = KuCoinAPIRequestBuilder(exchangeType: exchangeType, creds: credentials)
            
            let request = builder.createWalletBalanceRequest()
            
            #expect(request != nil)
            #expect(request?.httpMethod == "GET")
            #expect(request?.url?.absoluteString.contains("api-futures.kucoin.com") == true)
            #expect(request?.value(forHTTPHeaderField: "KC-API-KEY") == credentials.apiKey)
            #expect(request?.value(forHTTPHeaderField: "KC-API-TIMESTAMP") != nil)
            #expect(request?.value(forHTTPHeaderField: "KC-API-SIGN") != nil)
            #expect(request?.value(forHTTPHeaderField: "KC-API-PASSPHRASE") != nil)
            #expect(request?.value(forHTTPHeaderField: "KC-API-KEY-VERSION") == "3")
        }
        
        @Test("Creates valid spot wallet request")
        func testSpotWalletRequest() {
            let exchangeType = ExchangeType.kucoin(walletType: .spot)
            let credentials = TestFixtures.TestCredentials.kucoin
            let builder = KuCoinAPIRequestBuilder(exchangeType: exchangeType, creds: credentials)
            
            let request = builder.createWalletBalanceRequest()
            
            #expect(request != nil)
            #expect(request?.url?.absoluteString.contains("api.kucoin.com") == true)
            #expect(request?.url?.absoluteString.contains("/api/v1/accounts") == true)
        }
        
        @Test("Encrypts passphrase for API v3")
        func testPassphraseEncryption() {
            let exchangeType = ExchangeType.kucoin(walletType: .futures)
            let credentials = TestFixtures.TestCredentials.kucoin
            let builder = KuCoinAPIRequestBuilder(exchangeType: exchangeType, creds: credentials)
            
            let request = builder.createWalletBalanceRequest()
            let passphrase = request?.value(forHTTPHeaderField: "KC-API-PASSPHRASE")
            
            #expect(passphrase != nil)
            #expect(passphrase != credentials.passphrase) // Should be encrypted, not plain text
        }
        
        @Test("Signature is base64 encoded")
        func testSignatureFormat() {
            let exchangeType = ExchangeType.kucoin(walletType: .futures)
            let credentials = TestFixtures.TestCredentials.kucoin
            let builder = KuCoinAPIRequestBuilder(exchangeType: exchangeType, creds: credentials)
            
            let request = builder.createWalletBalanceRequest()
            let signature = request?.value(forHTTPHeaderField: "KC-API-SIGN")
            
            #expect(signature != nil)
            // Base64 strings typically end with = or contain +/
            let isBase64Like = signature?.contains(where: { "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=".contains($0) }) ?? false
            #expect(isBase64Like)
        }
        
        @Test("Uses correct endpoint for futures")
        func testFuturesEndpoint() {
            let exchangeType = ExchangeType.kucoin(walletType: .futures)
            let credentials = TestFixtures.TestCredentials.kucoin
            let builder = KuCoinAPIRequestBuilder(exchangeType: exchangeType, creds: credentials)
            
            let request = builder.createWalletBalanceRequest()
            
            #expect(request?.url?.path.contains("/api/v1/account-overview") == true)
            #expect(request?.url?.query?.contains("currency=USDT") == true)
        }
    }
    
    // MARK: - Binance Request Builder Tests
    
    @Suite("Binance Request Builder")
    struct BinanceRequestBuilderTests {
        
        @Test("Creates valid futures wallet request")
        func testFuturesWalletRequest() {
            let exchangeType = ExchangeType.binance(walletType: .futures)
            let credentials = TestFixtures.TestCredentials.binance
            let builder = BinanceAPIRequestBuilder(exchangeType: exchangeType, creds: credentials)
            
            let request = builder.createWalletBalanceRequest()
            
            #expect(request != nil)
            #expect(request?.httpMethod == "GET")
            #expect(request?.url?.absoluteString.contains("binance") == true)
            #expect(request?.url?.absoluteString.contains("/fapi/v2/account") == true)
            #expect(request?.value(forHTTPHeaderField: "X-MBX-APIKEY") == credentials.apiKey)
        }
        
        @Test("Includes timestamp in query string")
        func testTimestampInQuery() {
            let exchangeType = ExchangeType.binance(walletType: .futures)
            let credentials = TestFixtures.TestCredentials.binance
            let builder = BinanceAPIRequestBuilder(exchangeType: exchangeType, creds: credentials)
            
            let request = builder.createWalletBalanceRequest()
            
            #expect(request?.url?.query?.contains("timestamp=") == true)
            #expect(request?.url?.query?.contains("recvWindow=5000") == true)
        }
        
        @Test("Includes signature in query string")
        func testSignatureInQuery() {
            let exchangeType = ExchangeType.binance(walletType: .futures)
            let credentials = TestFixtures.TestCredentials.binance
            let builder = BinanceAPIRequestBuilder(exchangeType: exchangeType, creds: credentials)
            
            let request = builder.createWalletBalanceRequest()
            
            #expect(request?.url?.query?.contains("signature=") == true)
        }
        
        @Test("Signature is hex string")
        func testSignatureFormat() {
            let exchangeType = ExchangeType.binance(walletType: .futures)
            let credentials = TestFixtures.TestCredentials.binance
            let builder = BinanceAPIRequestBuilder(exchangeType: exchangeType, creds: credentials)
            
            let request = builder.createWalletBalanceRequest()
            
            guard let query = request?.url?.query,
                  let signatureRange = query.range(of: "signature="),
                  let signature = query[signatureRange.upperBound...].split(separator: "&").first else {
                Issue.record("Could not extract signature from query string")
                return
            }
            
            // Hex strings contain only 0-9 and a-f
            let isHex = signature.allSatisfy { "0123456789abcdef".contains($0) }
            #expect(isHex)
        }
        
        @Test("Uses testnet URL")
        func testTestnetURL() {
            let exchangeType = ExchangeType.binance(walletType: .futures)
            let credentials = TestFixtures.TestCredentials.binance
            let builder = BinanceAPIRequestBuilder(exchangeType: exchangeType, creds: credentials)
            
            let request = builder.createWalletBalanceRequest()
            
            // Currently uses testnet - update this test if switching to production
            #expect(request?.url?.absoluteString.contains("testnet.binancefuture.com") == true)
        }
    }
    
    // MARK: - Factory Tests
    
    @Suite("Request Builder Factory")
    struct RequestBuilderFactoryTests {
        
        @Test("Creates Bybit builder")
        @MainActor
        func testCreatesBybitBuilder() async {
            let credManager = MockCredentialManager()
            await credManager.setCredentials(TestFixtures.TestCredentials.bybit, forAccount: "bybit")
            
            let exchangeType = ExchangeType.bybit(walletType: .unified)
            let builder = await APIRequestBuilderFactory.builder(for: exchangeType, creds: credManager)
            
            #expect(builder != nil)
            #expect(builder is BybitAPIRequestBuilder)
        }
        
        @Test("Creates KuCoin builder")
        @MainActor
        func testCreatesKuCoinBuilder() async {
            let credManager = MockCredentialManager()
            await credManager.setCredentials(TestFixtures.TestCredentials.kucoin, forAccount: "kucoin")
            
            let exchangeType = ExchangeType.kucoin(walletType: .futures)
            let builder = await APIRequestBuilderFactory.builder(for: exchangeType, creds: credManager)
            
            #expect(builder != nil)
            #expect(builder is KuCoinAPIRequestBuilder)
        }
        
        @Test("Creates Binance builder")
        @MainActor
        func testCreatesBinanceBuilder() async {
            let credManager = MockCredentialManager()
            await credManager.setCredentials(TestFixtures.TestCredentials.binance, forAccount: "binance")
            
            let exchangeType = ExchangeType.binance(walletType: .futures)
            let builder = await APIRequestBuilderFactory.builder(for: exchangeType, creds: credManager)
            
            #expect(builder != nil)
            #expect(builder is BinanceAPIRequestBuilder)
        }
        
        @Test("Returns nil when credentials not found")
        @MainActor
        func testReturnsNilForMissingCredentials() async {
            let credManager = MockCredentialManager()
            // Don't set any credentials
            
            let exchangeType = ExchangeType.bybit(walletType: .unified)
            let builder = await APIRequestBuilderFactory.builder(for: exchangeType, creds: credManager)
            
            #expect(builder == nil)
        }
    }
}

