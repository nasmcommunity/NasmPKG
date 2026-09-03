#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "http.h"
#include "json.h"
#include "sha256.h"
#include "fs.h"

#define NASMPKG_VERSION "1.0.0"

static void print_path(const char *p)
{
    wchar_t w[1024];
    int n = MultiByteToWideChar(CP_ACP, 0, p, -1, w, 1024);
    if (n <= 0)
    {
        fputs(p, stdout);
        return;
    }
    char u[2048];
    int m = WideCharToMultiByte(CP_UTF8, 0, w, -1, u, sizeof u, NULL, NULL);
    if (m <= 0)
    {
        fputs(p, stdout);
        return;
    }
    fputs(u, stdout);
}

static void usage(void)
{
    printf(
        "nasmpkg - package manager for assembly libraries (Windows)\n"
        "usage:\n"
        "  nasmpkg install <pkg>   install a library\n"
        "  nasmpkg install         install all from .\\nasmpkg.deps\n"
        "  nasmpkg remove  <pkg>   remove a library\n"
        "  nasmpkg list            list installed libraries\n"
        "  nasmpkg search  <q>     search the registry\n"
        "  nasmpkg update          update nasmpkg to the latest version\n"
        "  nasmpkg version         show version\n"
        "  nasmpkg help            show this help\n");
}

static int semver_cmp(const char *a, const char *b)
{
    int am = 0, an = 0, ap = 0, bm = 0, bn = 0, bp = 0;
    sscanf(a, "%d.%d.%d", &am, &an, &ap);
    sscanf(b, "%d.%d.%d", &bm, &bn, &bp);
    if (am != bm)
        return am < bm ? -1 : 1;
    if (an != bn)
        return an < bn ? -1 : 1;
    if (ap != bp)
        return ap < bp ? -1 : 1;
    return 0;
}

static void print_version(void)
{
    printf("nasmpkg %s (windows/amd64)\n", NASMPKG_VERSION);
    printf("  registry: https://registry.nasmpkg.ru\n");
    printf("  update:   nasmpkg update\n");
}

static int cmd_update(void)
{
    printf("nasmpkg %s - проверяю обновления на registry.nasmpkg.ru ...\n", NASMPKG_VERSION);

    char *body = NULL;
    size_t n;
    if (http_get("/nasmpkg/latest.json", &body, &n) != 0)
    {
        printf("не удалось получить информацию о версии с сервера\n");
        return 1;
    }

    char ver[64] = {0};
    char *vp = j_after_quote(j_find(body, "\"version\""));
    if (vp)
        j_str(vp, ver, sizeof ver);
    if (!ver[0])
    {
        printf("сервер не сообщил версию\n");
        free(body);
        return 1;
    }

    if (semver_cmp(ver, NASMPKG_VERSION) <= 0)
    {
        printf("у вас последняя версия (%s)\n", NASMPKG_VERSION);
        free(body);
        return 0;
    }

    printf("доступна версия %s (у вас %s)\n", ver, NASMPKG_VERSION);
    char url[512] = {0};
    char *up = j_after_quote(j_find(body, "\"win64\""));
    if (up)
        j_str(up, url, sizeof url);
    free(body);

    if (!url[0])
    {
        printf("скачайте новую версию с registry.nasmpkg.ru и переустановите\n");
        return 0;
    }

    printf("качаю %s ...\n", url);
    char *exe = NULL;
    size_t exlen;
    if (http_get(url, &exe, &exlen) != 0 || exlen == 0)
    {
        printf("ошибка загрузки новой версии\n");
        if (exe)
            free(exe);
        return 1;
    }

    char self[MAX_PATH], neu[MAX_PATH], old[MAX_PATH];
    GetModuleFileNameA(NULL, self, sizeof self);
    snprintf(neu, sizeof neu, "%s.new", self);
    snprintf(old, sizeof old, "%s.old", self);

    if (fs_write(neu, exe, exlen) != 0)
    {
        printf("не удалось записать обновление (запустите от администратора)\n");
        free(exe);
        return 1;
    }
    free(exe);

    DeleteFileA(old);
    if (!MoveFileExA(self, old, MOVEFILE_REPLACE_EXISTING))
    {
        printf("не удалось заменить файл (запустите 'nasmpkg update' от администратора)\n");
        DeleteFileA(neu);
        return 1;
    }
    if (!MoveFileExA(neu, self, MOVEFILE_REPLACE_EXISTING))
    {
        MoveFileExA(old, self, MOVEFILE_REPLACE_EXISTING);
        printf("ошибка замены файла\n");
        return 1;
    }
    MoveFileExA(old, NULL, MOVEFILE_DELAY_UNTIL_REBOOT);

    printf("обновлено до %s. Запустите nasmpkg снова.\n", ver);
    return 0;
}

