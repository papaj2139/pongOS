play_sound:
    pusha
    
    ; set up PIT channel 2
    mov al, 0xb6      ; command: square wave
    out 0x43, al
    
    ; divisor (1193180 / frequency)
    mov bx, ax        ; store the frequency
    mov ax, 1193      ; here i use  1193 instead of 1193180 to avoid overflow
    mov dx, 0
    mul bx            ; multiply by frequency
    mov bx, 1000      ; NOW divide by 1000
    div bx
    
    ; sends divisor to PIT
    out 0x42, al      ; low byte
    mov al, ah
    out 0x42, al      ; high byte
    
    ; speaker ON
    in al, 0x61
    or al, 0x03       ; sets bits 0 and 1
    out 0x61, al
    
    popa
    ret

stop_sound:
    pusha
    in al, 0x61
    and al, 0xFC      ; clears the bits 0 and 1
    out 0x61, al
    popa
    ret