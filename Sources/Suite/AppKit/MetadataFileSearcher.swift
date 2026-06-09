//
//  MetadataFileSearcher.swift
//  Suite
//

#if os(macOS)
import Foundation

/// Searches the local filesystem for files matching one or more UTI content types,
/// using `NSMetadataQuery`. Results are sorted by filename.
///
/// Usage:
/// ```swift
/// let searcher = MetadataFileSearcher(contentTypes: ["public.markdown", "net.daringfireball.markdown"])
/// searcher.start()
/// // observe searcher.urls
/// ```
@available(macOS 14, *)
@MainActor
@Observable
public final class MetadataFileSearcher {
	public private(set) var urls: [URL] = []
	public private(set) var isSearching = false

	private let contentTypes: [String]
	private var query: NSMetadataQuery?
	private var observers: [NSObjectProtocol] = []

	public init(contentTypes: [String]) {
		self.contentTypes = contentTypes
	}

	public func start() {
		guard query == nil else { return }
		isSearching = true

		let q = NSMetadataQuery()
		let predicates = contentTypes.map {
			NSPredicate(format: "kMDItemContentTypeTree == %@", $0)
		}
		q.predicate = predicates.count == 1
			? predicates[0]
			: NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
		q.searchScopes = [NSMetadataQueryLocalComputerScope]
		q.notificationBatchingInterval = 0.5
		query = q

		let center = NotificationCenter.default
		observers.append(center.addObserver(forName: .NSMetadataQueryDidUpdate, object: q, queue: .main) { [weak self] _ in
			Task { @MainActor [weak self] in self?.refresh() }
		})
		observers.append(center.addObserver(forName: .NSMetadataQueryDidFinishGathering, object: q, queue: .main) { [weak self] _ in
			Task { @MainActor [weak self] in
				self?.refresh()
				self?.isSearching = false
			}
		})
		q.start()
	}

	public func stop() {
		query?.stop()
		observers.forEach(NotificationCenter.default.removeObserver)
		observers.removeAll()
		query = nil
		isSearching = false
	}

	private func refresh() {
		guard let query else { return }
		query.disableUpdates()
		defer { query.enableUpdates() }
		urls = (0..<query.resultCount).compactMap { i -> URL? in
			guard let item = query.result(at: i) as? NSMetadataItem,
				  let path = item.value(forAttribute: NSMetadataItemPathKey) as? String
			else { return nil }
			return URL(fileURLWithPath: path)
		}.sorted { $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending }
	}
}
#endif
