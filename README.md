# `rf`: A CLI tool to encrypt and decrypt data using [Rail Fence Cipher](https://en.wikipedia.org/wiki/Rail_fence_cipher).

### build

To build the `rf` executable, you will need [`Zig (version 0.13.0)`](https://ziglang.org/learn/getting-started/#installing-zig). To compile for release:
``` console
$ zig build -Doptimize=ReleaseFast
```

The executable will be compiled as `./zig-out/bin/rf`.

### examples

Encrypt a file in-place using 3 rails:
``` console
$ rf -r3 /path/to/secret_file_to_encrypt
```

To decrypt the file, run the same command, appending "-d" to the arguments.

Encrypt to a file from console input using 3 rails:
``` console
$ rf -r3 - > /path/to/new_file
three
$ cat /path/to/new_file
teher
```

After inputting data, press `Ctrl+d` twice instead of hitting enter.

