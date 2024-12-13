import struct

# Read the raw RGB file
with open("output.raw", "rb") as f:
    rgb_data = f.read()

# Convert to RGB555
rgb555_data = bytearray()
for i in range(0, len(rgb_data), 3):  # Process 3 bytes at a time (R, G, B)
    r = rgb_data[i] >> 3
    g = rgb_data[i+1] >> 3
    b = rgb_data[i+2] >> 3
    rgb555 = (b << 10) | (g << 5) | r
    rgb555_data.extend(struct.pack("<H", rgb555))  # Little-endian 16-bit

# Save the RGB555 data
with open("output.rgb555", "wb") as f:
    f.write(rgb555_data)

