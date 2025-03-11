def hz_to_ym2413_period(hz)
  octave = 3
  ((hz * (2**18) / 50000) / (2 ** (octave-1))).floor()
end

def find_optimal_fnum(hz)
  best_fnum = nil
  best_octave = nil

  # Try different octaves (0 to 7)
  (0..7).each do |octave|
    fnum = ((hz * (2**18) / 50000) / (2 ** (octave-1))).floor

    # Ensure fnum is within valid range (0-511)
    if fnum.between?(0, 511)
      best_fnum = fnum
      best_octave = octave
      break  # Stop at the first valid octave
    end
  end

  return nil if best_fnum.nil?  # No valid representation found

  # Extract register values
  reg_10 = best_fnum & 0xFF  # Lower 8 bits of fnum
  reg_20 = ((best_fnum >> 8) & 0x01) | (best_octave << 1)  # Upper bit of fnum + octave (bits 1-3)

  {
    frequency: hz,
    fnum: best_fnum,
    octave: best_octave,
    reg_10: reg_10,
    reg_20: reg_20
  }
end

notes_in_hz = [
41.20,43.65,46.25,49.00,51.91,55.00,58.27,61.74,
65.41,69.30,73.42,77.78,82.41,87.31,92.50,98.00,103.83,110.0,116.54,123.47,
130.81,138.59,146.83,155.56,164.81,174.61,185.0,196.0,207.65,220.0,233.08,246.94,
261.63,277.18,293.66,311.13,329.63,349.23,369.99,392.0,415.3,440.0,466.16,493.88,
523.25,554.37,587.33,622.25,659.25,698.46,739.99,783.99,830.61,880.0,932.33,987.77,
1046.5,1108.73,1174.66,1244.51,1318.51,1396.91,1479.98,1567.98,1661.22,1760,1864.66,1975.53,
2093,2217.46,2349.32,2489.02,2637.02,2793.83,2959.96,3135.96,3322.44,3520,3729.31,3951.07,
]

PERIOD_BITS = 11
steps_per_note = (((2 ** PERIOD_BITS) - 1) / notes_in_hz.length).floor()

note_index = 0
step_delta_hz = 0
note_hz = 0
period_hz_values = (0..((notes_in_hz.length - 1) * steps_per_note)).map do |period_value|
  if (period_value % steps_per_note) == 0 then
    note_hz = notes_in_hz[note_index]
    note_index += 1
    if note_index < notes_in_hz.length then
      next_note_hz = notes_in_hz[note_index]
      step_delta_hz = (next_note_hz - note_hz) / steps_per_note
    end
  else
    note_hz += step_delta_hz
  end
  note_hz
end

note_fnums = period_hz_values.map{|hz| find_optimal_fnum(hz)}
puts "PeriodToReg1x2xValues:"
note_fnums.each_slice(16) do |slice|
  puts ".dw %s" % (slice.map{|result| "$%03x" % ((result[:reg_20] << 8) | result[:reg_10])}.join(','))
end

note_to_period_table = (0..(notes_in_hz.length - 1)).map{|note| note * steps_per_note }
puts "NoteToPeriod:"
note_to_period_table.each_slice(16) do |slice|
  puts ".dw %s" % (slice.map{|period| "%d" % period}.join(','))
end
