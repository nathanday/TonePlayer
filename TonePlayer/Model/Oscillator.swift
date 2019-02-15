//
//  Oscillator.swift
//  TonePlayer
//
//  Created by Nathaniel Day on 13/02/19.
//  Copyright © 2019 Nathaniel Day. All rights reserved.
//

import Foundation

protocol OscillatorData {
	subscript(anX: Float32) -> Float32 { get }
}

protocol Oscillator {
	mutating func data(length aLength: Int) -> OscillatorData;
}
