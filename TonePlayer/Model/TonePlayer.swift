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
	private var		lock = NSRecursiveLock();

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
				if !theSamples.isEmpty {
					theTone.generate( buffer: theSamples, count: Int(anInNumberFrames) );
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
		lock.lock()
		let		theError = AudioOutputUnitStop(toneUnit! );
		assert( theError == noErr, "Error starting unit: \(theError)");
		lock.unlock()
	}

	func play(voice aVoice: Voice) {
		lock.lock()
		if voicies.count+1 > maximumPolyphony {
			voicies[0].stop({
				self.voicies.append(aVoice)
				NSLog( "release then play voices count = \(self.voicies.count)" );
			});
		} else {
			voicies.append(aVoice);
			NSLog( "play voices count = \(voicies.count)" );
		}
		lock.unlock()
	}

	private func ended(voice aVoice: Voice) {
		lock.lock()
		if let theIndex = voicies.firstIndex(of: aVoice) {
			NSLog( "removed = \(aVoice)" );
			voicies.remove(at:theIndex);
			NSLog( "ended voices count = \(voicies.count)" );
		}
		lock.unlock()
	}

	func instrument( oscillator anOscillator: Oscillator, amplitudeEnvelope anEnvelope: Envelope ) -> Instrument {
		return Instrument(tonePlayer: self, oscillator: anOscillator, amplitudeEnvelope: anEnvelope);
	}

	final func generate( buffer aBuffer : UnsafeMutableBufferPointer<Float32>, count aCount : Int ) {
		let		theGain = 1.0/Float32(maximumPolyphony);
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

	class Instrument {
		weak var	tonePlayer: TonePlayer? = nil;
		let			amplitudeEnvelope: Envelope;
		var			oscillator: Oscillator;

		fileprivate init( tonePlayer aTonePlayer: TonePlayer, oscillator anOscillator: Oscillator, amplitudeEnvelope anEnvelope: Envelope) {
			tonePlayer = aTonePlayer;
			oscillator = anOscillator;
			amplitudeEnvelope = anEnvelope;
		}

		func play(frequency aFrequency: Double) -> TonePlayer.Voice {
			let		theVoice = Voice(instrument:self, frequency: aFrequency);
			tonePlayer?.play(voice: theVoice)
			return theVoice;
		}
	}

	class Voice: Hashable, Equatable, CustomDebugStringConvertible {
		static private var			identifierCount: UInt64 = 0;
		private let					identifier: UInt64;
		public let					instrument: Instrument;
		public let					frequency: Double;
		public private(set) var		amplitude: Float32;

		private var		ended: (() -> Void)?

		private let		oscillatorData: OscillatorData;

		private var		theta : Double = 0;
		private var		amplitudeDelta: Float32;
		private var		amplitudeEnvelopeIndex = 0;
		private var		nextEnvelopeBreakTime: Int;

		init(instrument anInstrument: Instrument, frequency aFrequency: Double ) {
			Voice.identifierCount += 1;
			identifier = Voice.identifierCount;
			frequency = aFrequency;
			instrument = anInstrument;
			oscillatorData = instrument.oscillator.data(length: Int(instrument.tonePlayer!.sampleRate/frequency) );
			amplitude = instrument.amplitudeEnvelope.initialValue;
			amplitudeDelta = instrument.amplitudeEnvelope[0].delta(from: amplitude, sampleRate: anInstrument.tonePlayer!.sampleRate);
			nextEnvelopeBreakTime = Int(instrument.amplitudeEnvelope[0].duration*anInstrument.tonePlayer!.sampleRate);
		}

		func generate( add anAdd: Bool, buffer aBuffer : UnsafeMutableBufferPointer<Float32>, gain aGain: Float32, count aCount : Int ) {
			let		theFreqDiv = frequency/instrument.tonePlayer!.sampleRate;
			for i : Int in 0..<aCount {
				let		theValue = oscillatorData[Float32(theta)]*amplitude*aGain;
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
				} else if instrument.amplitudeEnvelope[amplitudeEnvelopeIndex].hold {
					amplitudeDelta = 0.0;
					nextEnvelopeBreakTime = Int.max;
				} else {
					if amplitudeEnvelopeIndex+1 < instrument.amplitudeEnvelope.count  {
						nextEvelopePoint();
					} else if amplitudeEnvelopeIndex == instrument.amplitudeEnvelope.count {
						instrument.tonePlayer?.ended(voice:self);
						ended?();
						ended = nil;
					}
				}
			}
		}

		private func nextEvelopePoint() {
			let		theSampleRate = instrument.tonePlayer!.sampleRate;
			if amplitudeEnvelopeIndex+1 < instrument.amplitudeEnvelope.count  {
				amplitudeEnvelopeIndex += 1;
				amplitudeDelta = instrument.amplitudeEnvelope[amplitudeEnvelopeIndex].delta(from: amplitude, sampleRate: theSampleRate);
				nextEnvelopeBreakTime = Int(instrument.amplitudeEnvelope[amplitudeEnvelopeIndex].duration*theSampleRate);
			}
		}

		func stop( _ anEnded: @escaping () -> Void ) {
			if amplitudeEnvelopeIndex < instrument.amplitudeEnvelope.count {
				amplitudeEnvelopeIndex = instrument.amplitudeEnvelope.count;
				amplitudeDelta = -Float32(amplitude)/Float32(instrument.tonePlayer!.sampleRate*1.0/20.0);
				nextEnvelopeBreakTime = Int(instrument.tonePlayer!.sampleRate*1.0/20.0);
				ended = anEnded;
			}
		}

		func trigger() {
			nextEvelopePoint();
		}

		func hash(into aHasher: inout Hasher) {
			aHasher.combine(identifier);
		}

		public static func ==(aLhs: Voice, aRhs: Voice) -> Bool {
			return aLhs.identifier == aRhs.identifier;
		}

		var debugDescription: String {
			return "identifier: \(identifier), instrument: \(instrument), frequency: \(frequency)";
		}
	}

}
