section .rodata
reg_host: db "registry.nasmpkg.ru", 0
hh_get:  db "GET "
hh_get_len equ $ - hh_get
hh_tail: db " HTTP/1.1", 13,10, "Host: registry.nasmpkg.ru", 13,10, "Connection: close", 13,10,13,10
hh_tail_len equ $ - hh_tail
hh_crlf2: db 13,10,13,10

section .bss
alignb 8
sa_reg:  resb 16
reg_ready: resb 1
hh_req:  resb 512
hh_raw:  resb 262144

section .text

https_get:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    mov     r14, rdx
    mov     r15, rcx
    mov     r12, rdi
    mov     r13, rsi
    cmp     byte [reg_ready], 0
    jne     .build
    lea     rdi, [sa_reg]
    mov     byte [rdi], AF_INET
    mov     byte [rdi+1], 0
    mov     byte [rdi+2], 0x01
    mov     byte [rdi+3], 0xBB
    lea     rdi, [reg_host]
    call    resolve_a
    test    rax, rax
    js      .err
    mov     eax, [resolved_ip]
    mov     [sa_reg+4], eax
    mov     byte [reg_ready], 1
.build:
    lea     rbx, [hh_req]
    mov     rdi, rbx
    lea     rsi, [hh_get]
    mov     rdx, hh_get_len
    call    memcpy
    add     rbx, hh_get_len
    mov     rdi, rbx
    mov     rsi, r12
    mov     rdx, r13
    call    memcpy
    add     rbx, r13
    mov     rdi, rbx
    lea     rsi, [hh_tail]
    mov     rdx, hh_tail_len
    call    memcpy
    add     rbx, hh_tail_len
    mov     r13, rbx
    lea     rax, [hh_req]
    sub     r13, rax
    lea     rdi, [sa_reg]
    mov     esi, 5000
    call    tcp_connect_timeout
    test    rax, rax
    js      .err
    mov     rdi, rax
    call    tls_handshake
    test    rax, rax
    js      .err
    lea     rdi, [hh_req]
    mov     rsi, r13
    call    tls_send_app
    xor     rbx, rbx
.rl:
    lea     rdi, [hh_raw]
    add     rdi, rbx
    mov     rsi, 262144
    sub     rsi, rbx
    call    tls_recv_app
    test    rax, rax
    jle     .rddone
    add     rbx, rax
    cmp     rbx, 262144
    jb      .rl
.rddone:
    mov     eax, SYS_close
    mov     edi, [tls_fd]
    syscall
    lea     rdi, [hh_raw]
    mov     rsi, rbx
    lea     rdx, [hh_crlf2]
    mov     rcx, 4
    call    memfind
    test    rax, rax
    jz      .err
    add     rax, 4
    lea     rcx, [hh_raw]
    add     rcx, rbx
    mov     rdx, rcx
    sub     rdx, rax
    cmp     rdx, r15
    jbe     .cp
    mov     rdx, r15
.cp:
    mov     rdi, r14
    mov     rsi, rax
    push    rdx
    call    memcpy
    pop     rax
    jmp     .ret
.err:
    mov     rax, -1
.ret:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret
