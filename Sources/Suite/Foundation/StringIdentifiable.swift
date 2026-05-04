//
//  StringIdentifiable.swift
//  
//
//  Created by ben on 11/6/20.
//

import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13, watchOS 6, *)
public protocol StringIdentifiable: Identifiable where ID: StringProtocol {
}
