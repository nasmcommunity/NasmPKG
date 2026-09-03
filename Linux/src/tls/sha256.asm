section .rodata
sha_h0:
    dd 0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a
    dd 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
sha_k:
    dd 0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5
    dd 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5
    dd 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3
    dd 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174
    dd 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc
    dd 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da
    dd 0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7
    dd 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967
    dd 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13
    dd 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85
    dd 0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3
    dd 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070
    dd 0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5
    dd 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3
    dd 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208
    dd 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2

section .bss
sha_h:    resd 8
sha_w:    resd 64
sha_v:    resd 8
sha_pad:  resb 128

section .text

sha256_block:
    push    rbx
    push    rbp
    push    r12
    push    r13
    push    r14
    push    r15
    lea     r15, [sha_h]
    lea     r14, [sha_w]
    lea     r13, [sha_k]
    lea     rbp, [sha_v]
    xor     rcx, rcx
.load:
    mov     eax, [rdi+rcx*4]
    bswap   eax
    mov     [r14+rcx*4], eax
    inc     rcx
    cmp     rcx, 16
    jb      .load
    mov     rcx, 16
.ext:
    mov     eax, [r14+rcx*4-60]
    mov     edx, eax
    ror     edx, 7
    mov     ebx, eax
    ror     ebx, 18
    xor     edx, ebx
    mov     ebx, eax
    shr     ebx, 3
    xor     edx, ebx
    mov     eax, [r14+rcx*4-8]
    mov     esi, eax
    ror     esi, 17
    mov     ebx, eax
    ror     ebx, 19
    xor     esi, ebx
    mov     ebx, eax
    shr     ebx, 10
    xor     esi, ebx
    mov     eax, [r14+rcx*4-64]
    add     eax, edx
    add     eax, [r14+rcx*4-28]
    add     eax, esi
    mov     [r14+rcx*4], eax
    inc     rcx
    cmp     rcx, 64
    jb      .ext
    xor     rcx, rcx
.cpv:
    mov     eax, [r15+rcx*4]
    mov     [rbp+rcx*4], eax
    inc     rcx
    cmp     rcx, 8
    jb      .cpv
    xor     rcx, rcx
.round:
    mov     eax, [rbp+16]
    mov     edx, eax
    ror     edx, 6
    mov     ebx, eax
    ror     ebx, 11
    xor     edx, ebx
    mov     ebx, eax
    ror     ebx, 25
    xor     edx, ebx
    mov     eax, [rbp+16]
    mov     ebx, [rbp+20]
    and     ebx, eax
    mov     esi, [rbp+16]
    not     esi
    and     esi, [rbp+24]
    xor     ebx, esi
    mov     eax, [rbp+28]
    add     eax, edx
    add     eax, ebx
    add     eax, [r13+rcx*4]
    add     eax, [r14+rcx*4]
    mov     r12d, eax
    mov     eax, [rbp+0]
    mov     edx, eax
    ror     edx, 2
    mov     ebx, eax
    ror     ebx, 13
    xor     edx, ebx
    mov     ebx, eax
    ror     ebx, 22
    xor     edx, ebx
    mov     eax, [rbp+0]
    mov     ebx, [rbp+4]
    mov     esi, eax
    and     esi, ebx
    mov     edi, eax
    and     edi, [rbp+8]
    xor     esi, edi
    mov     edi, ebx
    and     edi, [rbp+8]
    xor     esi, edi
    add     edx, esi
    mov     eax, [rbp+24]
    mov     [rbp+28], eax
    mov     eax, [rbp+20]
    mov     [rbp+24], eax
    mov     eax, [rbp+16]
    mov     [rbp+20], eax
    mov     eax, [rbp+12]
    add     eax, r12d
    mov     [rbp+16], eax
    mov     eax, [rbp+8]
    mov     [rbp+12], eax
    mov     eax, [rbp+4]
    mov     [rbp+8], eax
    mov     eax, [rbp+0]
    mov     [rbp+4], eax
    mov     eax, r12d
    add     eax, edx
    mov     [rbp+0], eax
    inc     rcx
    cmp     rcx, 64
    jb      .round
    xor     rcx, rcx
.addh:
    mov     eax, [r15+rcx*4]
    add     eax, [rbp+rcx*4]
    mov     [r15+rcx*4], eax
    inc     rcx
    cmp     rcx, 8
    jb      .addh
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbp
    pop     rbx
    ret

sha256:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    mov     r12, rdi
    mov     r13, rsi
    mov     r14, rdx
    lea     rdi, [sha_h0]
    lea     rsi, [sha_h]
    mov     rcx, 8
.cpH:
    mov     eax, [rdi]
    mov     [rsi], eax
    add     rdi, 4
    add     rsi, 4
    dec     rcx
    jnz     .cpH
    mov     rbx, r13
    shr     rbx, 6
    xor     rcx, rcx
.blk:
    cmp     rcx, rbx
    jae     .rem
    mov     rax, rcx
    shl     rax, 6
    lea     rdi, [r12+rax]
    push    rcx
    push    rbx
    call    sha256_block
    pop     rbx
    pop     rcx
    inc     rcx
    jmp     .blk
.rem:
    mov     rax, rbx
    shl     rax, 6
    lea     rsi, [r12+rax]
    mov     rcx, r13
    and     rcx, 63
    lea     rdi, [sha_pad]
    xor     r8, r8
.cprem:
    cmp     r8, rcx
    jae     .cpdone
    mov     al, [rsi+r8]
    mov     [rdi+r8], al
    inc     r8
    jmp     .cprem
.cpdone:
    mov     byte [rdi+rcx], 0x80
    lea     r9, [rcx+1]
    cmp     rcx, 56
    jb      .one
    mov     r10, 128
    jmp     .zt
.one:
    mov     r10, 64
.zt:
    mov     r11, r10
    sub     r11, 8
.zloop:
    cmp     r9, r11
    jae     .zdone
    mov     byte [rdi+r9], 0
    inc     r9
    jmp     .zloop
.zdone:
    mov     rax, r13
    shl     rax, 3
    bswap   rax
    mov     [rdi+r11], rax
    lea     rdi, [sha_pad]
    call    sha256_block
    cmp     r10, 128
    jb      .fin
    lea     rdi, [sha_pad+64]
    call    sha256_block
.fin:
    lea     r15, [sha_h]
    xor     rcx, rcx
.outp:
    mov     eax, [r15+rcx*4]
    bswap   eax
    mov     [r14+rcx*4], eax
    inc     rcx
    cmp     rcx, 8
    jb      .outp
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret
