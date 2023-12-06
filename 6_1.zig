const std = @import("std");

var gpa_raw = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_raw.allocator();

pub fn main() !void {
    var timer = try std.time.Timer.start();
    std.debug.print("example result {d}\n", .{try runProblem("examples/6_1.txt")});
    const example_time = timer.read();
    std.debug.print("run time: {d}.{d}ms\n", .{ example_time / 1_000_000, example_time % 1_000_000 });
    timer.reset();
    std.debug.print("actual result {d}\n", .{try runProblem("input/6_1.txt")});
    const actual_time = timer.read();
    std.debug.print("run time: {d}.{d}ms\n", .{ actual_time / 1_000_000, actual_time % 1_000_000 });
}


pub fn runProblem(file: []const u8) !i64 {
	var r = try FileReader.from_file(file);

	var times = std.ArrayList(i64).init(gpa);
	var distances = std.ArrayList(i64).init(gpa);
	{
		var lr = try r.lineReader();
		try lr.mustStr("Time:");
		while (!lr.eof()) {
			try times.append(try lr.i());
		}
	}
	{
		var lr = try r.lineReader();
		try lr.mustStr("Distance:");
		while (!lr.eof()) {
			try distances.append(try lr.i());
		}
	}

	var margin: i64 = 1;

	for (times.items, distances.items) |total_time, distance_record| {
		var beat_count: i64 = 0;
		for (0..@intCast(total_time)) |htl| {
			const hold_time: i64 = @intCast(htl);
			const travel_time = total_time - hold_time;
			const speed = hold_time;
			const distance = travel_time * speed;
			if (distance > distance_record) {
				beat_count += 1;
			}
		}
		//std.debug.print("{}", .{beat_count});
		margin *= beat_count;
	}

	return margin;
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
