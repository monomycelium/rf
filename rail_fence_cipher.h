#pragma once
#include <stddef.h>
#include <stdint.h>

typedef struct {
    size_t len;
    uint8_t *ptr;
} buf_t;

uint8_t *encode(buf_t text, size_t rails);
uint8_t *decode(buf_t ciphertext, size_t rails);
