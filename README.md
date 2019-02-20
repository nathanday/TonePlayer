TonePlayer
=========
Example project for a simple polyphonic synthesiser.

## Motivation
I couldn't  find any suitable examples projects of a synthesiser so I created my own.

## What it does
Plays back tones based on an oscillator, and a envelope to control the amplitude, there is no antialiasing filter in this example currently, instead I am using oscilator shapes that can be down sampled without causing aliasing, sine, simple square, sawtooth, or I generate the oscilator upto the correct cut off frequency so no anti aliasing filter is required.  
