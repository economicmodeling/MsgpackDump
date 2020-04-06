/**
 * Tool for viewing MessagePack files as text.
 * Copyright: © 2015 Economic Modeling Specialists, Intl.
 * Authors: Brian Schott
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt Boost, License 1.0)
 */

import std.stdio;
import std.exception;
import core.bitop : bswap;

enum hasNoUnsignedSwap = __VERSION__ < 2088;

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

version(hasNoUnsignedSwap)
{
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
}

private T read(T)(size_t index, const ubyte[] bytes) if (T.sizeof == 1)
{
	return cast(T) bytes[index];
}

private T read(T)(size_t index, const ubyte[] bytes) if (T.sizeof == 2)
{
	auto buf = bswap(*(cast(ushort*) (bytes.ptr + index)));
	T r = *(cast(T*) &buf);
	return r;
}

private T read(T)(size_t index, const ubyte[] bytes) if (T.sizeof == 4)
{
	auto buf = bswap(*(cast(uint*) (bytes.ptr + index)));
	T r = *(cast(T*) &buf);
	return r;
}

private T read(T)(size_t index, const ubyte[] bytes) if (T.sizeof == 8)
{
	auto buf = bswap(*(cast(ulong*) (bytes.ptr + index)));
	T r = *(cast(T*) &buf);
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
	size_t left_padding;
	string indent = "  ";
	// Current line
	enum TextWidth = 4096;
	char[TextWidth] line;
	// Current pos in the current line
	size_t pos;

	void formattedPrintToLine(Char, Args...)(in Char[] fmt, Args args)
	{
		import core.exception : RangeError;

		import std.format : sformat;
		char[] formatted;
		try
		{
			formatted = sformat(line[pos..TextWidth], fmt, args);
		}
		catch(RangeError re)
		{
			import std.algorithm : copy;
			import std.format : format;
			// Buffer is insufficent to output,
			// allocate appropriate length line on the heap
			// but copy there only data chunk that is placeable
			// to the buffer
			formatted = cast(char[])format(fmt, args)[0..TextWidth - pos];
			copy(formatted, line[pos..TextWidth]);
		}
		pos += formatted.length;
		assert (pos < TextWidth);
	}

	/// prints msgpack format
	void printFormat(Char, Args...)(in Char[] fmt, Args args)
	{
		import std.range : repeat, join;
		import std.algorithm : min, max;

		formattedPrintToLine("0x%06x: ", index);

		foreach (_; 0 .. left_padding)
			formattedPrintToLine("  ");

		formattedPrintToLine(fmt, args);
		formattedPrintToLine(" ".repeat(max(0, 50 - cast(int)pos)).join);
		formattedPrintToLine("( 0x%02x )", bytes[index]);
		index++;
	}

	/// prints data in msgpack format
	void printData(Char, Args...)(in Char[] fmt, Args args)
	{
		import std.range : repeat, join;
		import std.algorithm : min, max;

		formattedPrintToLine("0x%06x: ", index);

		foreach (_; 0 .. left_padding)
			formattedPrintToLine("  ");

		formattedPrintToLine(fmt, args);

		formattedPrintToLine(" ".repeat(max(0, 50 - cast(int)pos)).join);
		formattedPrintToLine("         [%(0x%02x %)]", bytes[index..index+1]);
		index++;
	}

	void printFixStr(Char, Args...)(ubyte format, ubyte[] data, in Char[] fmt, Args args)
	{
		import std.range : repeat, join;
		import std.algorithm : min, max;

		formattedPrintToLine("0x%06x: ", index);

		foreach (_; 0 .. left_padding)
		{
			formattedPrintToLine("  ");
		}

		formattedPrintToLine(fmt, args);

		formattedPrintToLine(" ".repeat(max(0, 50 - cast(int)pos)).join);

		formattedPrintToLine("( 0x%02x ) ", format);
		formattedPrintToLine("[%(0x%02x %)]", data);
	}

	void printBinOrStr(T)(string format_name)
	{
		import std.range : repeat, join;
		import std.algorithm : min, max;

		formattedPrintToLine("0x%06x: ", index);

		foreach (_; 0 .. left_padding)
			formattedPrintToLine("  ");

		size_t l = read!T(index+1, bytes);
		auto data = bytes[index+1..index+l+1+T.sizeof];

		formattedPrintToLine(format_name ~ ": '%s'", assumeStrings ? cast(char[]) data[T.sizeof..$] : "not shown");
		formattedPrintToLine(" ".repeat(max(0, 50 - cast(int)pos)).join);
		formattedPrintToLine("( 0x%02x ) ", bytes[index]);
		formattedPrintToLine("[%(0x%02x %)]", data);

		index += l + 1 + T.sizeof;
	}

	void printScalar(T)(string format_name)
	{
		import std.range : repeat, join;
		import std.algorithm : min, max;

		formattedPrintToLine("0x%06x: ", index);

		foreach (_; 0 .. left_padding)
			formattedPrintToLine("  ");

		size_t l = 1 + T.sizeof;
		auto data = bytes[index+1..index+l];

		formattedPrintToLine(format_name ~ ": %s", read!T(0, data));
		formattedPrintToLine(" ".repeat(max(0, 50 - cast(int)pos)).join);
		formattedPrintToLine("( 0x%02x ) ", bytes[index]);
		formattedPrintToLine("[%(0x%02x %)]", data);

		index += l;
	}

	size_t printArrayAndMap(T)(string format_name)
	{
		import std.range : repeat, join;
		import std.algorithm : min, max;

		formattedPrintToLine("0x%06x: ", index);

		foreach (_; 0 .. left_padding)
			formattedPrintToLine("  ");

		size_t l = read!T(index+1, bytes);
		auto data = bytes[index+1..index+T.sizeof+1];

		formattedPrintToLine(format_name ~ ": %s items", l);
		formattedPrintToLine(" ".repeat(max(0, 50 - cast(int)pos)).join);
		formattedPrintToLine("( 0x%02x ) ", bytes[index]);
		formattedPrintToLine("[%(0x%02x %)]", data);

		index += T.sizeof + 1;
		itemCounts ~= l;

		return l;
	}

	size_t printExt(T)(string format_name)
	{
		import std.range : repeat, join;
		import std.algorithm : min, max;

		formattedPrintToLine("0x%06x: ", index);

		foreach (_; 0 .. left_padding)
			formattedPrintToLine("  ");

		size_t l = read!T(index+1, bytes);
		auto data = bytes[index+1..index+1+T.sizeof+1+l];

		const type = bytes[index+1+T.sizeof];
		formattedPrintToLine(format_name ~ ": %s + %s items", type, l);
		formattedPrintToLine(" ".repeat(max(0, 50 - cast(int)pos)).join);
		formattedPrintToLine("( 0x%02x ) ", bytes[index]);
		formattedPrintToLine("[%(0x%02x %)]", data);

		index += T.sizeof + 2 + l;

		return l;
	}

	size_t printFixExt(size_t l)(string format_name)
	{
		import std.range : repeat, join;
		import std.algorithm : min, max;

		formattedPrintToLine("0x%06x: ", index);

		foreach (_; 0 .. left_padding)
			formattedPrintToLine("  ");

		auto data = bytes[index+1..index+1+1+l];

		const type = bytes[index+1];
		formattedPrintToLine(format_name ~ ": %s + %s items", type, l);
		formattedPrintToLine(" ".repeat(max(0, 50 - cast(int)pos)).join);
		formattedPrintToLine("( 0x%02x ) ", bytes[index]);
		formattedPrintToLine("[%(0x%02x %)]", data);

		index += 2 + l;

		return l;
	}

	while (index < bytes.length)
	{
		left_padding = 0;
		if (itemCounts.length)
		{
			foreach (_; 0 .. itemCounts.length)
			{
				left_padding += 1;
			}
			if (itemCounts[$ - 1] > 0)
				itemCounts[$ - 1]--;

		}
		switch (bytes[index])
		{
		case 0x00: .. case 0x7f: // positive fixint  0xxxxxxx
			printData("positive fixint: %d", bytes[index]);
			break;
		case 0x80: .. case 0x8f: // fixmap  1000xxxx
			int l = bytes[index] & 0b1111;
			itemCounts ~= l*2;
			printFormat("fixmap: %d items", l);
			break;
		case 0x90: .. case 0x9f: // fixarray  1001xxxx
			int l = bytes[index] & 0b1111;
			itemCounts ~= l;
			printFormat("fixarray: %d items", l);
			break;
		case 0xa0: .. case 0xbf: // fixstr  101xxxxx
			immutable size_t l = (cast(size_t) bytes[index]) & 0b11111;
			printFixStr(bytes[index], bytes[index+1..index+l+1], "fixstr: '%s'", cast(char[])bytes[index+1 .. index+l+1]);
			index += l+1;
			break;
		case 0xc0: // nil  11000000
			printFormat("nil");
			break;
		case 0xc1: // (never used)  11000001
			printFormat("Invalid msgpack byte");
			break;
		case 0xc2: // false  11000010
			printFormat("false");
			break;
		case 0xc3: // true  11000011
			printFormat("true");
			break;
		case 0xc4: // bin 8  11000100
			printBinOrStr!ubyte("bin8");
			break;
		case 0xc5: // bin 16  11000101
			printBinOrStr!ushort("bin16");
			break;
		case 0xc6: // bin 32  11000110
			printBinOrStr!uint("bin32");
			break;
		case 0xc7: // ext 8  11000111
			printExt!ubyte("ext8");
			break;
		case 0xc8: // ext 16  11001000
			printExt!ushort("ext16");
			break;
		case 0xc9: // ext 32  11001001
			printExt!uint("ext32");
			break;
		case 0xca: // float 32  11001010
			printScalar!float("float32");
			break;
		case 0xcb: // float 64  11001011
			printScalar!double("float64");
			break;
		case 0xcc: // uint 8  11001100
			printScalar!ubyte("uint8");
			break;
		case 0xcd:
			printScalar!ushort("uint16");
			break;
		case 0xce: // uint 32  11001110
			printScalar!uint("uint32");
			break;
		case 0xcf: // uint 64  11001111
			printScalar!ulong("uint64");
			break;
		case 0xd0: // int 8  11010000
			printScalar!ubyte("int8");
			break;
		case 0xd1: // int 16  11010001
			printScalar!ushort("int16");
			break;
		case 0xd2: // int 32  11010010
			printScalar!uint("int32");
			break;
		case 0xd3: // int 64  11010011
			printScalar!ulong("int64");
			break;
		case 0xd4: // fixext 1  11010100
			printFixExt!1("fixext1");
			break;
		case 0xd5: // fixext 2  11010101
			printFixExt!2("fixext2");
			break;
		case 0xd6: // fixext 4  11010110
			printFixExt!4("fixext4");
			break;
		case 0xd7: // fixext 8  11010111
			printFixExt!8("fixext8");
			break;
		case 0xd8: // fixext 16  11011000
			printFixExt!16("fixext16");
			break;
		case 0xd9: // str 8  11011001
			printBinOrStr!ubyte("str8");
			break;
		case 0xda: // str 16  11011010
			printBinOrStr!ushort("str16");
			break;
		case 0xdb: // str 32  11011011
			printBinOrStr!uint("str32");
			break;
		case 0xdc: // array 16  11011100
			printArrayAndMap!ushort("array16");
			break;
		case 0xdd: // array 32  11011101
			printArrayAndMap!uint("array32");
			break;
		case 0xde: // map 16  11011110
			// maps has double count of elements so
			// add them once again
			auto l = printArrayAndMap!ushort("map16");
			itemCounts[$-1] += l;
			break;
		case 0xdf: // map 32  11011111
			// maps has double count of elements so
			// add them once again
			auto l = printArrayAndMap!uint("map32");
			itemCounts[$-1] += l;
			break;
		case 0xe0: .. case 0xff: // negative fixint  111xxxxx
			printData("negative fixint: %d", cast(byte) bytes[index]);
			break;
		default:
			printData("Unknown value: %d", bytes[index]);
			break;
		}
		while (itemCounts.length && itemCounts[$ - 1] == 0)
			itemCounts = itemCounts[0 .. $ - 1];
		writeln(line[0..pos]);
		pos = 0;
	}
}
