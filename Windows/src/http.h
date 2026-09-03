#ifndef NASMPKG_HTTP_H
#define NASMPKG_HTTP_H

#include <stddef.h>

int http_get(const char *path, char **out, size_t *out_len);

#endif
