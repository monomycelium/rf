#include "rail_fence_cipher.h"

#include <stdlib.h>
#include <string.h>

uint8_t *encode(buf_t text, size_t k) {
    if (k == 0 || text.ptr == NULL) return NULL;

    uint8_t *str, *ptr;
    str = ptr = malloc(text.len + 1);
    if (str == NULL) return NULL;
    str[text.len] = '\0';

    if (k == 1) return memcpy(str, text.ptr, text.len);
    const size_t inc = 2 * (k - 1);

    // would checking whether current rail is the extreme top or bottom rail
    // everytime make much difference?
    for (size_t i = 0; i < k; i++)
        if (i == 0 || i == k - 1)
            for (size_t j = i; j < text.len; j += inc) *ptr++ = text.ptr[j];
        else
            for (size_t j = i, prev_inc = 2 * i; j < text.len;
                 prev_inc = inc - prev_inc, j += prev_inc)
                *ptr++ = text.ptr[j];

    return str;
}

uint8_t *decode(buf_t text, size_t k) {
    if (k == 0 || text.ptr == NULL) return NULL;

    uint8_t *str = malloc(text.len + 1);
    if (str == NULL) return NULL;
    str[text.len] = '\0';

    if (k == 1) return memcpy(str, text.ptr, text.len);
    const size_t inc = 2 * (k - 1);

    for (size_t i = 0; i < k; i++)
        if (i == 0 || i == k - 1)
            for (size_t j = i; j < text.len; j += inc) str[j] = *text.ptr++;
        else
            for (size_t j = i, prev_inc = 2 * i; j < text.len;
                 prev_inc = inc - prev_inc, j += prev_inc)
                str[j] = *text.ptr++;

    return str;
}
