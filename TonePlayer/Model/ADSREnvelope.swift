/*
	ADSREnvelope.swift
	Intonation
	
	Created by Nathan Day on 16/08/15.
	Copyright © 2015 Nathan Day. All rights reserved.
 */

import Foundation

struct ADSREnvelope : Envelope, CustomStringConvertible, CustomDebugStringConvertible {
	let		attack: TimeInterval;
	let		decay: TimeInterval;
	var		sustain: Float32;
	let		release: TimeInterval;

	init( attack anAttack: TimeInterval, decay aDecay: TimeInterval, sustain aSustain: Float32, release aRelease: TimeInterval ) {
		attack = anAttack;
		decay = aDecay;
		sustain = aSustain;
		release = aRelease;
	}

	init( attack anAttack: TimeInterval, release aRelease: TimeInterval ) { self.init( attack: anAttack, decay: 0.0, sustain: 1.0, release: aRelease ); }

	var	initialValue: Float32 {
		return 0.0;
	}

	var count: Int {
		return decay > 0.0 ? 3 : 2;
	}

	subscript( anX: Int ) -> EnvelopePoint {
		switch anX {
		case 0: return EnvelopePoint(duration:attack,value:1.0);
		case 1: return decay > 0.0
			? EnvelopePoint(duration:decay,value:sustain,hold:true)
			: EnvelopePoint(duration:release,value:0.0);
		default: return EnvelopePoint(duration:release,value:0.0);
		}
	}

	var description: String {
		return "( \(attack), \(decay), \(sustain), \(release) )";
	}

	var debugDescription: String {
		return "attack: \(attack), decay: \(decay), sustain: \(sustain), release: \(release)";
	}

}
