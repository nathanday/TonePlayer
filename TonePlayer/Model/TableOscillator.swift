//
//  TableOscillator.swift
//  TonePlayer
//
//  Created by Nathaniel Day on 8/12/18.
//  Copyright © 2018 Nathan Day. All rights reserved.
//

import Foundation
import Accelerate;
import simd;

struct TableOscillator {
	static let	length = 2048;
	let			harmonicsDescription: HarmonicsDescription;
	var			samples = [Int:TableOscillator.Samples]();

	init( harmonicsDescription aHarmonicsDescription: HarmonicsDescription ) {
		harmonicsDescription = aHarmonicsDescription;
	}

	mutating func samples(for aFreq: Float, sampleRate aSampleRate: Float ) -> TableOscillator.Samples {
		let		theLength = Int(ceil(aSampleRate/aFreq));
		if let theSamples = samples[theLength] {
			return theSamples;
		}
		let	theNewSamples = TableOscillator.Samples(length: theLength, harmonicsDescription: harmonicsDescription);
		samples[theLength] = theNewSamples;
		return theNewSamples;
	}

	struct Samples {
		let			values : [Float32];

		init( length aLength: Int, harmonicsDescription aHarmonicsDescription: HarmonicsDescription ) {
			var	theValues = [Float32](repeating: 0.0, count: aLength );
			var x = [Float](repeating: 0, count: aLength );
			var y1 = [Float](repeating: 0, count: aLength );
			var n = Int32( aLength );

			aHarmonicsDescription.enumerate(to:aLength/2) { (aHarmonic: Int, anAmplitude: Float32) in
				assert( aHarmonic <= aLength );
				Samples.rampedValues(x: &x, xc: x.count, value: 2.0*Float(aHarmonic))
				vvsinpif( &y1, x, &n );
				Samples.accumlateScaledFloats(y: &theValues, x: y1, yc: theValues.count, a: anAmplitude);
			}
			values = theValues
		}

		subscript(anX: Float) -> Float {
			get {
				let		theIndex = Int(anX);
				let		theX0 = floor(anX);
				let		theX1 = ceil(anX);
				let		theY0 = values[theIndex];
				let		theY1 = values[theIndex+1];
				return theY0*(anX-theX1)/(theX0-theX1)+theY1*(anX-theX0)/(theX1-theX0);
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
	}

}

