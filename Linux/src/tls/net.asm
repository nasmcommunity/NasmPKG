section .rodata
connect_req:
    db "CONNECT api.telegram.org:443 HTTP/1.1", 13, 10
    db "Host: api.telegram.org:443", 13, 10
    db 13, 10
connect_req_len equ $ - connect_req
status_200:   db " 200 "
status_200_len equ $ - status_200

section .bss
proxy_resp: resb 512

section .text

tcp_connect_timeout:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    mov     r14, rdi
    mov     r15d, esi
    mov     eax, SYS_socket
    mov     edi, AF_INET
    mov     esi, SOCK_STREAM
    xor     edx, edx
    syscall
    test    rax, rax
    js      .fail0
    mov     r12, rax
    mov     eax, SYS_fcntl
    mov     edi, r12d
    mov     esi, F_GETFL
    xor     edx, edx
    syscall
    mov     r13d, eax
    mov     eax, SYS_fcntl
    mov     edi, r12d
    mov     esi, F_SETFL
    mov     edx, r13d
    or      edx, O_NONBLOCK
    syscall
    mov     eax, SYS_connect
    mov     edi, r12d
    mov     rsi, r14
    mov     edx, 16
    syscall
    test    rax, rax
    jz      .connected
    cmp     rax, -EINPROGRESS
    jne     .failfd
    sub     rsp, 16
    mov     dword [rsp], r12d
    mov     word [rsp+4], POLLOUT
    mov     word [rsp+6], 0
    mov     eax, SYS_poll
    mov     rdi, rsp
    mov     esi, 1
    mov     edx, r15d
    syscall
    cmp     rax, 1
    jne     .failfd_sp
    mov     dword [rsp+8], 4
    mov     eax, SYS_getsockopt
    mov     edi, r12d
    mov     esi, SOL_SOCKET
    mov     edx, SO_ERROR
    lea     r10, [rsp+12]
    lea     r8, [rsp+8]
    syscall
    mov     eax, dword [rsp+12]
    add     rsp, 16
    test    eax, eax
    jnz     .failfd
    jmp     .connected
.failfd_sp:
    add     rsp, 16
.failfd:
    mov     eax, SYS_close
    mov     edi, r12d
    syscall
.fail0:
    mov     rax, -1
    jmp     .ret
.connected:
    mov     eax, SYS_fcntl
    mov     edi, r12d
    mov     esi, F_SETFL
    mov     edx, r13d
    syscall
    mov     rax, r12
.ret:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

tcp_connect_blocking:
    push    rbx
    push    r12
    mov     r12, rdi
    mov     eax, SYS_socket
    mov     edi, AF_INET
    mov     esi, SOCK_STREAM
    xor     edx, edx
    syscall
    test    rax, rax
    js      .f
    mov     rbx, rax
    mov     eax, SYS_connect
    mov     edi, ebx
    mov     rsi, r12
    mov     edx, 16
    syscall
    test    rax, rax
    js      .cf
    mov     rax, rbx
    jmp     .done
.cf:
    mov     eax, SYS_close
    mov     edi, ebx
    syscall
.f:
    mov     rax, -1
.done:
    pop     r12
    pop     rbx
    ret

write_all:
    push    r12
    push    r13
    push    r14
    mov     r12d, edi
    mov     r13, rsi
    mov     r14, rdx
.l:
    test    r14, r14
    jz      .done
    mov     eax, SYS_write
    mov     edi, r12d
    mov     rsi, r13
    mov     rdx, r14
    syscall
    test    rax, rax
    jle     .done
    add     r13, rax
    sub     r14, rax
    jmp     .l
.done:
    pop     r14
    pop     r13
    pop     r12
    ret

read_some:
    mov     eax, SYS_read
    syscall
    ret

proxy_open:
    push    r12
    call    tcp_connect_blocking
    test    rax, rax
    js      .fail
    mov     r12, rax
    mov     rdi, r12
    lea     rsi, [connect_req]
    mov     rdx, connect_req_len
    call    write_all
    mov     rdi, r12
    lea     rsi, [proxy_resp]
    mov     rdx, 512
    call    read_some
    test    rax, rax
    jle     .failclose
    mov     rsi, rax
    lea     rdi, [proxy_resp]
    lea     rdx, [status_200]
    mov     rcx, status_200_len
    call    memfind
    test    rax, rax
    jz      .failclose
    mov     rax, r12
    jmp     .done
.failclose:
    mov     eax, SYS_close
    mov     edi, r12d
    syscall
.fail:
    mov     rax, -1
.done:
    pop     r12
    ret
