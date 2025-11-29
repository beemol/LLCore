//
//  PollingStrategy.swift
//  LLCore
//
//  Created by Aleh Fiodarau on 29/11/2025.
//

import Foundation

@MainActor
final public class PollingStrategy<Output> {
    public typealias FrequencyProvider = () -> Double
    public typealias FetchHandler = () async throws -> Output
    public typealias UpdateHandler = (Output) -> Void
    public typealias ErrorHandler = (Error) -> Void
    
    private let getFrequency: FrequencyProvider
    private let fetchHandler: FetchHandler
    private let updateHandler: UpdateHandler
    private let errorHandler: ErrorHandler

    // reconnection controls
    private var reconnectionAttempts = 0
    private var maxReconnectionAttempts = 5
    private var reconnectionDelay: Double = 1.0
    
    // query closure to check if connection is in proper state (i.e. .connected)
    private let shouldContinue: () -> Bool
    
    private var pollingTask: Task<Void, Never>?
    
    public init(frequencyProvider: @escaping FrequencyProvider,
         shouldContinue: @escaping () -> Bool,
         fetchHandler: @escaping FetchHandler,
         updateHandler: @escaping UpdateHandler,
         errorHandler: @escaping ErrorHandler)
    {
        self.getFrequency = frequencyProvider
        self.shouldContinue = shouldContinue
        self.fetchHandler = fetchHandler
        self.updateHandler = updateHandler
        self.errorHandler = errorHandler
    }
    
    public func start() {
        stop()
        
        pollingTask = Task {
            while !Task.isCancelled && shouldContinue() {
                // Use configurable update frequency (convert seconds to nanoseconds)
                let nanoseconds = UInt64(getFrequency() * 1_000_000_000.0)
                try? await Task.sleep(nanoseconds: nanoseconds)
                
                // Check cancellation AND connection status immediately before API call
                // This eliminates the race condition
                guard !Task.isCancelled && shouldContinue() else {
                    break
                }
                
                do {
                    let data = try await fetchHandler()
                    updateHandler(data)

                    // reset reconnection state
                    reconnectionAttempts = 0
                    reconnectionDelay = 1.0
                } catch {
                    errorHandler(error)
                    
                    guard reconnectionAttempts < maxReconnectionAttempts else {
                        // Max attempts reached, stop polling
                        break
                    }
                    reconnectionAttempts += 1
                    reconnectionDelay *= 2
                    
                    // Wait with exponential backoff before next attempt
                    let backoffNanos = UInt64(reconnectionDelay * 1_000_000_000.0)
                    try? await Task.sleep(nanoseconds: backoffNanos)
                }
            }
        }
    }
    
    public func stop() {
        pollingTask?.cancel()
        pollingTask = nil
    }
}
