require "portmidi"
require "portmidi/midi_utilities"

class ChimeTime
  def initialize(@time : Time)
  end

  def hours
    hour = @time.hour % 12
    hour == 0 ? 12 : hour
  end

  def quarters
    qrtrs = (@time.minute.to_f / 60 * 4).round.to_i
    qrtrs == 0 ? 4 : qrtrs
  end

  def whole_hour?
    quarters == 4
  end
end

class BellTower
  include MidiUtilities

  def initialize(@channel = 0)
    PortMidi.start

    device_id = PortMidi.get_default_midi_output_device_id
    @output = PortMidi::MidiOutputStream.new device_id
  end

  def chime(time)
    chime_time = ChimeTime.new(time)

    if chime_time.whole_hour?
      chime_time.quarters.times { ring MidiNotes::QUARTER, 1.2 }
    end
    sleep 0.2
    chime_time.hours.times { ring MidiNotes::HOUR, 1.4 }

    bim_bam 32, 0.9, 12

    PortMidi.stop
  end

  module MidiNotes
    HOUR = 48
    QUARTER = HOUR + 4
  end

  private def ring(note, time)
    @output.write([note_on(note, 90, @channel)])
    sleep(time)
    @output.write([note_off(note, 0, @channel)])
  end

  private def bim_bam(base_note, interval, times)
    times.times do
      ring base_note + 2, interval
      ring base_note, interval
    end
  end
end

BellTower.new.chime(Time.now)
