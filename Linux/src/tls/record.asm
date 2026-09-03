%define RB_CAP 16384

section .bss
alignb 8
rb_buf:   resb RB_CAP
rb_start: resq 1
rb_end:   resq 1
rb_fd:    resq 1

section .text

rb_init:
    mov     [rb_fd], rdi
    mov     qword [rb_start], 0
    mov     qword [rb_end], 0
    ret

rb_readfull:
    push    rbx
    push    r12
    push    r13
    mov     r12, rdi
    mov     r13, rsi
.loop:
    test    r13, r13
    jz      .ok
    mov     rax, [rb_start]
    mov     rbx, [rb_end]
    cmp     rax, rbx
    jb      .have
    mov     qword [rb_start], 0
    mov     qword [rb_end], 0
    mov     eax, SYS_read
    mov     edi, [rb_fd]
    lea     rsi, [rb_buf]
    mov     edx, RB_CAP
    syscall
    test    rax, rax
    jle     .err
    mov     [rb_end], rax
    mov     qword [rb_start], 0
    jmp     .loop
.have:
    mov     rcx, rbx
    sub     rcx, rax
    cmp     rcx, r13
    jbe     .take
    mov     rcx, r13
.take:
    lea     rsi, [rb_buf]
    add     rsi, rax
    mov     rdi, r12
    mov     rdx, rcx
    push    rcx
    call    memcpy
    pop     rcx
    add     r12, rcx
    sub     r13, rcx
    add     [rb_start], rcx
    jmp     .loop
.ok:
    xor     eax, eax
    jmp     .ret
.err:
    mov     rax, -1
.ret:
    pop     r13
    pop     r12
    pop     rbx
    ret

read_record:
    push    r12
    push    r13
    mov     r12, rdi
    mov     rdi, r12
    mov     rsi, 5
    call    rb_readfull
    test    rax, rax
    js      .err
    movzx   r13d, byte [r12+3]
    shl     r13d, 8
    movzx   eax, byte [r12+4]
    or      r13d, eax
    lea     rdi, [r12+5]
    mov     rsi, r13
    call    rb_readfull
    test    rax, rax
    js      .err
    lea     rax, [r13+5]
    jmp     .ret
.err:
    mov     rax, -1
.ret:
    pop     r13
    pop     r12
    ret
