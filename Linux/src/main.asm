%include "tls/tls.inc"
%include "json.asm"
%include "fs.asm"
%include "https.asm"

%define SYS_rename    82
%define SYS_readlink  89
%define SYS_chmod     90

section .rodata
usage:
    db "nasmpkg - package manager for assembly libraries", 10
    db "usage:", 10
    db "  nasmpkg install <pkg>   install a library", 10
    db "  nasmpkg install         install all from ./nasmpkg.deps", 10
    db "  nasmpkg remove  <pkg>   remove a library", 10
    db "  nasmpkg list            list installed libraries", 10
    db "  nasmpkg search  <q>     search the registry", 10
    db "  nasmpkg update          update nasmpkg to the latest version", 10
    db "  nasmpkg version         show version", 10
    db "  nasmpkg help            show this help", 10
usage_len equ $ - usage

c_install: db "install", 0
c_remove:  db "remove", 0
c_list:    db "list", 0
c_search:  db "search", 0
c_help:    db "help", 0
c_version: db "version", 0
c_ver:     db "-v", 0
c_update:  db "update", 0
m_version: db "nasmpkg 1.0.0", 10
m_version_len equ $ - m_version
path_latest: db "/nasmpkg/latest.json"
path_latest_len equ $ - path_latest
n_version:  db `"version"`
n_version_len equ $ - n_version
n_linux:    db `"linux"`
n_linux_len equ $ - n_linux
cli_ver:    db "1.0.0", 0
proc_self:  db "/proc/self/exe", 0
s_new:      db ".new"
s_new_len equ $ - s_new
m_upd_check: db "проверяю обновления на registry.nasmpkg.ru ...", 10
m_upd_check_len equ $ - m_upd_check
m_upd_latest: db "у вас последняя версия (1.0.0)", 10
m_upd_latest_len equ $ - m_upd_latest
m_upd_avail: db "доступна версия "
m_upd_avail_len equ $ - m_upd_avail
m_upd_get:  db "качаю обновление ...", 10
m_upd_get_len equ $ - m_upd_get
m_upd_done: db "обновлено. Запустите nasmpkg снова.", 10
m_upd_done_len equ $ - m_upd_done
m_upd_neterr: db "не удалось получить обновление с сервера", 10
m_upd_neterr_len equ $ - m_upd_neterr
m_upd_perm: db "не удалось заменить файл (запустите от root/sudo)", 10
m_upd_perm_len equ $ - m_upd_perm
m_upd_nourl: db "сервер не сообщил ссылку на linux-бинарь", 10
m_upd_nourl_len equ $ - m_upd_nourl

