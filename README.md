# PongOS
A minimalist operating system that does one thing - plays Pong! Written entirely in x86 real mode assembly.

## About
PongOS boots directly into a two-player Pong game. 320 x 200 VGA 

## Features
- Boots directly to Pong game
- Two player support
- Double-buffered graphics
- Runs in 16-bit real mode
- Tiny footprint (<3KB)
- A shell

## Controls
- **Left Paddle**: W (up) / S (down)
- **Right Paddle**: ↑ (up) / ↓ (down)
- Press Enter at boot screen to start
- **Shell**: C

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
make run-pa # Or you can run with pulseaudio if you dont have alsa
```

## Details
- Written in x86 assembly (NASM syntax)
- Runs in 16-bit real mode
- Uses VGA mode 13h (320x200, 256 colors)
- Double buffered graphics 
- Fits in a single floppy disk image

## Plans
- Try to test it on REAL hardware (altho i DOUBT it will work)
- disk I/O (next update, 1.4)

## License
Feel free to use this code however you'd like!
