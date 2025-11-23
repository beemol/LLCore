//
//  BBAPIServiceTests.swift
//  bbtickerTests
//
//  Created by GitHub Copilot on 04/10/2025.
//

import XCTest
import Foundation
import LLApiService
@testable import bbticker

@MainActor
class BBAPIServiceTests: XCTestCase {
    
    @MainActor
    private lazy var mockCredentialManager: CredentialManagerProtocol = MockCredentialManager()
    
    @MainActor
    private lazy var mockURLSession = MockURLSession()
    
    @MainActor
    private lazy var mockSettingsService = MockSettingsService()
    
//    @MainActor
//    private lazy var apiService = BBAPIService(
//        credentialManager: mockCredentialManager,
//        settingsService: mockSettingsService,
//        urlSession: mockURLSession
//    )
    
    @MainActor
    private lazy var apiService = LLAPIServiceWrapper(
        credentialManager: mockCredentialManager,
        settingsService: mockSettingsService, urlSession: mockURLSession
    )
    
    // MARK: - Application-Level Error Detection Tests (HTTP 200 with errors)
    
    func testBybitAPIKeyExpiredError() async {
        // Given: Bybit returns HTTP 200 with API key expired error
        let errorResponse = """
        {
            "retCode": 33004,
            "retMsg": "Your api key has expired.",
            "result": {},
            "retExtInfo": {},
            "time": 1759564016973
        }
        """
        
        setupMockResponse(data: errorResponse, statusCode: 200, url: "https://api.bybit.com")
        
        // When & Then
        do {
            _ = try await apiService.fetchWalletBalance(for: .bybit(walletType: .unified))
            XCTFail("Expected APIDomainError to be thrown")
        } catch let error as APIDomainError {
            switch error {
            case .keyRevokedOrInactive(let context):
                XCTAssertEqual(context.apiCode, "33004")
                XCTAssertEqual(context.rawMessage, "Your api key has expired.")
                XCTAssertEqual(context.exchange, .bybit(walletType: .unified))
                XCTAssertEqual(context.httpStatus, 200)
            default:
                XCTFail("Expected keyRevokedOrInactive error, got \(error)")
            }
        } catch {
            XCTFail("Expected APIDomainError, got \(error)")
        }
    }
    
    func testBybitInvalidSignatureError() async {
        // Given: Bybit returns HTTP 200 with signature error
        let errorResponse = """
        {
            "retCode": 10004,
            "retMsg": "Invalid signature",
            "result": {},
            "retExtInfo": {},
            "time": 1759564016973
        }
        """
        
        setupMockResponse(data: errorResponse, statusCode: 200)
        
        do {
            _ = try await apiService.fetchWalletBalance(for: .bybit(walletType: .unified))
            XCTFail("Expected APIDomainError to be thrown")
        } catch let error as APIDomainError {
            switch error {
            case .signatureInvalid(let context):
                XCTAssertEqual(context.apiCode, "10004")
                XCTAssertEqual(context.rawMessage, "Invalid signature")
                XCTAssertEqual(context.exchange, .bybit(walletType: .unified))
            default:
                XCTFail("Expected signatureInvalid error, got \(error)")
            }
        } catch {
            XCTFail("Expected APIDomainError, got \(error)")
        }
    }
    
    func testBybitIPNotAllowedError() async {
        // Given: Bybit returns HTTP 200 with IP whitelist error
        let errorResponse = """
        {
            "retCode": 10006,
            "retMsg": "IP address not in whitelist",
            "result": {},
            "retExtInfo": {},
            "time": 1759564016973
        }
        """
        
        setupMockResponse(data: errorResponse, statusCode: 200)
        
        do {
            _ = try await apiService.fetchWalletBalance(for: .bybit(walletType: .unified))
            XCTFail("Expected APIDomainError to be thrown")
        } catch let error as APIDomainError {
            switch error {
            case .ipNotAllowed(let context):
                XCTAssertEqual(context.apiCode, "10006")
                XCTAssertEqual(context.rawMessage, "IP address not in whitelist")
            default:
                XCTFail("Expected ipNotAllowed error, got \(error)")
            }
        } catch {
            XCTFail("Expected APIDomainError, got \(error)")
        }
    }
    
