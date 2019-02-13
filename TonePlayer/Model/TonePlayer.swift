/*
	TonePlayer.swift
	TonePlayer

	Created by Nathan Day on 4/02/19..
	Copyright © 2019 Nathan Day. All rights reserved.
 */

import AudioToolbox;
import simd;

class TonePlayer {
	private var		toneUnit : AudioComponentInstance?;
	private var		voicies = ContiguousArray<TonePlayer.Voice>();
	private var		lock = NSLock();

	let				maximumPolyphony: Int;
	let				sampleRate: Float64;

	init( maximumPolyphony aMaximumPolyphony: Int, sampleRate aSampleRate: Float64 = 48000.0 ) {
		maximumPolyphony = aMaximumPolyphony;
		sampleRate = aSampleRate;
		toneUnit = nil;
		var		theDefaultOutputDescription = AudioComponentDescription( componentType: OSType(kAudioUnitType_Output),
																			componentSubType: OSType(kAudioUnitSubType_DefaultOutput),
																			componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
																			componentFlags: 0,
																			componentFlagsMask: 0);
		func toneCallback( _ anInRefCon : UnsafeMutableRawPointer, anIOActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>, anInTimeStamp : UnsafePointer<AudioTimeStamp>, anInBusNumber: UInt32, anInNumberFrames: UInt32, anIOData: UnsafeMutablePointer<AudioBufferList>?) -> OSStatus {
			let		theResult : OSStatus = kAudioServicesNoError;
			if let theBuffer : AudioBuffer = anIOData?.pointee.mBuffers {
				let		theSamples = UnsafeMutableBufferPointer<Float32>(theBuffer);
				let		theToneRef = anInRefCon.assumingMemoryBound(to: TonePlayer.self);
				let		theTone = theToneRef.pointee;
				let		theGain = Float32(0.5);
				assert( theGain > 0.0, "bad gain value: \(theGain)" );
				if !theSamples.isEmpty {
					theTone.generate( buffer: theSamples, gain: theGain, count: Int(anInNumberFrames) );
				}
			}
			return theResult;
		}

		// Create a new unit based on this that we'll use for output
		var		err = AudioComponentInstanceNew( AudioComponentFindNext(nil, &theDefaultOutputDescription)!, &toneUnit);

		// Set our tone rendering function on the unit
		//		var		theTonePlayer = self;
		let		theSelf = UnsafeMutablePointer<TonePlayer>.allocate(capacity: 1);
		theSelf.initialize(to: self);
		var		theInput = AURenderCallbackStruct( inputProc: toneCallback, inputProcRefCon: theSelf );
		err = AudioUnitSetProperty(toneUnit!, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &theInput, UInt32(MemoryLayout<AURenderCallbackStruct>.size));

		// Set the format to 32 bit, single channel, floating point, linear PCM
		let		four_bytes_per_float : UInt32 = 4;
		let		eight_bits_per_byte : UInt32 = 8;
		var		theStreamFormat = AudioStreamBasicDescription( mSampleRate: sampleRate,
																  mFormatID: kAudioFormatLinearPCM,
																  mFormatFlags: kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved,
																  mBytesPerPacket: four_bytes_per_float,
																  mFramesPerPacket: 1,
																  mBytesPerFrame: four_bytes_per_float,
																  mChannelsPerFrame: 1,
																  mBitsPerChannel: four_bytes_per_float * eight_bits_per_byte,
																  mReserved: 0);

		err = AudioUnitSetProperty (toneUnit!, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, AudioUnitElement(0), &theStreamFormat, UInt32(MemoryLayout<AudioStreamBasicDescription>.size) );

		assert(err == noErr, "Error setting stream format: \(err)" );
		err = AudioUnitInitialize(toneUnit!);
		assert(err == noErr, "Error starting unit: \(err)" );
		//		assert(frequency < 1.0);
		let		theError = AudioOutputUnitStart(toneUnit!);
		assert( theError == noErr, "Error starting unit: \(theError)");
	}

	deinit {
		let		theError = AudioOutputUnitStop(toneUnit! );
		assert( theError == noErr, "Error starting unit: \(theError)");
	}

