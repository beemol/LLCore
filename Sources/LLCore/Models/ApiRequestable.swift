//
//  ApiRequestable.swift
//  LLCore
//
//  Created by Aleh Fiodarau on 02/12/2025.
//

public protocol ApiRequestable {
    var displayName: String { get }
    var baseURL: String { get }
    var endpoint: String { get }
}

extension ExchangeType: ApiRequestable {
    public var displayName: String {
        self.name.rawValue
    }
    
    public var baseURL: String {
        switch self {
        case .bybit (let walletType):
            switch walletType {
            case .spot:
                return "https://api.bybit.com"
            case .futures:
                return "xxx"
            case .unified:
                return "https://api.bybit.com"
            }
        case .kucoin (let walletType):
            switch walletType {
            case .spot:
                return "https://api.kucoin.com"
            case .futures:
                return "https://api-futures.kucoin.com"
            case .unified:
                return "xxx" // TODO: Placeholder, KuCoin doesn't have a unified wallet type
            }
        case .binance:
            switch walletType {
            case .spot:
                return "xxx"
            case .futures:
                return "https://fapi.binance.com"
            case .unified:
                return "xxx" // TODO: Placeholder, binance doesn't have a unified wallet type
            }
        }
    }
    
    public var endpoint: String {
        switch self {
        case .bybit:
            switch walletType {
            case .spot:
                return "/v5/account/wallet-balance?accountType=SPOT"
            case .futures:
                return "xxx"
            case .unified:
                return "/v5/account/wallet-balance?accountType=UNIFIED"
            }
        case .kucoin (let walletType):
            switch walletType {
            case .spot:
                return "/api/v1/accounts?type=main"
            case .futures:
                return "/api/v1/account-overview?currency=USDT"
            case .unified:
                return "xxx" // TODO: Placeholder, KuCoin doesn't have a unified wallet type
            }
        case .binance:
            switch walletType {
            case .spot:
                return "xxx"
            case .futures:
                return "/fapi/v2/account"
            case .unified:
                return "xxx"
            }
        }
    }
}
