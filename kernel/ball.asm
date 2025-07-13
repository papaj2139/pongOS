BALL_SIZE       equ 4

section .data
;these variables can be modified by the shell and need initial values
current_ball_color:   db 0x0F  ;default white
ball_update_threshold: db 25    ;default speed (lower is faster)
initial_ball_dx_val:  dw 1     ;default initial X speed magnitude
initial_ball_dy_val:  dw 1     ;default initial Y speed magnitude

;ball current position and direction/speed initialized here
ball_x:         dw 160      ;ball current X position
ball_y:         dw 100      ;ball current Y position
ball_dx:        dw 1        ;ball current X direction and step
ball_dy:        dw 1        ;ball current Y direction and step
ball_counter:   db 0        ;counter to slow down ball updates


draw_ball:
    pusha
    mov ax, [ball_y]
    mov bx, 320
    mul bx              ; ax = y * 320
    add ax, [ball_x]    ; ax = y * 320 + x
    mov di, ax

    mov al, [current_ball_color]
    mov cx, BALL_SIZE   ;height
.row:
    push cx
    mov cx, BALL_SIZE   ;width
    rep stosb
    pop cx
    add di, 320-BALL_SIZE
    loop .row

    popa
    ret

update_ball:
    pusha

    ;increment counter and check against threshold for speed control
    inc byte [ball_counter]
    mov cl, [ball_update_threshold]
    cmp byte [ball_counter], cl
    jne .done                   ;if counter hasn't reached threshold skip update
    mov byte [ball_counter], 0  ;reset counter

    ;current osition of the ball
    mov ax, [ball_x]
    ;add current ball direction/speed
    add ax, [ball_dx]

    ;collision with left paddle
    cmp ax, LEFT_X + PADDLE_WIDTH ;is the ball beyond the right edge of left paddle?
    jg .check_right_wall_or_paddle ;IF its further right check right paddle/wall

    ;only check collision if ball is moving left
    mov bx, [ball_dx]
    test bx, bx             ;is ball_dx negative?
    jns .check_right_wall_or_paddle ;if not skip left paddle check

    mov bx, [ball_y]        ;ball's top Y
    add bx, BALL_SIZE / 2   ;middle of the ball Y
    mov cx, [left_paddle_y] ;left paddle's top Y
    cmp bx, cx              ;is ball middle above paddle top?
    jl .left_miss           ;if yes miss

    add cx, PADDLE_HEIGHT   ;paddle's bottom Y
    cmp bx, cx              ;is ball middle below paddle bottom?
    jg .left_miss           ;if yes miss

    ;hit left paddle
    neg word [ball_dx]      ;reverse X direction (bounce off paddle)
    mov ax, LEFT_X + PADDLE_WIDTH + 1 ;move ball just outside paddle
    mov [ball_x], ax

    ;play hit sound
    push ax
    mov ax, 440         ; A4 note
    call play_sound
    mov cx, 1000        ;duration
.delay_hit_sound_L:
    loop .delay_hit_sound_L
    call stop_sound
    pop ax
    jmp .update_y       ;ball bounced update Y

.left_miss:
    ;ball missed left paddle and is going off screen
    call .reset_ball_right_scores ;right player score
    jmp .done                     ;skip further updates this frame

    ;collision with right wall or paddle
.check_right_wall_or_paddle:
    ;AX still holds potential new ball_x
    cmp ax, RIGHT_X - BALL_SIZE ;is ball's left edge past the paddle left edge?
    jl .set_x                   ;if not far enough right just update X

    ;only check collision if ball is moving right
    mov bx, [ball_dx]
    test bx, bx             ;is ball_dx positive ( moving right )
    js .set_x               ;if not moving right skip right paddle check

    ;ball is at or right of paddle left edge AND moving right so check Y
    mov bx, [ball_y]        ;ball top Y
    add bx, BALL_SIZE / 2   ;middle of the ball Y
    mov cx, [right_paddle_y];right paddle top Y
    cmp bx, cx              ;is ball middle above paddle top?
    jl .right_miss          ;if yes missed

    add cx, PADDLE_HEIGHT   ;paddle bottom Y
    cmp bx, cx              ;is ball middle below paddle bottom?
    jg .right_miss          ;if yes then miss

    ;hit right paddle
    neg word [ball_dx]      ;reverse X direction
    mov ax, RIGHT_X - BALL_SIZE - 1 ;move ball just outside paddle
    mov [ball_x], ax

    ;play hit sound
    push ax
    mov ax, 523         ; C5 note
    call play_sound
    mov cx, 1000        ;duration
.delay_hit_sound_R:
    loop .delay_hit_sound_R
    call stop_sound
    pop ax
    jmp .update_y       ;ball bounced

.right_miss:
    ;ball missed right paddle so is going off screen
    call .reset_ball_left_scores ;left player score
    jmp .done                    ;skip further updates this frame

.set_x:
    mov [ball_x], ax    ;update the ball X position

.update_y:
    mov ax, [ball_y]
    add ax, [ball_dy]   ;add current ball Y direction/speed

    ;checks top boundary
    cmp ax, 0
    jge .check_bottom   ;if ax >= 0 not at or above the top
    ;hit top boundary
    mov ax, 0           ;clamp to top
    neg word [ball_dy]  ;reverse Y direction
    jmp .set_y_final

.check_bottom:
    cmp ax, SCREEN_HEIGHT - BALL_SIZE
    jle .set_y_final    ;if ax <= SCREEN_HEIGHT - BALL_SIZE not at or below bottom
    ;hit bottom boundary
    mov ax, SCREEN_HEIGHT - BALL_SIZE ;clamp to bottom
    neg word [ball_dy]  ;reverse Y direction

.set_y_final:
    mov [ball_y], ax    ;update ball's Y position
    jmp .done

.done:
    popa
    ret

.reset_ball_left_scores:
    inc word [left_score]
    call reset_ball_common
    ;set ball to move towards right paddle
    mov ax, [initial_ball_dx_val]
    mov [ball_dx], ax
    ret

.reset_ball_right_scores:
    inc word [right_score]
    call reset_ball_common
    ;set ball to move towards left paddle
    mov ax, [initial_ball_dx_val]
    neg ax
    mov [ball_dx], ax
    ret

reset_ball_common:
    ;reset ball to center
    mov word [ball_x], SCREEN_WIDTH / 2 - BALL_SIZE / 2
    mov word [ball_y], SCREEN_HEIGHT / 2 - BALL_SIZE / 2

    ;reset dy to its initial configured value
    mov ax, [initial_ball_dy_val]
    mov [ball_dy], ax
    ;dx is set by the caller (.reset_ball_left_scores or .reset_ball_right_scores)
    ret
