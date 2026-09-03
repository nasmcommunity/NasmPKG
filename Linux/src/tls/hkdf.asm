section .bss
hmac_k0:     resb 64
hmac_inner:  resb 576
hmac_ihash:  resb 32
hmac_outer:  resb 96
hkdf_tprev:  resb 32
hkdf_msg:    resb 320
hkdf_ti:     resb 32

section .text

hmac_sha256:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    mov     r12, rdi
    mov     r13, rsi
    mov     r14, rdx
    mov     r15, rcx
    mov     rbx, r8
    lea     rdi, [hmac_k0]
    xor     rcx, rcx
.z:
    mov     byte [rdi+rcx], 0
    inc     rcx
    cmp     rcx, 64
    jb      .z
    cmp     r13, 64
    jbe     .short
    mov     rdi, r12
    mov     rsi, r13
    lea     rdx, [hmac_k0]
    call    sha256
    jmp     .havek0
.short:
    lea     rdi, [hmac_k0]
    mov     rsi, r12
    mov     rdx, r13
    call    memcpy
.havek0:
    lea     rdi, [hmac_inner]
    lea     rsi, [hmac_k0]
    xor     rcx, rcx
.ip:
    mov     al, [rsi+rcx]
    xor     al, 0x36
    mov     [rdi+rcx], al
    inc     rcx
    cmp     rcx, 64
    jb      .ip
    lea     rdi, [hmac_inner+64]
    mov     rsi, r14
    mov     rdx, r15
    call    memcpy
    lea     rdi, [hmac_inner]
    mov     rsi, r15
    add     rsi, 64
    lea     rdx, [hmac_ihash]
    call    sha256
    lea     rdi, [hmac_outer]
    lea     rsi, [hmac_k0]
    xor     rcx, rcx
.op:
    mov     al, [rsi+rcx]
    xor     al, 0x5c
    mov     [rdi+rcx], al
    inc     rcx
    cmp     rcx, 64
    jb      .op
    lea     rdi, [hmac_outer+64]
    lea     rsi, [hmac_ihash]
    mov     rdx, 32
    call    memcpy
    lea     rdi, [hmac_outer]
    mov     rsi, 96
    mov     rdx, rbx
    call    sha256
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

hkdf_extract:
    jmp     hmac_sha256

hkdf_expand:
    push    rbx
    push    rbp
    push    r12
    push    r13
    push    r14
    push    r15
    mov     r12, rdi
    mov     r13, rsi
    mov     r14, rdx
    mov     r15, rcx
    mov     rbx, r8
    xor     rbp, rbp
    mov     r9, 1
.loop:
    test    rbx, rbx
    jz      .done
    lea     rdi, [hkdf_msg]
    lea     rsi, [hkdf_tprev]
    mov     rdx, rbp
    push    r9
    call    memcpy
    pop     r9
    lea     rdi, [hkdf_msg]
    add     rdi, rbp
    mov     rsi, r13
    mov     rdx, r14
    push    r9
    call    memcpy
    pop     r9
    lea     rdi, [hkdf_msg]
    add     rdi, rbp
    add     rdi, r14
    mov     [rdi], r9b
    mov     r10, rbp
    add     r10, r14
    add     r10, 1
    mov     rdi, r12
    mov     rsi, 32
    lea     rdx, [hkdf_msg]
    mov     rcx, r10
    lea     r8, [hkdf_ti]
    push    r9
    call    hmac_sha256
    pop     r9
    mov     rcx, 32
    cmp     rbx, 32
    jae     .full
    mov     rcx, rbx
.full:
    mov     rdi, r15
    lea     rsi, [hkdf_ti]
    mov     rdx, rcx
    push    r9
    push    rcx
    call    memcpy
    pop     rcx
    pop     r9
    add     r15, rcx
    sub     rbx, rcx
    lea     rdi, [hkdf_tprev]
    lea     rsi, [hkdf_ti]
    mov     rdx, 32
    push    r9
    call    memcpy
    pop     r9
    mov     rbp, 32
    inc     r9
    jmp     .loop
.done:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbp
    pop     rbx
    ret
