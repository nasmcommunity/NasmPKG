section .rodata
l_derived:  db "derived"
l_chs:      db "c hs traffic"
l_shs:      db "s hs traffic"
l_cap:      db "c ap traffic"
l_sap:      db "s ap traffic"
l_key:      db "key"
l_iv:       db "iv"
l_finished: db "finished"
zeros32:    times 32 db 0
ccs_rec:    db 0x14, 0x03, 0x03, 0x00, 0x01, 0x01

section .bss
alignb 8
tls_fd:         resq 1
transcript_buf: resb 32768
transcript_len: resq 1
sh_server_pub:  resb 32
shared:         resb 32
ch_buf:         resb 1024
rec:            resb 20480
ptbuf:          resb 20480
early:          resb 32
ehash:          resb 32
derived:        resb 32
hs_secret:      resb 32
master:         resb 32
c_hs:           resb 32
s_hs:           resb 32
c_ap:           resb 32
s_ap:           resb 32
th_chsh:        resb 32
th_sfin:        resb 32
c_hs_key:       resb 16
c_hs_iv:        resb 12
s_hs_key:       resb 16
s_hs_iv:        resb 12
c_ap_key:       resb 16
c_ap_iv:        resb 12
s_ap_key:       resb 16
s_ap_iv:        resb 12
c_fin_key:      resb 32
fin_verify:     resb 32
fin_msg:        resb 64
srv_hs_seq:     resq 1
cli_app_seq:    resq 1
srv_app_seq:    resq 1
parse_pos:      resq 1
got_fin:        resq 1
sr_fd:          resq 1
sr_rk:          resq 1
sr_iv:          resq 1
sr_seq:         resq 1
sr_ct:          resb 1
sr_data:        resq 1
sr_len:         resq 1
sr_nonce:       resb 16
op_nonce:       resb 16
calctag:        resb 16
sbuf_inner:     resb 20480
sbuf:           resb 20480
gctx:           resb 64
alignb 16
s_hs_rk:        resb 176
alignb 16
c_hs_rk:        resb 176
alignb 16
c_ap_rk:        resb 176
alignb 16
s_ap_rk:        resb 176

section .text

transcript_reset:
    mov     qword [transcript_len], 0
    ret

transcript_append:
    push    r12
    lea     r12, [transcript_buf]
    add     r12, [transcript_len]
    mov     rax, [transcript_len]
    add     rax, rsi
    mov     [transcript_len], rax
    mov     rax, rsi
    mov     rsi, rdi
    mov     rdi, r12
    mov     rdx, rax
    call    memcpy
    pop     r12
    ret

transcript_hash:
    mov     rdx, rdi
    lea     rdi, [transcript_buf]
    mov     rsi, [transcript_len]
    call    sha256
    ret

parse_serverhello:
    push    rbx
    mov     rcx, rdi
    add     rcx, 6
    add     rcx, 32
    movzx   eax, byte [rcx]
    inc     rcx
    add     rcx, rax
    add     rcx, 3
    movzx   eax, byte [rcx]
    shl     eax, 8
    movzx   edx, byte [rcx+1]
    or      eax, edx
    add     rcx, 2
    mov     rbx, rcx
    add     rbx, rax
.exloop:
    cmp     rcx, rbx
    jae     .notfound
    movzx   eax, byte [rcx]
    shl     eax, 8
    movzx   edx, byte [rcx+1]
    or      eax, edx
    movzx   r9d, byte [rcx+2]
    shl     r9d, 8
    movzx   edx, byte [rcx+3]
    or      r9d, edx
    cmp     eax, 0x0033
    je      .found
    add     rcx, 4
    add     rcx, r9
    jmp     .exloop
.found:
    lea     rsi, [rcx+8]
    lea     rdi, [sh_server_pub]
    mov     rdx, 32
    call    memcpy
    xor     eax, eax
    jmp     .ret
.notfound:
    mov     rax, -1
.ret:
    pop     rbx
    ret

build_nonce:
    mov     rax, [rdi]
    mov     [rdx], rax
    mov     eax, [rdi+8]
    mov     [rdx+8], eax
    mov     rax, rsi
    bswap   rax
    xor     rax, [rdx+4]
    mov     [rdx+4], rax
    ret

el_keyiv:
    push    rbx
    push    r12
    push    r13
    push    r14
    mov     r12, rdi
    mov     r13, rsi
    mov     r14, rdx
    mov     rbx, rcx
    mov     rdi, r12
    lea     rsi, [l_key]
    mov     rdx, 3
    mov     rcx, r12
    mov     r8, 0
    mov     r9, r13
    mov     r10, 16
    call    hkdf_expand_label
    mov     rdi, r12
    lea     rsi, [l_iv]
    mov     rdx, 2
    mov     rcx, r12
    mov     r8, 0
    mov     r9, r14
    mov     r10, 12
    call    hkdf_expand_label
    mov     rdi, r13
    mov     rsi, rbx
    call    aes128_expand
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

open_record:
    push    r12
    push    r13
    push    r14
    push    r15
    mov     r12, rdi
    mov     r13, rsi
    mov     r15, rdx
    mov     r14, r9
    mov     rdi, rcx
    mov     rsi, r8
    lea     rdx, [op_nonce]
    call    build_nonce
    mov     [gctx+0], r15
    lea     rax, [op_nonce]
    mov     [gctx+8], rax
    mov     [gctx+16], r12
    mov     qword [gctx+24], 5
    lea     rax, [r12+5]
    mov     [gctx+32], rax
    mov     rax, r13
    sub     rax, 16
    mov     [gctx+40], rax
    mov     [gctx+48], r14
    lea     rax, [calctag]
    mov     [gctx+56], rax
    lea     rdi, [gctx]
    call    gcm_open
    lea     rdi, [r12+5]
    add     rdi, r13
    sub     rdi, 16
    lea     rsi, [calctag]
    xor     rcx, rcx
.cmp:
    mov     al, [rdi+rcx]
    cmp     al, [rsi+rcx]
    jne     .bad
    inc     rcx
    cmp     rcx, 16
    jb      .cmp
    mov     rax, r13
    sub     rax, 16
    jmp     .ret
.bad:
    mov     rax, -1
.ret:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    ret

seal_record:
    push    r12
    mov     [sr_fd], rdi
    mov     [sr_rk], rsi
    mov     [sr_iv], rdx
    mov     [sr_seq], rcx
    mov     [sr_ct], r8b
    mov     [sr_data], r9
    mov     [sr_len], r10
    lea     rdi, [sbuf_inner]
    mov     rsi, r9
    mov     rdx, r10
    call    memcpy
    lea     rdi, [sbuf_inner]
    add     rdi, [sr_len]
    mov     al, [sr_ct]
    mov     [rdi], al
    lea     rdi, [sbuf]
    mov     byte [rdi], 0x17
    mov     byte [rdi+1], 0x03
    mov     byte [rdi+2], 0x03
    mov     rax, [sr_len]
    add     rax, 17
    mov     rcx, rax
    shr     rcx, 8
    mov     [rdi+3], cl
    mov     [rdi+4], al
    mov     rdi, [sr_iv]
    mov     rsi, [sr_seq]
    lea     rdx, [sr_nonce]
    call    build_nonce
    mov     rax, [sr_rk]
    mov     [gctx+0], rax
    lea     rax, [sr_nonce]
    mov     [gctx+8], rax
    lea     rax, [sbuf]
    mov     [gctx+16], rax
    mov     qword [gctx+24], 5
    lea     rax, [sbuf_inner]
    mov     [gctx+32], rax
    mov     rax, [sr_len]
    add     rax, 1
    mov     [gctx+40], rax
    lea     rax, [sbuf+5]
    mov     [gctx+48], rax
    lea     rax, [sbuf+5]
    add     rax, [sr_len]
    add     rax, 1
    mov     [gctx+56], rax
    lea     rdi, [gctx]
    call    gcm_seal
    mov     rdi, [sr_fd]
    lea     rsi, [sbuf]
    mov     rdx, [sr_len]
    add     rdx, 22
    call    write_all
    pop     r12
    ret

