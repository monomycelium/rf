#include "rail_fence_cipher.h"

#include <stdlib.h>

uint8_t *encode(buf_t text, size_t k) {
    uint8_t *str;
    uint8_t *ptr;

    if (k == 0) return NULL;

    str = malloc(text.len + 1);
    if (str == NULL) return NULL;
    str[text.len] = '\0';
    ptr = str;

    if (k == 1) return memcpy(str, text.ptr, text.len);

    for (size_t i = 0; i < k; i++)
        if (i == 0 || i == k - 1)
            for (size_t j = i, inc = 2 * (k - 1); j < text.len; j += inc)
                *ptr++ = text.ptr[j];
        else
            for (size_t j = i, inc = 2 * (k - 1), prev_inc = 2 * i;
                 j < text.len; prev_inc = inc - prev_inc, j += prev_inc)
                *ptr++ = text.ptr[j];

    return str;
}

uint8_t *decode(buf_t ciphertext, size_t k);
