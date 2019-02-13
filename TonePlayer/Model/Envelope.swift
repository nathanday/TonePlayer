//
//  Envelope.swift
//  TonePlayer
//
//  Created by Nathaniel Day on 6/02/19.
//  Copyright © 2019 Nathaniel Day. All rights reserved.
//

import Foundation

protocol Envelope {
	var count: Int { get }
	var	initialValue: Float32 { get };
	subscript(x:Int) -> EnvelopePoint { get }
}

struct EnvelopePoint: CustomStringConvertible, CustomDebugStringConvertible, Hashable {

	let	duration: TimeInterval;
	let	value: Float32;
	let	hold: Bool;
	init(duration aDuration: TimeInterval, value aValue: Float32, hold aHold: Bool = false ) {
		duration = aDuration;
		value = aValue;
		hold = aHold;
	}

	func delta(from aFrom: Float32, sampleRate aRate: Float64) -> Float32 {
		return (value - aFrom)/Float32(aRate*duration);
	}

	var description: String {
		return "\(duration) -> \(value)\(hold ? ", hold":"")";
	}

	var debugDescription: String {
		return "EnvelopePoint: duration: \(duration), value: \(value), hold: \(hold)";
	}
}

