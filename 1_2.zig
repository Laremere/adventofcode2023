const std = @import("std");

var gpa_raw = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_raw.allocator();

pub fn main() !void {
	std.debug.print("example sum {d}\n", .{try run_problem("examples/1_2.txt")});
	std.debug.print("actual sum {d}\n", .{try run_problem("input/1_1.txt")});
}

pub fn run_problem(file: []const u8) !u64 {
	var r = try Reader.from_file(file);
	var sum: u64 = 0;
	while (!r.eof()) {
		var lr = try r.line_reader();

		var first: ?u8 = null;
		var last: u8 = 0;

		while (!lr.eof()) {
			var digit: ?u8 = null;

			if (lr.test_str("one")) {
				digit = 1;
			} else if (lr.test_str("two")) {
				digit = 2;
			} else if (lr.test_str("three")) {
				digit = 3;
			} else if (lr.test_str("four")) {
				digit = 4;
			} else if (lr.test_str("five")) {
				digit = 5;
			} else if (lr.test_str("six")) {
				digit = 6;
			} else if (lr.test_str("seven")) {
				digit = 7;
			} else if (lr.test_str("eight")) {
				digit = 8;
			} else if (lr.test_str("nine")) {
				digit = 9;
			} else {
				const b = try lr.read_u8();
				if (b >= '0' and b <= '9') {
					digit = b - '0';
				}	
			}
			if (digit) |d| {
				if (first == null) {
					first = d;
				}
				last = d;
			}
		}

		if (first) |f| {
			sum += @as(u64, f * 10 + last);
		} else {
			return AoCError.BadProblem;
		}
	}
	return sum;
}


const AoCError = error {
	BadProblem,
	UnexpectedEOF,
};

const Reader = struct {
	b: []u8,

	fn eof(self: *Reader) bool {
		return self.b.len == 0;
	}

	fn read_u8(self: *Reader) !u8 {
		if (self.b.len == 0) {
			return AoCError.UnexpectedEOF;
		}
		const result = self.b[0];
		self.b = self.b[1..];
		return result;
	}

	fn test_str(self: *Reader, str: []const u8) bool {
		if (self.b.len < str.len) {
			return false;
		}
		const result = std.mem.eql(u8, self.b[0..str.len], str);
		if (result) {
			self.b = self.b[1..];
			// self.b = self.b[str.len..];
		}
		return result;
	}

	fn line_reader(self: *Reader) !Reader {
		for (self.b, 0..) |b, i| {
			if (b == '\n') {
				const result = self.b[0..i];
				self.b = self.b[i+1..];
				return Reader {
					.b = result,
				};
			}
		}
		return AoCError.UnexpectedEOF;
	}

	fn from_file(name: []const u8) !Reader {
		return Reader{
			.b = try std.fs.cwd().readFileAlloc(gpa, name, std.math.maxInt(usize)),
		};
	}
};
