# nasmpkg

Package manager for assembly libraries. `nasmpkg install <name>` fetches a library
from the registry and makes it available to your project through `%include`.

The CLI has two native implementations, one per platform:

- **`Windows/`** — written in C. Uses WinHTTP for HTTPS (system TLS) and BCrypt for
  SHA-256.
- **`Linux/`** — written in x86-64 NASM assembly. No libc, only syscalls, with a
  hand-written TLS 1.3 for the HTTPS transport.

Both talk to the same registry at `registry.nasmpkg.ru` and behave identically.

## Build

### Windows

Needs clang (MSVC toolchain).

```
cd Windows
build.bat
```

Produces `nasmpkg.exe`.

### Linux

Needs nasm and ld (x86-64, a CPU with AES-NI / PCLMULQDQ / RDSEED).

```
cd Linux
make
```

Produces `nasmpkg`.

## Usage

```
nasmpkg install <pkg>    install a library
nasmpkg install          install everything from ./nasmpkg.deps
nasmpkg update           update nasmpkg itself
nasmpkg list             list installed libraries
nasmpkg search <query>   search the registry
nasmpkg remove <pkg>     remove a library
nasmpkg version          print version
```

Installed libraries live in `~/.nasmpkg/lib` (Linux) or `%USERPROFILE%\.nasmpkg\lib`
(Windows); the install step points `NASMENV` there so `%include` finds them.