tls_handshake:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    mov     [tls_fd], rdi
    call    rb_init
    call    transcript_reset
    call    gen_keypair
    lea     rdi, [ch_buf]
    call    build_client_hello
    mov     r13, rax
    mov     rdi, [tls_fd]
    lea     rsi, [ch_buf]
    mov     rdx, r13
    call    write_all
    lea     rdi, [ch_buf+5]
    mov     rsi, r13
    sub     rsi, 5
    call    transcript_append

    lea     rdi, [rec]
    call    read_record
    test    rax, rax
    js      .err
    movzx   eax, byte [rec]
    cmp     eax, 0x16
    jne     .err
    movzx   r13d, byte [rec+3]
    shl     r13d, 8
    movzx   eax, byte [rec+4]
    or      r13d, eax
    lea     rdi, [rec+5]
    mov     rsi, r13
    call    transcript_append
    lea     rdi, [rec+5]
    mov     rsi, r13
    call    parse_serverhello
    test    rax, rax
    js      .err

    lea     rdi, [shared]
    lea     rsi, [ch_priv]
    lea     rdx, [sh_server_pub]
    call    x25519_scalarmult
    lea     rdi, [th_chsh]
    call    transcript_hash

    lea     rdi, [zeros32]
    mov     rsi, 32
    lea     rdx, [zeros32]
    mov     rcx, 32
    lea     r8, [early]
    call    hkdf_extract
    xor     rdi, rdi
    xor     rsi, rsi
    lea     rdx, [ehash]
    call    sha256
    lea     rdi, [early]
    lea     rsi, [l_derived]
    mov     rdx, 7
    lea     rcx, [ehash]
    lea     r8, [derived]
    call    derive_secret
    lea     rdi, [derived]
    mov     rsi, 32
    lea     rdx, [shared]
    mov     rcx, 32
    lea     r8, [hs_secret]
    call    hkdf_extract
    lea     rdi, [hs_secret]
    lea     rsi, [l_shs]
    mov     rdx, 12
    lea     rcx, [th_chsh]
    lea     r8, [s_hs]
    call    derive_secret
    lea     rdi, [hs_secret]
    lea     rsi, [l_chs]
    mov     rdx, 12
    lea     rcx, [th_chsh]
    lea     r8, [c_hs]
    call    derive_secret
    lea     rdi, [s_hs]
    lea     rsi, [s_hs_key]
    lea     rdx, [s_hs_iv]
    lea     rcx, [s_hs_rk]
    call    el_keyiv
    lea     rdi, [c_hs]
    lea     rsi, [c_hs_key]
    lea     rdx, [c_hs_iv]
    lea     rcx, [c_hs_rk]
    call    el_keyiv

    mov     rax, [transcript_len]
    mov     [parse_pos], rax
    mov     qword [got_fin], 0
    mov     qword [srv_hs_seq], 0
.flight:
    lea     rdi, [rec]
    call    read_record
    test    rax, rax
    js      .err
    movzx   eax, byte [rec]
    cmp     eax, 0x14
    je      .flight
    cmp     eax, 0x17
    jne     .err
    movzx   r13d, byte [rec+3]
    shl     r13d, 8
    movzx   eax, byte [rec+4]
    or      r13d, eax
    lea     rdi, [rec]
    mov     rsi, r13
    lea     rdx, [s_hs_rk]
    lea     rcx, [s_hs_iv]
    mov     r8, [srv_hs_seq]
    lea     r9, [ptbuf]
    call    open_record
    test    rax, rax
    js      .err
    mov     r14, rax
    inc     qword [srv_hs_seq]
.strip:
    test    r14, r14
    jz      .flight
    dec     r14
    lea     rbx, [ptbuf]
    movzx   edx, byte [rbx+r14]
    test    edx, edx
    jz      .strip
    cmp     edx, 0x16
    jne     .flight
    lea     rdi, [ptbuf]
    mov     rsi, r14
    call    transcript_append
.scan:
    mov     rax, [parse_pos]
    mov     rcx, [transcript_len]
    lea     rdx, [rax+4]
    cmp     rdx, rcx
    ja      .scandone
    lea     rbx, [transcript_buf]
    add     rbx, rax
    movzx   edx, byte [rbx+1]
    shl     edx, 16
    movzx   esi, byte [rbx+2]
    shl     esi, 8
    or      edx, esi
    movzx   esi, byte [rbx+3]
    or      edx, esi
    lea     rsi, [rax+4]
    add     rsi, rdx
    cmp     rsi, rcx
    ja      .scandone
    movzx   edx, byte [rbx]
    mov     [parse_pos], rsi
    cmp     edx, 0x14
    je      .gotfin
    jmp     .scan
.gotfin:
    mov     qword [got_fin], 1
