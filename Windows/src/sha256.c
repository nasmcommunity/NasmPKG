#include <windows.h>
#include <bcrypt.h>
#include "sha256.h"

int sha256_hex(const unsigned char *data, size_t len, char out_hex[65])
{
    BCRYPT_ALG_HANDLE alg = NULL;
    BCRYPT_HASH_HANDLE h = NULL;
    unsigned char digest[32];
    int rc = -1;

    if (BCryptOpenAlgorithmProvider(&alg, BCRYPT_SHA256_ALGORITHM, NULL, 0) != 0)
        goto done;
    if (BCryptCreateHash(alg, &h, NULL, 0, NULL, 0, 0) != 0)
        goto done;
    if (BCryptHashData(h, (PUCHAR)data, (ULONG)len, 0) != 0)
        goto done;
    if (BCryptFinishHash(h, digest, sizeof(digest), 0) != 0)
        goto done;

    static const char hx[] = "0123456789abcdef";
    for (int i = 0; i < 32; i++)
    {
        out_hex[i * 2] = hx[digest[i] >> 4];
        out_hex[i * 2 + 1] = hx[digest[i] & 15];
    }
    out_hex[64] = 0;
    rc = 0;

done:
    if (h)
        BCryptDestroyHash(h);
    if (alg)
        BCryptCloseAlgorithmProvider(alg, 0);
    return rc;
}
