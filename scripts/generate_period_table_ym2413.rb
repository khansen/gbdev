require 'bigdecimal'
require 'bigdecimal/util'

def find_optimal_fnum(hz)
  min_error = nil
  best_fnum = nil
  best_octave = nil

  clock  = 3579545.to_d
  base   = (clock / 72).to_d 
  factor = (2 ** 18).to_d 
  # Try different octaves (0 to 7)
  (0..7).each do |octave|
    scale  = (2.to_d ** (octave.to_d - 1)).to_d
    fnum = ((hz * factor) / base / scale).round

    next unless fnum.between?(0, 511)

    actual_hz = (fnum * scale * base) / factor
    error = (actual_hz - hz).abs

    if min_error.nil? || error < min_error
      min_error = error
      best_fnum = fnum
      best_octave = octave
    end
  end

  return nil if best_fnum.nil?  # No valid representation found

  # Extract register values
  reg_10 = best_fnum & 0xFF  # Lower 8 bits of fnum
  reg_20 = ((best_fnum >> 8) & 0x01) | (best_octave << 1)  # Upper bit of fnum + octave (bits 1-3)

#  puts "freq: %f" % hz
#  puts "fnum: %d" % best_fnum
#  puts "best octave: %d" % best_octave
#  puts "min error: %f" % min_error
  {
    frequency: hz,
    fnum: best_fnum,
    octave: best_octave,
    reg_10: reg_10,
    reg_20: reg_20
  }
end

notes_in_hz = [
                                      41.2034, 43.6535, 46.2493, 48.9994, 51.9131, 55.0,     58.2705, 61.7354,
  65.4064, 69.2957, 73.4162, 77.7817, 82.4069, 87.3071, 92.4986, 97.9989, 103.8262, 110.0,   116.5409, 123.4708,
  130.8128, 138.5913, 146.8324, 155.5635, 164.8138, 174.6141, 184.9972, 195.9977, 207.6523,  220.0,    233.0819, 246.9417,
  261.6256, 277.1826, 293.6648, 311.1270, 329.6276, 349.2282, 369.9944, 391.9954, 415.3047,  440.0,    466.1638, 493.8833,
  523.2511, 554.3653, 587.3295, 622.2540, 659.2551, 698.4565, 739.9888, 783.9909, 830.6094,  880.0,    932.3275, 987.7666,
  1046.5023,1108.7305,1174.6591,1244.5079,1318.5102,1396.9129,1479.9777,1567.9817,1661.2188,1760.0,   1864.6550,1975.5332,
  2093.0045,2217.4610,2349.3181,2489.0159,2637.0205,2793.8259,2959.9554,3135.9635,3322.4376,3520.0,   3729.3101,3951.0664
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
puts "PeriodToFMReg1x2xValues:"
note_fnums.each_slice(16) do |slice|
  puts ".dw %s" % (slice.map{|result| "$%03x" % ((result[:reg_20] << 8) | result[:reg_10])}.join(','))
end

note_to_period_table = (0..(notes_in_hz.length - 1)).map{|note| note * steps_per_note }
puts "NoteToFMPeriod:"
note_to_period_table.each_slice(16) do |slice|
  puts ".dw %s" % (slice.map{|period| "%d" % period}.join(','))
end