.scandone:
    cmp     qword [got_fin], 0
    je      .flight

    lea     rdi, [th_sfin]
    call    transcript_hash

    lea     rdi, [c_hs]
    lea     rsi, [l_finished]
    mov     rdx, 8
    lea     rcx, [c_hs]
    mov     r8, 0
    lea     r9, [c_fin_key]
    mov     r10, 32
    call    hkdf_expand_label
    lea     rdi, [c_fin_key]
    mov     rsi, 32
    lea     rdx, [th_sfin]
    mov     rcx, 32
    lea     r8, [fin_verify]
    call    hmac_sha256
    lea     rdi, [fin_msg]
    mov     byte [rdi], 0x14
    mov     byte [rdi+1], 0
    mov     byte [rdi+2], 0
    mov     byte [rdi+3], 32
    lea     rdi, [fin_msg+4]
    lea     rsi, [fin_verify]
    mov     rdx, 32
    call    memcpy

    mov     rdi, [tls_fd]
    lea     rsi, [ccs_rec]
    mov     rdx, 6
    call    write_all
    mov     rdi, [tls_fd]
    lea     rsi, [c_hs_rk]
    lea     rdx, [c_hs_iv]
    mov     rcx, 0
    mov     r8, 0x16
    lea     r9, [fin_msg]
    mov     r10, 36
    call    seal_record

    lea     rdi, [hs_secret]
    lea     rsi, [l_derived]
    mov     rdx, 7
    lea     rcx, [ehash]
    lea     r8, [derived]
    call    derive_secret
    lea     rdi, [derived]
    mov     rsi, 32
    lea     rdx, [zeros32]
    mov     rcx, 32
    lea     r8, [master]
    call    hkdf_extract
    lea     rdi, [master]
    lea     rsi, [l_cap]
    mov     rdx, 12
    lea     rcx, [th_sfin]
    lea     r8, [c_ap]
    call    derive_secret
    lea     rdi, [master]
    lea     rsi, [l_sap]
    mov     rdx, 12
    lea     rcx, [th_sfin]
    lea     r8, [s_ap]
    call    derive_secret
    lea     rdi, [c_ap]
    lea     rsi, [c_ap_key]
    lea     rdx, [c_ap_iv]
    lea     rcx, [c_ap_rk]
    call    el_keyiv
    lea     rdi, [s_ap]
    lea     rsi, [s_ap_key]
    lea     rdx, [s_ap_iv]
    lea     rcx, [s_ap_rk]
    call    el_keyiv

    mov     qword [cli_app_seq], 0
    mov     qword [srv_app_seq], 0
    xor     eax, eax
    jmp     .done
.err:
    mov     rax, -1
.done:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

tls_send_app:
    push    r12
    push    r13
    push    r14
    mov     r12, rdi
    mov     r13, rsi
.frag:
    test    r13, r13
    jz      .done
    mov     r14, r13
    cmp     r14, 16000
    jbe     .chunk
    mov     r14, 16000
.chunk:
    mov     rdi, [tls_fd]
    lea     rsi, [c_ap_rk]
    lea     rdx, [c_ap_iv]
    mov     rcx, [cli_app_seq]
    mov     r8, 0x17
    mov     r9, r12
    mov     r10, r14
    call    seal_record
    inc     qword [cli_app_seq]
    add     r12, r14
    sub     r13, r14
    jmp     .frag
.done:
    pop     r14
    pop     r13
    pop     r12
    ret

tls_recv_app:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    mov     r14, rdi
    mov     r15, rsi
.next:
    lea     rdi, [rec]
    call    read_record
    test    rax, rax
    js      .eof
    movzx   eax, byte [rec]
    cmp     eax, 0x14
    je      .next
    cmp     eax, 0x17
    jne     .eof
    movzx   r13d, byte [rec+3]
    shl     r13d, 8
    movzx   eax, byte [rec+4]
    or      r13d, eax
    lea     rdi, [rec]
    mov     rsi, r13
    lea     rdx, [s_ap_rk]
    lea     rcx, [s_ap_iv]
    mov     r8, [srv_app_seq]
    lea     r9, [ptbuf]
    call    open_record
    test    rax, rax
    js      .err
    inc     qword [srv_app_seq]
    mov     rbx, rax
.strip:
    test    rbx, rbx
    jz      .next
    dec     rbx
    lea     rdi, [ptbuf]
    movzx   edx, byte [rdi+rbx]
    test    edx, edx
    jz      .strip
    cmp     edx, 0x17
    jne     .skipct
    mov     rax, rbx
    cmp     rax, r15
    jbe     .cap
    mov     rax, r15
.cap:
    mov     rdi, r14
    lea     rsi, [ptbuf]
    mov     rdx, rax
    push    rax
    call    memcpy
    pop     rax
    jmp     .ret
.skipct:
    cmp     edx, 0x16
    je      .next
    jmp     .eof
.eof:
    xor     rax, rax
    jmp     .ret
.err:
    mov     rax, -1
.ret:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret
