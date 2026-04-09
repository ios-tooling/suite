//
//  SwiftUIView.swift
//
//
//  Created by Ben Gottlieb on 10/15/23.
//

import SwiftUI

extension String: FlowedHStackElement {
	public var isNewLine: Bool { self == "\n" }
	public var offset: CGSize { .zero }
}

public protocol FlowedHStackElement {
	var isNewLine: Bool { get }
	var offset: CGSize { get }
}

extension FlowedHStackElement {
	public var isNewLine: Bool { false }
	public var offset: CGSize { .zero }
}

public protocol FlowedHStackImageElement: Identifiable { }

public struct FlowedHStackImage: View, FlowedHStackImageElement {
	public let id = UUID()
	public let image: Image
	public var body: some View {
		image.renderingMode(.template)
			.offset(y: -0.5)
	}
}

@available(iOS 16, macOS 13, watchOS 9, tvOS 16, *)
struct FlowLayout: Layout {
	var hSpacing: Double
	var vSpacing: Double

	func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
		let rows = computeRows(proposal: proposal, subviews: subviews)
		var height: CGFloat = 0
		for (index, row) in rows.enumerated() {
			let rowHeight = row.map { $0.height }.max() ?? 0
			height += rowHeight
			if index < rows.count - 1 { height += vSpacing }
		}
		return CGSize(width: proposal.width ?? 0, height: height)
	}

	func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
		let rows = computeRows(proposal: proposal, subviews: subviews)
		var y = bounds.minY

		for row in rows {
			let rowHeight = row.map { $0.height }.max() ?? 0
			var x = bounds.minX

			for size in row {
				let subviewIndex = indexOf(size: size, x: x, y: y, rows: rows, bounds: bounds)
				if let subviewIndex, subviewIndex < subviews.count {
					let yOffset = (rowHeight - size.height) / 2
					subviews[subviewIndex].place(at: CGPoint(x: x, y: y + yOffset), proposal: ProposedViewSize(size))
				}
				x += size.width + hSpacing
			}
			y += rowHeight + vSpacing
		}
	}

	private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[CGSize]] {
		let width = proposal.width ?? .infinity
		var rows: [[CGSize]] = []
		var currentRow: [CGSize] = []
		var currentWidth: CGFloat = 0

		for subview in subviews {
			let size = subview.sizeThatFits(.unspecified)
			if currentWidth + size.width + (currentRow.isEmpty ? 0 : hSpacing) > width, !currentRow.isEmpty {
				rows.append(currentRow)
				currentRow = []
				currentWidth = 0
			}
			currentRow.append(size)
			currentWidth += size.width + (currentRow.count > 1 ? hSpacing : 0)
		}
		if !currentRow.isEmpty { rows.append(currentRow) }
		return rows
	}

	private func indexOf(size: CGSize, x: CGFloat, y: CGFloat, rows: [[CGSize]], bounds: CGRect) -> Int? {
		var index = 0
		var currentY = bounds.minY
		for row in rows {
			let rowHeight = row.map { $0.height }.max() ?? 0
			var currentX = bounds.minX
			for rowSize in row {
				if abs(currentX - x) < 0.5, abs(currentY - y) < 0.5 { return index }
				currentX += rowSize.width + hSpacing
				index += 1
			}
			currentY += rowHeight + vSpacing
		}
		return nil
	}
}

public struct FlowedHStack<Element: FlowedHStackElement, ElementView: View>: View {
	public init(_ elements: [Element], hSpacing: Double = 2, vSpacing: Double = 2, @ViewBuilder content: @escaping (Element) -> ElementView) {
		self.elements = elements
		horizontalSpacing = hSpacing
		verticalSpacing = vSpacing
		self.content = content
	}

	let elements: [Element]
	let horizontalSpacing: Double
	let verticalSpacing: Double
	let content: (Element) -> ElementView

	public var body: some View {
		if #available(iOS 16, macOS 13, watchOS 9, tvOS 16, *) {
			FlowLayout(hSpacing: horizontalSpacing, vSpacing: verticalSpacing) {
				ForEach(Array(zip(elements, elements.indices)), id: \.1) { element, _ in
					content(element)
				}
			}
		} else {
			legacyBody
		}
	}

	@ViewBuilder private var legacyBody: some View {
		let offsets = legacyLayout(sizes: elementSizes)
		VStack(spacing: 0) {
			GeometryReader { proxy in
				Color.clear
					.onAppear { availableWidth = proxy.width }
			}
			.frame(height: 0)

			ZStack(alignment: .topLeading) {
				ForEach(Array(zip(elements, elements.indices)), id: \.1) { element, index in
					content(element)
						.fixedSize()
						.background(GeometryReader { proxy in
							Color.clear.preference(key: FlowSizeKey.self, value: [proxy.size])
						})
						.alignmentGuide(.leading) { _ in
							guard index < offsets.count else { return 0 }
							return -offsets[index].x
						}
						.alignmentGuide(.top) { _ in
							guard index < offsets.count else { return 0 }
							return -offsets[index].y
						}
				}
			}
			.onPreferenceChange(FlowSizeKey.self) { [$elementSizes] sizes in $elementSizes.wrappedValue = sizes }
			.frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
		}
	}

	@State private var availableWidth: CGFloat = 0.0
	@State private var elementSizes: [CGSize] = []

	private func legacyLayout(sizes: [CGSize]) -> [CGPoint] {
		if availableWidth == 0.0 || sizes.isEmpty { return [] }
		var rows: [[CGSize]] = []
		var origins: [CGPoint] = []
		var currentRow: [CGSize] = []
		var currentSize: CGSize = .zero

		for size in sizes {
			if (currentSize.width + size.width + horizontalSpacing) >= availableWidth, !currentRow.isEmpty {
				currentSize = .zero
				rows.append(currentRow)
				currentRow = []
			}
			currentRow.append(size)
			currentSize.width += (size.width + horizontalSpacing)
			currentSize.height = max(currentSize.height, size.height)
		}
		if !currentRow.isEmpty { rows.append(currentRow) }

		currentSize = .zero
		for row in rows {
			let rowHeight = row.map { $0.height }.max() ?? 0
			for rowItem in row {
				let yOffset = (rowHeight - rowItem.height) / 2
				origins.append(CGPoint(x: currentSize.width, y: currentSize.height + yOffset))
				currentSize.width += rowItem.width + horizontalSpacing
			}
			currentSize.height += rowHeight + verticalSpacing
			currentSize.width = 0
		}
		return origins
	}
}

private struct FlowSizeKey: PreferenceKey {
	static let defaultValue: [CGSize] = []
	static func reduce(value: inout [CGSize], nextValue: () -> [CGSize]) {
		value.append(contentsOf: nextValue())
	}
}

public extension FlowedHStack where Element == String, ElementView == Text {
	init(_ elements: [Element], hSpacing: Double = 2, vSpacing: Double = 2) {
		self.elements = elements
		horizontalSpacing = hSpacing
		verticalSpacing = vSpacing
		self.content = { Text($0) }
	}
}
