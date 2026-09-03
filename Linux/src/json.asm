section .text

jfind:
    call    memfind
    test    rax, rax
    jz      .z
    add     rax, rcx
    ret
.z:
    xor     rax, rax
    ret

after_quote:
    mov     al, [rdi]
    inc     rdi
    cmp     al, 0x22
    jne     after_quote
    mov     rax, rdi
    ret

obj_next_key:
    push    rbx
.findq:
    mov     cl, [rdi]
    test    cl, cl
    jz      .end
    cmp     cl, '}'
    je      .end
    cmp     cl, 0x22
    je      .readk
    inc     rdi
    jmp     .findq
.readk:
    inc     rdi
    xor     rax, rax
.ck:
    cmp     rax, rdx
    jae     .kdone
    mov     cl, [rdi+rax]
    cmp     cl, 0x22
    je      .kdone
    mov     [rsi+rax], cl
    inc     rax
    jmp     .ck
.kdone:
    mov     rbx, rax
    add     rdi, rax
    inc     rdi
.tocolon:
    mov     cl, [rdi]
    inc     rdi
    test    cl, cl
    jz      .ret
    cmp     cl, ':'
    jne     .tocolon
.ws:
    mov     cl, [rdi]
    cmp     cl, ' '
    je      .wsadv
    cmp     cl, 9
    je      .wsadv
    cmp     cl, 10
    je      .wsadv
    cmp     cl, 13
    je      .wsadv
    jmp     .val
.wsadv:
    inc     rdi
    jmp     .ws
.val:
    mov     cl, [rdi]
    cmp     cl, '{'
    je      .obj
.scal:
    mov     cl, [rdi]
    test    cl, cl
    jz      .ret
    cmp     cl, ','
    je      .ret
    cmp     cl, '}'
    je      .ret
    inc     rdi
    jmp     .scal
.obj:
    xor     r8, r8
.od:
    mov     cl, [rdi]
    test    cl, cl
    jz      .ret
    inc     rdi
    cmp     cl, '{'
    je      .odopen
    cmp     cl, '}'
    je      .odclose
    jmp     .od
.odopen:
    inc     r8
    jmp     .od
.odclose:
    dec     r8
    jnz     .od
.ret:
    mov     rdx, rbx
    mov     rax, rdi
    pop     rbx
    ret
.end:
    xor     rax, rax
    pop     rbx
    ret

arr_next:
.skip:
    mov     cl, [rdi]
    cmp     cl, 0x22
    je      .read
    cmp     cl, ']'
    je      .end
    test    cl, cl
    jz      .end
    inc     rdi
    jmp     .skip
.read:
    inc     rdi
    xor     rax, rax
.cp:
    cmp     rax, rdx
    jae     .done
    mov     cl, [rdi+rax]
    cmp     cl, 0x22
    je      .done
    mov     [rsi+rax], cl
    inc     rax
    jmp     .cp
.done:
    lea     rcx, [rdi+rax]
    inc     rcx
    mov     rdx, rax
    mov     rax, rcx
    ret
.end:
    xor     rax, rax
    ret

jstr:
    xor     rax, rax
.l:
    cmp     rax, rdx
    jae     .d
    mov     cl, [rdi+rax]
    cmp     cl, 0x22
    je      .d
    mov     [rsi+rax], cl
    inc     rax
    jmp     .l
.d:
    ret

parse_ver:
    xor     rax, rax
    xor     r8, r8
.pv_digit:
    movzx   ecx, byte [rdi]
    cmp     cl, '0'
    jb      .pv_sep
    cmp     cl, '9'
    ja      .pv_sep
    imul    r8, r8, 10
    movzx   edx, cl
    sub     edx, '0'
    add     r8, rdx
    inc     rdi
    jmp     .pv_digit
.pv_sep:
    shl     rax, 20
    or      rax, r8
    xor     r8, r8
    cmp     cl, '.'
    jne     .pv_done
    inc     rdi
    jmp     .pv_digit
.pv_done:
    ret
