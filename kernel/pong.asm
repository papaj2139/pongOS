
PADDLE_HEIGHT   equ 30
PADDLE_WIDTH    equ 5
SCREEN_WIDTH    equ 320
SCREEN_HEIGHT   equ 200
LEFT_X          equ 10
RIGHT_X         equ SCREEN_WIDTH - PADDLE_WIDTH - 10
BUFFER_SEG      equ 0x8000  ; segment for the back buffer

; keyboard scancodes
SCANCODE_W      equ 0x11
SCANCODE_S      equ 0x1F
SCANCODE_UP     equ 0x48
SCANCODE_DOWN   equ 0x50
SCANCODE_C      equ 0x2E

section .data
left_paddle_y:  dw SCREEN_HEIGHT / 2 - PADDLE_HEIGHT / 2
right_paddle_y: dw SCREEN_HEIGHT / 2 - PADDLE_HEIGHT / 2
left_score:     dw 0
right_score:    dw 0
current_paddle_color: db 0x0F ; by default white

pong_main:
    ; set ES to the back buffer segment
    mov ax, BUFFER_SEG
    mov es, ax

    ; clear the back buffer initially
    xor di, di
    mov cx, SCREEN_WIDTH * SCREEN_HEIGHT
    xor al, al
    rep stosb

game_loop:
    ; point ES to the back buffer for drawing
    mov ax, BUFFER_SEG
    mov es, ax

    ; clear back buffer for the new frame
    xor di, di
    xor al, al
    mov cx, SCREEN_WIDTH * SCREEN_HEIGHT
    rep stosb

    ; update game state
    call update_ball

    ; draw game elements to back buffer
    call draw_ball
    call draw_scores

    ; draw left paddle
    mov ax, LEFT_X
    mov bx, [left_paddle_y]
    mov cx, PADDLE_HEIGHT
    mov dl, [current_paddle_color]
    call draw_paddle

    ; draw right paddle
    mov ax, RIGHT_X
    mov bx, [right_paddle_y]
    mov cx, PADDLE_HEIGHT
    mov dl, [current_paddle_color]
    call draw_paddle

    ; copy back buffer to video memory
    push ds
    mov ax, BUFFER_SEG
    mov ds, ax          ; DS:SI is source
    mov ax, 0xA000
    mov es, ax          ; ES:DI is destination
    xor si, si
    xor di, di
    mov cx, (SCREEN_WIDTH * SCREEN_HEIGHT) / 2
    rep movsw           ; move 2 bytes at a time
    pop ds

    ; check for keyboard input
    mov ah, 0x01
    int 0x16
    jz no_key           ; if no key pressed, jump to delay

    ; get key from buffer
    mov ah, 0x00
    int 0x16

    ; handle input
    cmp al, 'w'
    je move_left_up
    cmp al, 's'
    je move_left_down
    cmp ah, SCANCODE_UP
    je move_right_up
    cmp ah, SCANCODE_DOWN
    je move_right_down
    cmp al, 'c'
    je enter_shell
    jmp no_key

move_left_up:
    mov ax, [left_paddle_y]
    sub ax, 5
    cmp ax, 0
    jle .clamp_left_up  ; prevent moving off screen
    mov [left_paddle_y], ax
    jmp no_key
.clamp_left_up:
    mov word [left_paddle_y], 0
    jmp no_key

move_left_down:
    mov ax, [left_paddle_y]
    add ax, 5
    cmp ax, SCREEN_HEIGHT - PADDLE_HEIGHT
    jge .clamp_left_down ; prevent moving off screen
    mov [left_paddle_y], ax
    jmp no_key
.clamp_left_down:
    mov word [left_paddle_y], SCREEN_HEIGHT - PADDLE_HEIGHT
    jmp no_key

move_right_up:
    mov ax, [right_paddle_y]
    sub ax, 5
    cmp ax, 0
    jle .clamp_right_up ; prevent moving off screen
    mov [right_paddle_y], ax
    jmp no_key
.clamp_right_up:
    mov word [right_paddle_y], 0
    jmp no_key

