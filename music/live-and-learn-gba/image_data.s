    .section .rodata  // Read-only data section

    .global image_data // Make the symbol accessible from other files
image_data:
@ magick input.png -resize 160x128 -depth 8 -type TrueColor -define endian=msb rgb:output.raw
@ python3 ./convert_rbg24_to_rgb16.py
.incbin "background.bin"

