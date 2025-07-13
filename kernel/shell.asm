
%define BACKSPACE   0x08
%define ENTER       0x0D
%define ESC         0x1B
%define PROMPT_COLOR 0x0F    ; white
%define TEXT_COLOR  0x07     ; light gray
%define BUFFER_SIZE 78       ; max cimmand length

section .data
prompt:             db '> ', 0
input_buffer:       times BUFFER_SIZE+1 db 0 ; cimmand input buffer
buffer_pos:         db 0                     ; current position in buffer

pong_cmd:           db 'pong', 0
scores_cmd:         db 'scores', 0
reset_cmd:          db 'reset', 0
ver_cmd:            db 'ver', 0
echo_cmd_prefix:    db 'echo ', 0
set_ball_color_cmd: db 'set ball color ', 0
set_paddle_color_cmd: db 'set paddle color ', 0
set_ball_speed_cmd: db 'set ball speed ', 0
colors_cmd:         db 'colors', 0
clear_cmd:          db 'clear', 0
help_cmd:           db 'help', 0

unknown_cmd_msg:    db 'Unknown command', 13, 10, 0
score_fmt_msg:      db 'Left: ', 0
score_sep_msg:      db '  Right: ', 0
newline_msg:        db 13, 10, 0
reset_scores_msg:   db 'Scores reset.', 13, 10, 0
version_str_msg:    db 'PongOS version 1.4', 13, 10, 0
cmd_ok_msg:         db 'OK', 13, 10, 0
err_val_msg:        db 'Error: Invalid or missing value.', 13, 10, 0
err_arg_msg:        db 'Error: Invalid argument format.', 13, 10, 0

colors_msg_hdr:     db "Common Colors (Hex):", 13, 10, 0
colors_msg_line1:   db "  00 Black   01 Blue     02 Green   03 Cyan", 13, 10, 0
colors_msg_line2:   db "  04 Red     05 Magenta  06 Brown   07 Lt Gray", 13, 10, 0
colors_msg_line3:   db "  08 Dk Gray 09 Lt Blue  0A LtGreen 0B Lt Cyan", 13, 10, 0
colors_msg_line4:   db "  0C Lt Red  0D Lt Mag.  0E Yellow  0F White", 13, 10, 0

help_msg_hdr:       db "Available commands:", 13, 10, 0
help_msg_pong:      db "  pong            - Return to the game", 13, 10, 0
help_msg_scores:    db "  scores          - Show current scores", 13, 10, 0
help_msg_reset:     db "  reset           - Reset scores and ball", 13, 10, 0
help_msg_ver:       db "  ver             - Show PongOS version", 13, 10, 0
help_msg_echo:      db "  echo <text>     - Print <text> to screen", 13, 10, 0
help_msg_setballc:  db "  set ball color <hex> - Set ball color (e.g., 0F)", 13, 10, 0
help_msg_setpadc:   db "  set paddle color <hex> - Set paddle color (e.g., 0E)", 13, 10, 0
help_msg_setballs:  db "  set ball speed <num> - Set ball speed (1-255, lower=faster)", 13, 10, 0
help_msg_colors:    db "  colors          - Show common color hex codes", 13, 10, 0
help_msg_clear:     db "  clear           - Clear the shell screen", 13, 10, 0
help_msg_help:      db "  help            - Show this help message", 13, 10, 0


section .text
shell_main:
    pusha
    call clear_screen_text_mode ; ensure text mode
    call draw_prompt

shell_loop:
    mov ah, 0x00        ; get keystroke
    int 0x16            ;wait for key

    cmp al, ENTER
    je handle_enter

    cmp al, BACKSPACE
    je handle_backspace

    ;prevents buffer overflow
    mov bl, [buffer_pos]
    cmp bl, BUFFER_SIZE - 1
    jae shell_loop

    ; echo the character to the screen
    mov ah, 0x0E
    mov bh, 0
    mov bl, TEXT_COLOR
    int 0x10

    ; store character in buffer
    mov bl, [buffer_pos]
    mov [input_buffer + bx], al
    inc byte [buffer_pos]

    jmp shell_loop

handle_enter:
    mov si, newline_msg
    call print_string_stdout

    ; null-terminate the input buffer
    mov bl, [buffer_pos]
    mov byte [input_buffer + bx], 0

    ; if buffer is empty, do nothing
    cmp byte [buffer_pos], 0
    je .empty_command_handler

    ;command parsing
    ; check for commands with arguments (prefixes) first
    mov si, input_buffer
    mov di, set_ball_color_cmd
    mov cx, 15 ; length of "set ball color "
    call strncmp_prefix
    jz .do_set_ball_color

    mov si, input_buffer
    mov di, set_paddle_color_cmd
    mov cx, 17 ; length of "set paddle color "
    call strncmp_prefix
    jz .do_set_paddle_color

    mov si, input_buffer
    mov di, set_ball_speed_cmd
    mov cx, 15 ; length of "set ball speed "
    call strncmp_prefix
    jz .do_set_ball_speed

    mov si, input_buffer
    mov di, echo_cmd_prefix
    mov cx, 5 ; length of "echo "
    call strncmp_prefix
    jz .do_echo_text

    ; check for full commands (without arguments)
    mov si, input_buffer

    mov di, pong_cmd
    call strcmp_cs
    jz .do_shell_exit_to_pong

    mov di, scores_cmd
    call strcmp_cs
    jz .do_show_scores

    mov di, reset_cmd
    call strcmp_cs
    jz .do_reset_scores

    mov di, ver_cmd
    call strcmp_cs
    jz .do_show_version

    mov di, colors_cmd
    call strcmp_cs
    jz .do_show_colors

    mov di, clear_cmd
    call strcmp_cs
    jz .do_clear_shell_screen

    mov di, help_cmd
    call strcmp_cs
    jz .do_show_help

    ; if no command matched show error
    mov si, unknown_cmd_msg
    call print_string_stdout
    jmp .finish_command_handling

; command handlers
.do_set_ball_color:
    call parse_hex_byte_from_si
    jc .error_value_handler
    mov [current_ball_color], al
    mov si, cmd_ok_msg
    call print_string_stdout
    jmp .finish_command_handling
.error_value_handler:
    mov si, err_val_msg
    call print_string_stdout
    jmp .finish_command_handling

.do_set_paddle_color:
    call parse_hex_byte_from_si
    jc .error_value_handler
    mov [current_paddle_color], al
    mov si, cmd_ok_msg
    call print_string_stdout
    jmp .finish_command_handling

.do_set_ball_speed:
    call parse_decimal_byte_from_si
    jc .error_value_handler
    cmp al, 1
    jl .error_value_handler ;speed MUST be at least 1
    mov [ball_update_threshold], al
    mov si, cmd_ok_msg
    call print_string_stdout
    jmp .finish_command_handling

.do_echo_text:
    cmp byte [si], 0
    je .echo_no_text_to_print
    call print_string_stdout
.echo_no_text_to_print:
    jmp .finish_command_handling

.do_shell_exit_to_pong:
    mov ax, 0x0013      ;set VGA mode 320x200
    int 0x10
    popa
    ret

.do_show_scores:
    mov si, score_fmt_msg
    call print_string_stdout
    mov ax, [left_score]
    call print_number_stdout
    mov si, score_sep_msg
    call print_string_stdout
    mov ax, [right_score]
    call print_number_stdout
    mov si, newline_msg
    call print_string_stdout
    jmp .finish_command_handling

.do_reset_scores:
    mov word [left_score], 0
    mov word [right_score], 0
    call reset_ball_common
    mov si, reset_scores_msg
    call print_string_stdout
    jmp .finish_command_handling