move_right_down:
    mov ax, [right_paddle_y]
    add ax, 5
    cmp ax, SCREEN_HEIGHT - PADDLE_HEIGHT
    jge .clamp_right_down ; prevent moving off screen
    mov [right_paddle_y], ax
    jmp no_key
.clamp_right_down:
    mov word [right_paddle_y], SCREEN_HEIGHT - PADDLE_HEIGHT
    jmp no_key

no_key:
    mov cx, 20000       ; delay loop
.game_delay_loop:
    nop
    nop
    loop .game_delay_loop
    jmp game_loop

enter_shell:
    call shell_main
    mov ax, 0x0013      ; restore VGA mode after shell exits
    int 0x10
    jmp pong_main       ; restart the game logic

;draws a paddle
; ax: x position bx: y position cx: height dl: color
draw_paddle:
    pusha
    mov di, bx
    imul di, SCREEN_WIDTH ; calculate starting row offset
    add di, ax          ; add column offset
    mov al, dl          ; the color
.draw_line_loop:
    ; draw a 5 pixel wide horizontal line for each row of the paddle
    mov byte [es:di + 0], al
    mov byte [es:di + 1], al
    mov byte [es:di + 2], al
    mov byte [es:di + 3], al
    mov byte [es:di + 4], al
    add di, SCREEN_WIDTH ; move to the next row
    loop .draw_line_loop
    popa
    ret

;draws a single digit using a 5x5 pixel font
draw_number:
    pusha
    mov bx, di          ; save original position

    ; jump to the correct drawing routine based on the digit
    cmp al, 0
    je .draw_0_num
    cmp al, 1
    je .draw_1_num
    cmp al, 2
    je .draw_2_num
    cmp al, 3
    je .draw_3_num
    cmp al, 4
    je .draw_4_num
    cmp al, 5
    je .draw_5_num
    cmp al, 6
    je .draw_6_num
    cmp al, 7
    je .draw_7_num
    cmp al, 8
    je .draw_8_num
    cmp al, 9
    je .draw_9_num
    jmp .draw_done_num

.draw_0_num:
    mov di, bx
    mov cx, 5
.d0_vert_loop:
    mov byte [es:di], dl      ; left vertical line
    mov byte [es:di+4], dl    ; right vertical line
    add di, SCREEN_WIDTH
    loop .d0_vert_loop
    mov di, bx
    mov cx, 5
.d0_top_loop:
    mov byte [es:di], dl      ; top horizontal line
    inc di
    loop .d0_top_loop
    mov di, bx
    add di, SCREEN_WIDTH*4
    mov cx, 5
.d0_bottom_loop:
    mov byte [es:di], dl      ; bottom horizontal line
    inc di
    loop .d0_bottom_loop
    jmp .draw_done_num

.draw_1_num:
    mov di, bx
    add di, 2                 ; center column
    mov cx, 5
.d1_vert_loop:
    mov byte [es:di], dl      ; vertical line
    add di, SCREEN_WIDTH
    loop .d1_vert_loop
    jmp .draw_done_num

.draw_2_num:
    mov di, bx
    mov cx, 5
.d2_top_loop:
    mov byte [es:di], dl      ; top line
    inc di
    loop .d2_top_loop
    mov di, bx
    add di, SCREEN_WIDTH
    add di, 4
    mov byte [es:di], dl      ; top-right pixel
    mov di, bx
    add di, SCREEN_WIDTH*2
    mov cx, 5
.d2_mid_loop:
    mov byte [es:di], dl      ; middle line
    inc di
    loop .d2_mid_loop
    mov di, bx
    add di, SCREEN_WIDTH*3
    mov byte [es:di], dl      ; bottom-left pixel
    mov di, bx
    add di, SCREEN_WIDTH*4
    mov cx, 5
.d2_bot_loop:
    mov byte [es:di], dl      ; bottom line
    inc di
    loop .d2_bot_loop
    jmp .draw_done_num

.draw_3_num:
    mov di, bx
    mov cx, 5
.d3_top_loop:
    mov byte [es:di], dl      ; top line
    inc di
    loop .d3_top_loop
    mov di, bx
    add di, 4
    mov cx, 5
.d3_right_vert_loop:
    mov byte [es:di], dl      ; right vertical line
    add di, SCREEN_WIDTH
    loop .d3_right_vert_loop
    mov di, bx
    add di, SCREEN_WIDTH*2
    mov cx, 4
.d3_mid_loop:
    mov byte [es:di], dl      ; middle line
    inc di
    loop .d3_mid_loop
    mov di, bx
    add di, SCREEN_WIDTH*4
    mov cx, 5
.d3_bot_loop:
    mov byte [es:di], dl      ; bottom line
    inc di
    loop .d3_bot_loop
    jmp .draw_done_num

.draw_4_num:
    mov di, bx
    mov cx, 3
.d4_left_vert_loop:
    mov byte [es:di], dl      ; top-left vertical line
    add di, SCREEN_WIDTH
    loop .d4_left_vert_loop
    mov di, bx
    add di, 4
    mov cx, 5
.d4_right_vert_loop:
    mov byte [es:di], dl      ; right vertical line
    add di, SCREEN_WIDTH
    loop .d4_right_vert_loop
    mov di, bx
    add di, SCREEN_WIDTH*2
    mov cx, 5
.d4_mid_loop:
    mov byte [es:di], dl      ; middle line
    inc di
    loop .d4_mid_loop
    jmp .draw_done_num

.draw_5_num:
    mov di, bx
    mov cx, 5
.d5_top_loop:
    mov byte [es:di], dl      ; top line
    inc di
    loop .d5_top_loop
    mov di, bx
    add di, SCREEN_WIDTH
    mov byte [es:di], dl      ; top-left pixel
    mov di, bx
    add di, SCREEN_WIDTH*2
    mov cx, 5
.d5_mid_loop:
    mov byte [es:di], dl      ; middle line
    inc di
    loop .d5_mid_loop
    mov di, bx
    add di, SCREEN_WIDTH*3
    add di, 4
    mov byte [es:di], dl      ; bottom-right pixel
    mov di, bx
    add di, SCREEN_WIDTH*4
    mov cx, 5
.d5_bot_loop:
    mov byte [es:di], dl      ; bottom line
    inc di
    loop .d5_bot_loop
    jmp .draw_done_num

.draw_6_num:
    mov di, bx
    mov cx, 5
.d6_left_vert_loop:
    mov byte [es:di], dl      ; left vertical line
    add di, SCREEN_WIDTH
    loop .d6_left_vert_loop
    mov di, bx
    mov cx, 5
.d6_top_loop:
    mov byte [es:di], dl      ; top line
    inc di
    loop .d6_top_loop
    mov di, bx
    add di, SCREEN_WIDTH*2
    mov cx, 5
.d6_mid_loop:
    mov byte [es:di], dl      ; middle line
    inc di
    loop .d6_mid_loop
    mov di, bx
    add di, SCREEN_WIDTH*3
    add di, 4
    mov byte [es:di], dl      ; bottom-right pixel
    mov di, bx
    add di, SCREEN_WIDTH*4
    mov cx, 5
.d6_bot_loop:
    mov byte [es:di], dl      ; bottom line
    inc di
    loop .d6_bot_loop
    jmp .draw_done_num

.draw_7_num:
    mov di, bx
    mov cx, 5
.d7_top_loop:
    mov byte [es:di], dl      ; top line
    inc di
    loop .d7_top_loop
    mov di, bx
    add di, 4
    mov cx, 5
.d7_right_vert_loop:
    mov byte [es:di], dl      ; right vertical line
    add di, SCREEN_WIDTH
    loop .d7_right_vert_loop
    jmp .draw_done_num

.draw_8_num:
    mov di, bx
    mov cx, 5
.d8_left_vert_loop:
    mov byte [es:di], dl      ; left vertical line
    add di, SCREEN_WIDTH
    loop .d8_left_vert_loop
    mov di, bx
    add di, 4
    mov cx, 5
.d8_right_vert_loop:
    mov byte [es:di], dl      ; right vertical line
    add di, SCREEN_WIDTH
    loop .d8_right_vert_loop
    mov di, bx
    mov cx, 5
.d8_top_loop:
    mov byte [es:di], dl      ; top line
    inc di
    loop .d8_top_loop
    mov di, bx
    add di, SCREEN_WIDTH*2
    mov cx, 5
