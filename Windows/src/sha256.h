#ifndef NASMPKG_SHA256_H
#define NASMPKG_SHA256_H

#include <stddef.h>

int sha256_hex(const unsigned char *data, size_t len, char out_hex[65]);

#endif
