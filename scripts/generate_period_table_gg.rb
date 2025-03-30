require 'bigdecimal'
require 'bigdecimal/util'

def hz_to_gg_period(hz)
  clock  = 3579545.to_d
  ideal = clock / (32 * hz.to_d)
  floor_val = ideal.floor
  ceil_val = ideal.ceil
  floor_hz = clock / (32 * floor_val)
  ceil_hz = clock / (32 * ceil_val)
  floor_error = (floor_hz - hz.to_d).abs
  ceil_error  = (ceil_hz - hz.to_d).abs
  best_val = if floor_error < ceil_error then floor_val else ceil_val end
  0x7ff - best_val*2
end

octaves_in_hz = [
  [110.0,   116.5409, 123.4708],
  [130.8128, 138.5913, 146.8324, 155.5635, 164.8138, 174.6141, 184.9972, 195.9977, 207.6523,  220.0,    233.0819, 246.9417],
  [261.6256, 277.1826, 293.6648, 311.1270, 329.6276, 349.2282, 369.9944, 391.9954, 415.3047,  440.0,    466.1638, 493.8833],
  [523.2511, 554.3653, 587.3295, 622.2540, 659.2551, 698.4565, 739.9888, 783.9909, 830.6094,  880.0,    932.3275, 987.7666],
  [1046.5023,1108.7305,1174.6591,1244.5079,1318.5102,1396.9129,1479.9777,1567.9817,1661.2188,1760.0,   1864.6550,1975.5332],
  [2093.0045,2217.4610,2349.3181,2489.0159,2637.0205,2793.8259,2959.9554,3135.9635,3322.4376,3520.0,   3729.3101,3951.0664]
]
puts "PSGPeriodTable:"
octaves_in_hz.each do |octave|
#	puts ".dw %s" % (octave.map{|hz| hz_to_gg_period(hz)}).map{|period| "$%03x" % (0x3ff - (period/2))}.join(',')
	puts ".dw %s" % (octave.map{|hz| hz_to_gg_period(hz)}).map{|period| "$%03x" % period}.join(',')
end