m_inst_a:  db "installing '"
m_inst_a_len equ $ - m_inst_a
m_inst_b:  db "'...", 10
m_inst_b_len equ $ - m_inst_b
path_index: db "/index.json"
path_index_len equ $ - path_index
m_neterr:  db "error: cannot reach registry.nasmpkg.ru (network/TLS failure)", 10
m_neterr_len equ $ - m_neterr
n_latest:  db `"latest"`
n_latest_len equ $ - n_latest
n_entry:   db `"entry"`
n_entry_len equ $ - n_entry
s_pkgpre:  db "/pkg/"
s_pkgpre_len equ $ - s_pkgpre
s_manifest: db "/nasmpkg.json"
s_manifest_len equ $ - s_manifest
s_slash:   db "/"
m_latest:  db "latest version: "
m_latest_len equ $ - m_latest
m_manifest: db "manifest (nasmpkg.json):", 10
m_manifest_len equ $ - m_manifest
m_entry:   db "entry file: "
m_entry_len equ $ - m_entry
m_notfound: db "error: package not found in registry", 10
m_notfound_len equ $ - m_notfound
n_files:   db `"files"`
n_files_len equ $ - n_files
s_naproot: db "/.nasmpkg"
s_naproot_len equ $ - s_naproot
s_lib:     db "/lib"
s_lib_len equ $ - s_lib
m_gotfile: db "  downloaded "
m_gotfile_len equ $ - m_gotfile
m_instto:  db "installed to: "
m_instto_len equ $ - m_instto
m_use1:    db `use: %include "`
m_use1_len equ $ - m_use1
m_use2:    db `"`
m_use2_len equ $ - m_use2
n_sha:     db `"sha256"`
n_sha_len equ $ - n_sha
m_verified: db " (sha256 ok)"
m_verified_len equ $ - m_verified
m_shafail: db "error: sha256 MISMATCH for "
m_shafail_len equ $ - m_shafail
m_nasmenv: db "NASMENV set in ~/.bashrc (restart shell or: source ~/.bashrc)", 10
m_nasmenv_len equ $ - m_nasmenv
s_depsfile: db "nasmpkg.deps", 0
m_fromdeps: db "installing from nasmpkg.deps ...", 10
m_fromdeps_len equ $ - m_fromdeps
m_nodeps:  db "error: no package given and no nasmpkg.deps in current dir", 10
m_nodeps_len equ $ - m_nodeps
nl:        db 10
m_needarg: db "error: this command needs an argument", 10
m_needarg_len equ $ - m_needarg
m_listhdr: db "installed libraries:", 10
m_listhdr_len equ $ - m_listhdr
m_none:    db "  (none)", 10
m_none_len equ $ - m_none
m_removed: db "removed "
m_removed_len equ $ - m_removed
m_notinst: db "not installed: "
m_notinst_len equ $ - m_notinst
m_badname: db "error: invalid package name (no '/')", 10
m_badname_len equ $ - m_badname
n_packages: db `"packages"`
n_packages_len equ $ - n_packages
m_srch_a:  db "searching '"
m_srch_a_len equ $ - m_srch_a
m_srch_b:  db "':", 10
m_srch_b_len equ $ - m_srch_b
m_srch_none: db "  no matching packages", 10
m_srch_none_len equ $ - m_srch_none

section .bss
alignb 8
saved_rsp: resq 1
body_buf: resb 65536
file_buf: resb 262144
pkglen:   resq 1
verlen:   resq 1
qlen:     resq 1
srv_ver:  resb 32
srv_len:  resq 1
url_buf:  resb 256
url_len:  resq 1
dl_len:   resq 1
self_path: resb 512
new_path: resb 512
deps_buf: resb 8192
ver_buf:  resb 32
entry_buf: resb 64
q_pkg:    resb 128
path_buf: resb 256
dir_buf:  resb 512
dest_buf: resb 512
fname_buf: resb 128
fnamelen: resq 1
file_len: resq 1
libdirlen: resq 1
entrylen: resq 1
hash_bin: resb 32
hash_hex: resb 64
exp_hex:  resb 64
q_fname:  resb 128

section .text
global _start

_start:
    mov     r12, rsp
    mov     [saved_rsp], rsp
    mov     rax, [r12]
    cmp     rax, 2
    jb      .usage
    mov     r13, [r12+16]

    mov     rdi, r13
    lea     rsi, [c_install]
    call    streq
    test    rax, rax
    jnz     .install
    mov     rdi, r13
    lea     rsi, [c_remove]
    call    streq
    test    rax, rax
    jnz     .remove
    mov     rdi, r13
    lea     rsi, [c_list]
    call    streq
    test    rax, rax
    jnz     .list
    mov     rdi, r13
    lea     rsi, [c_search]
    call    streq
    test    rax, rax
    jnz     .search
    mov     rdi, r13
    lea     rsi, [c_update]
    call    streq
    test    rax, rax
    jnz     .update
    mov     rdi, r13
    lea     rsi, [c_version]
    call    streq
    test    rax, rax
    jnz     .version
    mov     rdi, r13
    lea     rsi, [c_ver]
    call    streq
    test    rax, rax
    jnz     .version
    jmp     .usage

.version:
    lea     rsi, [m_version]
    mov     rdx, m_version_len
    call    puts
    jmp     .ok

