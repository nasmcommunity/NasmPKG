section .rodata
tls13_prefix: db "tls13 "

section .bss
el_buf:     resb 256
el_ctxlen:  resq 1

section .text

hkdf_expand_label:
    push    rbx
    push    rbp
    push    r12
    push    r13
    push    r14
    push    r15
    mov     r12, rdi
    mov     r15, rsi
    mov     rbx, rdx
    mov     rbp, rcx
    mov     [el_ctxlen], r8
    mov     r13, r9
    mov     r14, r10
    lea     rdi, [el_buf]
    mov     rax, r14
    shr     rax, 8
    mov     [rdi], al
    mov     rax, r14
    mov     [rdi+1], al
    lea     rax, [rbx+6]
    mov     [rdi+2], al
    lea     rdi, [el_buf+3]
    lea     rsi, [tls13_prefix]
    mov     rdx, 6
    call    memcpy
    lea     rdi, [el_buf+9]
    mov     rsi, r15
    mov     rdx, rbx
    call    memcpy
    lea     rdi, [el_buf+9]
    add     rdi, rbx
    mov     rax, [el_ctxlen]
    mov     [rdi], al
    inc     rdi
    mov     rsi, rbp
    mov     rdx, [el_ctxlen]
    push    rdi
    call    memcpy
    pop     rdi
    mov     rax, [el_ctxlen]
    add     rdi, rax
    lea     rax, [el_buf]
    sub     rdi, rax
    mov     rdx, rdi
    mov     rdi, r12
    lea     rsi, [el_buf]
    mov     rcx, r13
    mov     r8, r14
    call    hkdf_expand
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbp
    pop     rbx
    ret

derive_secret:
    mov     r9, r8
    mov     r8, 32
    mov     r10, 32
    jmp     hkdf_expand_label
