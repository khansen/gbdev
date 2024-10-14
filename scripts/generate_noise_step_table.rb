def is_integer?(input)
  Integer(input)
  true
rescue ArgumentError
  false
end

hz_table = [
     8.00,     9.26,    10.72,    12.40,    14.36,    16.62,    19.23,    22.26,
    25.76,    29.82,    34.52,    39.95,    46.24,    53.52,    61.94,    71.69,
    82.98,    96.04,   111.16,   128.66,   148.91,   172.35,   199.49,   230.89,
   267.24,   309.31,   358.00,   414.36,   479.59,   555.09,   642.47,   743.61,
   860.67,   996.16,  1152.98,  1334.48,  1544.56,  1787.71,  2069.13,  2394.86,
  2771.87,  3208.22,  3713.27,  4297.82,  4974.40,  5757.49,  6663.85,  7712.89,
  8927.07, 10332.40, 11958.95, 13841.57, 16020.55, 18542.55, 21461.57, 24840.11,
 28750.51, 33276.50, 38514.98, 44578.12, 51595.73, 59718.08, 69119.08, 80000.00]

def hz_to_step(hz, mixer_hz, sample_length)
#  period = 1 / hz
#  samples_per_period = mixer_hz * period
#  (0x10000 * sample_length / samples_per_period).round
  ((hz / mixer_hz) * sample_length * 0x10000).round
end

if ARGV.length != 2
  puts "Please provide mixer frequency and sample length."
  exit -1
end

if !is_integer?(ARGV[0])
  puts "First parameter (mixer frequency) must be an integer."
  exit -1
end
mixer_hz = Integer(ARGV[0])

if !is_integer?(ARGV[1])
  puts "Second parameter (sample length) must be an integer."
  exit -1
end
sample_length = Integer(ARGV[1])

puts "noise_step_table:"

(0..7).each do |index_hi|
  puts ".word %s" % (0..7).map{|index_lo| hz_to_step(hz_table[index_hi*8 + index_lo], mixer_hz, sample_length)}.map{|step| "0x%08x" % step}.join(',')
end
