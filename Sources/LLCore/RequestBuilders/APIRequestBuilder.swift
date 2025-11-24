//
//  APIRequestBuilder.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 06/09/2025.
//

import Foundation
import LLApiService

public protocol CredentialManagerProtocol: Actor {
    func getCredentials(forAccount account: String) async throws -> Credentials
    func saveCredentials(key: String, secret: String, passphrase: String, forAccount account: String) async -> OSStatus
    func deleteCredentials(forAccount account: String) async -> OSStatus
}

public protocol APIRequestBuilder: LLAPIRequestBuilder {
    func createWalletBalanceRequest() -> URLRequest?
}

public extension APIRequestBuilder {
    func createRequest() throws -> URLRequest {
        return createWalletBalanceRequest() ?? URLRequest(url: URL(string: "")!)
    }
}

@MainActor
public struct APIRequestBuilderFactory {
    public static func builder(for exchangeType: ExchangeType, creds: CredentialManagerProtocol) async -> APIRequestBuilder? {
        let accountName = exchangeType.displayName

        guard let credentials = try? await creds.getCredentials(forAccount: accountName) else { return nil }

        switch exchangeType {
        case .bybit:
            return BybitAPIRequestBuilder(exchangeType: exchangeType, creds: credentials)
        case .kucoin:
            return KuCoinAPIRequestBuilder(exchangeType: exchangeType, creds: credentials)
        case .binance:
            return BinanceAPIRequestBuilder(exchangeType: exchangeType, creds: credentials)
        }
    }
}

// MARK: concrete implementations
struct BybitAPIRequestBuilder: APIRequestBuilder {
    public let exchangeType: ExchangeType
    public let creds: Credentials
    
    public init(exchangeType: ExchangeType, creds: Credentials) {
        self.exchangeType = exchangeType
        self.creds = creds
    }
    
    public func createWalletBalanceRequest() -> URLRequest? {
        // Use endpoint as-is; it already contains the accountType query for spot/unified
        let urlString = exchangeType.baseURL + exchangeType.endpoint
        guard let url = URL(string: urlString) else { return nil }
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let recvWindow = "5000"
        // Sign with accountType matching selected wallet
        let accountTypeParam: String = (exchangeType.walletType == .spot) ? "SPOT" : "UNIFIED"
        let queryString = "accountType=\(accountTypeParam)"
        let signaturePayload = timestamp + creds.apiKey + recvWindow + queryString
        let signature = signaturePayload.hmacSHA256(key: creds.apiSecret)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(creds.apiKey, forHTTPHeaderField: "X-BAPI-API-KEY")
        request.setValue(timestamp, forHTTPHeaderField: "X-BAPI-TIMESTAMP")
        request.setValue(recvWindow, forHTTPHeaderField: "X-BAPI-RECV-WINDOW")
        request.setValue(signature, forHTTPHeaderField: "X-BAPI-SIGN")
        return request
    }
}

struct KuCoinAPIRequestBuilder: APIRequestBuilder {
    public let exchangeType: ExchangeType
    public let creds: Credentials
    public let apiVersion: String = "3"
    
    public init(exchangeType: ExchangeType, creds: Credentials) {
        self.exchangeType = exchangeType
        self.creds = creds
    }
    
    public func createWalletBalanceRequest() -> URLRequest? {
        let urlString = exchangeType.baseURL + exchangeType.endpoint
        guard let url = URL(string: urlString) else { return nil }
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let method = "GET"
        let endpoint = exchangeType.endpoint
        
        // For KuCoin API v3, the signature format is: timestamp + method + endpoint + body
        // For GET requests, body is empty
        let signaturePayload = timestamp + method + endpoint
        let signatureHex = signaturePayload.hmacSHA256(key: creds.apiSecret)
        // Convert hex signature to base64
        let signatureData = hexStringToData(signatureHex)
        let signature = signatureData.base64EncodedString()
        
        // Handle passphrase based on API version
        let requestPassphrase: String
        
        // For API v3, passphrase needs to be encrypted with HMAC-sha256 and then base64 encoded
        if apiVersion == "3", let encryptedPassphrase = creds.passphrase?.hmacSHA256(key: creds.apiSecret) {
            // Convert hex string to data and then base64 encode
            let hexData = hexStringToData(encryptedPassphrase)
            requestPassphrase = hexData.base64EncodedString()
        } else {
            // For older versions, passphrase needs to be base64 encoded
            requestPassphrase = creds.passphrase?.data(using: .utf8)?.base64EncodedString() ?? creds.passphrase ?? ""
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(creds.apiKey, forHTTPHeaderField: "KC-API-KEY")
        request.setValue(timestamp, forHTTPHeaderField: "KC-API-TIMESTAMP")
        request.setValue(signature, forHTTPHeaderField: "KC-API-SIGN")
        request.setValue(requestPassphrase, forHTTPHeaderField: "KC-API-PASSPHRASE")
        request.setValue(apiVersion, forHTTPHeaderField: "KC-API-KEY-VERSION")
        
        return request
    }
}

struct BinanceAPIRequestBuilder: APIRequestBuilder {
    public let exchangeType: ExchangeType
    public let creds: Credentials
    
    public init(exchangeType: ExchangeType, creds: Credentials) {
        self.exchangeType = exchangeType
        self.creds = creds
    }
    
    public func createWalletBalanceRequest() -> URLRequest? {
        // Binance USDT-M Futures account (equity) endpoint
        // GET /fapi/v2/account with signed query: timestamp & optional recvWindow
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let recvWindow = "5000"
        let queryString = "timestamp=\(timestamp)&recvWindow=\(recvWindow)"
        let signature = queryString.hmacSHA256(key: creds.apiSecret)
        
        let urlString = "https://testnet.binancefuture.com/fapi/v2/account?\(queryString)&signature=\(signature)"
        //let urlString = "https://fapi.binance.com/fapi/v2/account?\(queryString)&signature=\(signature)"
        guard let url = URL(string: urlString) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(creds.apiKey, forHTTPHeaderField: "X-MBX-APIKEY")
        return request
    }
}
