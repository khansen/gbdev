# Game Boy development

## How to build the projects

### Game Boy

- Install rgbds: https://rgbds.gbdev.io/ (tested on version: 0.8.0)
- Clone the repository https://github.com/khansen/xm2nes/, check out the `xm2gb` branch, build and install the `xm2gb` tool
- In a project folder (e.g., `music/super-mario-land/`), run `make`

### Game Boy Advance

- Install `arm-none-eabi-gcc`. On Mac, you can get it via Homebrew: `brew install --cask gcc-arm-embedded`
- Clone the repository https://github.com/khansen/xm2nes/, check out the `xm2gba` branch, build and install the `xm2gba` tool
- In a project folder (e.g., `music/bob-omb-battlefield-gba/`), run `make`

## Video recordings

To see the projects in action, visit https://www.youtube.com/notube4me

## Articles

- [The process of porting an NES sound engine to Game Boy](https://github.com/khansen/gbdev/blob/master/articles/porting-nes-sound-engine/index.md)

## A selection of useful resources

- https://gbdev.io/pandocs/: Comprehensive technical reference
- https://github.com/vinheim3/tetris-gb-disasm/: Comprehensive disassembly of Tetris
- https://rgbds.gbdev.io/docs/master/gbz80.7: CPU opcode reference
- https://gbdev.gg8.se/wiki
- https://github.com/tbsp/simple-gb-asm-examples
- https://gbdev.io/gb-asm-tutorial/
- https://github.com/ahrnbom/gbapfomgd: Game Boy Assembly Programming for the Modern Game Developer
- https://16-bits.org/ft2.php: FastTracker II clone
- https://openmpt.org: OpenMPT is a powerful audio application that makes writing music fun, easy and efficient

