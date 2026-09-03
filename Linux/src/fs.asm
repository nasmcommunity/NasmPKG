%define SYS_mkdir       83
%define SYS_rmdir       84
%define SYS_getdents64  217
%define SYS_unlinkat    263
%define O_DIRECTORY     0x10000

section .rodata
fallback_home: db "/tmp", 0
s_bullet: db "  "
nl_f:     db 10
s_bashrc:  db "/.bashrc"
s_bashrc_len equ $ - s_bashrc
s_nasmenv: db "NASMENV"
s_nasmenv_len equ $ - s_nasmenv
s_envline: db `\nexport NASMENV="-I$HOME/.nasmpkg/lib/"\n`
s_envline_len equ $ - s_envline

section .bss
alignb 8
env_path:  resb 512
env_read:  resb 65536
dents_buf: resb 32768

section .text

ensure_nasmenv:
    push    rbx
    push    r12
    call    get_home
    mov     r12, rax
    mov     rdi, r12
    call    strlen
    mov     rbx, rax
    lea     rdi, [env_path]
    mov     rsi, r12
    mov     rdx, rbx
    call    memcpy
    lea     rdi, [env_path]
    add     rdi, rbx
    lea     rsi, [s_bashrc]
    mov     rdx, s_bashrc_len
    call    memcpy
    add     rbx, s_bashrc_len
    lea     rcx, [env_path]
    add     rcx, rbx
    mov     byte [rcx], 0
    mov     eax, SYS_open
    lea     rdi, [env_path]
    xor     esi, esi
    xor     edx, edx
    syscall
    test    rax, rax
    js      .append
    mov     r12, rax
    mov     eax, 0
    mov     edi, r12d
    lea     rsi, [env_read]
    mov     edx, 65535
    syscall
    mov     rbx, rax
    mov     eax, 3
    mov     edi, r12d
    syscall
    test    rbx, rbx
    jle     .append
    lea     rdi, [env_read]
    mov     rsi, rbx
    lea     rdx, [s_nasmenv]
    mov     rcx, s_nasmenv_len
    call    memfind
    test    rax, rax
    jnz     .done
.append:
    mov     eax, SYS_open
    lea     rdi, [env_path]
    mov     esi, 0x441
    mov     edx, 420
    syscall
    test    rax, rax
    js      .done
    mov     r12, rax
    mov     rdi, r12
    lea     rsi, [s_envline]
    mov     rdx, s_envline_len
    call    write_all
    mov     eax, 3
    mov     edi, r12d
    syscall
.done:
    pop     r12
    pop     rbx
    ret

get_home:
    mov     r8, [saved_rsp]
    mov     rax, [r8]
    lea     r8, [r8 + rax*8 + 16]
.l:
    mov     rsi, [r8]
    test    rsi, rsi
    jz      .none
    cmp     byte [rsi], 'H'
    jne     .next
    cmp     byte [rsi+1], 'O'
    jne     .next
    cmp     byte [rsi+2], 'M'
    jne     .next
    cmp     byte [rsi+3], 'E'
    jne     .next
    cmp     byte [rsi+4], '='
    jne     .next
    lea     rax, [rsi+5]
    ret
.next:
    add     r8, 8
    jmp     .l
.none:
    lea     rax, [fallback_home]
    ret

my_mkdir:
    mov     eax, SYS_mkdir
    mov     esi, 493
    syscall
    ret

write_file:
    push    r12
    push    r13
    push    r14
    mov     r13, rsi
    mov     r14, rdx
    mov     eax, SYS_open
    mov     esi, 0x241
    mov     edx, 420
    syscall
    test    rax, rax
    js      .err
    mov     r12, rax
    mov     rdi, r12
    mov     rsi, r13
    mov     rdx, r14
    call    write_all
    mov     eax, 3
    mov     edi, r12d
    syscall
    xor     rax, rax
    jmp     .ret
.err:
    mov     rax, -1
.ret:
    pop     r14
    pop     r13
    pop     r12
    ret

print_libs:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    mov     eax, SYS_open
    mov     esi, O_DIRECTORY
    xor     edx, edx
    syscall
    test    rax, rax
    js      .none
    mov     r12, rax
    xor     r15, r15
.dents:
    mov     eax, SYS_getdents64
    mov     edi, r12d
    lea     rsi, [dents_buf]
    mov     edx, 32768
    syscall
    test    rax, rax
    jle     .done
    mov     r13, rax
    xor     rbx, rbx
.entry:
    cmp     rbx, r13
    jae     .dents
    lea     r14, [dents_buf+rbx]
    movzx   eax, byte [r14+18]
    cmp     al, 4
    jne     .next
    lea     rdi, [r14+19]
    cmp     byte [rdi], '.'
    jne     .print
    cmp     byte [rdi+1], 0
    je      .next
    cmp     byte [rdi+1], '.'
    jne     .print
    cmp     byte [rdi+2], 0
    je      .next
.print:
    inc     r15
    lea     rsi, [s_bullet]
    mov     rdx, 2
    call    puts
    lea     rdi, [r14+19]
    call    strlen
    lea     rsi, [r14+19]
    mov     rdx, rax
    call    puts
    lea     rsi, [nl_f]
    mov     rdx, 1
    call    puts
.next:
    movzx   eax, word [r14+16]
    add     rbx, rax
    jmp     .entry
.done:
    mov     eax, SYS_close
    mov     edi, r12d
    syscall
    mov     rax, r15
    jmp     .ret
.none:
    xor     rax, rax
.ret:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

remove_pkg:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    mov     r15, rdi
    mov     eax, SYS_open
    mov     esi, O_DIRECTORY
    xor     edx, edx
    syscall
    test    rax, rax
    js      .nf
    mov     r12, rax
.dents:
    mov     eax, SYS_getdents64
    mov     edi, r12d
    lea     rsi, [dents_buf]
    mov     edx, 32768
    syscall
    test    rax, rax
    jle     .done
    mov     r13, rax
    xor     rbx, rbx
.entry:
    cmp     rbx, r13
    jae     .dents
    lea     r14, [dents_buf+rbx]
    lea     rdi, [r14+19]
    cmp     byte [rdi], '.'
    jne     .del
    cmp     byte [rdi+1], 0
    je      .next
    cmp     byte [rdi+1], '.'
    jne     .del
    cmp     byte [rdi+2], 0
    je      .next
.del:
    mov     eax, SYS_unlinkat
    mov     edi, r12d
    lea     rsi, [r14+19]
    xor     edx, edx
    syscall
.next:
    movzx   eax, word [r14+16]
    add     rbx, rax
    jmp     .entry
.done:
    mov     eax, SYS_close
    mov     edi, r12d
    syscall
    mov     eax, SYS_rmdir
    mov     rdi, r15
    syscall
    xor     rax, rax
    jmp     .ret
.nf:
    mov     rax, -1
.ret:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret
