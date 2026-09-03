#ifndef NASMPKG_FS_H
#define NASMPKG_FS_H

#include <stddef.h>

const char *fs_home(void);
int fs_mkdirs(const char *path);
int fs_write(const char *path, const void *data, size_t len);
int fs_list_libs(const char *dir);
int fs_remove_pkg(const char *dir);
int fs_set_nasmenv(const char *libroot);

#endif
