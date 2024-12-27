section .data
    start_token db "START", 0
    start_len equ $ - start_token - 1
    end_token db "END", 0
    end_len equ $ - end_token - 1
    string_marker db "> ", 0
    marker_len equ $ - string_marker - 1
    newline db 10
    error_msg db "Usage: soot <filename>", 10, 0
    error_len equ $ - error_msg - 1

section .bss
    buffer resb 1024
    print_buffer resb 1024
    fd_in resq 1
    start_found resb 1
    end_found resb 1

section .text
    global _start

_start:
    mov byte [start_found], 0
    mov byte [end_found], 0

    pop rcx
    cmp rcx, 2
    jne error_exit

    pop rdi
    pop rdi

    mov rax, 2
    xor rsi, rsi
    xor rdx, rdx
    syscall

    cmp rax, 0
    jl exit
    mov [fd_in], rax

read_loop:
    mov rdi, [fd_in]
    mov rax, 0
    mov rsi, buffer
    mov rdx, 1024
    syscall

    cmp rax, 0
    jle close_file

    mov rcx, rax
    mov rsi, buffer
    
process_buffer:
    mov rdi, start_token
    mov rdx, start_len
    call check_token
    cmp rax, 1
    je mark_start

    mov rdi, end_token
    mov rdx, end_len
    call check_token
    cmp rax, 1
    je mark_end

    cmp byte [start_found], 1
    jne continue_processing

    mov rdi, string_marker
    mov rdx, marker_len
    call check_token
    cmp rax, 1
    je handle_string

continue_processing:
    inc rsi
    dec rcx
    jnz process_buffer
    jmp read_loop

mark_start:
    mov byte [start_found], 1
    jmp continue_processing

mark_end:
    cmp byte [start_found], 1
    jne continue_processing
    mov byte [end_found], 1
    jmp close_file

handle_string:
    add rsi, marker_len        ; Skip the "> " marker
    inc rsi                    ; Skip the opening quote
    sub rcx, marker_len
    dec rcx
    
    mov rdi, print_buffer
    xor rdx, rdx              ; Initialize string length counter

copy_string_loop:
    mov al, [rsi]
    cmp al, '"'               ; Check for closing quote
    je do_print
    cmp al, 10                ; Check for newline
    je continue_processing
    
    mov [rdi + rdx], al       ; Copy character to print buffer
    inc rdx                   ; Increment string length
    inc rsi
    dec rcx
    jnz copy_string_loop

do_print:
    push rcx
    push rsi
    
    ; Print the string with its actual length
    mov rax, 1
    mov rdi, 1
    mov rsi, print_buffer
    ; rdx already contains the string length
    syscall
    
    ; Print newline
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    
    pop rsi
    pop rcx
    jmp continue_processing

close_file:
    mov rax, 3
    mov rdi, [fd_in]
    syscall
    jmp exit

error_exit:
    mov rax, 1
    mov rdi, 1
    mov rsi, error_msg
    mov rdx, error_len
    syscall

exit:
    mov rax, 60
    xor rdi, rdi
    syscall

check_token:
    push rcx
    push rsi
    push rdi
    mov rcx, rdx
compare_loop:
    mov al, [rsi]
    mov bl, [rdi]
    cmp al, bl
    jne no_match
    inc rsi
    inc rdi
    dec rcx
    jnz compare_loop
    mov rax, 1
    jmp check_done
no_match:
    xor rax, rax
check_done:
    pop rdi
    pop rsi
    pop rcx
    ret