    func testBybitRateLimitedError() async {
        // Given: Bybit returns HTTP 200 with rate limit error
        let errorResponse = """
        {
            "retCode": 10016,
            "retMsg": "Too many requests",
            "result": {},
            "retExtInfo": {},
            "time": 1759564016973
        }
        """
        
        setupMockResponse(data: errorResponse, statusCode: 200)
        
        do {
            _ = try await apiService.fetchWalletBalance(for: .bybit(walletType: .unified))
            XCTFail("Expected APIDomainError to be thrown")
        } catch let error as APIDomainError {
            switch error {
            case .rateLimited(let context):
                XCTAssertEqual(context.apiCode, "10016")
                XCTAssertEqual(context.rawMessage, "Too many requests")
            default:
                XCTFail("Expected rateLimited error, got \(error)")
            }
        } catch {
            XCTFail("Expected APIDomainError, got \(error)")
        }
    }
    
    func testBybitPermissionDeniedError() async {
        // Given: Bybit returns HTTP 200 with permission error
        let errorResponse = """
        {
            "retCode": 10018,
            "retMsg": "Permission denied for this API",
            "result": {},
            "retExtInfo": {},
            "time": 1759564016973
        }
        """
        
        setupMockResponse(data: errorResponse, statusCode: 200)
        
        do {
            _ = try await apiService.fetchWalletBalance(for: .bybit(walletType: .unified))
            XCTFail("Expected APIDomainError to be thrown")
        } catch let error as APIDomainError {
            switch error {
            case .permissionDenied(let context):
                XCTAssertEqual(context.apiCode, "10018")
                XCTAssertEqual(context.rawMessage, "Permission denied for this API")
            default:
                XCTFail("Expected permissionDenied error, got \(error)")
            }
        } catch {
            XCTFail("Expected APIDomainError, got \(error)")
        }
    }
    
    func testBybitUnknownError() async {
        // Given: Bybit returns HTTP 200 with unknown error code
        let errorResponse = """
        {
            "retCode": 99999,
            "retMsg": "Unknown error occurred",
            "result": {},
            "retExtInfo": {},
            "time": 1759564016973
        }
        """
        
        setupMockResponse(data: errorResponse, statusCode: 200)
        
        do {
            _ = try await apiService.fetchWalletBalance(for: .bybit(walletType: .unified))
            XCTFail("Expected APIDomainError to be thrown")
        } catch let error as APIDomainError {
            switch error {
            case .unknown(let context):
                XCTAssertEqual(context.apiCode, "99999")
                XCTAssertEqual(context.rawMessage, "Unknown error occurred")
            default:
                XCTFail("Expected unknown error, got \(error)")
            }
        } catch {
            XCTFail("Expected APIDomainError, got \(error)")
        }
    }
    
    // MARK: - KuCoin Application-Level Error Tests
    
    func testKuCoinAPIKeyNotExistsError() async {
        // Given: KuCoin returns HTTP 200 with API key error
        let errorResponse = """
        {
            "code": "400003",
            "msg": "KC-API-KEY not exists"
        }
        """
        
        setupMockResponse(data: errorResponse, statusCode: 200)
        
        do {
            _ = try await apiService.fetchWalletBalance(for: .kucoin(walletType: .futures))
            XCTFail("Expected APIDomainError to be thrown")
        } catch let error as APIDomainError {
            switch error {
            case .invalidCredentials(let context):
                XCTAssertEqual(context.apiCode, "400003")
                XCTAssertEqual(context.rawMessage, "KC-API-KEY not exists")
                XCTAssertEqual(context.exchange, .kucoin(walletType: .futures))
            default:
                XCTFail("Expected invalidCredentials error, got \(error)")
            }
        } catch {
            XCTFail("Expected APIDomainError, got \(error)")
        }
    }
    
    func testKuCoinInvalidSignatureError() async {
        // Given: KuCoin returns HTTP 200 with signature error
        let errorResponse = """
        {
            "code": "400005",
            "msg": "KC-API-SIGN Invalid"
        }
        """
        
        setupMockResponse(data: errorResponse, statusCode: 200)
        
        do {
            _ = try await apiService.fetchWalletBalance(for: .kucoin(walletType: .futures))
            XCTFail("Expected APIDomainError to be thrown")
        } catch let error as APIDomainError {
            switch error {
            case .signatureInvalid(let context):
                XCTAssertEqual(context.apiCode, "400005")
                XCTAssertEqual(context.rawMessage, "KC-API-SIGN Invalid")
            default:
                XCTFail("Expected signatureInvalid error, got \(error)")
            }
        } catch {
            XCTFail("Expected APIDomainError, got \(error)")
        }
    }
    
