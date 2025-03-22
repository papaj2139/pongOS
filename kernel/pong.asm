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
    
    call draw_scores      
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

draw_number:
    pusha
    mov bx, di        ; save original position
    
    cmp al, 0
    je draw_0
    cmp al, 1
    je draw_1
    cmp al, 2
    je draw_2
    cmp al, 3
    je draw_3
    cmp al, 4
    je draw_4
    cmp al, 5
    je draw_5
    cmp al, 6
    je draw_6
    cmp al, 7
    je draw_7
    cmp al, 8
    je draw_8
    cmp al, 9
    je draw_9
    jmp draw_done


draw_0:
    mov di, bx
    mov cx, 5
.vert:
    mov byte [es:di], dl      ; left
    mov byte [es:di+4], dl    ; right
    add di, 320
    loop .vert
    
    mov di, bx        ; top line
    mov cx, 5
.top:
    mov byte [es:di], dl
    inc di
    loop .top
    
    mov di, bx        ; bottom line
    add di, 320*4     ; move to last row
    mov cx, 5
.bottom:
    mov byte [es:di], dl
    inc di
    loop .bottom
    jmp draw_done

draw_1:
    mov di, bx
    mov cx, 5
.vert:
    mov byte [es:di+2], dl    ; center line
    add di, 320
    loop .vert
    jmp draw_done

draw_2:
    mov di, bx
    mov cx, 5         ; top horizontal
.top:
    mov byte [es:di], dl
    inc di
    loop .top
    
    mov di, bx        ; right vertical top
    add di, 4
    mov cx, 2
.right_top:
    mov byte [es:di], dl
    add di, 320
    loop .right_top
    
    sub di, 4         ; middle horizontal
    mov cx, 5
.mid:
    mov byte [es:di], dl
    inc di
    loop .mid
    
    sub di, 5         ; left vertical bottom
    mov cx, 2
.left_bot:
    mov byte [es:di], dl
    add di, 320
    loop .left_bot
    
    mov cx, 5         ; bottom horizontal
.bot:
    mov byte [es:di], dl
    inc di
    loop .bot
    jmp draw_done

draw_3:
    mov di, bx
    mov cx, 5
.top:
    mov byte [es:di], dl
    inc di
    loop .top
    
    mov di, bx
    add di, 4
    mov cx, 5
.right:
    mov byte [es:di], dl
    add di, 320
    loop .right
    
    mov di, bx
    add di, 320*2
    mov cx, 4
.mid:
    mov byte [es:di], dl
    inc di
    loop .mid
    
    mov di, bx
    add di, 320*4
    mov cx, 5
.bot:
    mov byte [es:di], dl
    inc di
    loop .bot
    jmp draw_done

draw_4:
    mov di, bx
    mov cx, 3         ; left vertical top
.left_vert:
    mov byte [es:di], dl
    add di, 320
    loop .left_vert

    mov di, bx
    mov cx, 5         ; right vertical
.right_vert:
    mov byte [es:di+4], dl
    add di, 320
    loop .right_vert

    mov di, bx        ; horizontal middle
    add di, 320*2
    mov cx, 5
.mid:
    mov byte [es:di], dl
    inc di
    loop .mid
    jmp draw_done

draw_5:
    mov di, bx
    mov cx, 5         ; top horizontal
.top:
    mov byte [es:di], dl
    inc di
    loop .top

    mov di, bx        ; left vertical top
    mov cx, 2
.left_vert:
    mov byte [es:di], dl
    add di, 320
    loop .left_vert

    mov cx, 5         ; middle horizontal
.mid:
    mov byte [es:di], dl
    inc di
    loop .mid

    mov di, bx        ; right vertical bottom
    add di, 320*3
    mov cx, 2
.right_vert:
    mov byte [es:di+4], dl
    add di, 320
    loop .right_vert

    mov cx, 5         ; bottom horizontal
.bot:
    mov byte [es:di], dl
    inc di
    loop .bot
    jmp draw_done

