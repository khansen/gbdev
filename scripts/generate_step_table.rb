def is_integer?(input)
  Integer(input)
  true
rescue ArgumentError
  false
end

def period_to_step(period, mixer_hz, sample_length)
  ((0x200000000 * sample_length) / (2048 - period) / mixer_hz).round
end

if ARGV.length != 3
  puts "Please provide table label prefix, mixer frequency, and sample length."
  exit -1
end

table_label_prefix = ARGV[0]

if !is_integer?(ARGV[1])
  puts "Second parameter (mixer frequency) must be an integer."
  exit -1
end
mixer_hz = Integer(ARGV[1])

if !is_integer?(ARGV[2])
  puts "Third parameter (sample length) must be an integer."
  exit -1
end
sample_length = Integer(ARGV[2])

puts "%s_step_table:" % table_label_prefix

(0..127).each do |period_hi|
  puts ".word %s" % (0..15).map{|period_lo| period_to_step(period_hi*16 + period_lo, mixer_hz, sample_length)}.map{|step| "0x%08x" % step}.join(',')
end
