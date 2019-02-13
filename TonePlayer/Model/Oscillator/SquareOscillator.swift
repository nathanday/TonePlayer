//
//  SquareOscillator.swift
//  TonePlayer
//
//  Created by Nathaniel Day on 13/02/19.
//  Copyright © 2019 Nathaniel Day. All rights reserved.
//

import Foundation

struct SquareOscillator: Oscillator {
	subscript(x: Float32) -> Float32 {
		return x < 0.5 ? 1.0 : -1.0;
	}
}