.update:
    lea     rsi, [m_upd_check]
    mov     rdx, m_upd_check_len
    call    puts
    lea     rdi, [path_latest]
    mov     rsi, path_latest_len
    lea     rdx, [body_buf]
    mov     rcx, 65536
    call    https_get
    test    rax, rax
    js      .upd_neterr
    mov     r13, rax
    lea     rdi, [body_buf]
    mov     rsi, r13
    lea     rdx, [n_version]
    mov     rcx, n_version_len
    call    jfind
    test    rax, rax
    jz      .upd_neterr
    mov     rdi, rax
    call    after_quote
    mov     rdi, rax
    lea     rsi, [srv_ver]
    mov     rdx, 31
    call    jstr
    mov     [srv_len], rax
    lea     rcx, [srv_ver]
    add     rcx, rax
    mov     byte [rcx], 0
    lea     rdi, [srv_ver]
    call    parse_ver
    mov     r14, rax
    lea     rdi, [cli_ver]
    call    parse_ver
    cmp     r14, rax
    jbe     .upd_latest
    lea     rsi, [m_upd_avail]
    mov     rdx, m_upd_avail_len
    call    puts
    lea     rsi, [srv_ver]
    mov     rdx, [srv_len]
    call    puts
    lea     rsi, [nl]
    mov     rdx, 1
    call    puts
    lea     rdi, [body_buf]
    mov     rsi, r13
    lea     rdx, [n_linux]
    mov     rcx, n_linux_len
    call    jfind
    test    rax, rax
    jz      .upd_nourl
    mov     rdi, rax
    call    after_quote
    mov     rdi, rax
    lea     rsi, [url_buf]
    mov     rdx, 255
    call    jstr
    mov     [url_len], rax
    lea     rsi, [m_upd_get]
    mov     rdx, m_upd_get_len
    call    puts
    lea     rdi, [url_buf]
    mov     rsi, [url_len]
    lea     rdx, [file_buf]
    mov     rcx, 262144
    call    https_get
    test    rax, rax
    js      .upd_neterr
    mov     [dl_len], rax
    mov     eax, SYS_readlink
    lea     rdi, [proc_self]
    lea     rsi, [self_path]
    mov     rdx, 511
    syscall
    test    rax, rax
    js      .upd_perm
    lea     rcx, [self_path]
    add     rcx, rax
    mov     byte [rcx], 0
    mov     r15, rax
    lea     rdi, [new_path]
    lea     rsi, [self_path]
    mov     rdx, r15
    call    memcpy
    lea     rdi, [new_path]
    add     rdi, r15
    lea     rsi, [s_new]
    mov     rdx, s_new_len
    call    memcpy
    lea     rcx, [new_path]
    add     rcx, r15
    add     rcx, s_new_len
    mov     byte [rcx], 0
    lea     rdi, [new_path]
    lea     rsi, [file_buf]
    mov     rdx, [dl_len]
    call    write_file
    test    rax, rax
    js      .upd_perm
    mov     eax, SYS_chmod
    lea     rdi, [new_path]
    mov     esi, 493
    syscall
    mov     eax, SYS_rename
    lea     rdi, [new_path]
    lea     rsi, [self_path]
    syscall
    test    rax, rax
    js      .upd_perm
    lea     rsi, [m_upd_done]
    mov     rdx, m_upd_done_len
    call    puts
    jmp     .ok
.upd_latest:
    lea     rsi, [m_upd_latest]
    mov     rdx, m_upd_latest_len
    call    puts
    jmp     .ok
.upd_nourl:
    lea     rsi, [m_upd_nourl]
    mov     rdx, m_upd_nourl_len
    call    puts
    jmp     .ok
.upd_neterr:
    lea     rsi, [m_upd_neterr]
    mov     rdx, m_upd_neterr_len
    call    puts
    mov     eax, SYS_exit
    mov     edi, 1
    syscall
.upd_perm:
    lea     rsi, [m_upd_perm]
    mov     rdx, m_upd_perm_len
    call    puts
    mov     eax, SYS_exit
    mov     edi, 1
    syscall