	func play(instrument anInstrument:Instrument, frequency aFrequency: Double) -> TonePlayer.Voice {
		let		theVoice = Voice(tonePlayer: self, frequency: aFrequency, instrument:anInstrument);
		lock.lock()
		if voicies.count+1 > maximumPolyphony {
			voicies.remove(at: 0);
		}
		voicies.append(theVoice);
		lock.unlock()
		return theVoice;
	}

	final func generate( buffer aBuffer : UnsafeMutableBufferPointer<Float32>, gain aGain: Float32, count aCount : Int ) {
		let		theGain = aGain/Float32(maximumPolyphony);
		lock.lock();
		if voicies.count > 0 {
			for (theIndex,theVoice) in voicies.enumerated() {
				theVoice.generate( add: theIndex != 0, buffer: aBuffer, gain: theGain, count: aCount );
			}
		} else {
			for i : Int in 0..<aCount {
				aBuffer[i] = 0.0;
			}
		}
		lock.unlock();
	}

	struct Instrument {
		let				envelope: Envelope;
		let				oscillator: Oscillator;
	}

	class Voice: Hashable, Comparable {
		weak var					tonePlayer: TonePlayer? = nil;
		public let					instrument: Instrument;
		public let					frequency: Double;
		public private(set) var		amplitude: Float32;

		private var		theta : Double = 0;
		private var		amplitudeDelta: Float32;
		private var		envelopeIndex = 0;
		private var		nextEnvelopeBreakTime: Int;

		init( tonePlayer aTonePlayer: TonePlayer, frequency aFrequency: Double, instrument anInstrument: Instrument ) {
			tonePlayer = aTonePlayer;
			frequency = aFrequency;
			instrument = anInstrument;
			amplitude = instrument.envelope.initialValue;
			amplitudeDelta = instrument.envelope[0].delta(from: amplitude, sampleRate: aTonePlayer.sampleRate);
			nextEnvelopeBreakTime = Int(instrument.envelope[0].duration*aTonePlayer.sampleRate);
		}

		func generate( add anAdd: Bool, buffer aBuffer : UnsafeMutableBufferPointer<Float32>, gain aGain: Float32, count aCount : Int ) {
			let		theFreqDiv = frequency/tonePlayer!.sampleRate;
			for i : Int in 0..<aCount {
				let		theValue = instrument.oscillator[Float32(theta)]*amplitude*aGain;
				if anAdd {
					aBuffer[i] += theValue;
				} else {
					aBuffer[i] = theValue;
				}
				amplitude = max(amplitude+amplitudeDelta,0);
				theta += theFreqDiv;
				while theta >= 1.0 {
					theta -= 1.0;
				}
				if nextEnvelopeBreakTime > 0 {
					nextEnvelopeBreakTime -= 1;
				} else if instrument.envelope[envelopeIndex].hold {
					amplitudeDelta = 0.0;
					nextEnvelopeBreakTime = Int.max;
				} else {
					nextEvelopePoint();
				}
			}
		}

		private func nextEvelopePoint() {
			let		theSampleRate = tonePlayer!.sampleRate;
			if envelopeIndex+1 < instrument.envelope.count  {
				envelopeIndex += 1;
				amplitudeDelta = instrument.envelope[envelopeIndex].delta(from: amplitude, sampleRate: theSampleRate);
				nextEnvelopeBreakTime = Int(instrument.envelope[envelopeIndex].duration*theSampleRate);
			}
		}

		func stop() {
			if envelopeIndex < instrument.envelope.count {
				envelopeIndex = instrument.envelope.count;
				amplitudeDelta = -Float32(tonePlayer!.sampleRate*1.0/20.0);
			}
		}

		func trigger() {
			nextEvelopePoint();
		}

		func hash(into aHasher: inout Hasher) {
			aHasher.combine((frequency*1000.0).rounded());
		}

		public static func ==(aLhs: Voice, aRhs: Voice) -> Bool {
			return aLhs.frequency.distance(to: aRhs.frequency) < 0.0001;
		}

		static func < (lhs: TonePlayer.Voice, rhs: TonePlayer.Voice) -> Bool {
			return lhs.frequency < rhs.frequency;
		}
	}

}
