const std = @import("std");

var gpa_raw = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_raw.allocator();

pub fn main() !void {
    var timer = try std.time.Timer.start();
    std.debug.print("example result {d}\n", .{try runProblem("examples/8_2.txt")});
    const example_time = timer.read();
    std.debug.print("run time: {d}.{d}ms\n", .{ example_time / 1_000_000, example_time % 1_000_000 });
    timer.reset();
    std.debug.print("actual result {d}\n", .{try runProblem("input/8_1.txt")});
    const actual_time = timer.read();
    std.debug.print("run time: {d}.{d}ms\n", .{ actual_time / 1_000_000, actual_time % 1_000_000 });
}

pub fn index(bytes: [3]u8) u16 {
	const hundreds: u16 = @intCast(bytes[0]-'A');
	const tens: u16 = @intCast(bytes[1]-'A');
	const units: u16 = @intCast(bytes[2]-'A');

	return hundreds*26*26 + tens*26 + units;
}

fn indexName(i: u16) [3]u8{
	return .{
		'A' + @as(u8, @intCast(i/26/26)),
		'A' + @as(u8, @intCast((i/26)%26)),
		'A' + @as(u8, @intCast(i%26)),
	};
}

pub fn runProblem(file: []const u8) !i64 {
	var r = try FileReader.from_file(file);

	var rights = std.ArrayList(u1).init(gpa);
	defer rights.deinit();

	{
		var lr = try r.lineReader();
		while(!lr.eof()) {
			if (lr.testStr("L")) {
				try rights.append(0);
			} else {
				try lr.mustStr("R");
				try rights.append(1);
			}
		}
	}
	{
		var lr = try r.lineReader();
		try lr.mustEof();
	}

	var nodes = try gpa.alloc([2]u16, 26*26*26);
	defer gpa.free(nodes);

	var positions = std.ArrayList(u16).init(gpa);
	defer positions.deinit();

	while (!r.eof()) {
		var lr = try r.lineReader();
		const i = index(try lr.bytesFixed(3));
		if (i % 26 == 0) {
			try positions.append(i);
		}
		try lr.mustStr("= (");
		nodes[i][0] = index(try lr.bytesFixed(3));
		try lr.mustStr(", ");
		nodes[i][1] = index(try lr.bytesFixed(3));
		try lr.mustStr(")");
		try lr.mustEof();
	}

	var result: u64 = 1;
	for (positions.items) |start_pos| {
		var steps: u64 = 0;
		var pos = start_pos;

		while (pos % 26 != 25) {
			const turn_step: usize = @as(usize, @intCast(steps)) % rights.items.len;
			pos = nodes[pos][rights.items[turn_step]];
			steps+=1;
		}
		result *= steps / std.math.gcd(result, steps);
	}

	return @intCast(result);
}

const AoCError = error {
	BadProblem,
	BadInput,
	UnexpectedEOF,
};

const Reader = struct {
	b: []u8,
	full_b: []u8,
	line: u64,

	fn eof(self: *Reader) bool {
		self.trimSpaces();
		return self.b.len == 0;
	}

	fn mustEof(self: *Reader) !void {
		if (!self.eof()) {
			self.err("end of line");
			return AoCError.BadInput;
		}
	}

	fn i(self: *Reader) !i64 {
		self.trimSpaces();
		if (self.b.len == 0 or self.b[0] < '0' or self.b[0] > '9') {
			self.err("number");
			return AoCError.BadInput;
		}
		var sum: i64 = 0;

		while (self.b.len > 0 and self.b[0] >= '0' and self.b[0] <= '9') {
			sum *= 10;
			sum += @as(i64, self.b[0] - '0');
			self.b = self.b[1..];
		}

		return sum;
	}

	fn testStr(self: *Reader, str: []const u8) bool {
		self.trimSpaces();
		if (self.b.len < str.len) {
			return false;
		}
		const result = std.mem.eql(u8, self.b[0..str.len], str);
		if (result) {
			self.b = self.b[str.len..];
		}
		return result;
	}

	fn mustStr(self: *Reader, str: []const u8) !void {
		if (!self.testStr(str)) {
			self.err(str);
			return AoCError.BadInput;
		}
	}

	fn trimSpaces(self: *Reader) void {
		while (self.b.len > 0 and self.b[0] == ' ') {
			self.b = self.b[1..];
		}
	}

	fn bytesFixed(self: *Reader, comptime len: usize) ![len]u8 {
		if (self.b.len < len) {
			return AoCError.UnexpectedEOF;
		}
		const result = self.b[0..len];
		self.b = self.b[len..];
		return result.*;
	}

	fn byte(self: *Reader) !u8 {
		if (self.eof()) {
			self.err("byte");
			return AoCError.UnexpectedEOF;
		}
		const result = self.b[0];
		self.b = self.b[1..];
		return result;
	}

	fn err(self: *Reader, str: []const u8) void {
		const pos: u64 = @as(u64, @intFromPtr(self.b.ptr) - @intFromPtr(self.full_b.ptr));
		std.debug.print("Error line {d} pos {d}: expected {s}\n", .{self.line + 1, pos + 1, str});
		std.debug.print("{s}\n", .{self.full_b});
		for (0..pos) |j| {
			_ = j;
			std.debug.print(" ", .{});
		}
		std.debug.print("^\n", .{});
	}
};

const FileReader = struct {
	b: []u8,
	line: u64 = 0,

	fn eof(self: *FileReader) bool {
		return self.b.len == 0;
	}

	fn lineReader(self: *FileReader) !Reader {
		for (self.b, 0..) |b, i| {
			if (b == '\n') {
				const result = Reader {
					.b = self.b[0..i],
					.full_b = self.b[0..i],
					.line = self.line,
				};
				self.b = self.b[i+1..];
				self.line += 1;
				return result;
			}
		}
		return AoCError.UnexpectedEOF;
	}

	fn from_file(name: []const u8) !FileReader {
		return FileReader{
			.b = try std.fs.cwd().readFileAlloc(gpa, name, std.math.maxInt(usize)),
		};
	}
};
