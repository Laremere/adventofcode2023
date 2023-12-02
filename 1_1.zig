const std = @import("std");

var gpa_raw = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_raw.allocator();

pub fn main() !void {
	var r = try Reader.from_file("input/1_1.txt");
	var sum: u64 = 0;
	while (!r.eof()) {
		var lr = try r.line_reader();

		var first: ?u8 = null;
		var last: u8 = 0;

		while (!lr.eof()) {
			const b = try lr.read_u8();
			if (b >= '0' and b <= '9') {
				if (first == null) {
					first = b;
				}
				last = b;
			}
		}

		if (first) |f| {
			sum += @as(u64, (f - '0') * 10 + last - '0');
		} else {
			return AoCError.BadProblem;
		}
	}
	std.debug.print("sum {d}\n", .{sum});
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
