#include <string.h>
#include "json.h"

char *j_find(char *p, const char *needle)
{
    if (!p)
        return NULL;
    char *q = strstr(p, needle);
    return q ? q + strlen(needle) : NULL;
}

char *j_after_quote(char *p)
{
    if (!p)
        return NULL;
    char *q = strchr(p, '"');
    return q ? q + 1 : NULL;
}

size_t j_str(char *p, char *out, size_t max)
{
    size_t i = 0;
    if (!p)
    {
        if (max)
            out[0] = 0;
        return 0;
    }
    while (p[i] && p[i] != '"' && i + 1 < max)
    {
        out[i] = p[i];
        i++;
    }
    out[i] = 0;
    return i;
}

char *j_arr_next(char *p, char *out, size_t max, size_t *len)
{
    if (!p)
        return NULL;
    while (*p && *p != '"' && *p != ']')
        p++;
    if (*p != '"')
        return NULL;
    p++;
    size_t i = 0;
    while (p[i] && p[i] != '"' && i + 1 < max)
    {
        out[i] = p[i];
        i++;
    }
    out[i] = 0;
    if (len)
        *len = i;
    return p + i + 1;
}

char *j_obj_next_key(char *p, char *out, size_t max, size_t *len)
{
    if (!p)
        return NULL;
    while (*p && *p != '"' && *p != '}')
        p++;
    if (*p != '"')
        return NULL;
    p++;
    size_t i = 0;
    while (p[i] && p[i] != '"' && i + 1 < max)
    {
        out[i] = p[i];
        i++;
    }
    out[i] = 0;
    if (len)
        *len = i;
    p += i + 1;

    while (*p && *p != ':')
        p++;
    if (*p == ':')
        p++;
    while (*p == ' ' || *p == '\t' || *p == '\n' || *p == '\r')
        p++;

    if (*p == '{')
    {
        int depth = 0;
        while (*p)
        {
            if (*p == '{')
                depth++;
            else if (*p == '}')
            {
                depth--;
                if (depth == 0)
                {
                    p++;
                    break;
                }
            }
            p++;
        }
    }
    else
    {
        while (*p && *p != ',' && *p != '}')
            p++;
    }
    return p;
}
