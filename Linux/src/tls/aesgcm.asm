section .rodata
align 16
bswap_mask: db 15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0

section .bss
alignb 16
gcm_zero:    resb 16
gcm_h:       resb 16
gcm_hr:      resb 16
gcm_j0:      resb 16
gcm_ej0:     resb 16
gcm_ctr:     resb 16
gcm_ks:      resb 16
gcm_y:       resb 16
gcm_lenblk:  resb 16
gcm_scratch: resb 16
gcm_isopen:  resb 16

section .text

aes128_expand:
    movdqu  xmm1, [rdi]
    movdqu  [rsi], xmm1
    aeskeygenassist xmm2, xmm1, 0x01
    call    .ke
    movdqu  [rsi+16], xmm1
    aeskeygenassist xmm2, xmm1, 0x02
    call    .ke
    movdqu  [rsi+32], xmm1
    aeskeygenassist xmm2, xmm1, 0x04
    call    .ke
    movdqu  [rsi+48], xmm1
    aeskeygenassist xmm2, xmm1, 0x08
    call    .ke
    movdqu  [rsi+64], xmm1
    aeskeygenassist xmm2, xmm1, 0x10
    call    .ke
    movdqu  [rsi+80], xmm1
    aeskeygenassist xmm2, xmm1, 0x20
    call    .ke
    movdqu  [rsi+96], xmm1
    aeskeygenassist xmm2, xmm1, 0x40
    call    .ke
    movdqu  [rsi+112], xmm1
    aeskeygenassist xmm2, xmm1, 0x80
    call    .ke
    movdqu  [rsi+128], xmm1
    aeskeygenassist xmm2, xmm1, 0x1b
    call    .ke
    movdqu  [rsi+144], xmm1
    aeskeygenassist xmm2, xmm1, 0x36
    call    .ke
    movdqu  [rsi+160], xmm1
    ret
.ke:
    pshufd  xmm2, xmm2, 0xff
    movdqa  xmm3, xmm1
    pslldq  xmm3, 4
    pxor    xmm1, xmm3
    pslldq  xmm3, 4
    pxor    xmm1, xmm3
    pslldq  xmm3, 4
    pxor    xmm1, xmm3
    pxor    xmm1, xmm2
    ret

aes128_enc:
    movdqu  xmm0, [rsi]
    pxor    xmm0, [rdi]
    aesenc  xmm0, [rdi+16]
    aesenc  xmm0, [rdi+32]
    aesenc  xmm0, [rdi+48]
    aesenc  xmm0, [rdi+64]
    aesenc  xmm0, [rdi+80]
    aesenc  xmm0, [rdi+96]
    aesenc  xmm0, [rdi+112]
    aesenc  xmm0, [rdi+128]
    aesenc  xmm0, [rdi+144]
    aesenclast xmm0, [rdi+160]
    movdqu  [rdx], xmm0
    ret

ghash_mul:
    movdqa  xmm3, xmm0
    pclmulqdq xmm3, xmm1, 0x00
    movdqa  xmm4, xmm0
    pclmulqdq xmm4, xmm1, 0x10
    movdqa  xmm5, xmm0
    pclmulqdq xmm5, xmm1, 0x01
    movdqa  xmm6, xmm0
    pclmulqdq xmm6, xmm1, 0x11
    pxor    xmm4, xmm5
    movdqa  xmm5, xmm4
    pslldq  xmm4, 8
    psrldq  xmm5, 8
    pxor    xmm3, xmm4
    pxor    xmm6, xmm5
    movdqa  xmm7, xmm3
    movdqa  xmm8, xmm6
    psrld   xmm7, 31
    psrld   xmm8, 31
    pslld   xmm3, 1
    pslld   xmm6, 1
    movdqa  xmm9, xmm7
    pslldq  xmm7, 4
    pslldq  xmm8, 4
    psrldq  xmm9, 12
    por     xmm3, xmm7
    por     xmm6, xmm8
    por     xmm6, xmm9
    movdqa  xmm7, xmm3
    movdqa  xmm8, xmm3
    movdqa  xmm9, xmm3
    pslld   xmm7, 31
    pslld   xmm8, 30
    pslld   xmm9, 25
    pxor    xmm7, xmm8
    pxor    xmm7, xmm9
    movdqa  xmm8, xmm7
    pslldq  xmm7, 12
    psrldq  xmm8, 4
    pxor    xmm3, xmm7
    movdqa  xmm2, xmm3
    movdqa  xmm4, xmm3
    movdqa  xmm5, xmm3
    psrld   xmm2, 1
    psrld   xmm4, 2
    psrld   xmm5, 7
    pxor    xmm2, xmm4
    pxor    xmm2, xmm5
    pxor    xmm2, xmm8
    pxor    xmm3, xmm2
    pxor    xmm6, xmm3
    movdqa  xmm0, xmm6
    ret

