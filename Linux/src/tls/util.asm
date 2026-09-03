section .rodata
hex_chars: db "0123456789abcdef"

section .text

to_hex:
    push    rbx
    lea     r8, [hex_chars]
    xor     rcx, rcx
.l:
    cmp     rcx, rsi
    jae     .done
    movzx   eax, byte [rdi+rcx]
    mov     ebx, eax
    shr     ebx, 4
    mov     bl, [r8+rbx]
    mov     [rdx], bl
    inc     rdx
    mov     ebx, eax
    and     ebx, 0x0f
    mov     bl, [r8+rbx]
    mov     [rdx], bl
    inc     rdx
    inc     rcx
    jmp     .l
.done:
    pop     rbx
    ret

puts:
    mov     eax, SYS_write
    mov     edi, 1
    syscall
    ret

memcpy:
    xor     rcx, rcx
.l:
    cmp     rcx, rdx
    jae     .d
    mov     al, [rsi+rcx]
    mov     [rdi+rcx], al
    inc     rcx
    jmp     .l
.d:
    ret

eputs:
    mov     eax, SYS_write
    mov     edi, 2
    syscall
    ret

parse_uint:
    xor     rax, rax
    mov     rdx, rdi
.next:
    movzx   rcx, byte [rdx]
    cmp     cl, '0'
    jb      .end
    cmp     cl, '9'
    ja      .end
    imul    rax, rax, 10
    sub     cl, '0'
    add     rax, rcx
    inc     rdx
    jmp     .next
.end:
    ret

parse_ipv4:
    push    rbx
    push    r12
    push    r13
    mov     r12, rdi
    mov     r13, rsi
    mov     ebx, 4
.loop:
    mov     rdi, r12
    call    parse_uint
    mov     [r13], al
    inc     r13
    mov     r12, rdx
    dec     ebx
    jz      .done
    cmp     byte [r12], '.'
    jne     .done
    inc     r12
    jmp     .loop
.done:
    mov     rax, r12
    pop     r13
    pop     r12
    pop     rbx
    ret

byte_to_dec:
    movzx   eax, dil
    xor     r9d, r9d
    mov     r8d, 100
    xor     edx, edx
    div     r8d
    test    eax, eax
    jz      .skip_h
    add     al, '0'
    mov     [rsi], al
    inc     rsi
    mov     r9d, 1
.skip_h:
    mov     eax, edx
    xor     edx, edx
    mov     r8d, 10
    div     r8d
    test    r9d, r9d
    jnz     .emit_t
    test    eax, eax
    jz      .skip_t
.emit_t:
    add     al, '0'
    mov     [rsi], al
    inc     rsi
.skip_t:
    add     dl, '0'
    mov     [rsi], dl
    inc     rsi
    mov     rax, rsi
    ret

ip_line:
    push    rbx
    push    r12
    mov     rbx, rdi
    mov     r12, rsi
    movzx   edi, byte [rbx]
    mov     rsi, r12
    call    byte_to_dec
    mov     r12, rax
    mov     byte [r12], '.'
    inc     r12
    movzx   edi, byte [rbx+1]
    mov     rsi, r12
    call    byte_to_dec
    mov     r12, rax
    mov     byte [r12], '.'
    inc     r12
    movzx   edi, byte [rbx+2]
    mov     rsi, r12
    call    byte_to_dec
    mov     r12, rax
    mov     byte [r12], '.'
    inc     r12
    movzx   edi, byte [rbx+3]
    mov     rsi, r12
    call    byte_to_dec
    mov     r12, rax
    mov     byte [r12], 10
    inc     r12
    mov     rax, r12
    pop     r12
    pop     rbx
    ret

memfind:
    mov     r8, rsi
    sub     r8, rcx
    js      .none
    xor     r9, r9
.outer:
    cmp     r9, r8
    jg      .none
    lea     r10, [rdi+r9]
    xor     r11, r11
.inner:
    cmp     r11, rcx
    jae     .found
    mov     al, [r10+r11]
    cmp     al, [rdx+r11]
    jne     .mismatch
    inc     r11
    jmp     .inner
.found:
    mov     rax, r10
    ret
.mismatch:
    inc     r9
    jmp     .outer
.none:
    xor     rax, rax
    ret