.do_show_version:
    mov si, version_str_msg
    call print_string_stdout
    jmp .finish_command_handling

.do_show_colors:
    mov si, colors_msg_hdr
    call print_string_stdout
    mov si, colors_msg_line1
    call print_string_stdout
    mov si, colors_msg_line2
    call print_string_stdout
    mov si, colors_msg_line3
    call print_string_stdout
    mov si, colors_msg_line4
    call print_string_stdout
    jmp .finish_command_handling

.do_clear_shell_screen:
    call clear_screen_text_mode
    jmp .finish_command_handling

.do_show_help:
    mov si, help_msg_hdr
    call print_string_stdout
    mov si, help_msg_pong
    call print_string_stdout
    mov si, help_msg_scores
    call print_string_stdout
    mov si, help_msg_reset
    call print_string_stdout
    mov si, help_msg_ver
    call print_string_stdout
    mov si, help_msg_echo
    call print_string_stdout
    mov si, help_msg_setballc
    call print_string_stdout
    mov si, help_msg_setpadc
    call print_string_stdout
    mov si, help_msg_setballs
    call print_string_stdout
    mov si, help_msg_colors
    call print_string_stdout
    mov si, help_msg_clear
    call print_string_stdout
    mov si, help_msg_help
    call print_string_stdout
    jmp .finish_command_handling

.empty_command_handler:
.finish_command_handling:
    call clear_input_buffer
    call draw_prompt
    jmp shell_loop

handle_backspace:
    mov bl, [buffer_pos]
    test bl, bl         ;is buffer position 0?
    jz shell_loop       ;if so nothing to backspace

    ; BIOS teletype backspace overwrite with space and then backspace again
    mov ah, 0x0E
    mov al, BACKSPACE
    int 0x10
    mov al, ' '
    int 0x10
    mov al, BACKSPACE
    int 0x10

    ;updates buffer state
    dec byte [buffer_pos]
    mov bl, [buffer_pos]
    mov byte [input_buffer + bx], 0 ;null-terminate at new position
    jmp shell_loop

clear_screen_text_mode:
    pusha
    mov ah, 0x00        ; set video mode function
    mov al, 0x03        ; 80x25 CGA text mode
    int 0x10
    popa
    ret

draw_prompt:
    pusha
    mov si, prompt
    call print_string_stdout_color
    popa
    ret


;compares first CX characters of two strings
strncmp_prefix:
    push di
    push cx
    push es
    push si
    mov ax, ds
    mov es, ax
.loop_strncmp:
    cmp cx, 0
    je .match_strncmp   ; if cx is 0, we've matched all chars
    mov al, [byte ds:si]
    mov bl, [byte es:di]
    cmp al, bl
    jne .no_match_strncmp ; if characters don't match
    test al, al
    jz .no_match_strncmp  ; if we hit a null terminator
    inc si
    inc di
    dec cx
    jmp .loop_strncmp
.match_strncmp:
    add sp, 2
    pop es
    pop cx
    pop di
    xor ax, ax          ; return 0 for match
    ret
.no_match_strncmp:
    pop si
    pop es
    pop cx
    pop di
    mov ax, 1           ; return 1 for no match
    ret

;case-sensitive string comparison

strcmp_cs:
    push di
    push si
    push es
    mov ax, ds
    mov es, ax
.loop_strcmp:
    mov al, [byte ds:si]
    mov bl, [byte es:di]
    cmp al, bl
    jne .not_equal_strcmp
    test al, al
    jz .equal_strcmp    ; if null terminator reached then strings are equal
    inc si
    inc di
    jmp .loop_strcmp
.not_equal_strcmp:
    mov ax, 1
    jmp .done_strcmp
.equal_strcmp:
    xor ax, ax
.done_strcmp:
    pop es
    pop si
    pop di
    ret

