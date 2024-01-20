i = 0
arr = []
while i < Math::PI*2 do
  arr.push(Math.sin(i))
  i += (Math::PI*2)/32
end
nibbles = arr.map {|v| (v*7).round() + 8}
i = 0
while i < 32
  puts "db $%02x" % ((nibbles[i] << 4) | nibbles[i+1])
  i += 2
end