draw_6:
    mov di, bx
    mov cx, 5         ; left vertical
.left_vert:
    mov byte [es:di], dl
    add di, 320
    loop .left_vert

    mov di, bx        ; top horizontal
    mov cx, 5
.top:
    mov byte [es:di], dl
    inc di
    loop .top

    mov di, bx        ; middle horizontal
    add di, 320*2
    mov cx, 5
.mid:
    mov byte [es:di], dl
    inc di
    loop .mid

    mov di, bx        ; right vertical bottom
    add di, 320*3
    mov cx, 2
.right_vert:
    mov byte [es:di+4], dl
    add di, 320
    loop .right_vert

    mov di, bx        ; bottom horizontal
    add di, 320*4
    mov cx, 5
.bot:
    mov byte [es:di], dl
    inc di
    loop .bot
    jmp draw_done

draw_7:
    mov di, bx
    mov cx, 5         ; top horizontal
.top:
    mov byte [es:di], dl
    inc di
    loop .top

    mov di, bx        ; right vertical
    mov cx, 5
.vert:
    mov byte [es:di+4], dl
    add di, 320
    loop .vert
    jmp draw_done

draw_8:
    mov di, bx
    mov cx, 5         ; full height verticals
.vert:
    mov byte [es:di], dl      ; left
    mov byte [es:di+4], dl    ; right
    add di, 320
    loop .vert

    mov di, bx        ; top horizontal
    mov cx, 5
.top:
    mov byte [es:di], dl
    inc di
    loop .top

    mov di, bx        ; middle horizontal
    add di, 320*2
    mov cx, 5
.mid:
    mov byte [es:di], dl
    inc di
    loop .mid

    mov di, bx        ; bottom horizontal
    add di, 320*4
    mov cx, 5
.bot:
    mov byte [es:di], dl
    inc di
    loop .bot
    jmp draw_done

draw_9:
    mov di, bx
    mov cx, 3         ; left vertical top
.left_vert:
    mov byte [es:di], dl
    add di, 320
    loop .left_vert

    mov di, bx        ; right vertical full
    mov cx, 5
.right_vert:
    mov byte [es:di+4], dl
    add di, 320
    loop .right_vert

    mov di, bx        ; top horizontal
    mov cx, 5
.top:
    mov byte [es:di], dl
    inc di
    loop .top

    mov di, bx        ; middle horizontal
    add di, 320*2
    mov cx, 5
.mid:
    mov byte [es:di], dl
    inc di
    loop .mid

    mov di, bx        ; bottom horizontal
    add di, 320*4
    mov cx, 5
.bot:
    mov byte [es:di], dl
    inc di
    loop .bot
    jmp draw_done

draw_done:
    popa
    ret

draw_scores:
    pusha
    ; Draw left score
    mov ax, [left_score]
    xor dx, dx
    mov bx, 10
    div bx           ; AX = quotient, DX = remainder
    
    push dx          ; save remainder (ones)
    
    ; Draw tens digit if > 0
    test ax, ax
    jz .left_ones
    mov di, 320*10+45  ; position for tens
    mov al, al        ; quotient is already in AL
    mov dl, 0x0F      ; color
    call draw_number
    
.left_ones:
    pop ax           ; get ones digit
    mov di, 320*10+50
    mov dl, 0x0F
    call draw_number
    
    ; Right score
    mov ax, [right_score]
    xor dx, dx
    mov bx, 10
    div bx
    
    push dx
    test ax, ax
    jz .right_ones
    mov di, 320*10+245
    mov al, al
    mov dl, 0x0F
    call draw_number
    
.right_ones:
    pop ax
    mov di, 320*10+250
    mov dl, 0x0F
    call draw_number
    
    popa
    ret

left_paddle_y:    dw 100
right_paddle_y:   dw 100
left_score:       dw 0    
right_score:      dw 0

%include "kernel/ball.asm"
%include "kernel/sound.asm"