.install:
    call    arg2
    test    rax, rax
    jz      .from_deps
    mov     r14, rax
    mov     rdi, r14
    call    strlen
    mov     rsi, rax
    mov     rdi, r14
    call    install_one
    test    rax, rax
    jnz     .install_fail
    jmp     .install_env
.from_deps:
    mov     eax, SYS_open
    lea     rdi, [s_depsfile]
    xor     esi, esi
    xor     edx, edx
    syscall
    test    rax, rax
    js      .nodeps
    mov     r12, rax
    mov     eax, SYS_read
    mov     edi, r12d
    lea     rsi, [deps_buf]
    mov     edx, 8191
    syscall
    mov     r13, rax
    mov     eax, SYS_close
    mov     edi, r12d
    syscall
    test    r13, r13
    jle     .nodeps
    lea     rsi, [m_fromdeps]
    mov     rdx, m_fromdeps_len
    call    puts
    xor     rbx, rbx
.dline:
    cmp     rbx, r13
    jae     .install_env
    mov     al, [deps_buf+rbx]
    cmp     al, 10
    je      .dadv
    cmp     al, 13
    je      .dadv
    cmp     al, ' '
    je      .dadv
    cmp     al, 9
    je      .dadv
    cmp     al, '#'
    je      .dcomment
    mov     r14, rbx
.dtok:
    cmp     rbx, r13
    jae     .dgo
    mov     al, [deps_buf+rbx]
    cmp     al, 10
    je      .dgo
    cmp     al, 13
    je      .dgo
    cmp     al, ' '
    je      .dgo
    cmp     al, 9
    je      .dgo
    inc     rbx
    jmp     .dtok
.dgo:
    lea     rdi, [deps_buf+r14]
    mov     rsi, rbx
    sub     rsi, r14
    call    install_one
    test    rax, rax
    jnz     .install_fail
.dgoeol:
    cmp     rbx, r13
    jae     .install_env
    mov     al, [deps_buf+rbx]
    inc     rbx
    cmp     al, 10
    jne     .dgoeol
    jmp     .dline
.dcomment:
    inc     rbx
    cmp     rbx, r13
    jae     .install_env
    mov     al, [deps_buf+rbx]
    cmp     al, 10
    jne     .dcomment
    jmp     .dline
.dadv:
    inc     rbx
    jmp     .dline
.install_env:
    call    ensure_nasmenv
    lea     rsi, [m_nasmenv]
    mov     rdx, m_nasmenv_len
    call    puts
    jmp     .ok
.nodeps:
    lea     rsi, [m_nodeps]
    mov     rdx, m_nodeps_len
    call    puts
    mov     eax, SYS_exit
    mov     edi, 1
    syscall
.install_fail:
    mov     eax, SYS_exit
    mov     edi, 1
    syscall

.remove:
    call    arg2
    test    rax, rax
    jz      .needarg
    mov     r14, rax
    mov     rdi, r14
.rchk:
    mov     al, [rdi]
    test    al, al
    jz      .rok
    cmp     al, '/'
    je      .badname
    inc     rdi
    jmp     .rchk
.rok:
    call    get_home
    mov     r12, rax
    mov     rdi, r12
    call    strlen
    mov     rbx, rax
    lea     rdi, [dir_buf]
    mov     rsi, r12
    mov     rdx, rbx
    call    memcpy
    lea     rdi, [dir_buf]
    add     rdi, rbx
    lea     rsi, [s_naproot]
    mov     rdx, s_naproot_len
    call    memcpy
    add     rbx, s_naproot_len
    lea     rdi, [dir_buf]
    add     rdi, rbx
    lea     rsi, [s_lib]
    mov     rdx, s_lib_len
    call    memcpy
    add     rbx, s_lib_len
    lea     rcx, [dir_buf]
    add     rcx, rbx
    mov     byte [rcx], '/'
    inc     rbx
    mov     rdi, r14
    call    strlen
    mov     r13, rax
    lea     rdi, [dir_buf]
    add     rdi, rbx
    mov     rsi, r14
    mov     rdx, r13
    call    memcpy
    add     rbx, r13
    lea     rcx, [dir_buf]
    add     rcx, rbx
    mov     byte [rcx], 0
    lea     rdi, [dir_buf]
    call    remove_pkg
    test    rax, rax
    js      .rnotinst
    lea     rsi, [m_removed]
    mov     rdx, m_removed_len
    call    puts
    mov     rsi, r14
    mov     rdx, r13
    call    puts
    lea     rsi, [nl]
    mov     rdx, 1
    call    puts
    jmp     .ok
