/**
 * Tool for viewing MessagePack files as text.
 * Copyright: © 2015 Economic Modeling Specialists, Intl.
 * Authors: Brian Schott
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt Boost, License 1.0)
 */

import std.stdio;
import std.exception;
import core.bitop : bswap;

private ushort bswap(ushort u)
{
	version (LittleEndian)
	{
		version (D_InlineAsm_X86_64)
		{
			asm
			{
				naked;
				mov AX, DI;
				xchg AL, AH;
				ret;
			}
		}
		else
		{
			union UshortBytes
			{
				ushort u;
				ubyte[2] b;
			}

			UshortBytes src;
			src.u = u;
			UshortBytes dest;
			dest.b[1] = src.b[0];
			dest.b[0] = src.b[1];
			return dest.u;
		}
	}
	else return u;
}

private ulong bswap(ulong u)
{
	version (LittleEndian)
	{
		version (D_InlineAsm_X86_64)
		{
			asm
			{
				naked;
				mov RAX, RDI;
				bswap RAX;
				ret;
			}
		}
		else
		{
			union UlongBytes
			{
				ulong u;
				ubyte[8] b;
			}

			UlongBytes src;
			src.u = u;
			UlongBytes dst;
			dst.b[0] = src.b[7];
			dst.b[1] = src.b[6];
			dst.b[2] = src.b[5];
			dst.b[3] = src.b[4];
			dst.b[4] = src.b[3];
			dst.b[5] = src.b[2];
			dst.b[6] = src.b[1];
			dst.b[7] = src.b[0];
			return dst.u;
		}
	}
	else return u;
}

private T read16(T)(ref size_t index, const ubyte[] bytes) if (T.sizeof == 2)
{
	T r = cast(T) bswap(*(cast(ushort*) (bytes.ptr + index)));
	index += 2;
	return r;
}

private T read32(T)(ref size_t index, const ubyte[] bytes) if (T.sizeof == 4)
{
	T r = cast(T) bswap(*(cast(uint*) (bytes.ptr + index)));
	index += 4;
	return r;
}

private T read64(T)(ref size_t index, const ubyte[] bytes) if (T.sizeof == 8)
{
	T r = cast(T) bswap(*(cast(ulong*) (bytes.ptr + index)));
	index += 8;
	return r;
}

