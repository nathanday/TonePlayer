//
//  Oscillator_Test.swift
//  IntonationTests
//
//  Created by Nathaniel Day on 18/12/18.
//  Copyright © 2018 Nathan Day. All rights reserved.
//

import XCTest

class Oscillator_Test: XCTestCase {

	private let		accuracy = powf(2.0,-12.0);

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

	func testSineWave() {
		let		theOscillator = SineOscillator();
		let		theMult = 1.0/Float32(256);
		let		theData = theOscillator.data(length: 256);
		for anIndex in 0..<256 {
			let		x = Float32(anIndex)*theMult;
			let		y = sin(2.0*Float32.pi*x);
			let		v = theData[x];
			XCTAssertEqual( v, y, accuracy: accuracy, "theData[\(anIndex)] = \(v) != \(y)" );
		}
	}

	func testSawToothWave() {
		let		theOscillator = SawtoothOscillator();
		let		theData = theOscillator.data(length: 256);
		XCTAssertEqual( theData[0.0], 1.0, accuracy: accuracy, "theData[0.0] = \(theData[0.0]) != \(1.0)" );
		XCTAssertEqual( theData[0.25], 0.5, accuracy: accuracy, "theData[0.0] = \(theData[0.25]) != \(0.5)" );
		XCTAssertEqual( theData[0.5], 0.0, accuracy: accuracy, "theData[0.0] = \(theData[0.5]) != \(0.0)" );
		XCTAssertEqual( theData[0.75], -0.5, accuracy: accuracy, "theData[0.0] = \(theData[0.75]) != \(-0.5)" );
		XCTAssertEqual( theData[1.0], -1.0, accuracy: accuracy, "theData[0.0] = \(theData[1.0]) != \(-1.0)" );
	}

	func testSquareWave() {
		let		theOscillator = SquareOscillator();
		let		theData = theOscillator.data(length: 256);
		XCTAssertEqual( theData[0.0], 1.0, accuracy: accuracy, "theData[0.0] = \(theData[0.0]) != \(1.0)" );
		XCTAssertEqual( theData[0.25], 1.0, accuracy: accuracy, "theData[0.0] = \(theData[0.25]) != \(1.0)" );
		XCTAssertEqual( theData[0.49], 1.0, accuracy: accuracy, "theData[0.0] = \(theData[0.45]) != \(1.0)" );
		XCTAssertEqual( theData[0.51], -1.0, accuracy: accuracy, "theData[0.0] = \(theData[0.55]) != \(-1.0)" );
		XCTAssertEqual( theData[0.75], -1.0, accuracy: accuracy, "theData[0.0] = \(theData[0.75]) != \(-1.0)" );
		XCTAssertEqual( theData[1.0], -1.0, accuracy: accuracy, "theData[0.0] = \(theData[1.0]) != \(-1.0)" );
	}

	func testHarmonicsDescription() {
		let		theDescription = HarmonicsDescription(amount: 1.0, evenAmount: 1.0);
		for (anIndex,aValue) in theDescription.amplitudes.enumerated() {
			XCTAssertEqual( aValue, 1.0/(Float(anIndex)+1.0), accuracy: accuracy, "amplitudes[\(anIndex)] = \(aValue) != \(1.0/(Float(anIndex)+1.0))" );
		}
	}

//	func testSawToothWave() {
//		let		theOscillator = HarmonicSeriesOscillator(harmonicsDescription:HarmonicsDescription(amount: 1.0, evenAmount: 1.0));
//		let		theMult = 2.0*Float32.pi/Float32(256);
//		for (anIndex,aValue) in theOscillator.amplitudes.enumerated() {
//			let		x = Float32(anIndex)*theMult;
//			var		y = Float32(0.0);
//			for i in 1...theOscillator.count {
//				y += 1.0/Float32(i)*sin(Float32(i)*x);
//			}
//			XCTAssertEqual( aValue, y, accuracy: accuracy, "amplitudes[\(anIndex)] = \(aValue) != \(y)" );
//		}
//	}

	func testPerformanceSineWave() {
		let			theHarmonicsDescription = HarmonicsDescription(amount: 0.0, evenAmount: 1.0);
		self.measure {
			let		_ = theHarmonicsDescription;
		}
	}

	func testPerformanceSawToothWave() {
		let			theHarmonicsDescription = HarmonicsDescription(amount: 1.0, evenAmount: 1.0);
		self.measure {
			let		_ = theHarmonicsDescription;
		}
	}

}
