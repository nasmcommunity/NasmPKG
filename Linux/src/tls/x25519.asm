section .rodata
align 8
c121665: dq 0xDB41,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0

section .bss
alignb 8
sm_z:   resb 32
sm_r:   resd 1
sm_x:   resq 16
sm_a:   resq 16
sm_b:   resq 16
sm_c:   resq 16
sm_d:   resq 16
sm_e:   resq 16
sm_f:   resq 16
m_t:    resq 31
inv_c:  resq 16
pk_t:   resq 16
pk_m:   resq 16

section .text

gf_copy:
    xor     rcx, rcx
.l:
    mov     rax, [rsi+rcx*8]
    mov     [rdi+rcx*8], rax
    inc     rcx
    cmp     rcx, 16
    jb      .l
    ret

gf_zero:
    xor     rcx, rcx
.l:
    mov     qword [rdi+rcx*8], 0
    inc     rcx
    cmp     rcx, 16
    jb      .l
    ret

gf_A:
    xor     rcx, rcx
.l:
    mov     rax, [rsi+rcx*8]
    add     rax, [rdx+rcx*8]
    mov     [rdi+rcx*8], rax
    inc     rcx
    cmp     rcx, 16
    jb      .l
    ret

gf_Z:
    xor     rcx, rcx
.l:
    mov     rax, [rsi+rcx*8]
    sub     rax, [rdx+rcx*8]
    mov     [rdi+rcx*8], rax
    inc     rcx
    cmp     rcx, 16
    jb      .l
    ret

gf_car:
    xor     rcx, rcx
.l:
    mov     rax, [rdi+rcx*8]
    add     rax, 0x10000
    mov     r8, rax
    sar     r8, 16
    lea     r9, [r8-1]
    add     [rdi+rcx*8+8], r9
    mov     r10, r8
    shl     r10, 16
    sub     rax, r10
    mov     [rdi+rcx*8], rax
    inc     rcx
    cmp     rcx, 15
    jb      .l
    mov     rax, [rdi+15*8]
    add     rax, 0x10000
    mov     r8, rax
    sar     r8, 16
    lea     r9, [r8-1]
    imul    r9, r9, 38
    add     [rdi], r9
    mov     r10, r8
    shl     r10, 16
    sub     rax, r10
    mov     [rdi+15*8], rax
    ret

gf_sel:
    mov     eax, edx
    neg     rax
    xor     rcx, rcx
.l:
    mov     r8, [rdi+rcx*8]
    mov     r9, [rsi+rcx*8]
    mov     r10, r8
    xor     r10, r9
    and     r10, rax
    xor     r8, r10
    xor     r9, r10
    mov     [rdi+rcx*8], r8
    mov     [rsi+rcx*8], r9
    inc     rcx
    cmp     rcx, 16
    jb      .l
    ret

gf_M:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    mov     r12, rsi
    mov     r13, rdx
    mov     r14, rdi
    lea     r15, [m_t]
    xor     rcx, rcx
.z:
    mov     qword [r15+rcx*8], 0
    inc     rcx
    cmp     rcx, 31
    jb      .z
    xor     rcx, rcx
.oi:
    xor     rbx, rbx
.oj:
    mov     rax, [r12+rcx*8]
    imul    rax, [r13+rbx*8]
    lea     rdx, [rcx+rbx]
    add     [r15+rdx*8], rax
    inc     rbx
    cmp     rbx, 16
    jb      .oj
    inc     rcx
    cmp     rcx, 16
    jb      .oi
    xor     rcx, rcx
.f:
    mov     rax, [r15+rcx*8+128]
    imul    rax, rax, 38
    add     [r15+rcx*8], rax
    inc     rcx
    cmp     rcx, 15
    jb      .f
    xor     rcx, rcx
.c:
    mov     rax, [r15+rcx*8]
    mov     [r14+rcx*8], rax
    inc     rcx
    cmp     rcx, 16
    jb      .c
    mov     rdi, r14
    call    gf_car
    mov     rdi, r14
    call    gf_car
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

gf_S:
    mov     rdx, rsi
    jmp     gf_M

gf_unpack:
    xor     rcx, rcx
.l:
    movzx   eax, byte [rsi+rcx*2]
    movzx   edx, byte [rsi+rcx*2+1]
    shl     edx, 8
    or      eax, edx
    mov     [rdi+rcx*8], rax
    inc     rcx
    cmp     rcx, 16
    jb      .l
    and     qword [rdi+15*8], 0x7fff
    ret

gf_pack:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    mov     r14, rdi
    lea     rdi, [pk_t]
    call    gf_copy
    lea     rdi, [pk_t]
    call    gf_car
    lea     rdi, [pk_t]
    call    gf_car
    lea     rdi, [pk_t]
    call    gf_car
    mov     r15d, 2
.round:
    lea     r12, [pk_t]
    lea     r13, [pk_m]
    mov     rax, [r12]
    sub     rax, 0xffed
    mov     [r13], rax
    mov     rcx, 1
.mi:
    mov     rax, [r13+rcx*8-8]
    sar     rax, 16
    and     rax, 1
    mov     rdx, [r12+rcx*8]
    sub     rdx, 0xffff
    sub     rdx, rax
    mov     [r13+rcx*8], rdx
    mov     rax, [r13+rcx*8-8]
    and     rax, 0xffff
    mov     [r13+rcx*8-8], rax
    inc     rcx
    cmp     rcx, 15
    jb      .mi
    mov     rax, [r13+14*8]
    sar     rax, 16
    and     rax, 1
    mov     rdx, [r12+15*8]
    sub     rdx, 0x7fff
    sub     rdx, rax
    mov     [r13+15*8], rdx
    mov     rax, [r13+15*8]
    sar     rax, 16
    and     rax, 1
    mov     r8, rax
    mov     rax, [r13+14*8]
    and     rax, 0xffff
    mov     [r13+14*8], rax
    lea     rdi, [pk_t]
    lea     rsi, [pk_m]
    mov     edx, 1
    sub     edx, r8d
    call    gf_sel
    dec     r15d
    jnz     .round
    lea     r12, [pk_t]
    xor     rcx, rcx
