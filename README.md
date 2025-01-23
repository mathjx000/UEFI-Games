# UEFI Games

Simple games re-implemented for [UEFI] using the [Zig] programming language,
playable directly during boot process.

Contains the following games:

- [Connect 4](https://en.wikipedia.org/wiki/Connect_Four) (WIP)

## Building

Requires [Zig] version `0.13.0`.

```sh
# To build all the games simply use
zig build

# To get more info on what is available
zig build --help
```

## Running

You can place the built `efi` files in the right place, or you can test using a
virtual machine.

### Linux, using QEMU

Example command to run:
(You need to be in the right directory, which should contains
`efi/boot/xxx.efi`)

```sh
qemu-system-x86_64 -bios /usr/share/edk2/ovmf/OVMF_CODE.fd -hdd fat:rw:.
```

## Acknowledgements

- [UEFI examples in Zig](https://github.com/nrdmn/uefi-examples)

[UEFI]: https://uefi.org/ "Unified Extensible Firmware Interface"
[Zig]: https://ziglang.org/