gcm_inc32_ptr:
    mov     eax, [rdi+12]
    bswap   eax
    add     eax, 1
    bswap   eax
    mov     [rdi+12], eax
    ret

gctr:
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
.loop:
    test    r15, r15
    jz      .done
    mov     rdi, r12
    mov     rsi, r13
    lea     rdx, [gcm_ks]
    call    aes128_enc
    mov     rcx, 16
    cmp     r15, 16
    jae     .full
    mov     rcx, r15
.full:
    lea     r9, [gcm_ks]
    xor     rax, rax
.xr:
    mov     dl, [r14+rax]
    xor     dl, [r9+rax]
    mov     [rbx+rax], dl
    inc     rax
    cmp     rax, rcx
    jb      .xr
    add     r14, rcx
    add     rbx, rcx
    sub     r15, rcx
    mov     rdi, r13
    call    gcm_inc32_ptr
    jmp     .loop
.done:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

gh_feed:
.loop:
    cmp     r11, 16
    jb      .partial
    movdqu  xmm2, [r10]
    pshufb  xmm2, [bswap_mask]
    pxor    xmm0, xmm2
    movdqa  xmm1, [gcm_hr]
    call    ghash_mul
    add     r10, 16
    sub     r11, 16
    jmp     .loop
.partial:
    test    r11, r11
    jz      .done
    pxor    xmm2, xmm2
    movdqu  [gcm_scratch], xmm2
    lea     rdx, [gcm_scratch]
    xor     rcx, rcx
.cp:
    mov     al, [r10+rcx]
    mov     [rdx+rcx], al
    inc     rcx
    cmp     rcx, r11
    jb      .cp
    movdqu  xmm2, [gcm_scratch]
    pshufb  xmm2, [bswap_mask]
    pxor    xmm0, xmm2
    movdqa  xmm1, [gcm_hr]
    call    ghash_mul
.done:
    ret

gcm_ghash_all:
    pxor    xmm0, xmm0
    mov     r10, [rbx+16]
    mov     r11, [rbx+24]
    call    gh_feed
    mov     r10, rsi
    mov     r11, r14
    call    gh_feed
    mov     rax, [rbx+24]
    shl     rax, 3
    bswap   rax
    mov     [gcm_lenblk], rax
    mov     rax, r14
    shl     rax, 3
    bswap   rax
    mov     [gcm_lenblk+8], rax
    movdqu  xmm2, [gcm_lenblk]
    pshufb  xmm2, [bswap_mask]
    pxor    xmm0, xmm2
    movdqa  xmm1, [gcm_hr]
    call    ghash_mul
    pshufb  xmm0, [bswap_mask]
    movdqu  [gcm_y], xmm0
    ret

gcm_seal:
    mov     byte [gcm_isopen], 0
    jmp     gcm_core

gcm_open:
    mov     byte [gcm_isopen], 1
    jmp     gcm_core

gcm_core:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    mov     rbx, rdi
    mov     r12, [rbx+0]
    mov     r13, [rbx+32]
    mov     r14, [rbx+40]
    mov     r15, [rbx+48]
    mov     rdi, r12
    lea     rsi, [gcm_zero]
    lea     rdx, [gcm_h]
    call    aes128_enc
    movdqu  xmm0, [gcm_h]
    pshufb  xmm0, [bswap_mask]
    movdqu  [gcm_hr], xmm0
    mov     rsi, [rbx+8]
    lea     rdi, [gcm_j0]
    mov     eax, [rsi]
    mov     [rdi], eax
    mov     eax, [rsi+4]
    mov     [rdi+4], eax
    mov     eax, [rsi+8]
    mov     [rdi+8], eax
    mov     dword [rdi+12], 0x01000000
    mov     rdi, r12
    lea     rsi, [gcm_j0]
    lea     rdx, [gcm_ej0]
    call    aes128_enc
    movdqu  xmm0, [gcm_j0]
    movdqu  [gcm_ctr], xmm0
    lea     rdi, [gcm_ctr]
    call    gcm_inc32_ptr
    cmp     byte [gcm_isopen], 0
    jne     .open
    mov     rdi, r12
    lea     rsi, [gcm_ctr]
    mov     rdx, r13
    mov     rcx, r14
    mov     r8, r15
    call    gctr
    mov     rsi, r15
    call    gcm_ghash_all
    jmp     .finish
.open:
    mov     rsi, r13
    call    gcm_ghash_all
    mov     rdi, r12
    lea     rsi, [gcm_ctr]
    mov     rdx, r13
    mov     rcx, r14
    mov     r8, r15
    call    gctr
.finish:
    mov     rdi, [rbx+56]
    movdqu  xmm0, [gcm_y]
    movdqu  xmm1, [gcm_ej0]
    pxor    xmm0, xmm1
    movdqu  [rdi], xmm0
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret
