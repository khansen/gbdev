def lfsr_15bit(seed, length):
    lfsr = seed & 0x7FFF  # Ensure the seed is 15 bits (0 to 32767)
    result = []
    
    for _ in range(length):
        result.append(lfsr & 0xFF)  # Output the lower 8 bits of the LFSR
        
        # XOR tap bits (15th and 14th bit) to feedback into the LFSR
        bit = ((lfsr >> 14) ^ (lfsr >> 13)) & 1
        
        # Shift LFSR and input the new bit at the top (15th bit)
        lfsr = ((lfsr << 1) & 0x7FFF) | bit
    
    return result

# Generate 4096 bytes using an arbitrary 15-bit seed
seed = 0x1ACE  # Example seed
lfsr_values = lfsr_15bit(seed, 4096)

# Format the output as hex, 16 values per line
formatted_output = []
for i in range(0, len(lfsr_values), 16):
    formatted_output.append(
        ".byte " + ",".join(f"0x{val:02X}" for val in lfsr_values[i:i+16])
    )

# Join all lines for the final output
output_string = "\n".join(formatted_output)
print(output_string)

