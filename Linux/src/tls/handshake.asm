section .rodata
align 8
base9:  db 9
        times 31 db 0

ext_sni:
    db 0x00,0x00, 0x00,0x18, 0x00,0x16, 0x00, 0x00,0x13
    db "registry.nasmpkg.ru"
ext_sni_len equ $ - ext_sni

ext_groups:
    db 0x00,0x0a, 0x00,0x04, 0x00,0x02, 0x00,0x1d
ext_groups_len equ $ - ext_groups

ext_sigalgs:
    db 0x00,0x0d, 0x00,0x12, 0x00,0x10
    db 0x04,0x03, 0x08,0x04, 0x04,0x01, 0x05,0x03, 0x08,0x05, 0x05,0x01, 0x08,0x06, 0x06,0x01
ext_sigalgs_len equ $ - ext_sigalgs

ext_versions:
    db 0x00,0x2b, 0x00,0x03, 0x02, 0x03,0x04
ext_versions_len equ $ - ext_versions

ext_ks_hdr:
    db 0x00,0x33, 0x00,0x26, 0x00,0x24, 0x00,0x1d, 0x00,0x20
ext_ks_hdr_len equ $ - ext_ks_hdr

section .bss
alignb 8
ch_priv:     resb 32
ch_pub:      resb 32
ch_out:      resq 1
ch_hs:       resq 1
ch_body:     resq 1
ch_extstart: resq 1
ch_extlen:   resq 1

section .text

get_random:
    push    rbx
    push    r12
    mov     r12, rdi
    mov     rbx, rsi
.l:
    test    rbx, rbx
    jz      .done
.rs:
    rdseed  rax
    jnc     .rs
    mov     rcx, 8
    cmp     rbx, 8
    jae     .st
    mov     rcx, rbx
.st:
    xor     rdx, rdx
.sb:
    mov     [r12+rdx], al
    shr     rax, 8
    inc     rdx
    cmp     rdx, rcx
    jb      .sb
    add     r12, rcx
    sub     rbx, rcx
    jmp     .l
.done:
    pop     r12
    pop     rbx
    ret

gen_keypair:
    lea     rdi, [ch_priv]
    mov     rsi, 32
    call    get_random
    lea     rdi, [ch_pub]
    lea     rsi, [ch_priv]
    lea     rdx, [base9]
    call    x25519_scalarmult
    ret

build_client_hello:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    mov     [ch_out], rdi
    mov     r12, rdi
    mov     byte [r12], 0x16
    mov     byte [r12+1], 0x03
    mov     byte [r12+2], 0x01
    add     r12, 5
    mov     [ch_hs], r12
    mov     byte [r12], 0x01
    add     r12, 4
    mov     [ch_body], r12
    mov     byte [r12], 0x03
    mov     byte [r12+1], 0x03
    add     r12, 2
    mov     rdi, r12
    mov     rsi, 32
    call    get_random
    add     r12, 32
    mov     byte [r12], 32
    inc     r12
    mov     rdi, r12
    mov     rsi, 32
    call    get_random
    add     r12, 32
    mov     byte [r12], 0x00
    mov     byte [r12+1], 0x02
    mov     byte [r12+2], 0x13
    mov     byte [r12+3], 0x01
    add     r12, 4
    mov     byte [r12], 0x01
    mov     byte [r12+1], 0x00
    add     r12, 2
    mov     [ch_extlen], r12
    add     r12, 2
    mov     [ch_extstart], r12
    mov     rdi, r12
    lea     rsi, [ext_sni]
    mov     rdx, ext_sni_len
    call    memcpy
    add     r12, ext_sni_len
    mov     rdi, r12
    lea     rsi, [ext_groups]
    mov     rdx, ext_groups_len
    call    memcpy
    add     r12, ext_groups_len
    mov     rdi, r12
    lea     rsi, [ext_sigalgs]
    mov     rdx, ext_sigalgs_len
    call    memcpy
    add     r12, ext_sigalgs_len
    mov     rdi, r12
    lea     rsi, [ext_versions]
    mov     rdx, ext_versions_len
    call    memcpy
    add     r12, ext_versions_len
    mov     rdi, r12
    lea     rsi, [ext_ks_hdr]
    mov     rdx, ext_ks_hdr_len
    call    memcpy
    add     r12, ext_ks_hdr_len
    mov     rdi, r12
    lea     rsi, [ch_pub]
    mov     rdx, 32
    call    memcpy
    add     r12, 32
    mov     rax, r12
    mov     rcx, [ch_extstart]
    sub     rax, rcx
    mov     rdx, [ch_extlen]
    mov     rcx, rax
    shr     rcx, 8
    mov     [rdx], cl
    mov     [rdx+1], al
    mov     rax, r12
    mov     rcx, [ch_body]
    sub     rax, rcx
    mov     rdx, [ch_hs]
    mov     rcx, rax
    shr     rcx, 16
    mov     [rdx+1], cl
    mov     rcx, rax
    shr     rcx, 8
    mov     [rdx+2], cl
    mov     [rdx+3], al
    mov     rax, r12
    mov     rcx, [ch_hs]
    sub     rax, rcx
    mov     rdx, [ch_out]
    mov     rcx, rax
    shr     rcx, 8
    mov     [rdx+3], cl
    mov     [rdx+4], al
    mov     rax, r12
    sub     rax, [ch_out]
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret
