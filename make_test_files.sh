#!/bin/bash

# Usage:
#     rdmd src/msgpackdump.d -s test.bin
#

# 0x000000: fixarray: 3 items                       ( 0x93 )
# 0x000001:   positive fixint: 11                            [0x0b]
# 0x000002:   positive fixint: 8                             [0x08]
# 0x000003:   fixarray: 5 items                     ( 0x95 )
# 0x000004:     uint8: 255                          ( 0xcc ) [0xff]
# 0x000006:     positive fixint: 0                           [0x00]
# 0x000007:     positive fixint: 7                           [0x07]
# 0x000008:     uint8: 170                          ( 0xcc ) [0xaa]
# 0x00000a:     positive fixint: 85                          [0x55]
# 0x00000b: false                                   ( 0xc2 )
# 0x00000c: true                                    ( 0xc3 )
# 0x00000d: nil                                     ( 0xc0 )
# 0x00000e: Invalid msgpack byte                    ( 0xc1 )
# 0x00000f: negative fixint: -17                             [0xef]
echo -n -e '\x93\x0b\x08\x95\xcc\xff\x00\x07\xcc\xaa\x55\xc2\xc3\xc0\xc1\xef' > test.msgpack

# generates tests for fix array, array16 and array32:
# 0x000000: fixarray: 1 items                       ( 0x91 )
# 0x000001:   array16: 1 items                      ( 0xdc ) [0x00 0x01]
# 0x000004:     array32: 1 items                    ( 0xdd ) [0x00 0x00 0x00 0x01]
# 0x000009:       positive fixint: 10                        [0x0a]
# 0x00000a: nil                                     ( 0xc0 )
echo -n -e '\x91\xdc\x00\x01\xdd\x00\x00\x00\x01\x0a\xc0' > test.array

# generates tests for fix map, map16 and map32
# 0x000000: fixmap: 1 items                         ( 0x81 )
# 0x000001:   positive fixint: 16                            [0x10]
# 0x000002:   map16: 1 items                        ( 0xde ) [0x00 0x01]
# 0x000005:     positive fixint: 32                          [0x20]
# 0x000006:     map32: 1 items                      ( 0xdf ) [0x00 0x00 0x00 0x01]
# 0x00000b:       positive fixint: 48                        [0x30]
# 0x00000c:       positive fixint: 10                        [0x0a]
# 0x00000d: nil                                     ( 0xc0 )
echo -n -e '\x81\x10\xde\x00\x01\x20\xdf\x00\x00\x00\x01\x30\x0a\xc0' > test.map

# generates tests for fixstr, str8, str16 and str32
# 0x000000: fixstr: 'ABC'                           ( 0xa3 ) [0x41 0x42 0x43]
# 0x000004: str8: 'DEF'                             ( 0xd9 ) [0x03 0x44 0x45 0x46]
# 0x000009: str16: 'GHI'                            ( 0xda ) [0x00 0x03 0x47 0x48 0x49]
# 0x00000f: str32: 'JKL'                            ( 0xdb ) [0x00 0x00 0x00 0x03 0x4a 0x4b 0x4c]
# 0x000017: nil                                     ( 0xc0 )
echo -n -e '\xa3\x41\x42\x43\xd9\x03\x44\x45\x46\xda\x00\x03\x47\x48\x49\xdb\x00\x00\x00\x03\x4a\x4b\x4c\xc0' > test.str

# generates tests for fixext1, fixext2, fixext4, fixext8
# 0x000000: fixext1: 1 + 1 items                    ( 0xd4 ) [0x01 0x0e]
# 0x000003: fixext2: 2 + 2 items                    ( 0xd5 ) [0x02 0x01 0x02]
# 0x000007: fixext4: 4 + 4 items                    ( 0xd6 ) [0x04 0x03 0x04 0x05 0x06]
# 0x00000d: fixext8: 8 + 8 items                    ( 0xd7 ) [0x08 0x07 0x08 0x09 0x0a 0x0b 0x0c 0x0d 0x0e]
# 0x000017: nil                                     ( 0xc0 )
echo -n -e '\xd4\x01\x0e\xd5\x02\x01\x02\xd6\x04\x03\x04\x05\x06\xd7\x08\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\xc0' > test.fixext