static void neterr(void)
{
    printf("error: cannot reach registry.nasmpkg.ru (network/TLS failure)\n");
}

static int install_one(const char *name)
{
    char url[1024];
    char *index = NULL, *manifest = NULL, *file = NULL;
    size_t n;
    int rc = 1;

    printf("installing '%s'...\n", name);

    if (http_get("/index.json", &index, &n) != 0)
    {
        neterr();
        goto done;
    }

    char needle[256];
    snprintf(needle, sizeof needle, "\"%s\"", name);
    char *pkg = strstr(index, needle);
    if (!pkg)
    {
        printf("error: package not found in registry\n");
        goto done;
    }

    char ver[64];
    char *lp = j_after_quote(j_find(pkg, "\"latest\""));
    j_str(lp, ver, sizeof ver);
    if (!ver[0])
    {
        printf("error: package not found in registry\n");
        goto done;
    }
    printf("latest version: %s\n", ver);

    snprintf(url, sizeof url, "/pkg/%s/%s/nasmpkg.json", name, ver);
    if (http_get(url, &manifest, &n) != 0)
    {
        neterr();
        goto done;
    }
    printf("manifest (nasmpkg.json):\n%s\n", manifest);

    char entry[128] = {0};
    char *ep = j_after_quote(j_find(manifest, "\"entry\""));
    if (ep)
        j_str(ep, entry, sizeof entry);
    if (entry[0])
        printf("entry file: %s\n", entry);

    const char *home = fs_home();
    char libdir[1024];
    snprintf(libdir, sizeof libdir, "%s\\.nasmpkg\\lib\\%s", home, name);
    fs_mkdirs(libdir);

    char *fp = j_find(manifest, "\"files\"");
    char fname[256];
    size_t flen;
    while ((fp = j_arr_next(fp, fname, sizeof fname, &flen)) != NULL)
    {
        snprintf(url, sizeof url, "/pkg/%s/%s/%s", name, ver, fname);
        if (http_get(url, &file, &n) != 0)
        {
            neterr();
            goto done;
        }

        char hash[65];
        sha256_hex((const unsigned char *)file, n, hash);

        char *sp = j_find(manifest, "\"sha256\"");
        char fneedle[256];
        snprintf(fneedle, sizeof fneedle, "\"%s\"", fname);
        char *xp = sp ? strstr(sp, fneedle) : NULL;
        if (xp)
        {
            char exp[65];
            j_str(j_after_quote(xp + strlen(fneedle)), exp, sizeof exp);
            if (strcmp(exp, hash) != 0)
            {
                printf("error: sha256 MISMATCH for %s\n", fname);
                free(file);
                file = NULL;
                goto done;
            }
        }

        char dest[1024];
        snprintf(dest, sizeof dest, "%s\\%s", libdir, fname);
        if (fs_write(dest, file, n) != 0)
        {
            printf("error: cannot write %s\n", dest);
            free(file);
            file = NULL;
            goto done;
        }
        printf("  downloaded %s (sha256 ok)\n", fname);
        free(file);
        file = NULL;
    }

    printf("installed to: ");
    print_path(libdir);
    printf("\n");
    printf("use: %%include \"%s/%s\"\n", name, entry);
    rc = 0;

done:
    if (index)
        free(index);
    if (manifest)
        free(manifest);
    if (file)
        free(file);
    return rc;
}

static int cmd_install(int argc, char **argv)
{
    if (argc >= 3)
    {
        if (install_one(argv[2]) != 0)
            return 1;
    }
    else
    {
        FILE *f = fopen("nasmpkg.deps", "rb");
        if (!f)
        {
            printf("error: no package given and no nasmpkg.deps in current dir\n");
            return 1;
        }
        printf("installing from nasmpkg.deps ...\n");
        char line[512];
        while (fgets(line, sizeof line, f))
        {
            char *s = line;
            unsigned char *u = (unsigned char *)s;
            if (u[0] == 0xEF && u[1] == 0xBB && u[2] == 0xBF)
                s += 3;
            while (*s == ' ' || *s == '\t')
                s++;
            if (*s == '#' || *s == '\n' || *s == '\r' || *s == 0)
                continue;
            char *e = s;
            while (*e && *e != ' ' && *e != '\t' && *e != '\n' && *e != '\r')
                e++;
            *e = 0;
            if (*s == 0)
                continue;
            if (install_one(s) != 0)
            {
                fclose(f);
                return 1;
            }
        }
        fclose(f);
    }

    const char *home = fs_home();
    char libroot[1024];
    snprintf(libroot, sizeof libroot, "%s\\.nasmpkg\\lib", home);
    fs_set_nasmenv(libroot);
    printf("NASMENV set for your user (open a NEW terminal to pick it up)\n");
    return 0;
}

static int cmd_remove(int argc, char **argv)
{
    if (argc < 3)
    {
        printf("error: this command needs an argument\n");
        return 1;
    }
    const char *name = argv[2];
    if (strchr(name, '/') || strchr(name, '\\'))
    {
        printf("error: invalid package name (no path separators)\n");
        return 1;
    }
    const char *home = fs_home();
    char dir[1024];
    snprintf(dir, sizeof dir, "%s\\.nasmpkg\\lib\\%s", home, name);
    if (fs_remove_pkg(dir) != 0)
    {
        printf("not installed: %s\n", name);
        return 1;
    }
    printf("removed %s\n", name);
    return 0;
}

static int cmd_list(void)
{
    const char *home = fs_home();
    char dir[1024];
    snprintf(dir, sizeof dir, "%s\\.nasmpkg\\lib", home);
    printf("installed libraries:\n");
    int c = fs_list_libs(dir);
    if (c <= 0)
        printf("  (none)\n");
    return 0;
}

static int cmd_search(int argc, char **argv)
{
    if (argc < 3)
    {
        printf("error: this command needs an argument\n");
        return 1;
    }
    const char *q = argv[2];
    printf("searching '%s':\n", q);

    char *index = NULL;
    size_t n;
    if (http_get("/index.json", &index, &n) != 0)
    {
        neterr();
        return 1;
    }

    char *p = j_find(index, "\"packages\"");
    char key[256];
    size_t kl;
    int found = 0;
    while ((p = j_obj_next_key(p, key, sizeof key, &kl)) != NULL)
    {
        if (strstr(key, q))
        {
            printf("  %s\n", key);
            found = 1;
        }
    }
    free(index);
    if (!found)
        printf("  no matching packages\n");
    return 0;
}

int main(int argc, char **argv)
{
    SetConsoleOutputCP(CP_UTF8);
    if (argc < 2)
    {
        usage();
        return 0;
    }
    if (strcmp(argv[1], "version") == 0 || strcmp(argv[1], "-v") == 0)
    {
        print_version();
        return 0;
    }
    if (strcmp(argv[1], "update") == 0)
        return cmd_update();
    if (strcmp(argv[1], "install") == 0)
        return cmd_install(argc, argv);
    if (strcmp(argv[1], "remove") == 0)
        return cmd_remove(argc, argv);
    if (strcmp(argv[1], "list") == 0)
        return cmd_list();
    if (strcmp(argv[1], "search") == 0)
        return cmd_search(argc, argv);
    if (strcmp(argv[1], "help") == 0)
    {
        usage();
        return 0;
    }
    usage();
    return 0;
}
