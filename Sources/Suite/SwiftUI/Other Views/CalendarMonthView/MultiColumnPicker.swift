//
//  MultiColumnPicker.swift
//  Internal
//
//  Created by Ben Gottlieb on 12/16/24.
//

import SwiftUI

#if os(iOS)
extension UIPickerView {
	override open var intrinsicContentSize: CGSize {
		get {
			CGSize(width: UIView.noIntrinsicMetric, height: 150)
		}
	}
}

@available(iOS 16, macOS 14.0, watchOS 10, *)
struct MultiColumnPicker<Data>: View where Data: Hashable {
	let labels: [String]
	let data: [[Data]]
	@Binding var selection: [Data]
	var minimumColumnWidth = 140.0
	
	var body: some View {
		GeometryReader { geometry in
			HStack(spacing: 0) {
				ForEach(0..<data.count, id: \.self) { column in
					picker(label: labels[column], columnData: data[column], column: column, geometry: geometry)
				}
			}
		}
		.frame(height: 150)
		.frame(minWidth: minimumColumnWidth * Double(labels.count))
	}
	
	@ViewBuilder private func picker(label: String, columnData: [Data], column: Int, geometry: GeometryProxy) -> some View {
		let columnWidth = max(geometry.size.width / CGFloat(self.data.count), minimumColumnWidth)
		
		Picker(label, selection: $selection[column]) {
			ForEach(0..<columnData.count, id: \.self) { row in
				Text(String(describing: columnData[row]))
					.tag(columnData[row])
			}
		}
		.pickerStyle(.wheel)
		.frame(width: columnWidth, height: geometry.size.height)
		.clipped()
		
		Spacer()
	}
}
#endif
