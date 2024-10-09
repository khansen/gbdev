def lfsr_7bit_normalized(seed, length):
    lfsr = seed & 0x7F  # Ensure the seed is 7 bits (0 to 127)
    result = []
    
    for _ in range(length):
        # Normalize LFSR output to the range -128 to 127
        normalized_value = (lfsr * 2) - 128
        result.append(normalized_value)
        
        # XOR tap bits (7th and 6th bit) to feedback into the LFSR
        bit = ((lfsr >> 6) ^ (lfsr >> 5)) & 1
        
        # Shift LFSR and input the new bit at the top (7th bit)
        lfsr = ((lfsr << 1) & 0x7F) | bit
    
    return result

# Generate 4096 bytes using an arbitrary 7-bit seed and normalize to -128 to 127 range
seed = 0x5E  # Example seed
lfsr_values = lfsr_7bit_normalized(seed, 4096)

# Format the output as hex, 16 values per line
formatted_output = []
for i in range(0, len(lfsr_values), 16):
    formatted_output.append(
        ".byte " + ",".join(f"0x{(val & 0xFF):02X}" for val in lfsr_values[i:i+16])
    )

# Join all lines for the final output
output_string = "\n".join(formatted_output)
print(output_string)

