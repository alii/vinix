#include <stddef.h>

void lib__kpanicc(char *message);

void qsort(void *ptr, size_t count, size_t size, int (*comp)(const void *, const void *)) {
    (void)ptr;
    (void)count;
    (void)size;
    (void)comp;
    lib__kpanicc("qsort is a stub");
}
