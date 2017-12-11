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
    qrtrs = ((@time.minute.to_f / 60) * 4).round.to_i
    qrtrs == 0 ? 4 : qrtrs
  end

  def whole_hour?
    quarters == 4
  end

  def ==(b)
    hours == b.hours &&
      quarters == b.quarters
  end
end

class BellTower
  include MidiUtilities

  def initialize(@channel = 0, alarm_time = Time.now)
    @alarm_chime_time = ChimeTime.new alarm_time

    PortMidi.start

    device_id = PortMidi.get_default_midi_output_device_id
    @output = PortMidi::MidiOutputStream.new device_id
  end

  def chime(time)
    chime_time = ChimeTime.new(time)

    chime_time.quarters.times { ring MidiNotes::QUARTER, 1.2 }
    if chime_time.whole_hour?
      sleep 0.2
      chime_time.hours.times { ring MidiNotes::HOUR, 1.4 }
    end

    grand_ringing if chime_time == @alarm_chime_time

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

  private def bim_bam(base_note, interval, times = nil)
    bim_bam_proc = -> do
      ring base_note + 2, interval
      ring base_note, interval
    end

    if times
      times.times &bim_bam_proc
    else
      loop &bim_bam_proc
    end
  end

  private def grand_ringing
    channels = [] of Channel(Int32)

    4.times do |i|
      channel = Channel(Int32).new
      channels << channel

      spawn do
        sleep i * 6
        bim_bam 32 + (i * 7), 0.9 - (i * 0.15), nil

        channel.send 0
      end
    end

    # wait for the fibers to finish (although they will never finish)
    channels.each {|c| c.receive }
  end
end

alarm_time = Time.new(2000, 1, 1, 21, 30) # only hour and minute are relevant
puts "Current time " + Time.now.to_s("%I:%M")
puts "Alarm set to " + alarm_time.to_s("%I:%M")

loop do
  minute = Time.now.minute
  wait_minutes = 15 - (minute % 15)
  puts "Next chime in #{wait_minutes} minutes"
  sleep wait_minutes * 60

  BellTower.new(0, alarm_time).chime(Time.now)
end