.rnotinst:
    lea     rsi, [m_notinst]
    mov     rdx, m_notinst_len
    call    puts
    mov     rsi, r14
    mov     rdx, r13
    call    puts
    lea     rsi, [nl]
    mov     rdx, 1
    call    puts
    mov     eax, SYS_exit
    mov     edi, 1
    syscall
.badname:
    lea     rsi, [m_badname]
    mov     rdx, m_badname_len
    call    puts
    mov     eax, SYS_exit
    mov     edi, 1
    syscall

.search:
    call    arg2
    test    rax, rax
    jz      .needarg
    mov     r14, rax
    mov     rdi, r14
    call    strlen
    mov     [qlen], rax
    lea     rsi, [m_srch_a]
    mov     rdx, m_srch_a_len
    call    puts
    mov     rsi, r14
    mov     rdx, [qlen]
    call    puts
    lea     rsi, [m_srch_b]
    mov     rdx, m_srch_b_len
    call    puts
    lea     rdi, [path_index]
    mov     rsi, path_index_len
    lea     rdx, [body_buf]
    mov     rcx, 65536
    call    https_get
    test    rax, rax
    js      .srch_err
    mov     r13, rax
    lea     rdi, [body_buf]
    mov     rsi, r13
    lea     rdx, [n_packages]
    mov     rcx, n_packages_len
    call    jfind
    test    rax, rax
    jz      .srchnone
    mov     r15, rax
    xor     r12, r12
.sloop:
    mov     rdi, r15
    lea     rsi, [fname_buf]
    mov     rdx, 127
    call    obj_next_key
    test    rax, rax
    jz      .srchdone
    mov     r15, rax
    mov     [fnamelen], rdx
    lea     rdi, [fname_buf]
    mov     rsi, [fnamelen]
    mov     rdx, r14
    mov     rcx, [qlen]
    call    memfind
    test    rax, rax
    jz      .sloop
    inc     r12
    lea     rsi, [s_bullet]
    mov     rdx, 2
    call    puts
    lea     rsi, [fname_buf]
    mov     rdx, [fnamelen]
    call    puts
    lea     rsi, [nl]
    mov     rdx, 1
    call    puts
    jmp     .sloop
.srchdone:
    test    r12, r12
    jnz     .ok
.srchnone:
    lea     rsi, [m_srch_none]
    mov     rdx, m_srch_none_len
    call    puts
    jmp     .ok
.srch_err:
    lea     rsi, [m_neterr]
    mov     rdx, m_neterr_len
    call    puts
    mov     eax, SYS_exit
    mov     edi, 1
    syscall

.list:
    call    get_home
    mov     r12, rax
    mov     rdi, r12
    call    strlen
    mov     rbx, rax
    lea     rdi, [dir_buf]
    mov     rsi, r12
    mov     rdx, rbx
    call    memcpy
    lea     rdi, [dir_buf]
    add     rdi, rbx
    lea     rsi, [s_naproot]
    mov     rdx, s_naproot_len
    call    memcpy
    add     rbx, s_naproot_len
    lea     rdi, [dir_buf]
    add     rdi, rbx
    lea     rsi, [s_lib]
    mov     rdx, s_lib_len
    call    memcpy
    add     rbx, s_lib_len
    lea     rcx, [dir_buf]
    add     rcx, rbx
    mov     byte [rcx], 0
    lea     rsi, [m_listhdr]
    mov     rdx, m_listhdr_len
    call    puts
    lea     rdi, [dir_buf]
    call    print_libs
    test    rax, rax
    jnz     .ok
    lea     rsi, [m_none]
    mov     rdx, m_none_len
    call    puts
    jmp     .ok