; prints a null-terminated string to screen
print_string_stdout:
    pusha
    mov ah, 0x0E        ; teletype output
    mov bh, 0           ; page 0
    mov bl, TEXT_COLOR
.loop_ps:
    lodsb               ; load char from SI into AL
    test al, al
    jz .done_ps
    int 0x10
    jmp .loop_ps
.done_ps:
    popa
    ret

; prints a string with color
print_string_stdout_color:
    pusha
    mov ah, 0x0E
    mov bh, 0
    mov bl, PROMPT_COLOR
.loop_psc:
    lodsb
    test al, al
    jz .done_psc
    int 0x10
    jmp .loop_psc
.done_psc:
    popa
    ret

;fills the input buffer with nulls
clear_input_buffer:
    pusha
    mov byte [buffer_pos], 0
    mov di, input_buffer
    mov cx, BUFFER_SIZE + 1
    xor al, al
    rep stosb
    popa
    ret

;prints a number in AX to the screen
print_number_stdout:
    pusha
    mov cx, 0
    mov bx, 10
.divide_loop_pn:
    xor dx, dx
    div bx              ; divide AX by 10 remainder in DX
    push dx             ; push remainder onto stack
    inc cx              ; count digits
    test ax, ax
    jnz .divide_loop_pn
.print_loop_pn:
    pop dx
    add dl, '0'         ; convert to ASCII
    mov ah, 0x0E
    mov al, dl
    mov bh, 0
    mov bl, TEXT_COLOR
    int 0x10
    loop .print_loop_pn
    popa
    ret


;parses a 2-char hex string (ex., "0F") from SI
parse_hex_byte_from_si:
    push si
    call parse_single_hex_char_from_si
    jc .phbfs_error_single1
    mov bh, al          ; store high nibble
    shl bh, 4
    call parse_single_hex_char_from_si
    jc .phbfs_error_single2
    mov bl, al          ; low nibble
    or al, bh           ; combine nibbles
    clc
    add sp, 2
    ret
.phbfs_error_single1:
    pop si
    stc
    ret
.phbfs_error_single2:
    pop si
    stc
    ret

;parses one hex char from SI
parse_single_hex_char_from_si:
    mov bl, [ds:si]
    cmp bl, '0'
    jl .pshcfs_invalid
    cmp bl, '9'
    jle .pshcfs_digit
    cmp bl, 'A'
    jl .pshcfs_invalid
    cmp bl, 'F'
    jle .pshcfs_hex_upper
    cmp bl, 'a'
    jl .pshcfs_invalid
    cmp bl, 'f'
    jle .pshcfs_hex_lower
.pshcfs_invalid:
    stc
    ret
.pshcfs_digit:
    sub bl, '0'
    jmp .pshcfs_valid
.pshcfs_hex_upper:
    sub bl, 'A'
    add bl, 10
    jmp .pshcfs_valid
.pshcfs_hex_lower:
    sub bl, 'a'
    add bl, 10
.pshcfs_valid:
    inc si
    mov al, bl
    clc
    ret

;parses a decimal string into a byte

parse_decimal_byte_from_si:
    xor ax, ax          ; clear result
    xor cx, cx          ; clear digit counter
    clc
.pdbfs_loop:
    mov bl, [ds:si]
    cmp bl, '0'
    jl .pdbfs_done_parsing
    cmp bl, '9'
    jg .pdbfs_done_parsing
    inc si
    inc cx
    sub bl, '0'         ; convert char to digit
    mov dl, al
    mov al, 10
    mul dl              ; result = result * 10
    jc .pdbfs_overflow_generic
    add al, bl          ; result = result + digit
    jc .pdbfs_overflow_generic
    jmp .pdbfs_loop
.pdbfs_done_parsing:
    cmp cx, 0
    je .pdbfs_no_digits ; errors out if no digits were found
    clc
    ret
.pdbfs_no_digits:
    stc
    ret
.pdbfs_overflow_generic:
    stc
    ret
