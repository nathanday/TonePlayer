//
//  HarmonicSeriesOscillator.swift
//  TonePlayer
//
//  Created by Nathaniel Day on 14/02/19.
//  Copyright © 2019 Nathaniel Day. All rights reserved.
//

import Foundation
import Accelerate;
import simd;

struct HarmonicSeriesOscillator: Oscillator {
	var		data = [Int:HarmonicSeriesOscillatorData]();
	let		harmonicsDescription: HarmonicsDescription;

	init(harmonicsDescription aHarmonicsDescription: HarmonicsDescription ) {
		harmonicsDescription = aHarmonicsDescription;
	}
	mutating func data(length aLength: Int) -> OscillatorData {
		let		theLength = aLength>>2;
		if let theData = data[theLength] {
			print("\(theData)");
			return theData;
		} else {
			let		theData = HarmonicSeriesOscillatorData(length:theLength<<2, harmonicsDescription:harmonicsDescription);
			data[theLength] = theData;
			print("\(theData)");
			return theData;
		}
	}
}

class HarmonicSeriesOscillatorData: OscillatorData, CustomStringConvertible {
	let		sample: [Float32];

	init(length aLength: Int, harmonicsDescription aHarmonicsDescription: HarmonicsDescription ) {
		var	theSamples = [Float32](repeating: 0.0, count: aLength );
//		var x = [Float](repeating: 0.0, count: aLength );
//		var y1 = [Float](repeating: 0.0, count: aLength );
//		var n = Int32( aLength );

		var		theMax: Float = 0.0;

		aHarmonicsDescription.enumerate(to:aLength/2) { (aHarmonic: Int, anAmplitude: Float32) in
			assert( aHarmonic <= aLength );
			for i in 0..<aLength {
				theSamples[i] += sin(2.0*Float.pi*Float(i*aHarmonic)/Float(aLength-1))*anAmplitude;
				theMax = max(theMax,abs(theSamples[i]));
			}
//			HarmonicSeriesOscillatorData.rampedValues(x: &x, xc: x.count, value:Float(aHarmonic))
//			vvsinpif( &y1, x, &n );
//			HarmonicSeriesOscillatorData.accumlateScaledFloats(y: &theSamples, x: y1, yc: theSamples.count, a: anAmplitude);
		}
		if theMax != 1.0 {
			for i in 0..<aLength {
				theSamples[i] /= theMax;
			}
		}

		sample = theSamples
	}

	subscript(x: Float32) -> Float32 {
		let		theLength = sample.count-1;
		let		theX = x*Float32(theLength);
		let		theIndex = Int(theX);
		let		theX0 = floor(theX);
		let		theX1 = ceil(theX);
		if theX0 != theX1 {
			let		theY0 = sample[theIndex];
			let		theY1 = sample[(theIndex+1)%theLength];
			return theY0*(theX-theX1)/(theX0-theX1)+theY1*(theX-theX0)/(theX1-theX0);
		} else {
			return sample[theIndex];
		}
	}

	static private func rampedValues(x: UnsafeMutablePointer<Float>, xc: Int, value aValue: Float) {
		assert( xc%4 == 0, "The length of the arrays must be multiples of 4" );
		if xc < 4 {
			return;
		}
		let		theXLen = xc>>2;
		let		thheDelta = aValue/Float(xc);
		let 	theDeltaV = float4(4.0*thheDelta,4.0*thheDelta,4.0*thheDelta,4.0*thheDelta);
		x.withMemoryRebound(to: float4.self, capacity: theXLen) { theX in
			var		p = float4( 0.0, thheDelta, 2.0*thheDelta, 3.0*thheDelta );
			theX[0] = p;
			for t in 1..<theXLen {
				p = p+theDeltaV;
				theX[t] = p;
			}
		}
	}

	static private func accumlateScaledFloats(y: UnsafeMutablePointer<Float>, x: UnsafePointer<Float>, yc: Int, a: Float) {
		assert( yc%4 == 0, "The length of the arrays must be multiples of 4" );
		let theA = float4(a, a, a, a)
		let	theYLen = yc>>2;
		y.withMemoryRebound(to: float4.self, capacity: theYLen) { theY in
			x.withMemoryRebound(to: float4.self, capacity: theYLen) { theX in
				for t in 0..<theYLen {
					theY[t] += theA * theX[t]
				}
			}
		}
	}

	var description: String {
		return "length: \(sample.count)";
	}
}
