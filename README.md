# PongOS
A minimalist operating system that does one thing - plays Pong! Written entirely in x86 real mode assembly.

## About
PongOS boots directly into a two-player Pong game. 320x200 VGA, and has a shell for customization features.

## Features
- Boots directly to Pong game
- Two-player support
- Double-buffered graphics
- Runs in 16-bit real mode
- Tiny footprint (<4KB)
- A shell with customization options

## Controls
- **Left Paddle**: W (up) / S (down)
- **Right Paddle**: ↑ (up) / ↓ (down)
- **Shell**: C (Press during the game)
- **Start Game**: Press Enter at the boot screen

## Building
Requires:
- NASM 
- GNU Make
- QEMU for testing (optional)

Build commands:
```bash
make        # Build PongOS
gmake       # For FreeBSD
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
- disk I/O (next update, 1.4)

## License
Feel free to use this code however you'd like!
