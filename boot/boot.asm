[BITS 16]               
[ORG 0x7C00]            

start:
    ; segments
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; save boot drive
    mov [boot_drive], dl

    ; show splash screen
    mov si, splash_msg
    call print_string
    
wait_for_key:
    mov ah, 0x00
    int 0x16
    cmp al, 0x0D        ; enter key
    jne wait_for_key

    ; clear screen before loading kernel
    mov ax, 0x13        ; reset video mode
    int 0x10

    ; load kernel from disk
    mov bx, 0x1000
    mov ah, 0x02
    mov al, 32          ; amount of sectors
    mov ch, 0           
    mov cl, 2           ; start from sector 2
    mov dh, 0           
    mov dl, [boot_drive]
    int 0x13
    jc disk_error

    ; go to kernel
    jmp 0x0000:0x1000

disk_error:
    mov si, error_msg
    call print_string
    jmp $

print_string:
    mov ah, 0x0E
print_char:
    lodsb
    test al, al
    jz print_done
    int 0x10
    jmp print_char
print_done:
    ret

; Messages
splash_msg db 'Welcome to PongOS!', 13, 10
          db 'A simple OS for playing Pong', 13, 10, 13, 10
          db 'Controls:', 13, 10
          db 'Left paddle:  W/S', 13, 10
          db 'Right paddle: Up/Down arrows', 13, 10, 13, 10
          db 'Press ENTER to start...', 13, 10, 0
error_msg  db 'Error loading kernel!', 13, 10, 0
boot_drive db 0

times 510-($-$$) db 0
dw 0xAA55