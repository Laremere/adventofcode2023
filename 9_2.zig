const std = @import("std");

var gpa_raw = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_raw.allocator();

pub fn main() !void {
	const filenames = [_][]const u8 {
		"examples/9_1.txt",
		"input/9_1.txt",
	};

    for (filenames) |filename| {
    	var r = try FileReader.from_file(filename);
    	var timer = try std.time.Timer.start();
    	const result = try runProblem(&r);
    	const finish_time = timer.read();
	    std.debug.print("{s} result {d}\n", .{filename, result});
	    std.debug.print("run time: {d}.{d}ms\n\n", .{ finish_time / 1_000_000, finish_time % 1_000_000 });
    }
}

pub fn runProblem(r: *FileReader) !i64 {
	var difs = std.ArrayList(i64).init(gpa);
	defer difs.deinit();
	var firsts = std.ArrayList(i64).init(gpa);
	defer firsts.deinit();

	var sum: i64 = 0;
	while (!r.eof()) {
		difs.clearRetainingCapacity();
		firsts.clearRetainingCapacity();

		var lr = try r.lineReader();

		while (!lr.eof()) {
			var next = try lr.i();
			for (difs.items) |*dif| {
				const next_next = next - dif.*;
				dif.* = next;
				next = next_next;
			}
			try difs.append(next);
			try firsts.append(next);
		}

		{
			var sub: i64 = 0;
			var i: i64 = @as(i64, @intCast(firsts.items.len)) - 1;
			while (i >= 0) {
				sub = firsts.items[@intCast(i)] - sub;

				i -= 1;
			}
			sum += sub;
		}
	}

	return sum;
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
		if (self.b.len == 0) {
			self.err("number");
			return AoCError.BadInput;			
		}
		var multiplier: i64 = 1;
		if (self.b[0] == '-') {
			multiplier = -1;
			self.b = self.b[1..];
		}

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

		return sum * multiplier;
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
