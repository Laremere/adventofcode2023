const std = @import("std");

var gpa_raw = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_raw.allocator();

pub fn main() !void {
    var timer = try std.time.Timer.start();
    std.debug.print("example sum {d}\n", .{try runProblem("examples/4_1.txt")});
    const example_time = timer.read();
    std.debug.print("run time: {d}.{d}ms\n", .{ example_time / 1_000_000, example_time % 1_000_000 });
    timer.reset();
    std.debug.print("actual sum {d}\n", .{try runProblem("input/4_1.txt")});
    const actual_time = timer.read();
    std.debug.print("run time: {d}.{d}ms\n", .{ actual_time / 1_000_000, actual_time % 1_000_000 });
}

pub fn runProblem(file: []const u8) !u64 {
	var r = try FileReader.from_file(file);
	var sum: u64 = 0;

	var copies = std.ArrayList(u64).init(gpa);
	var i: usize = 0;
	while (!r.eof()) {
		while (copies.items.len <= i) {
			try copies.append(0);
		}
		copies.items[i] += 1;
		var lr = try r.line_reader();

		try lr.must_str("Card");
		_ = try lr.u(u64);
		try lr.must_str(":");

		var nums = std.ArrayList(u64).init(gpa);
		defer nums.deinit();

		while (!lr.test_str("|")) {
			try nums.append(try lr.u(u64));
		}

		var points: u64 = 0;
		while (!lr.eof()) {
			const mynum = try lr.u(u64);
			for (nums.items) |winner| {
				if (winner == mynum) {
					points += 1;
				}
			}
		}

		for (i+1..i+points+1) |j| {
			while (copies.items.len <= j) {
				try copies.append(0);
			}
			copies.items[j] += copies.items[i];
		}

		sum += copies.items[i];
		i+= 1;
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
		self.trim_spaces();
		return self.b.len == 0;
	}

	fn u(self: *Reader, comptime T: type) !T {
		self.trim_spaces();
		if (self.b.len == 0 or self.b[0] < '0' or self.b[0] > '9') {
			self.err("number");
			return AoCError.BadInput;
		}
		var sum: T = 0;

		while (self.b.len > 0 and self.b[0] >= '0' and self.b[0] <= '9') {
			sum *= 10;
			sum += @as(T, self.b[0] - '0');
			self.b = self.b[1..];
		}

		return sum;
	}

	fn test_str(self: *Reader, str: []const u8) bool {
		self.trim_spaces();
		if (self.b.len < str.len) {
			return false;
		}
		const result = std.mem.eql(u8, self.b[0..str.len], str);
		if (result) {
			self.b = self.b[str.len..];
		}
		return result;
	}

	fn must_str(self: *Reader, str: []const u8) !void {
		if (!self.test_str(str)) {
			self.err(str);
			return AoCError.BadInput;
		}
	}

	fn trim_spaces(self: *Reader) void {
		while (self.b.len > 0 and self.b[0] == ' ') {
			self.b = self.b[1..];
		}
	}

	fn err(self: *Reader, str: []const u8) void {
		const pos: u64 = @as(u64, @intFromPtr(self.b.ptr) - @intFromPtr(self.full_b.ptr));
		std.debug.print("Error line {d} pos {d}: expected {s}\n", .{self.line + 1, pos + 1, str});
		std.debug.print("{s}\n", .{self.full_b});
		for (0..pos) |i| {
			_ = i;
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

	fn line_reader(self: *FileReader) !Reader {
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