# generates tests for fixext16
# 0x000000: fixext16: 16 + 16 items                 ( 0xd8 ) [0x10 0x00 0x01 0x02 0x03 0x04 0x05 0x06 0x07 0x08 0x09 0x0a 0x0b 0x0c 0x0d 0x0e 0x0f]
# 0x000012: nil                                     ( 0xc0 )
echo -n -e '\xd8\x10\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\xc0' > test.fixext16

# generates tests for ext8, ext16, ext32
# 0x000000: ext8: 8 + 1 items                       ( 0xc7 ) [0x01 0x08 0x01]
# 0x000004: ext16: 16 + 1 items                     ( 0xc8 ) [0x00 0x01 0x10 0x02]
# 0x000009: ext32: 32 + 1 items                     ( 0xc9 ) [0x00 0x00 0x00 0x01 0x20 0x03]
# 0x000010: nil                                     ( 0xc0 )
echo -n -e '\xc7\x01\x08\x01\xc8\x00\x01\x10\x02\xc9\x00\x00\x00\x01\x20\x03\xc0' > test.ext

# generates tests for bin8
# 0x000000: bin8:                                   ( 0xc4 ) [0x00]
# 0x000002: bin8: A                                 ( 0xc4 ) [0x01 0x41]
# 0x000005: bin8: BC                                ( 0xc4 ) [0x02 0x42 0x43]
# 0x000009: bin8: DEF                               ( 0xc4 ) [0x03 0x44 0x45 0x46]
# 0x00000e: nil                                     ( 0xc0 )
echo -n -e '\xc4\x00\xc4\x01\x41\xc4\x02\x42\x43\xc4\x03\x44\x45\x46\xc0' > test.bin8

# generates tests for bin16, bin32
# 0x000000: bin16: A                                ( 0xc5 ) [0x00 0x01 0x41]
# 0x000004: bin32: B                                ( 0xc6 ) [0x00 0x00 0x00 0x01 0x42]
# 0x00000a: nil                                     ( 0xc0 )
echo -n -e '\xc5\x00\x01\x41\xc6\x00\x00\x00\x01\x42\xc0' > test.bin

# generates tests for float32, float64
# 0x000000: float32: 1.23457e+08                    ( 0xca ) [0x4c 0xeb 0x79 0xa3]
# 0x000005: float64: 1.23457e+08                    ( 0xcb ) [0x41 0x9d 0x6f 0x34 0x54 0x00 0x00 0x00]
# 0x00000e: nil                                     ( 0xc0 )
echo -n -e '\xca\x4c\xeb\x79\xa3\xcb\x41\x9d\x6f\x34\x54\x00\x00\x00\xc0' > test.float

# generates tests for uint8, uint16, uint32, uint64
# 0x000000: uint8: 255                              ( 0xcc ) [0xff]
# 0x000002: uint16: 257                             ( 0xcd ) [0x01 0x01]
# 0x000005: uint32: 16777216                        ( 0xce ) [0x01 0x00 0x00 0x00]
# 0x00000a: uint64: 72057594037927936               ( 0xcf ) [0x01 0x00 0x00 0x00 0x00 0x00 0x00 0x00]
# 0x000013: nil                                     ( 0xc0 )
echo -n -e '\xcc\xff\xcd\x01\x01\xce\x01\x00\x00\x00\xcf\x01\x00\x00\x00\x00\x00\x00\x00\xc0' > test.uint

# generates tests for int8, int16, int32, int64
# 0x000000: int8: 255                               ( 0xd0 ) [0xff]
# 0x000002: int16: 257                              ( 0xd1 ) [0x01 0x01]
# 0x000005: int32: 16777216                         ( 0xd2 ) [0x01 0x00 0x00 0x00]
# 0x00000a: int64: 72057594037927936                ( 0xd3 ) [0x01 0x00 0x00 0x00 0x00 0x00 0x00 0x00]
# 0x000013: nil                                     ( 0xc0 )
echo -n -e '\xd0\xff\xd1\x01\x01\xd2\x01\x00\x00\x00\xd3\x01\x00\x00\x00\x00\x00\x00\x00\xc0' > test.int