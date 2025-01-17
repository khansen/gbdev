/* gba.ld: Linker script for GBA */
MEMORY {
    rom (rx) : ORIGIN = 0x08000000, LENGTH = 32M
    iwram (rwx) : ORIGIN = 0x03000000, LENGTH = 32k
}

SECTIONS
{
    .rom 0x08000000 : AT(0x00000000) {
        *(.header)
        . = ALIGN(4);
        *(.text*)
        . = ALIGN(4);
        *(.rodata*)
        . = ALIGN(4);
    } > rom = 0xff

    /* Place uninitialized data (.bss) in IWRAM */
    .bss 0x03000000 : { *(.bss*) }

    /* Discard all other unexpected sections */
    /DISCARD/ : {
        *(*)
    }
}
