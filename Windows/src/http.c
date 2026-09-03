#include <windows.h>
#include <winhttp.h>
#include <stdlib.h>
#include "http.h"

#define REG_HOST L"registry.nasmpkg.ru"

static wchar_t *widen(const char *s)
{
    int n = MultiByteToWideChar(CP_UTF8, 0, s, -1, NULL, 0);
    if (n <= 0)
        return NULL;
    wchar_t *w = (wchar_t *)malloc((size_t)n * sizeof(wchar_t));
    if (!w)
        return NULL;
    MultiByteToWideChar(CP_UTF8, 0, s, -1, w, n);
    return w;
}

int http_get(const char *path, char **out, size_t *out_len)
{
    *out = NULL;
    *out_len = 0;

    int rc = -1;
    wchar_t *wpath = widen(path);
    HINTERNET hS = NULL, hC = NULL, hR = NULL;
    char *buf = NULL;

    if (!wpath)
        goto done;

    hS = WinHttpOpen(L"nasmpkg/1.0",
                     WINHTTP_ACCESS_TYPE_AUTOMATIC_PROXY,
                     WINHTTP_NO_PROXY_NAME, WINHTTP_NO_PROXY_BYPASS, 0);
    if (!hS)
        goto done;

    hC = WinHttpConnect(hS, REG_HOST, INTERNET_DEFAULT_HTTPS_PORT, 0);
    if (!hC)
        goto done;

    hR = WinHttpOpenRequest(hC, L"GET", wpath, NULL,
                            WINHTTP_NO_REFERER, WINHTTP_DEFAULT_ACCEPT_TYPES,
                            WINHTTP_FLAG_SECURE);
    if (!hR)
        goto done;

    if (!WinHttpSendRequest(hR, WINHTTP_NO_ADDITIONAL_HEADERS, 0,
                            WINHTTP_NO_REQUEST_DATA, 0, 0, 0))
        goto done;

    if (!WinHttpReceiveResponse(hR, NULL))
        goto done;

    DWORD status = 0, slen = sizeof(status);
    if (!WinHttpQueryHeaders(hR,
                             WINHTTP_QUERY_STATUS_CODE | WINHTTP_QUERY_FLAG_NUMBER,
                             WINHTTP_HEADER_NAME_BY_INDEX, &status, &slen,
                             WINHTTP_NO_HEADER_INDEX))
        goto done;
    if (status != 200)
        goto done;

    size_t cap = 65536, len = 0;
    buf = (char *)malloc(cap);
    if (!buf)
        goto done;

    for (;;)
    {
        DWORD avail = 0;
        if (!WinHttpQueryDataAvailable(hR, &avail))
            goto done;
        if (avail == 0)
            break;
        if (len + avail + 1 > cap)
        {
            while (len + avail + 1 > cap)
                cap *= 2;
            char *nb = (char *)realloc(buf, cap);
            if (!nb)
                goto done;
            buf = nb;
        }
        DWORD got = 0;
        if (!WinHttpReadData(hR, buf + len, avail, &got))
            goto done;
        if (got == 0)
            break;
        len += got;
    }

    buf[len] = 0;
    *out = buf;
    *out_len = len;
    buf = NULL;
    rc = 0;

done:
    if (buf)
        free(buf);
    if (hR)
        WinHttpCloseHandle(hR);
    if (hC)
        WinHttpCloseHandle(hC);
    if (hS)
        WinHttpCloseHandle(hS);
    if (wpath)
        free(wpath);
    return rc;
}