.needarg:
    lea     rsi, [m_needarg]
    mov     rdx, m_needarg_len
    call    puts
    mov     eax, SYS_exit
    mov     edi, 1
    syscall

.usage:
    lea     rsi, [usage]
    mov     rdx, usage_len
    call    puts
.ok:
    mov     eax, SYS_exit
    xor     edi, edi
    syscall

arg2:
    mov     rax, [r12]
    cmp     rax, 3
    jb      .none
    mov     rax, [r12+24]
    ret
.none:
    xor     rax, rax
    ret

streq:
.l:
    mov     al, [rdi]
    cmp     al, [rsi]
    jne     .no
    test    al, al
    jz      .yes
    inc     rdi
    inc     rsi
    jmp     .l
.yes:
    mov     rax, 1
    ret
.no:
    xor     rax, rax
    ret

strlen:
    xor     rax, rax
.l:
    cmp     byte [rdi+rax], 0
    je      .e
    inc     rax
    jmp     .l
.e:
    ret

install_one:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    mov     r14, rdi
    mov     [pkglen], rsi
    lea     rsi, [m_inst_a]
    mov     rdx, m_inst_a_len
    call    puts
    mov     rsi, r14
    mov     rdx, [pkglen]
    call    puts
    lea     rsi, [m_inst_b]
    mov     rdx, m_inst_b_len
    call    puts
    lea     rdi, [path_index]
    mov     rsi, path_index_len
    lea     rdx, [body_buf]
    mov     rcx, 65536
    call    https_get
    test    rax, rax
    js      .io_neterr
    mov     r13, rax
    mov     byte [q_pkg], 0x22
    lea     rdi, [q_pkg+1]
    mov     rsi, r14
    mov     rdx, [pkglen]
    call    memcpy
    lea     rdi, [q_pkg]
    add     rdi, [pkglen]
    mov     byte [rdi+1], 0x22
    lea     rdi, [body_buf]
    mov     rsi, r13
    lea     rdx, [q_pkg]
    mov     rcx, [pkglen]
    add     rcx, 2
    call    jfind
    test    rax, rax
    jz      .io_notfound
    mov     r12, rax
    lea     rcx, [body_buf]
    add     rcx, r13
    sub     rcx, r12
    mov     rdi, r12
    mov     rsi, rcx
    lea     rdx, [n_latest]
    mov     rcx, n_latest_len
    call    jfind
    test    rax, rax
    jz      .io_notfound
    mov     rdi, rax
    call    after_quote
    mov     rdi, rax
    lea     rsi, [ver_buf]
    mov     rdx, 31
    call    jstr
    mov     [verlen], rax
    lea     rsi, [m_latest]
    mov     rdx, m_latest_len
    call    puts
    lea     rsi, [ver_buf]
    mov     rdx, [verlen]
    call    puts
    lea     rsi, [nl]
    mov     rdx, 1
    call    puts
    lea     rbx, [path_buf]
    mov     rdi, rbx
    lea     rsi, [s_pkgpre]
    mov     rdx, s_pkgpre_len
    call    memcpy
    add     rbx, s_pkgpre_len
    mov     rdi, rbx
    mov     rsi, r14
    mov     rdx, [pkglen]
    call    memcpy
    add     rbx, [pkglen]
    mov     byte [rbx], '/'
    inc     rbx
    mov     rdi, rbx
    lea     rsi, [ver_buf]
    mov     rdx, [verlen]
    call    memcpy
    add     rbx, [verlen]
    mov     rdi, rbx
    lea     rsi, [s_manifest]
    mov     rdx, s_manifest_len
    call    memcpy
    add     rbx, s_manifest_len
    mov     rax, rbx
    lea     rcx, [path_buf]
    sub     rax, rcx
    lea     rdi, [path_buf]
    mov     rsi, rax
    lea     rdx, [body_buf]
    mov     rcx, 65536
    call    https_get
    test    rax, rax
    js      .io_neterr
    mov     r13, rax
    lea     rsi, [m_manifest]
    mov     rdx, m_manifest_len
    call    puts
    lea     rsi, [body_buf]
    mov     rdx, r13
    call    puts
    lea     rdi, [body_buf]
    mov     rsi, r13
    lea     rdx, [n_entry]
    mov     rcx, n_entry_len
    call    jfind
    test    rax, rax
    jz      .io_ok
    mov     rdi, rax
    call    after_quote
    mov     rdi, rax
    lea     rsi, [entry_buf]
    mov     rdx, 63
    call    jstr
    mov     [entrylen], rax
    lea     rsi, [nl]
    mov     rdx, 1
    call    puts
    lea     rsi, [m_entry]
    mov     rdx, m_entry_len
    call    puts
    lea     rsi, [entry_buf]
    mov     rdx, [entrylen]
    call    puts
    lea     rsi, [nl]
    mov     rdx, 1
    call    puts
    call    get_home
    mov     r12, rax
    mov     rdi, r12
    call    strlen
    mov     rbx, rax
    lea     rdi, [dir_buf]
    mov     rsi, r12
    mov     rdx, rbx
    call    memcpy
    lea     rdi, [dir_buf]
    add     rdi, rbx
    lea     rsi, [s_naproot]
    mov     rdx, s_naproot_len
    call    memcpy
    add     rbx, s_naproot_len
    lea     rcx, [dir_buf]
    add     rcx, rbx
    mov     byte [rcx], 0
    lea     rdi, [dir_buf]
    call    my_mkdir
    lea     rdi, [dir_buf]
    add     rdi, rbx
    lea     rsi, [s_lib]
    mov     rdx, s_lib_len
    call    memcpy
    add     rbx, s_lib_len
    lea     rcx, [dir_buf]
    add     rcx, rbx
    mov     byte [rcx], 0
    lea     rdi, [dir_buf]
    call    my_mkdir
    lea     rcx, [dir_buf]
    add     rcx, rbx
    mov     byte [rcx], '/'
    inc     rbx
    lea     rdi, [dir_buf]
    add     rdi, rbx
    mov     rsi, r14
    mov     rdx, [pkglen]
    call    memcpy
    add     rbx, [pkglen]
    lea     rcx, [dir_buf]
    add     rcx, rbx
    mov     byte [rcx], 0
    lea     rdi, [dir_buf]
    call    my_mkdir
    mov     [libdirlen], rbx
    lea     rdi, [body_buf]
    mov     rsi, r13
    lea     rdx, [n_files]
    mov     rcx, n_files_len
    call    jfind
    test    rax, rax
    jz      .io_ok
    mov     r15, rax
