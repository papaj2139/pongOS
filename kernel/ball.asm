BALL_SIZE       equ 4
BALL_COLOR      equ 0x0F    
BALL_SPEED_X    equ 1       
BALL_SPEED_Y    equ 1


ball_x:         dw 160     
ball_y:         dw 100
ball_dx:        dw 1        ; direction at spawn
ball_dy:        dw 1
ball_counter:   db 0        


draw_ball:
    pusha
    mov ax, [ball_y]
    mov bx, 320
    mul bx              ; ax = y * 320
    add ax, [ball_x]    ; ax = y * 320 + x
    mov di, ax
    
    mov al, BALL_COLOR
    mov cx, BALL_SIZE   ; height
.row:
    push cx
    mov cx, BALL_SIZE   ; width
    rep stosb           
    pop cx
    add di, 320-BALL_SIZE  
    loop .row
    
    popa
    ret

update_ball:
    pusha
    
    ; every what frame update ball?
    inc byte [ball_counter]
    cmp byte [ball_counter], 18    ;  << if you increase THIS number the ball will be slower
    jne .done
    mov byte [ball_counter], 0
    
    mov ax, [ball_x]
    add ax, [ball_dx]
    
    ; collision, left paddle
    cmp ax, LEFT_X + PADDLE_WIDTH
    jg .check_right
    mov bx, [ball_y]
    add bx, BALL_SIZE/2
    mov cx, [left_paddle_y]
    cmp bx, cx
    jl .reset_ball
    add cx, PADDLE_HEIGHT
    cmp bx, cx
    jg .reset_ball
    neg word [ball_dx]
    jmp .update_y

.check_right:
    cmp ax, RIGHT_X
    jl .set_x
    mov bx, [ball_y]
    add bx, BALL_SIZE/2
    mov cx, [right_paddle_y]
    cmp bx, cx
    jl .reset_ball
    add cx, PADDLE_HEIGHT
    cmp bx, cx
    jg .reset_ball
    neg word [ball_dx]
    jmp .update_y

.set_x:
    mov [ball_x], ax

.update_y:
    mov ax, [ball_y]
    add ax, [ball_dy]
    
    ; checks top and bottom bounds
    cmp ax, 0
    jg .check_bottom
    neg word [ball_dy]
    jmp .done
    
.check_bottom:
    cmp ax, SCREEN_HEIGHT - BALL_SIZE
    jl .set_y
    neg word [ball_dy]
    jmp .done
    
.set_y:
    mov [ball_y], ax
    jmp .done

.reset_ball:
    ; go back to center
    mov word [ball_x], 160
    mov word [ball_y], 100
    neg word [ball_dx]

.done:
    popa
    ret