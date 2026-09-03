@echo off
clang -O2 -D_CRT_SECURE_NO_WARNINGS src\main.c src\http.c src\sha256.c src\json.c src\fs.c -o nasmpkg.exe -lwinhttp -lbcrypt -ladvapi32 -luser32
