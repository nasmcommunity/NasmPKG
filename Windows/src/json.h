#ifndef NASMPKG_JSON_H
#define NASMPKG_JSON_H

#include <stddef.h>

char  *j_find(char *p, const char *needle);
char  *j_after_quote(char *p);
size_t j_str(char *p, char *out, size_t max);
char  *j_arr_next(char *p, char *out, size_t max, size_t *len);
char  *j_obj_next_key(char *p, char *out, size_t max, size_t *len);

#endif
