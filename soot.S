; basic_parser.asm
section .data
    start_token db "START", 0
    start_len equ $ - start_token - 1
    end_token db "END", 0
    end_len equ $ - end_token - 1
    error_msg db "Usage: ./parser <filename>", 10, 0
    error_len equ $ - error_msg - 1
    file_error db "Error opening file", 10, 0
    file_error_len equ $ - file_error - 1
    start_found_msg db "START token found", 10, 0
    start_found_len equ $ - start_found_msg - 1
    end_found_msg db "END token found", 10, 0
    end_found_len equ $ - end_found_msg - 1

section .bss
    buffer resb 1024
    fd_in resq 1

section .text
    global _start

_start:
    ; Check if we have exactly one argument (program name + filename)
    pop rcx         ; Get argc
    cmp rcx, 2      ; Check if argc == 2
    jne error_exit

    ; Get filename from argv[1]
    pop rdi         ; Skip argv[0] (program name)
    pop rdi         ; Get argv[1] (filename)

    ; Open file
    mov rax, 2      ; sys_open
    xor rsi, rsi    ; O_RDONLY
    xor rdx, rdx    ; mode (not used)
    syscall

    ; Check if file opened successfully
    cmp rax, 0
    jl file_error_exit
    
    ; Store file descriptor
    mov [fd_in], rax

read_loop:
    ; Read from file
    mov rdi, [fd_in]
    mov rax, 0      ; sys_read
    mov rsi, buffer
    mov rdx, 1024
    syscall

    ; Check for end of file
    cmp rax, 0
    jle close_file

    ; Process buffer
    mov rcx, rax    ; Store number of bytes read
    mov rsi, buffer ; Buffer pointer
    
process_buffer:
    ; Check for START token
    mov rdi, start_token
    mov rdx, start_len
    call check_token
    cmp rax, 1
    je found_start

    ; Check for END token
    mov rdi, end_token
    mov rdx, end_len
    call check_token
    cmp rax, 1
    je found_end

    inc rsi
    dec rcx
    jnz process_buffer
    jmp read_loop

found_start:
    mov rax, 1      ; sys_write
    mov rdi, 1      ; stdout
    mov rsi, start_found_msg
    mov rdx, start_found_len
    syscall
    jmp read_loop

found_end:
    mov rax, 1      ; sys_write
    mov rdi, 1      ; stdout
    mov rsi, end_found_msg
    mov rdx, end_found_len
    syscall
    jmp read_loop

close_file:
    mov rax, 3      ; sys_close
    mov rdi, [fd_in]
    syscall
    jmp exit

error_exit:
    mov rax, 1      ; sys_write
    mov rdi, 1      ; stdout
    mov rsi, error_msg
    mov rdx, error_len
    syscall
    jmp exit

file_error_exit:
    mov rax, 1      ; sys_write
    mov rdi, 1      ; stdout
    mov rsi, file_error
    mov rdx, file_error_len
    syscall

exit:
    mov rax, 60     ; sys_exit
    xor rdi, rdi    ; status = 0
    syscall

; Function to check if current buffer position matches token
; Parameters:
;   rdi = token string
;   rsi = current buffer position
;   rdx = token length
; Returns:
;   rax = 1 if match, 0 if not
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
