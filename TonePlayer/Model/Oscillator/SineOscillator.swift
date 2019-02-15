//
//  SineOscillator.swift
//  TonePlayer
//
//  Created by Nathaniel Day on 13/02/19.
//  Copyright © 2019 Nathaniel Day. All rights reserved.
//

import Foundation

struct SineOscillator : Oscillator, OscillatorData {
	func data(length aLength: Int) -> OscillatorData {
		return self;
	}
	subscript(x: Float32) -> Float32 {
		return sin(2.0*Float32.pi*x);
	}
}
