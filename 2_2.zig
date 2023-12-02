const std = @import("std");

var gpa_raw = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_raw.allocator();

pub fn main() !void {
	std.debug.print("example sum {d}\n", .{try run_problem("examples/2_1.txt")});
	std.debug.print("actual sum {d}\n", .{try run_problem("input/2_1.txt")});
}

pub fn run_problem(file: []const u8) !u64 {
	var r = try FileReader.from_file(file);
	var sum: u64 = 0;
	while (!r.eof()) {
		var lr = try r.line_reader();

		try lr.must_str("Game");
		_ = try lr.u(u64);
		try lr.must_str(":");

		var red_min: u64 = 0;
		var green_min: u64 = 0;
		var blue_min: u64 = 0;

		while (!lr.eof()) {
			var red: u64 = 0;
			var green: u64 = 0;
			var blue: u64 = 0;

			while (true) {
				const count = try lr.u(u64);
				if (lr.test_str("red")) {
					red += count;
				} else if (lr.test_str("green")) {
					green += count;
				} else if (lr.test_str("blue")) {
					blue += count;
				} else {
					return AoCError.BadInput;
				}

				if (!lr.test_str(",")) {
					break;
				}
			}

			red_min = @max(red, red_min);
			green_min = @max(green, green_min);
			blue_min = @max(blue, blue_min);
			_ = lr.test_str(";");
		}

		// std.debug.print("{d}, {any}\n", .{index, valid});
		sum += red_min * green_min * blue_min;
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
