//
//  Credentials.swift
//  LLCore
//
//  Created by Aleh Fiodarau on 10/7/26.
//

import Foundation

public struct Credentials: Equatable, Sendable {
    public let apiKey: String
    public let apiSecret: String
    public let passphrase: String?
    
    public init(apiKey: String, apiSecret: String, passphrase: String? = nil) {
        self.apiKey = apiKey
        self.apiSecret = apiSecret
        self.passphrase = passphrase
    }
}
