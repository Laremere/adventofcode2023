const std = @import("std");

var gpa_raw = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_raw.allocator();

pub fn main() !void {
    var timer = try std.time.Timer.start();
    std.debug.print("example result {d}\n", .{try runProblem("examples/5_1.txt")});
    const example_time = timer.read();
    std.debug.print("run time: {d}.{d}ms\n", .{ example_time / 1_000_000, example_time % 1_000_000 });
    timer.reset();
    std.debug.print("actual result {d}\n", .{try runProblem("input/5_1.txt")});
    const actual_time = timer.read();
    std.debug.print("run time: {d}.{d}ms\n", .{ actual_time / 1_000_000, actual_time % 1_000_000 });
}

const RangeMap = struct {
	src: i64,
	dst: i64,
	len: i64,
};

pub fn runProblem(file: []const u8) !i64 {
	var r = try FileReader.from_file(file);

	var seeds = std.ArrayList(i64).init(gpa);
	{
		var lr = try r.lineReader();
		try lr.mustStr("seeds:");
		while (!lr.eof()) {
			try seeds.append(try lr.i());
		}
	}
	{
		var lr = try r.lineReader();
		try lr.mustEof();
	}
	// std.debug.print("seeds: {any}\n", .{seeds.items});
	applyMap(seeds, try readMap(&r, "seed-to-soil"));
	applyMap(seeds, try readMap(&r, "soil-to-fertilizer"));
	applyMap(seeds, try readMap(&r, "fertilizer-to-water"));
	applyMap(seeds, try readMap(&r, "water-to-light"));
	applyMap(seeds, try readMap(&r, "light-to-temperature"));
	applyMap(seeds, try readMap(&r, "temperature-to-humidity"));
	applyMap(seeds, try readMap(&r, "humidity-to-location"));

	var min_seed = seeds.items[0];
	for (seeds.items) |seed| {
		min_seed = @min(min_seed, seed);
	}
	return min_seed;
}

fn readMap(r: *FileReader, header: []const u8) !std.ArrayList(RangeMap) {
	{
		var lr = try r.lineReader();
		try lr.mustStr(header);
		try lr.mustStr("map:");
		try lr.mustEof();
	}
	var result = std.ArrayList(RangeMap).init(gpa);
	errdefer result.deinit();

	while (true) {
		var rm: RangeMap = undefined;

		if (r.eof()) {
			return result;
		}
		var lr = try r.lineReader();
		if (lr.eof()) {
			return result;
		}

		rm.dst = try lr.i();
		rm.src = try lr.i();
		rm.len = try lr.i();
		try result.append(rm);
	}
}

fn applyMap(seeds: std.ArrayList(i64), mappings: std.ArrayList(RangeMap)) void {
	for (0..seeds.items.len) |i| {
		for (mappings.items) |m| {
			const seed = seeds.items[i];
			if (seed >= m.src and seed < m.src + m.len) {
				seeds.items[i] -= m.src;
				seeds.items[i] += m.dst;
				break;
			}
		}
	}
	// std.debug.print("seeds: {any}\n", .{seeds.items});
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
