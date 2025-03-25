%define BACKSPACE   0x08    
%define ENTER       0x0D    
%define ESC         0x1B    
%define PROMPT_COLOR 0x0F   ; white
%define TEXT_COLOR  0x07    ; light gray
%define BUFFER_SIZE 78      ; max command lenght

section .data
prompt          db '> ', 0
input_buffer    times BUFFER_SIZE db 0   ; cimmand input buffer
buffer_pos      db 0                     ; the CURRENT position in buffer
pong_cmd        db 'pong', 0            ; << goes back to the game
scores_cmd      db 'scores', 0          
reset_cmd       db 'reset', 0           
echo_cmd        db 'echo ', 0           
unknown_cmd     db 'Unknown command', 13, 10, 0
score_fmt       db 'Left: ', 0          
score_sep       db '  Right: ', 0       
newline         db 13, 10, 0            
reset_msg       db 'Scores reset', 13, 10, 0
version_msg     db 'PongOS version 1.3', 13, 10, 0
ver_cmd         db 'ver', 0             

section .text
shell_main:
    pusha                   ; save registers
    call clear_screen      
    call draw_prompt      

shell_loop:
    mov ah, 0x00          ; BIOS'es keyboard function
    int 0x16             ; wait for key
    
 
    cmp al, ENTER
    je handle_enter
    
    cmp al, BACKSPACE
    je handle_backspace
    
    ; is buffer full?
    mov bl, [buffer_pos]
    cmp bl, BUFFER_SIZE
    jae shell_loop       ; if the answer is yes, ingore input
    
    ; echo character to screen
    mov ah, 0x0E
    mov bh, 0           
    mov bl, TEXT_COLOR
    int 0x10
    
    ; store the character in the buffer
    mov bl, [buffer_pos]
    mov [input_buffer + bx], al
    inc byte [buffer_pos]
    
    jmp shell_loop

handle_enter:
    ; print newline
    mov ah, 0x0E
    mov al, 0x0D        
    int 0x10
    mov al, 0x0A        
    int 0x10
    
    ; null terminate input
    mov bl, [buffer_pos]
    mov byte [input_buffer + bx], 0
    
    
    cmp byte [buffer_pos], 0
    je .empty_cmd


    mov si, input_buffer
    mov di, echo_cmd
    mov cx, 5           ; length of command
    push si
.check_echo:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .not_echo
    inc si
    inc di
    loop .check_echo
    pop si
    jmp echo_text     
    
.not_echo:
    pop si
    
    mov si, input_buffer
    
    mov di, pong_cmd
    call strcmp
    test ax, ax
    jz shell_exit
    
    mov di, scores_cmd
    call strcmp
    test ax, ax
    jz show_scores
    
    mov di, reset_cmd
    call strcmp
    test ax, ax
    jz reset_scores
    
    mov di, ver_cmd
    call strcmp
    test ax, ax
    jz show_version
    
    mov si, unknown_cmd
    call print_string
    
.empty_cmd:
    call clear_buffer
    call draw_prompt
    jmp shell_loop

show_scores:
    pusha
    mov si, score_fmt
    call print_string
    mov ax, [left_score]
    call print_number
    mov si, score_sep
    call print_string
    mov ax, [right_score]
    call print_number
    mov si, newline
    call print_string
    popa
    call clear_buffer
    call draw_prompt
    jmp shell_loop

reset_scores:
    mov word [left_score], 0
    mov word [right_score], 0
    mov si, reset_msg
    call print_string
    call clear_buffer
    call draw_prompt
    jmp shell_loop

echo_text:
    pusha
    mov si, input_buffer
    add si, 5
    cmp byte [si], 0
    je .no_text
    call print_string
.no_text:
    mov si, newline
    call print_string
    popa
    call clear_buffer
    call draw_prompt
    jmp shell_loop

handle_backspace:
    mov bl, [buffer_pos]
    test bl, bl
    jz shell_loop
    mov ah, 0x0E
    mov al, BACKSPACE
    int 0x10
    mov al, ' '
    int 0x10
    mov al, BACKSPACE
    int 0x10
    dec byte [buffer_pos]
    mov bl, [buffer_pos]
    mov byte [input_buffer + bx], 0
    jmp shell_loop

shell_exit:
    pusha
    mov ah, 0x00
    mov al, 0x13
    int 0x10
    popa
    popa
    ret

clear_screen:
    pusha
    mov ah, 0x00
    mov al, 0x03
    int 0x10
    mov ah, 0x0B
    mov bh, 0x00
    mov bl, 0x00
    int 0x10
    popa
    ret

draw_prompt:
    pusha
    mov si, prompt
    mov ah, 0x0E
    mov bh, 0
    mov bl, PROMPT_COLOR
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .loop
.done:
    popa
    ret

strcmp:
    pusha
.loop:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .not_equal
    test al, al
    jz .equal
    inc si
    inc di
    jmp .loop
.not_equal:
    popa
    mov ax, 1
    ret
.equal:
    popa
    xor ax, ax
    ret

print_string:
    pusha
    mov ah, 0x0E
    mov bh, 0
    mov bl, TEXT_COLOR
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .loop
.done:
    popa
    ret

clear_buffer:
    pusha
    mov byte [buffer_pos], 0
    mov di, input_buffer
    mov cx, BUFFER_SIZE
    mov al, 0
    rep stosb
    popa
    ret

print_number:
    pusha
    mov cx, 0
    mov bx, 10
.divide:
    xor dx, dx
    div bx
    push dx
    inc cx
    test ax, ax
    jnz .divide
.print:
    pop dx
    add dl, '0'
    mov ah, 0x0E
    mov al, dl
    int 0x10
    loop .print
    popa
    ret

show_version:
    mov si, version_msg
    call print_string
    call clear_buffer
    call draw_prompt
    jmp shell_loop