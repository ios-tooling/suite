//
//  View.gesture.swift
//  Suite
//
//  Created by Ben Gottlieb on 2/11/26.
//

import SwiftUI

public extension View {
	@ViewBuilder func gesture<G: Gesture>(enabled: Bool, _ gesture: G) -> some View {
		self.gesture(enabled ? gesture : nil)
	}
}


