//
//  ViewController.swift
//  TonePlayer
//
//  Created by Nathaniel Day on 4/02/19.
//  Copyright © 2019 Nathaniel Day. All rights reserved.
//

import Cocoa
import WebKit

private func index( for aControl: NSControl ) -> Int { return aControl.tag&0xFF; }

class ViewController: NSViewController {

	var				frequencies : [Double] = [110.0, 165.0, 220.0, 275.0, 330.0, 385.0, 440.0, 495.0];
	var				voices : [TonePlayer.Voice?] = [nil, nil, nil, nil, nil, nil, nil, nil];
	var				tonePlayer = TonePlayer(maximumPolyphony: 8, sampleRate: 48000.0);

	@objc var		envelopeAttack: Double = 0.01 {
		didSet { currentInstrument = nil; }
	}
	@objc var		envelopeDecay: Double = 0.125 {
		didSet { currentInstrument = nil; }
	}
	@objc var		envelopeSustain: Float = 0.25 {
		didSet { currentInstrument = nil; }
	}
	@objc var		envelopeRelease: Double = 0.5 {
		didSet { currentInstrument = nil; }
	}

	var				envelope: Envelope {
		return ADSREnvelope( attack: envelopeAttack, decay: envelopeDecay, sustain: envelopeSustain, release: envelopeRelease )
	}

	@objc var		selectedOscillatorIndex: Int = 0 {
		didSet { currentInstrument = nil; }
	}

	var		selectedOscillator: Oscillator {
		switch selectedOscillatorIndex {
		case 0:
			return SineOscillator();
		case 1:
			return SawtoothOscillator();
		case 2:
			return SquareOscillator();
		case 3:
			return PulseOscillator(width:pulseWidth/100.0);
		default:
			return SineOscillator();
		}
	}

	private var		_currentInstrument: TonePlayer.Instrument? = nil;
	var		currentInstrument: TonePlayer.Instrument? {
		set(aValue) {
		_currentInstrument = aValue;
		}
		get {
			if _currentInstrument == nil {
				_currentInstrument = tonePlayer.instrument(oscillator: selectedOscillator, envelope: envelope);
			}
			return _currentInstrument;
		}
	}

	@objc var		pulseWidth: Float = 50.0 {
		didSet {
			if selectedOscillatorIndex == 3 {
				currentInstrument = nil;
			}
		}
	}

	@IBOutlet weak var freqTextFieldContainerView: NSView!

	override func viewDidLoad() {
		super.viewDidLoad()
		fillFreqTextFields();
		currentInstrument = tonePlayer.instrument(oscillator: selectedOscillator, envelope: envelope);
	}

	override var representedObject: Any? {
		didSet {
		// Update the view, if already loaded.
		}
	}

	func fillFreqTextFields() {
		for (theIndex,theFreq) in frequencies.enumerated() {
			if let theTextField = freqTextFieldContainerView.viewWithTag(theIndex+0x100) as? NSTextField {
				theTextField.doubleValue = theFreq;
			}
		}
	}


	@IBAction func frequencyChangedAction(_ aSender: NSTextField) {
		assert( aSender.tag >= 0x100, "tag not set" );
		if frequencies[aSender.tag&0xFF].distance(to: aSender.doubleValue) > 0.1 {
			print( "setting freq[\(aSender.tag&0xFF)]=\(aSender.doubleValue)" );
			frequencies[index(for:aSender)] = aSender.doubleValue;
		}
	}

	@IBAction func playStateChanged(_ aSender: NSButton) {
		assert( aSender.tag >= 0x100, "tag not set" );
		let		theIndex = index(for:aSender);
		if let theVoice = voices[theIndex] {
			theVoice.trigger();
			voices[theIndex] = nil;
		} else if let theInstrument = currentInstrument {
			voices[theIndex] = theInstrument.play(frequency: frequencies[theIndex]);
		}
	}
}

