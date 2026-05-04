//
//  URLSession.swift
//  
//
//  Created by Ben Gottlieb on 12/28/21.
//

import Foundation

enum SuiteURLSessionError: Error { case unknownErrorOccurred }

@available(OSX 10.15, iOS 13.0, tvOS 13, watchOS 6, *)
extension URLSession {
	public func data(for url: URL) async throws -> (Data, URLResponse) {
		try await data(for: URLRequest(url: url))
	}

	public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
		let holder = DataTaskHolder()
		return try await withTaskCancellationHandler {
			try await withCheckedThrowingContinuation { continuation in
				let task = dataTask(with: request) { data, response, error in
					if let err = error {
						continuation.resume(throwing: err)
					} else if let data = data, let resp = response {
						continuation.resume(returning: (data, resp))
					} else {
						continuation.resume(throwing: SuiteURLSessionError.unknownErrorOccurred)
					}
				}
				holder.task = task
				task.resume()
			}
		} onCancel: {
			holder.task?.cancel()
		}
	}
}

private final class DataTaskHolder: @unchecked Sendable {
	private let lock = NSLock()
	private var _task: URLSessionDataTask?
	var task: URLSessionDataTask? {
		get { lock.lock(); defer { lock.unlock() }; return _task }
		set { lock.lock(); defer { lock.unlock() }; _task = newValue }
	}
}
