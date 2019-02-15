//
//  HarmonicSeriesOscillator.swift
//  TonePlayer
//
//  Created by Nathaniel Day on 14/02/19.
//  Copyright © 2019 Nathaniel Day. All rights reserved.
//

import Foundation

struct HarmonicSeriesOscillator: Oscillator {
	var		data = [Int:HarmonicSeriesOscillatorData]();
	let		harmonicsDescription: HarmonicsDescription;

	init(harmonicsDescription aHarmonicsDescription: HarmonicsDescription ) {
		harmonicsDescription = aHarmonicsDescription;
	}
	mutating func data(length aLength: Int) -> OscillatorData {
		if let theData = data[aLength>>1] {
			return theData;
		} else {
			let		theData = HarmonicSeriesOscillatorData(harmonicsDescription:harmonicsDescription);
			data[aLength>>1] = theData;
			return theData;
		}
	}
}

class HarmonicSeriesOscillatorData: OscillatorData {
	let		sample: [Float32];

	init(harmonicsDescription aHarmonicsDescription: HarmonicsDescription ) {
	}
	subscript(x: Float32) -> Float32 {
	}
}