    func testKuCoinRateLimitedError() async {
        // Given: KuCoin returns HTTP 200 with rate limit error
        let errorResponse = """
        {
            "code": "429000",
            "msg": "Too Many Requests"
        }
        """
        
        setupMockResponse(data: errorResponse, statusCode: 200)
        
        do {
            _ = try await apiService.fetchWalletBalance(for: .kucoin(walletType: .futures))
            XCTFail("Expected APIDomainError to be thrown")
        } catch let error as APIDomainError {
            switch error {
            case .rateLimited(let context):
                XCTAssertEqual(context.apiCode, "429000")
                XCTAssertEqual(context.rawMessage, "Too Many Requests")
            default:
                XCTFail("Expected rateLimited error, got \(error)")
            }
        } catch {
            XCTFail("Expected APIDomainError, got \(error)")
        }
    }
    
    // MARK: - Binance Application-Level Error Tests
    
    func testBinanceInvalidAPIKeyError() async {
        // Given: Binance returns HTTP 200 with API key error
        let errorResponse = """
        {
            "code": -2014,
            "msg": "API-key format invalid."
        }
        """
        
        setupMockResponse(data: errorResponse, statusCode: 200)
        
        do {
            _ = try await apiService.fetchWalletBalance(for: .binance(walletType: .futures))
            XCTFail("Expected APIDomainError to be thrown")
        } catch let error as APIDomainError {
            switch error {
            case .invalidCredentials(let context):
                XCTAssertEqual(context.apiCode, "-2014")
                XCTAssertEqual(context.rawMessage, "API-key format invalid.")
                XCTAssertEqual(context.exchange, .binance(walletType: .futures))
            default:
                XCTFail("Expected invalidCredentials error, got \(error)")
            }
        } catch {
            XCTFail("Expected APIDomainError, got \(error)")
        }
    }
    
    func testBinanceInvalidSignatureError() async {
        // Given: Binance returns HTTP 200 with signature error
        let errorResponse = """
        {
            "code": -1022,
            "msg": "Signature for this request is not valid."
        }
        """
        
        setupMockResponse(data: errorResponse, statusCode: 200)
        
        do {
            _ = try await apiService.fetchWalletBalance(for: .binance(walletType: .futures))
            XCTFail("Expected APIDomainError to be thrown")
        } catch let error as APIDomainError {
            switch error {
            case .signatureInvalid(let context):
                XCTAssertEqual(context.apiCode, "-1022")
                XCTAssertEqual(context.rawMessage, "Signature for this request is not valid.")
            default:
                XCTFail("Expected signatureInvalid error, got \(error)")
            }
        } catch {
            XCTFail("Expected APIDomainError, got \(error)")
        }
    }
    
    func testBinanceTimestampError() async {
        // Given: Binance returns HTTP 200 with timestamp error
        let errorResponse = """
        {
            "code": -1021,
            "msg": "Timestamp for this request is outside of the recvWindow."
        }
        """
        
        setupMockResponse(data: errorResponse, statusCode: 200)
        
        do {
            _ = try await apiService.fetchWalletBalance(for: .binance(walletType: .futures))
            XCTFail("Expected APIDomainError to be thrown")
        } catch let error as APIDomainError {
            switch error {
            case .timestampOutOfRange(let context):
                XCTAssertEqual(context.apiCode, "-1021")
                XCTAssertEqual(context.rawMessage, "Timestamp for this request is outside of the recvWindow.")
            default:
                XCTFail("Expected timestampOutOfRange error, got \(error)")
            }
        } catch {
            XCTFail("Expected APIDomainError, got \(error)")
        }
    }
    
    // MARK: - Success Cases (No Application Errors)
    
    func testBybitUnifiedSuccess_ParsesTotals() async {
        // Given: Bybit unified-style totals in result
        let successResponse = """
        {
            "retCode": 0,
            "retMsg": "OK",
            "result": {
                "totalEquity": "1000.00",
                "totalWalletBalance": "900.00"
            },
            "retExtInfo": {},
            "time": 1759564016973
        }
        """
        
        setupMockResponse(data: successResponse, statusCode: 200)
        
        do {
            let data = try await apiService.fetchWalletBalance(for: .bybit(walletType: .unified))
            XCTAssertEqual(data.totalEquity, "1000.00")
            XCTAssertEqual(data.walletBalance, "900.00")
        } catch {
            XCTFail("Expected successful parse, got error: \(error)")
        }
    }
    
    func testKuCoinSuccessResponse_NoApplicationError() async {
        // Given: KuCoin returns HTTP 200 with success (code = "200000")
        let successResponse = """
        {
            "code": "200000",
            "data": [
                {
                    "currency": "USDT",
                    "balance": "1000.00",
                    "available": "1000.00"
                }
            ]
        }
        """
        
        setupMockResponse(data: successResponse, statusCode: 200)
        
        do {
            _ = try await apiService.fetchWalletBalance(for: .kucoin(walletType: .unified))
        } catch let error as APIDomainError {
            XCTFail("Should not throw APIDomainError for successful response, got \(error)")
        } catch {
            // Expected parse error - this is fine, we just want to ensure no APIDomainError
            XCTAssert(error is APIError)
        }
    }
    
