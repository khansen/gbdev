arr = []
for i in 0..7 do
  divider = i > 0 ? i : 0.5
  for j in 0..15 do
    shift = j
    hz = (262144 / (divider * 2**shift)).round()
    arr.push([hz, (j << 4) | i])
  end
end
sorted = arr.sort {|a,b| a[0] <=> b[0]}
uni = sorted.uniq {|v| v[0]}
puts "NR43Values:"
puts "db %s" % (uni.map {|v| "$%02x" % v[1]}.join(","))
