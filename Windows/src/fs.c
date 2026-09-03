#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "fs.h"

const char *fs_home(void)
{
    const char *h = getenv("USERPROFILE");
    if (h && *h)
        return h;
    static char buf[1024];
    const char *d = getenv("HOMEDRIVE");
    const char *p = getenv("HOMEPATH");
    if (d && p)
    {
        snprintf(buf, sizeof buf, "%s%s", d, p);
        return buf;
    }
    return ".";
}

int fs_mkdirs(const char *path)
{
    char tmp[1024];
    snprintf(tmp, sizeof tmp, "%s", path);
    size_t n = strlen(tmp);
    size_t start = (n >= 3 && tmp[1] == ':') ? 3 : 0;
    for (size_t i = start; i < n; i++)
    {
        if (tmp[i] == '\\' || tmp[i] == '/')
        {
            char c = tmp[i];
            tmp[i] = 0;
            CreateDirectoryA(tmp, NULL);
            tmp[i] = c;
        }
    }
    CreateDirectoryA(tmp, NULL);
    return 0;
}

int fs_write(const char *path, const void *data, size_t len)
{
    HANDLE h = CreateFileA(path, GENERIC_WRITE, 0, NULL,
                           CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (h == INVALID_HANDLE_VALUE)
        return -1;
    DWORD wr = 0;
    BOOL ok = WriteFile(h, data, (DWORD)len, &wr, NULL);
    CloseHandle(h);
    return (ok && wr == len) ? 0 : -1;
}

int fs_list_libs(const char *dir)
{
    char pat[1024];
    snprintf(pat, sizeof pat, "%s\\*", dir);
    WIN32_FIND_DATAA fd;
    HANDLE h = FindFirstFileA(pat, &fd);
    if (h == INVALID_HANDLE_VALUE)
        return -1;
    int count = 0;
    do
    {
        if (fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
        {
            if (strcmp(fd.cFileName, ".") != 0 && strcmp(fd.cFileName, "..") != 0)
            {
                printf("  %s\n", fd.cFileName);
                count++;
            }
        }
    } while (FindNextFileA(h, &fd));
    FindClose(h);
    return count;
}

int fs_remove_pkg(const char *dir)
{
    char pat[1024];
    snprintf(pat, sizeof pat, "%s\\*", dir);
    WIN32_FIND_DATAA fd;
    HANDLE h = FindFirstFileA(pat, &fd);
    if (h == INVALID_HANDLE_VALUE)
        return -1;
    do
    {
        if (!(fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY))
        {
            char f[1024];
            snprintf(f, sizeof f, "%s\\%s", dir, fd.cFileName);
            DeleteFileA(f);
        }
    } while (FindNextFileA(h, &fd));
    FindClose(h);
    return RemoveDirectoryA(dir) ? 0 : -1;
}

int fs_set_nasmenv(const char *libroot)
{
    char shortp[1024];
    DWORD r = GetShortPathNameA(libroot, shortp, sizeof shortp);
    const char *use = (r > 0 && r < sizeof shortp) ? shortp : libroot;

    char value[1100];
    snprintf(value, sizeof value, "-I%s\\", use);

    HKEY k;
    if (RegOpenKeyExA(HKEY_CURRENT_USER, "Environment", 0,
                      KEY_READ | KEY_WRITE, &k) != ERROR_SUCCESS)
        return -1;

    char cur[2048];
    DWORD cl = sizeof cur, type = 0;
    if (RegQueryValueExA(k, "NASMENV", NULL, &type, (BYTE *)cur, &cl) == ERROR_SUCCESS)
    {
        if (strstr(cur, ".nasmpkg"))
        {
            RegCloseKey(k);
            SetEnvironmentVariableA("NASMENV", value);
            return 0;
        }
    }

    LONG rc = RegSetValueExA(k, "NASMENV", 0, REG_SZ,
                             (const BYTE *)value, (DWORD)strlen(value) + 1);
    RegCloseKey(k);
    if (rc != ERROR_SUCCESS)
        return -1;

    DWORD_PTR res;
    SendMessageTimeoutA(HWND_BROADCAST, WM_SETTINGCHANGE, 0,
                        (LPARAM)"Environment", SMTO_ABORTIFHUNG, 3000, &res);
    SetEnvironmentVariableA("NASMENV", value);
    return 0;
}