    // MARK: - Edge Cases
    
    func testInvalidJSONResponse_NoApplicationError() async {
        // Given: Invalid JSON response
        let invalidResponse = "{ invalid json"
        
        setupMockResponse(data: invalidResponse, statusCode: 200)
        
        do {
            _ = try await apiService.fetchWalletBalance(for: .bybit(walletType: .unified))
            XCTFail("Expected parse error")
        } catch let error as APIDomainError {
            XCTFail("Should not throw APIDomainError for invalid JSON, got \(error)")
        } catch {
            // Expected - invalid JSON should result in parse error, not application error
            XCTAssert(error is APIError)
        }
    }
    
    func testEmptyResponse_NoApplicationError() async {
        // Given: Empty response
        setupMockResponse(data: "", statusCode: 200)
        
        do {
            _ = try await apiService.fetchWalletBalance(for: .bybit(walletType: .unified))
            XCTFail("Expected parse error")
        } catch let error as APIDomainError {
            XCTFail("Should not throw APIDomainError for empty response, got \(error)")
        } catch {
            // Expected - empty response should result in parse error
            XCTAssert(error is APIError)
        }
    }
    
    // MARK: - Bybit SPOT Parsing
    
    func testBybitSpotParsing_USDT() async {
        // Given: Bybit returns HTTP 200 with SPOT account list and USDT coin walletBalance
        let successResponse = """
        {
            "retCode": 0,
            "retMsg": "OK",
            "result": {
                "list": [
                    {
                        "accountType": "SPOT",
                        "coin": [
                            {"coin": "BTC", "walletBalance": "0.0000"},
                            {"coin": "USDT", "walletBalance": "123.45"}
                        ]
                    }
                ]
            },
            "retExtInfo": {},
            "time": 1759564016973
        }
        """
        
        setupMockResponse(data: successResponse, statusCode: 200)
        
        do {
            let data = try await apiService.fetchWalletBalance(for: .bybit(walletType: .unified))
            XCTAssertEqual(data.walletBalance, "123.45")
            XCTAssertEqual(data.totalEquity, "123.45") // equity falls back to walletBalance for SPOT
        } catch {
            XCTFail("Expected successful parse, got error: \(error)")
        }
    }
    
    // MARK: - HTTP Error Cases (Still Work)
    
    func testHTTPErrorStillMapped() async {
        // Given: HTTP 401 error (should still be handled by existing HTTP error mapping)
        let errorResponse = """
        {
            "error": "Unauthorized"
        }
        """
        
        setupMockResponse(data: errorResponse, statusCode: 401)
        
        do {
            _ = try await apiService.fetchWalletBalance(for: .bybit(walletType: .unified))
            XCTFail("Expected APIDomainError to be thrown")
        } catch let error as APIDomainError {
            // Should still map HTTP errors correctly - the exact error type depends on APIErrorMapper
            XCTAssertNotNil(error)
        } catch {
            XCTFail("Expected APIDomainError for HTTP error, got \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupMockResponse(data: String, statusCode: Int, url: String = "https://api.test.com") {
        mockURLSession.mockData = data.data(using: .utf8)
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: url)!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )
        
        // Setup mock request builder to return a valid request
        // Mock the request builder factory to return our mock
        let mockRequestBuilder = MockAPIRequestBuilder()
        APIRequestBuilderFactory.mockBuilder = mockRequestBuilder
        mockRequestBuilder.mockRequest = URLRequest(url: URL(string: url)!)
    }
}

// MARK: - Mock URL Session
@MainActor
class MockURLSession: URLSessionProtocol {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let error = mockError {
            throw error
        }
        
        guard let data = mockData, let response = mockResponse else {
            throw URLError(.badServerResponse)
        }
        
        return (data, response)
    }
}

// MARK: - Mock Request Builder

class MockAPIRequestBuilder {
    var mockRequest: URLRequest?
    
    func createWalletBalanceRequest() -> URLRequest? {
        return mockRequest
    }
}

// MARK: - Mock Factory Extension

@MainActor
private extension APIRequestBuilderFactory {
    static var mockBuilder: MockAPIRequestBuilder?
    
    static func builder(for exchangeType: ExchangeType, creds: CredentialManagerProtocol) async -> MockAPIRequestBuilder? {
        return MockAPIRequestBuilder()
    }
}