.ob:
    mov     rax, [r12+rcx*8]
    mov     [r14+rcx*2], al
    mov     rdx, rax
    shr     rdx, 8
    mov     [r14+rcx*2+1], dl
    inc     rcx
    cmp     rcx, 16
    jb      .ob
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

gf_inv:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    mov     r14, rdi
    mov     r12, rsi
    lea     rdi, [inv_c]
    mov     rsi, r12
    call    gf_copy
    mov     r13d, 253
.l:
    lea     rdi, [inv_c]
    lea     rsi, [inv_c]
    call    gf_S
    cmp     r13d, 2
    je      .skip
    cmp     r13d, 4
    je      .skip
    lea     rdi, [inv_c]
    lea     rsi, [inv_c]
    mov     rdx, r12
    call    gf_M
.skip:
    dec     r13d
    jns     .l
    mov     rdi, r14
    lea     rsi, [inv_c]
    call    gf_copy
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

x25519_scalarmult:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    mov     r12, rdi
    mov     r13, rsi
    mov     r14, rdx
    lea     rdi, [sm_z]
    mov     rsi, r13
    mov     rdx, 32
    call    memcpy
    lea     rdx, [sm_z]
    mov     al, [rdx]
    and     al, 248
    mov     [rdx], al
    mov     al, [r13+31]
    and     al, 127
    or      al, 64
    mov     [rdx+31], al
    lea     rdi, [sm_x]
    mov     rsi, r14
    call    gf_unpack
    lea     rdi, [sm_b]
    lea     rsi, [sm_x]
    call    gf_copy
    lea     rdi, [sm_a]
    call    gf_zero
    lea     rdi, [sm_c]
    call    gf_zero
    lea     rdi, [sm_d]
    call    gf_zero
    mov     qword [sm_a], 1
    mov     qword [sm_d], 1
    mov     r15d, 254
.loop:
    mov     rcx, r15
    mov     rbx, rcx
    shr     rbx, 3
    lea     rdx, [sm_z]
    movzx   eax, byte [rdx+rbx]
    mov     rcx, r15
    and     cl, 7
    shr     eax, cl
    and     eax, 1
    mov     [sm_r], eax
    lea     rdi, [sm_a]
    lea     rsi, [sm_b]
    mov     edx, [sm_r]
    call    gf_sel
    lea     rdi, [sm_c]
    lea     rsi, [sm_d]
    mov     edx, [sm_r]
    call    gf_sel
    lea     rdi, [sm_e]
    lea     rsi, [sm_a]
    lea     rdx, [sm_c]
    call    gf_A
    lea     rdi, [sm_a]
    lea     rsi, [sm_a]
    lea     rdx, [sm_c]
    call    gf_Z
    lea     rdi, [sm_c]
    lea     rsi, [sm_b]
    lea     rdx, [sm_d]
    call    gf_A
    lea     rdi, [sm_b]
    lea     rsi, [sm_b]
    lea     rdx, [sm_d]
    call    gf_Z
    lea     rdi, [sm_d]
    lea     rsi, [sm_e]
    call    gf_S
    lea     rdi, [sm_f]
    lea     rsi, [sm_a]
    call    gf_S
    lea     rdi, [sm_a]
    lea     rsi, [sm_c]
    lea     rdx, [sm_a]
    call    gf_M
    lea     rdi, [sm_c]
    lea     rsi, [sm_b]
    lea     rdx, [sm_e]
    call    gf_M
    lea     rdi, [sm_e]
    lea     rsi, [sm_a]
    lea     rdx, [sm_c]
    call    gf_A
    lea     rdi, [sm_a]
    lea     rsi, [sm_a]
    lea     rdx, [sm_c]
    call    gf_Z
    lea     rdi, [sm_b]
    lea     rsi, [sm_a]
    call    gf_S
    lea     rdi, [sm_c]
    lea     rsi, [sm_d]
    lea     rdx, [sm_f]
    call    gf_Z
    lea     rdi, [sm_a]
    lea     rsi, [sm_c]
    lea     rdx, [c121665]
    call    gf_M
    lea     rdi, [sm_a]
    lea     rsi, [sm_a]
    lea     rdx, [sm_d]
    call    gf_A
    lea     rdi, [sm_c]
    lea     rsi, [sm_c]
    lea     rdx, [sm_a]
    call    gf_M
    lea     rdi, [sm_a]
    lea     rsi, [sm_d]
    lea     rdx, [sm_f]
    call    gf_M
    lea     rdi, [sm_d]
    lea     rsi, [sm_b]
    lea     rdx, [sm_x]
    call    gf_M
    lea     rdi, [sm_b]
    lea     rsi, [sm_e]
    call    gf_S
    lea     rdi, [sm_a]
    lea     rsi, [sm_b]
    mov     edx, [sm_r]
    call    gf_sel
    lea     rdi, [sm_c]
    lea     rsi, [sm_d]
    mov     edx, [sm_r]
    call    gf_sel
    dec     r15d
    jns     .loop
    lea     rdi, [sm_c]
    lea     rsi, [sm_c]
    call    gf_inv
    lea     rdi, [sm_a]
    lea     rsi, [sm_a]
    lea     rdx, [sm_c]
    call    gf_M
    mov     rdi, r12
    lea     rsi, [sm_a]
    call    gf_pack
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret
