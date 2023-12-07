const std = @import("std");

var gpa_raw = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_raw.allocator();

pub fn main() !void {
    var timer = try std.time.Timer.start();
    std.debug.print("example result {d}\n", .{try runProblem("examples/7_1.txt")});
    const example_time = timer.read();
    std.debug.print("run time: {d}.{d}ms\n", .{ example_time / 1_000_000, example_time % 1_000_000 });
    timer.reset();
    std.debug.print("actual result {d}\n", .{try runProblem("input/7_1.txt")});
    const actual_time = timer.read();
    std.debug.print("run time: {d}.{d}ms\n", .{ actual_time / 1_000_000, actual_time % 1_000_000 });
}

const StrengthBid = struct {
	strength: u64,
	bid: i64,
};

fn strengthLess(_: void, a: StrengthBid, b: StrengthBid) bool {
	return a.strength < b.strength;
}

pub fn runProblem(file: []const u8) !i64 {
	var r = try FileReader.from_file(file);

	var hands = std.ArrayList(StrengthBid).init(gpa);
	defer hands.deinit();

	while (!r.eof()) {
		var lr = try r.lineReader();
		const bytes = try lr.bytes_fixed(5);
		const bid = try lr.i();
		try lr.mustEof();

		var doubles: u8 = 0;
		// var tripples: u8 = 0;

		for (0..bytes.len) |i| {
			for (i+1..bytes.len) |j| {
				if (bytes[i] == bytes[j]) {
					doubles += 1;
				}
			}
		}

		var j_count: u8 = 0;
		for (bytes) |b| {
			if (b == 'J') {
				j_count += 1;
			}
		}

		const Ranks = enum(u64) {
			five_of_a_kind = 6,
			four_of_a_kind = 5,
			full_house = 4,
			three_of_a_kind = 3,
			two_pair = 2,
			pair = 1,
			high_card = 0,
		};

		var rank: u64 = @intFromEnum(if (doubles == 10) blk: {
			break :blk Ranks.five_of_a_kind;

		} else if (doubles == 6) blk: {
			if (j_count > 0) {
				// 1 wildcard matches 4 or 4 wildcards match 1.
				break :blk Ranks.five_of_a_kind;
			}
			break :blk Ranks.four_of_a_kind;

		} else if (doubles == 1 + 3) blk: {
			if (j_count > 1) {
				break :blk Ranks.five_of_a_kind; // wildcards match other match, becoming 5.
			}
			break :blk Ranks.full_house;

		} else if (doubles == 3) blk: {
			if (j_count > 0) {
				break :blk Ranks.four_of_a_kind;
			}
			break :blk Ranks.three_of_a_kind;

		} else if (doubles == 2) blk: {
			if (j_count == 2) {
				break :blk Ranks.four_of_a_kind;
			} else if (j_count == 1) {
				break :blk Ranks.full_house;
			}
			break :blk Ranks.two_pair;

		} else if (doubles == 1) blk: {
			if (j_count > 0) {
				break :blk Ranks.three_of_a_kind;
			} 
			break :blk Ranks.pair;

		} else blk: { // high card
			if (j_count > 0) {
				break :blk Ranks.pair;
			}
			break :blk Ranks.high_card;

		});

		for (bytes) |b| {
			rank <<= 8;
			if (b == 'A') {
				rank += 14;
			} else if (b == 'K') {
				rank += 13;
			} else if (b == 'Q') {
				rank += 12;
			} else if (b == 'T') {
				rank += 10;
			} else if (b >= '2' and b <= '9') {
				rank += @intCast(b - '0');
			} else if (b == 'J') {
				rank += 1;
			} else {
				return AoCError.BadInput;
			}
		}

		try hands.append(StrengthBid{
			.strength = rank,
			.bid = bid,
		});
	}


	std.mem.sort(StrengthBid, hands.items, {}, strengthLess);

	var result: i64 = 0;

	for (hands.items, 1..) |hand, multiplier| {
		result += hand.bid * @as(i64, @intCast(multiplier));
	}

	return result;
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

	fn bytes_fixed(self: *Reader, comptime len: usize) ![len]u8 {
		if (self.b.len < len) {
			return AoCError.UnexpectedEOF;
		}
		const result = self.b[0..len];
		self.b = self.b[len..];
		return result.*;
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
