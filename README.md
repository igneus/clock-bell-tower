# "Clock Bell Tower"

Bell tower chimes

## Requirements

developed with Crystal 0.23.1

## "Installation" and Running

Get the sources, run

`$ crystal deps`

then execute

`$ crystal main.cr`

## Setup

This program only emits MIDI messages. It must be connected
to some MIDI instrument in order to produce sounds.
The author uses fluidsynth synthesizer with
[The Ghent Carillon][tgc] sound font.

[tgc]: https://musical-artifacts.com/artifacts/90