.floop:
    mov     rdi, r15
    lea     rsi, [fname_buf]
    mov     rdx, 127
    call    arr_next
    test    rax, rax
    jz      .io_instdone
    mov     r15, rax
    mov     [fnamelen], rdx
    lea     rbx, [path_buf]
    mov     rdi, rbx
    lea     rsi, [s_pkgpre]
    mov     rdx, s_pkgpre_len
    call    memcpy
    add     rbx, s_pkgpre_len
    mov     rdi, rbx
    mov     rsi, r14
    mov     rdx, [pkglen]
    call    memcpy
    add     rbx, [pkglen]
    mov     byte [rbx], '/'
    inc     rbx
    mov     rdi, rbx
    lea     rsi, [ver_buf]
    mov     rdx, [verlen]
    call    memcpy
    add     rbx, [verlen]
    mov     byte [rbx], '/'
    inc     rbx
    mov     rdi, rbx
    lea     rsi, [fname_buf]
    mov     rdx, [fnamelen]
    call    memcpy
    add     rbx, [fnamelen]
    mov     rax, rbx
    lea     rcx, [path_buf]
    sub     rax, rcx
    lea     rdi, [path_buf]
    mov     rsi, rax
    lea     rdx, [file_buf]
    mov     rcx, 262144
    call    https_get
    test    rax, rax
    js      .io_neterr
    mov     [file_len], rax
    lea     rdi, [file_buf]
    mov     rsi, [file_len]
    lea     rdx, [hash_bin]
    call    sha256
    lea     rdi, [hash_bin]
    mov     rsi, 32
    lea     rdx, [hash_hex]
    call    to_hex
    mov     byte [q_fname], 0x22
    lea     rdi, [q_fname+1]
    lea     rsi, [fname_buf]
    mov     rdx, [fnamelen]
    call    memcpy
    lea     rdi, [q_fname]
    add     rdi, [fnamelen]
    mov     byte [rdi+1], 0x22
    lea     rdi, [body_buf]
    mov     rsi, r13
    lea     rdx, [n_sha]
    mov     rcx, n_sha_len
    call    jfind
    test    rax, rax
    jz      .verified
    mov     rbx, rax
    lea     rcx, [body_buf]
    add     rcx, r13
    sub     rcx, rbx
    mov     rdi, rbx
    mov     rsi, rcx
    lea     rdx, [q_fname]
    mov     rcx, [fnamelen]
    add     rcx, 2
    call    jfind
    test    rax, rax
    jz      .verified
    mov     rdi, rax
    call    after_quote
    mov     rsi, rax
    lea     rdi, [exp_hex]
    mov     rdx, 64
    call    memcpy
    lea     rdi, [hash_hex]
    lea     rsi, [exp_hex]
    xor     rcx, rcx