void main(string[] args)
{
	// If true, assume that the bin formats actually represent UTF-8 strings.
	// This is useful for msgpack data that uses a version of the spec before v5
	//  (when a dedicated string type was added).
	bool assumeStrings = false;

	import std.getopt;
	args.getopt(
		"strings|s", { assumeStrings = true; }
	);

	File f;
	if (args.length >= 2)
		f = File(args[1]);
	else
		f = stdin;

	size_t index = 0;
	ubyte[] bytes = new ubyte[](f.size);
	f.rawRead(bytes);
	size_t[] itemCounts;

	while (index < bytes.length)
	{
		if (itemCounts.length)
		{
			foreach (_; 0 .. itemCounts.length)
				write("  ");
			if (itemCounts[$ - 1] > 0)
				itemCounts[$ - 1]--;

		}
		switch (bytes[index])
		{
		case 0x00: .. case 0x7f: // positive fixint  0xxxxxxx
			writeln("positive fixint: ", bytes[index]);
			index++;
			break;
		case 0x80: .. case 0x8f: // fixmap  1000xxxx
			int l = bytes[index] & 0b1111;
			itemCounts ~= l;
			writeln("fixmap: ", l, " items");
			index++;
			break;
		case 0x90: .. case 0x9f: // fixarray  1001xxxx
			int l = bytes[index] & 0b1111;
			itemCounts ~= l;
			writeln("fixarray: ", l, " items");
			index++;
			break;
		case 0xa0: .. case 0xbf: // fixstr  101xxxxx
			immutable size_t l = (cast(size_t) bytes[index]) & 0b11111;
			index++;
			writeln("fixstr: ", cast(string) bytes[index .. index + l]);
			index += l;
			break;
		case 0xc0: // nil  11000000
			writeln("nil");
			index++;
			break;
		case 0xc1: // (never used)  11000001
			writeln("Invalid msgpack byte");
			index++;
			break;
		case 0xc2: // false  11000010
			writeln("false");
			index++;
			break;
		case 0xc3: // true  11000011
			writeln("true");
			index++;
			break;
		case 0xc4: // bin 8  11000100
			index++;
			if (assumeStrings)
			{
				size_t l = bytes[index++];
				writeln("bin8: ", cast(char[])bytes[index .. index + l]);
				index += l;
			} else {
				index += bytes[index] + 1;
				writeln("bin8: not shown");
			}
			break;
		case 0xc5: // bin 16  11000101
			index++;
			if (assumeStrings)
			{
				size_t l = read16!(ushort)(index, bytes);
				writeln("bin16: ", cast(char[])bytes[index .. index + l]);
				index += l;
			} else {
				size_t l = read16!(ushort)(index, bytes);
				index += l;
				writeln("bin16: not shown");
			}
			break;
		case 0xc6: // bin 32  11000110
			index++;
			if (assumeStrings)
			{
				size_t l = read32!(uint)(index, bytes);
				writeln("bin32: ", cast(char[])bytes[index .. index + l]);
				index += l;
			} else {
				size_t l = read32!(uint)(index, bytes);
				index += l;
				writeln("bin32: not shown");
			}
			break;
		case 0xc7: // ext 8  11000111
			index++;
			index += bytes[index] + 2;
			writeln("ext8: not shown");
			break;
		case 0xc8: // ext 16  11001000
			index++;
			size_t l = read16!(ushort)(index, bytes);
			index += l + 1;
			writeln("ext16: not shown");
			break;
		case 0xc9: // ext 32  11001001
			index++;
			size_t l = read32!(uint)(index, bytes);
			index += l + 1;
			writeln("ext32: not shown");
			break;
		case 0xca: // float 32  11001010
			index++;
			writeln("float32: ", read32!float(index, bytes));
			break;
		case 0xcb: // float 64  11001011
			index++;
			writeln("float64: ", read64!double(index, bytes));
			break;
		case 0xcc: // uint 8  11001100
			writeln("uint8: ", bytes[index + 1]);
			index += 2;
			break;
		case 0xcd: // uint 16  11001101
			index++;
			writeln("uint16: ", read16!ushort(index, bytes));
			break;
		case 0xce: // uint 32  11001110
			index++;
			writeln("uint32: ", read32!uint(index, bytes));
			break;
		case 0xcf: // uint 64  11001111
			writeln("uint64: ", read64!ulong(index, bytes));
			break;
		case 0xd0: // int 8  11010000
			writeln("int8: ", cast(byte) bytes[index + 1]);
			index += 2;
			break;
		case 0xd1: // int 16  11010001
			index++;
			writeln("int16: ", read16!(short)(index, bytes));
			break;
		case 0xd2: // int 32  11010010
			index++;
			writeln("int32: ", read32!int(index, bytes));
			break;
		case 0xd3: // int 64  11010011
			index++;
			writeln("int64: ", read64!long(index, bytes));
			break;
		case 0xd4: // fixext 1  11010100
			index += 3;
			writeln("fixext1: not shown");
			break;
		case 0xd5: // fixext 2  11010101
			index += 4;
			writeln("fixext2: not shown");
			break;
		case 0xd6: // fixext 4  11010110
			index += 6;
			writeln("fixext4: not shown");
			break;
		case 0xd7: // fixext 8  11010111
			index += 20;
			writeln("fixext8: not shown");
			break;
		case 0xd8: // fixext 16  11011000
			index += 18;
			writeln("fixext16: not shown");
			break;
		case 0xd9: // str 8  11011001
			index++;
			size_t l = bytes[index];
			index++;
			writeln("str8: ", cast(char[]) bytes[index .. index + l]);
			index += l;
			break;
		case 0xda: // str 16  11011010
			index++;
			size_t l = read16!ushort(index, bytes);
			writeln("str16: ", cast(char[]) bytes[index .. index + l]);
			index += l;
			break;
		case 0xdb: // str 32  11011011
			index++;
			size_t l = read32!(uint)(index, bytes);
			writeln("str32: ", cast(char[]) bytes[index .. index + l]);
			index += l;
			break;
		case 0xdc: // array 16  11011100
			index++;
			size_t l = read16!ushort(index, bytes);
			itemCounts ~= l;
			writeln("array32: ", l, " items");
			index += l;
			break;
		case 0xdd: // array 32  11011101
			index++;
			size_t l = read32!uint(index, bytes);
			itemCounts ~= l;
			writeln("array32: ", l, " items");
			index += l;
			break;
		case 0xde: // map 16  11011110
			index++;
			size_t l = read16!ushort(index, bytes);
			itemCounts ~= l;
			writeln("map16: ", l, " items");
			index += l;
			break;
		case 0xdf: // map 32  11011111
			index++;
			size_t l = read32!uint(index, bytes);
			itemCounts ~= l;
			writeln("map32: ", l, " items");
			index += l;
			break;
		case 0xe0 - 0xff: // negative fixint  111xxxxx
			writeln("negative fixint: ", -(cast(byte) bytes[index]));
			index++;
			break;
		default:
			writeln("default");
			index++;
			break;
		}
		while (itemCounts.length && itemCounts[$ - 1] == 0)
			itemCounts = itemCounts[0 .. $ - 1];
	}
}