.d8_mid_loop:
    mov byte [es:di], dl      ; middle line
    inc di
    loop .d8_mid_loop
    mov di, bx
    add di, SCREEN_WIDTH*4
    mov cx, 5
.d8_bot_loop:
    mov byte [es:di], dl      ; bottom line
    inc di
    loop .d8_bot_loop
    jmp .draw_done_num

.draw_9_num:
    mov di, bx
    mov cx, 3
.d9_left_vert_loop:
    mov byte [es:di], dl      ; top-left vertical line
    add di, SCREEN_WIDTH
    loop .d9_left_vert_loop
    mov di, bx
    add di, 4
    mov cx, 5
.d9_right_vert_loop:
    mov byte [es:di], dl      ; right vertical line
    add di, SCREEN_WIDTH
    loop .d9_right_vert_loop
    mov di, bx
    mov cx, 5
.d9_top_loop:
    mov byte [es:di], dl      ; top line
    inc di
    loop .d9_top_loop
    mov di, bx
    add di, SCREEN_WIDTH*2
    mov cx, 5
.d9_mid_loop:
    mov byte [es:di], dl      ; middle line
    inc di
    loop .d9_mid_loop
    mov di, bx
    add di, SCREEN_WIDTH*4
    mov cx, 5
.d9_bot_loop:
    mov byte [es:di], dl      ; bottom line
    inc di
    loop .d9_bot_loop
    jmp .draw_done_num

.draw_done_num:
    popa
    ret

;draws the scores for both paddles
draw_scores:
    pusha

    ; draw left score
    mov ax, [left_score]
    xor dx, dx
    mov bx, 10
    div bx              ; ax = score / 10 dx = ones digit
    push dx
    xor dx, dx
    div bx              ; ax = score / 100 dx = tens digit
    push dx
    mov cl, al          ; hundreds digit
    mov ch, 0           ; flag have we printed a non-zero digit?

    ; draw left score hundreds digit
    test cl, cl
    jz .skip_left_hundreds
    mov ch, 1
    mov di, 10*SCREEN_WIDTH + (SCREEN_WIDTH/4 - 15)
    mov al, cl
    mov dl, 0x0F
    call draw_number
.skip_left_hundreds:

    ; draw left score tens digit
    pop ax              ; tens digit in al
    mov cl, al
    test ch, ch
    jnz .draw_left_tens
    test cl, cl
    jz .skip_left_tens
.draw_left_tens:
    mov ch, 1
    mov di, 10*SCREEN_WIDTH + (SCREEN_WIDTH/4 - 9)
    mov al, cl
    mov dl, 0x0F
    call draw_number
.skip_left_tens:

    ; draw left score ones digit
    pop ax              ; ones digit in al
    mov di, 10*SCREEN_WIDTH + (SCREEN_WIDTH/4 - 3)
    mov dl, 0x0F
    call draw_number

    ; draw right score
    mov ax, [right_score]
    xor dx, dx
    mov bx, 10
    div bx
    push dx
    xor dx, dx
    div bx
    push dx
    mov cl, al          ; hundreds digit
    mov ch, 0           ; reset flag

    ; draw right score hundreds digit
    test cl, cl
    jz .skip_right_hundreds
    mov ch, 1
    mov di, 10*SCREEN_WIDTH + (SCREEN_WIDTH - SCREEN_WIDTH/4 - 15)
    mov al, cl
    mov dl, 0x0F
    call draw_number
.skip_right_hundreds:

    ; draw right score tens digit
    pop ax
    mov cl, al
    test ch, ch
    jnz .draw_right_tens
    test cl, cl
    jz .skip_right_tens
.draw_right_tens:
    mov ch, 1
    mov di, 10*SCREEN_WIDTH + (SCREEN_WIDTH - SCREEN_WIDTH/4 - 9)
    mov al, cl
    mov dl, 0x0F
    call draw_number
.skip_right_tens:

    ; draw right score ones digit
    pop ax
    mov di, 10*SCREEN_WIDTH + (SCREEN_WIDTH - SCREEN_WIDTH/4 - 3)
    mov dl, 0x0F
    call draw_number

    popa
    ret