.vcmp:
    mov     al, [rdi+rcx]
    cmp     al, [rsi+rcx]
    jne     .io_shafail
    inc     rcx
    cmp     rcx, 64
    jb      .vcmp
.verified:
    lea     rbx, [dest_buf]
    mov     rdi, rbx
    lea     rsi, [dir_buf]
    mov     rdx, [libdirlen]
    call    memcpy
    add     rbx, [libdirlen]
    mov     byte [rbx], '/'
    inc     rbx
    mov     rdi, rbx
    lea     rsi, [fname_buf]
    mov     rdx, [fnamelen]
    call    memcpy
    add     rbx, [fnamelen]
    mov     byte [rbx], 0
    lea     rdi, [dest_buf]
    lea     rsi, [file_buf]
    mov     rdx, [file_len]
    call    write_file
    lea     rsi, [m_gotfile]
    mov     rdx, m_gotfile_len
    call    puts
    lea     rsi, [fname_buf]
    mov     rdx, [fnamelen]
    call    puts
    lea     rsi, [m_verified]
    mov     rdx, m_verified_len
    call    puts
    lea     rsi, [nl]
    mov     rdx, 1
    call    puts
    jmp     .floop
.io_instdone:
    lea     rsi, [m_instto]
    mov     rdx, m_instto_len
    call    puts
    lea     rsi, [dir_buf]
    mov     rdx, [libdirlen]
    call    puts
    lea     rsi, [nl]
    mov     rdx, 1
    call    puts
    lea     rsi, [m_use1]
    mov     rdx, m_use1_len
    call    puts
    mov     rsi, r14
    mov     rdx, [pkglen]
    call    puts
    lea     rsi, [s_slash]
    mov     rdx, 1
    call    puts
    lea     rsi, [entry_buf]
    mov     rdx, [entrylen]
    call    puts
    lea     rsi, [m_use2]
    mov     rdx, m_use2_len
    call    puts
    lea     rsi, [nl]
    mov     rdx, 1
    call    puts
.io_ok:
    xor     rax, rax
    jmp     .io_ret
.io_neterr:
    lea     rsi, [m_neterr]
    mov     rdx, m_neterr_len
    call    puts
    mov     rax, 1
    jmp     .io_ret
.io_notfound:
    lea     rsi, [m_notfound]
    mov     rdx, m_notfound_len
    call    puts
    mov     rax, 1
    jmp     .io_ret
.io_shafail:
    lea     rsi, [m_shafail]
    mov     rdx, m_shafail_len
    call    puts
    lea     rsi, [fname_buf]
    mov     rdx, [fnamelen]
    call    puts
    lea     rsi, [nl]
    mov     rdx, 1
    call    puts
    mov     rax, 1
    jmp     .io_ret
.io_ret:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret
