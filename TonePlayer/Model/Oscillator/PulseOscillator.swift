//
//  PulseOscillator.swift
//  TonePlayer
//
//  Created by Nathaniel Day on 13/02/19.
//  Copyright © 2019 Nathaniel Day. All rights reserved.
//

import Foundation

struct PulseOscillator: Oscillator, OscillatorData {
	let		width: Float;
	func data(length aLength: Int) -> OscillatorData {
		return self;
	}
	subscript(x: Float32) -> Float32 {
		let		theWidth = width*0.5;
		return x < theWidth ? 1.0 : x < (1.0-theWidth) ? 0.0 : -1.0;
	}
}
