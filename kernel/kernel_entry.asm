[BITS 16]              
[ORG 0x1000]          

start:
    ; sets up stack
    mov ax, 0x2000
    mov ss, ax
    mov sp, 0xFFFF

    ; setup VGA 
    mov ax, 0x13       
    int 0x10

    ; jump to game
    jmp pong_main

%include "kernel/pong.asm"
%include "kernel/ball.asm"
%include "kernel/sound.asm"
%include "kernel/shell.asm"