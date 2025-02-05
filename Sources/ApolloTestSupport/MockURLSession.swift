//
//  MockURLSession.swift
//  ApolloTestSupport
//
//  Copyright © 2019 Apollo GraphQL. All rights reserved.
//

import Foundation
import Apollo
import ApolloCore

public final class MockURLSessionClient: URLSessionClient {

  public private (set) var lastRequest: Atomic<URLRequest?> = Atomic(nil)

  public var data: Data?
  public var response: HTTPURLResponse?
  public var error: Error?
  
  private let callbackQueue: DispatchQueue
  
  public init(callbackQueue: DispatchQueue? = nil) {
    self.callbackQueue = callbackQueue ?? .main
  }

  public override func sendRequest(_ request: URLRequest,
                                   rawTaskCompletionHandler: URLSessionClient.RawCompletion? = nil,
                                   completion: @escaping URLSessionClient.Completion) -> URLSessionTask {
    self.lastRequest.mutate { $0 = request }
        
    // Capture data, response, and error instead of self to ensure we complete with the current state
    // even if it is changed before the block runs.
    callbackQueue.async { [data, response, error] in
      rawTaskCompletionHandler?(data, response, error)
      
      if let error = error {
        completion(.failure(error))
      } else {
        guard let data = data else {
          completion(.failure(URLSessionClientError.dataForRequestNotFound(request: request)))
          return
        }
        
        guard let response = response else {
          completion(.failure(URLSessionClientError.noHTTPResponse(request: request)))
          return
        }
        
        completion(.success((data, response)))
      }
    }
    
  
    let mockTask = URLSessionDataTaskMock()
    return mockTask
  }
}

private final class URLSessionDataTaskMock: URLSessionDataTask {
  override func resume() {
    // No-op
  }
}
