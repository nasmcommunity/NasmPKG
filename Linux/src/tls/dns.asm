section .rodata
resolv_path:  db "/etc/resolv.conf", 0
ns_needle:    db "nameserver"
ns_needle_len equ $ - ns_needle

section .bss
resolv_buf:     resb 512
nameserver_ip:  resb 4
dns_query:      resb 512
dns_resp:       resb 512
dns_ns_sa:      resb 16
resolved_ip:    resb 4
dns_tv:         resq 2

section .text

get_nameserver:
    mov     eax, SYS_open
    lea     rdi, [resolv_path]
    xor     esi, esi
    xor     edx, edx
    syscall
    test    rax, rax
    js      .fail
    mov     r8, rax
    mov     eax, SYS_read
    mov     edi, r8d
    lea     rsi, [resolv_buf]
    mov     edx, 511
    syscall
    mov     r9, rax
    mov     eax, SYS_close
    mov     edi, r8d
    syscall
    test    r9, r9
    jle     .fail
    lea     rdi, [resolv_buf]
    mov     rsi, r9
    lea     rdx, [ns_needle]
    mov     rcx, ns_needle_len
    call    memfind
    test    rax, rax
    jz      .fail
    add     rax, ns_needle_len
.skipsp:
    mov     cl, [rax]
    cmp     cl, ' '
    je      .adv
    cmp     cl, 9
    je      .adv
    jmp     .parse
.adv:
    inc     rax
    jmp     .skipsp
.parse:
    mov     rdi, rax
    lea     rsi, [nameserver_ip]
    call    parse_ipv4
    xor     eax, eax
    ret
.fail:
    mov     rax, -1
    ret

encode_qname:
    mov     r8, rsi
.label:
    mov     r9, rdi
    xor     rcx, rcx
.scan:
    mov     al, [rdi]
    test    al, al
    je      .last
    cmp     al, '.'
    je      .emit
    inc     rdi
    inc     rcx
    jmp     .scan
.emit:
    mov     [r8], cl
    inc     r8
    mov     rdx, r9
.cpy:
    test    rcx, rcx
    jz      .cpydone
    mov     al, [rdx]
    mov     [r8], al
    inc     r8
    inc     rdx
    dec     rcx
    jmp     .cpy
.cpydone:
    inc     rdi
    jmp     .label
.last:
    mov     [r8], cl
    inc     r8
    mov     rdx, r9
.cpy2:
    test    rcx, rcx
    jz      .term
    mov     al, [rdx]
    mov     [r8], al
    inc     r8
    inc     rdx
    dec     rcx
    jmp     .cpy2
.term:
    mov     byte [r8], 0
    inc     r8
    mov     rax, r8
    ret

skip_name:
.l:
    movzx   ecx, byte [rdi]
    test    cl, cl
    jz      .end0
    mov     al, cl
    and     al, 0xC0
    cmp     al, 0xC0
    je      .ptr
    inc     rdi
    add     rdi, rcx
    jmp     .l
.ptr:
    add     rdi, 2
    mov     rax, rdi
    ret
.end0:
    inc     rdi
    mov     rax, rdi
    ret

resolve_a:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    mov     r15, rdi
    call    get_nameserver
    test    rax, rax
    js      .fail
    lea     rdi, [dns_query]
    mov     word [rdi], 0x3412
    mov     word [rdi+2], 0x0001
    mov     word [rdi+4], 0x0100
    mov     word [rdi+6], 0
    mov     word [rdi+8], 0
    mov     word [rdi+10], 0
    lea     rsi, [rdi+12]
    mov     rdi, r15
    call    encode_qname
    mov     rbx, rax
    mov     word [rbx], 0x0100
    mov     word [rbx+2], 0x0100
    add     rbx, 4
    lea     rax, [dns_query]
    sub     rbx, rax
    mov     r14, rbx
    mov     eax, SYS_socket
    mov     edi, AF_INET
    mov     esi, SOCK_DGRAM
    xor     edx, edx
    syscall
    test    rax, rax
    js      .fail
    mov     r13, rax
    mov     qword [dns_tv], 3
    mov     qword [dns_tv+8], 0
    mov     eax, SYS_setsockopt
    mov     edi, r13d
    mov     esi, SOL_SOCKET
    mov     edx, SO_RCVTIMEO
    lea     r10, [dns_tv]
    mov     r8d, 16
    syscall
    lea     rdi, [dns_ns_sa]
    mov     byte [rdi], AF_INET
    mov     byte [rdi+1], 0
    mov     byte [rdi+2], 0
    mov     byte [rdi+3], 53
    mov     eax, [nameserver_ip]
    mov     [rdi+4], eax
    xor     rax, rax
    mov     [rdi+8], rax
    mov     eax, SYS_sendto
    mov     edi, r13d
    lea     rsi, [dns_query]
    mov     rdx, r14
    xor     r10, r10
    lea     r8, [dns_ns_sa]
    mov     r9d, 16
    syscall
    test    rax, rax
    js      .fail_close
    mov     eax, SYS_recvfrom
    mov     edi, r13d
    lea     rsi, [dns_resp]
    mov     edx, 512
    xor     r10, r10
    xor     r8, r8
    xor     r9, r9
    syscall
    test    rax, rax
    jle     .fail_close
    mov     eax, SYS_close
    mov     edi, r13d
    syscall
    movzx   ecx, byte [dns_resp+6]
    shl     ecx, 8
    movzx   edx, byte [dns_resp+7]
    or      ecx, edx
    test    ecx, ecx
    jz      .fail
    mov     r13d, ecx
    lea     rdi, [dns_resp+12]
    call    skip_name
    mov     r14, rax
    add     r14, 4
.ans:
    mov     rdi, r14
    call    skip_name
    mov     r14, rax
    movzx   eax, byte [r14]
    shl     eax, 8
    movzx   edx, byte [r14+1]
    or      eax, edx
    movzx   ecx, byte [r14+8]
    shl     ecx, 8
    movzx   edx, byte [r14+9]
    or      ecx, edx
    cmp     eax, 1
    jne     .next
    cmp     ecx, 4
    jne     .next
    mov     eax, [r14+10]
    mov     [resolved_ip], eax
    xor     eax, eax
    jmp     .ret
.next:
    lea     r14, [r14+10]
    add     r14, rcx
    dec     r13d
    jnz     .ans
    jmp     .fail
.fail_close:
    mov     eax, SYS_close
    mov     edi, r13d
    syscall
.fail:
    mov     rax, -1
.ret:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret
