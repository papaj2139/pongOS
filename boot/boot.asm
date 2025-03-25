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
    mov dl, 0x00        ; force THAT ITS A FUCKING FLOPPY DRIVE
    mov [boot_drive], dl
    mov si, boot_drive_msg
    call print_string
    mov al, dl          ; print actual dl, not memory
    call print_hex
    mov si, newline
    call print_string

    ; show splash screen
    mov si, splash_msg
    call print_string
    
wait_for_key:
    mov ah, 0x00
    int 0x16
    cmp al, 0x0D        ; enter key
    jne wait_for_key

    ; init disk
    mov ah, 0x00      ; reset disk
    mov dl, [boot_drive]
    int 0x13
    jc disk_error

    ; clear screen and set video mode
    mov ax, 0x0013    ; VGA 320x200
    int 0x10
    
    ; save BIOS disk parameters
    push es           ; saves ES
    mov ah, 0x08      ; get parameters
    mov dl, [boot_drive]
    int 0x13
    jc disk_error
    
    ; calculate and save disk parameters
    and cl, 0x3F      ; mask off cylinder bits
    mov byte [sectors_per_track], cl
    mov byte [heads_per_cylinder], dh
    mov byte [cylinders], ch
    pop es           

    ; load kernel from disk
    xor ax, ax        ; sets AX to 0
    mov es, ax        ; ES = 0
    mov bx, 0x1000    ; loads address
    mov ah, 0x02      ; read the sectors
    mov al, 10        ; how many sectors?
    mov ch, 0         ; cylinder 0
    mov cl, 2         ; starts from sector 2
    mov dh, 0         ; head 0
    mov dl, [boot_drive]
    int 0x13
    jc disk_error

    ; debug after load
    mov si, loaded_msg
    call print_string
    mov al, ah
    call print_hex
    mov si, newline
    call print_string

    ; go to kernel
    mov dl, [boot_drive]
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

print_hex:
    pusha
    mov bl, al
    shr al, 4
    mov bx, hex_chars
    xlat
    mov ah, 0x0E
    int 0x10
    mov al, bl
    and al, 0x0F
    mov bx, hex_chars
    xlat
    mov ah, 0x0E
    int 0x10
    popa
    ret

splash_msg db 'Welcome to PongOS!', 13, 10
          db 'A simple OS for playing Pong', 13, 10, 13, 10
          db 'Controls:', 13, 10
          db 'Left paddle:  W/S', 13, 10
          db 'Right paddle: Up/Down arrows', 13, 10
          db 'C: Shell', 13, 10, 13, 10
          db 'Press ENTER to start...', 13, 10, 0
error_msg  db 'Error loading kernel!', 13, 10, 0
boot_drive_msg db 'Boot drive at start: ', 0
loaded_msg db 'Kernel loaded, status: ', 0
newline    db 13, 10, 0
hex_chars  db '0123456789ABCDEF'

times 510-($-$$) db 0
dw 0xAA55

section .data
boot_drive        db 0
sectors_per_track db 18
heads_per_cylinder db 2
cylinders         db 80