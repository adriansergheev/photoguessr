import Foundation
import Dependencies

public struct StorageClient {
	public var delete: @Sendable (_ fileName: String) throws -> Void
	public var load: @Sendable (_ fileName: String) throws -> Data
	public var save: @Sendable (_ fileName: String, Data) throws -> Void

	public func load<A: Decodable>(_ type: A.Type, from fileName: String) throws -> A {
		try JSONDecoder().decode(A.self, from: self.load(fileName))
	}

	public func save<A: Encodable>(_ data: A, to fileName: String) throws {
		try self.save(fileName, JSONEncoder().encode(data))
	}
}
