# PongOS
A minimalist operating system that does one thing - plays Pong! Written entirely in x86 real mode assembly.

## About
PongOS boots directly into a two-player Pong game. 320 x 200 VGA 

## Features
- Boots directly to Pong game
- Two player support
- Smooth paddle movement
- Double-buffered graphics
- Runs in 16-bit real mode
- Tiny footprint (<1KB)

## Controls
- **Left Paddle**: W (up) / S (down)
- **Right Paddle**: ↑ (up) / ↓ (down)
- Press Enter at boot screen to start

## Building
Requires:
- NASM assembler
- GNU Make
- QEMU for testing (optional)

Build commands:
```bash
make        # Build PongOS
make run    # Build and run in QEMU
make clean  # Clean build files
```

## Details
- Written in x86 assembly (NASM syntax)
- Runs in 16-bit real mode
- Uses VGA mode 13h (320x200, 256 colors)
- Double buffered graphics 
- Fits in a single floppy disk image

## Plans
- Make it do some fucking fancy beep boop sounds with PC speaker
- Try to test it on REAL hardware (altho i DOUBT it will work)
- Font rendering forrr scores

## License
Feel free to use this code however you'd like!
