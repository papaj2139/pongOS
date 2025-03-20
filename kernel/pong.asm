PADDLE_HEIGHT    equ 30
PADDLE_WIDTH     equ 5
SCREEN_WIDTH     equ 320
SCREEN_HEIGHT    equ 200
LEFT_X          equ 10
RIGHT_X         equ SCREEN_WIDTH - PADDLE_WIDTH - 10
BUFFER_SEG      equ 0x1000  

; scan codes
SCANCODE_W      equ 0x11
SCANCODE_S      equ 0x1F
SCANCODE_UP     equ 0x48
SCANCODE_DOWN   equ 0x50

pong_main:
    ; initialize paddle positions, center them
    mov word [left_paddle_y], 100     
    mov word [right_paddle_y], 100    
    
    ; allocate buffer memory
    push es
    mov ax, BUFFER_SEG
    mov es, ax
    xor di, di
    mov cx, SCREEN_WIDTH * SCREEN_HEIGHT
    xor al, al
    rep stosb
    pop es

game_loop:
    ; draw to buffer
    mov ax, BUFFER_SEG
    mov es, ax
    
    ; clear buffer
    xor di, di
    xor al, al
    mov cx, SCREEN_WIDTH * SCREEN_HEIGHT
    rep stosb
    
    call update_ball
    
    call draw_ball
    
    ; draws left paddle
    mov ax, LEFT_X
    mov bx, [left_paddle_y]
    mov cx, PADDLE_HEIGHT
    mov dl, 0x0F 
    call draw_paddle

    ; ^^ but right
    mov ax, RIGHT_X
    mov bx, [right_paddle_y]
    mov cx, PADDLE_HEIGHT
    mov dl, 0x0F       
    call draw_paddle
    
    ; copies buffer to video memory
    push ds
    mov ax, BUFFER_SEG
    mov ds, ax
    mov ax, 0xA000
    mov es, ax
    xor si, si
    xor di, di
    mov cx, SCREEN_WIDTH * SCREEN_HEIGHT / 2  ;move 2 bytes at a time 
    rep movsw
    pop ds
    
    ; keyboard input handling
    mov ah, 0x01       ; is key avaible?
    int 0x16
    jz no_key          ; if nah then fuck you
    
    mov ah, 0x00       ; get keystroe
    int 0x16
    
    cmp al, 'w'        
    je move_left_up
    cmp al, 's'        
    je move_left_down
    cmp ah, 0x48       
    je move_right_up
    cmp ah, 0x50       
    je move_right_down
    jmp no_key

move_left_up:
    mov ax, [left_paddle_y]
    cmp ax, 5
    jle no_key
    sub ax, 5          ; speed of paddle
    mov [left_paddle_y], ax
    jmp no_key

move_left_down:
    mov ax, [left_paddle_y]
    cmp ax, SCREEN_HEIGHT - PADDLE_HEIGHT - 5
    jge no_key
    add ax, 5          ; spped
    mov [left_paddle_y], ax
    jmp no_key

move_right_up:
    mov ax, [right_paddle_y]
    cmp ax, 5
    jle no_key
    sub ax, 5          ; speed
    mov [right_paddle_y], ax
    jmp no_key

move_right_down:
    mov ax, [right_paddle_y]
    cmp ax, SCREEN_HEIGHT - PADDLE_HEIGHT - 5
    jge no_key
    add ax, 5          ; speed
    mov [right_paddle_y], ax
    jmp no_key

no_key:
    mov cx, 500       
delay_loop:
    loop delay_loop
    
    jmp game_loop


draw_paddle:
    push ax
    push bx
    push cx
    
    mov di, bx         ; y position
    imul di, 320       ; y * screen width
    add di, ax         ; add x position
    mov al, dl         ; color
    
.draw_line:
    mov byte [es:di], al
    mov byte [es:di+1], al       
    mov byte [es:di+2], al      
    mov byte [es:di+3], al      
    mov byte [es:di+4], al      
    add di, 320                 
    loop .draw_line
    
    pop cx
    pop bx
    pop ax
    ret

left_paddle_y:    dw 100
right_paddle_y:   dw 100

%include "kernel/ball.asm"
%include "kernel/sound.asm"