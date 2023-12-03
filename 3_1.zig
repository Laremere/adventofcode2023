const std = @import("std");

var gpa_raw = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_raw.allocator();

pub fn main() !void {
	var timer = try std.time.Timer.start();
	std.debug.print("example sum {d}\n", .{try runProblem("examples/3_1.txt")});
	const example_time = timer.read();
	std.debug.print("run time: {d}.{d}ms\n", .{example_time / 1_000_000, example_time % 1_000_000});
	timer.reset();
	std.debug.print("actual sum {d}\n", .{try runProblem("input/3_1.txt")});
	const actual_time = timer.read();
	std.debug.print("run time: {d}.{d}ms\n", .{actual_time / 1_000_000, actual_time % 1_000_000});
}

const Number = struct {
	line: i64,
	start: i64,
	end: i64,
	value: u64,
};

const Part = struct {
	line: i64,
	column: i64,
};

pub fn runProblem(file: []const u8) !u64 {
	var r = try FileReader.fromFile(file);
	var sum: u64 = 0;

	var numbers = std.ArrayList(Number).init(gpa);
	var parts = std.ArrayList(Part).init(gpa);

	var line: i64 = 0;
	while (!r.eof()) {
		const bytes = try r.readLine();

		var running: ?Number = null;

		for (bytes, 0..) |b, i| {
			if (std.ascii.isDigit(b)) {
				if (running) |*num| {
					num.value *= 10;
					num.value += @intCast(b - '0'); 
					num.end = @intCast(i);
				} else {
					running = Number {
						.line = line,
						.start = @intCast(i),
						.end = @intCast(i),
						.value = @intCast(b - '0'), 
					};
				}
			} else {
				if (running) |num| {
					try numbers.append(num);
					running = null;
				}
				if (b != '.') {
					try parts.append(Part{
						.line = line,
						.column = @intCast(i),
					});
				}
			}
		}
		if (running) |num| {
			try numbers.append(num);
		}
		line += 1; 
	}

	// This is O(items * parts).  Could be greatly improved, but
	// it runs so fast I don't care. Hold on let me add a timer to this.
	// Ok yeah it takes 5ms, including file load.  It's ok.
	for (numbers.items) |num| {
		for (parts.items) |part| {
			const adjacent_line = num.line - 1 <= part.line and part.line <= num.line + 1;
			const adjacent_column = num.start - 1 <= part.column and part.column <= num.end + 1;
			if (adjacent_line and adjacent_column) {
				sum += num.value;
				break;
			}
		}
	}

	return sum;
}


const AoCError = error {
	BadProblem,
	BadInput,
	UnexpectedEOF,
};

const FileReader = struct {
	b: []u8,
	line: u64 = 0,

	fn eof(self: *FileReader) bool {
		return self.b.len == 0;
	}

	fn readLine(self: *FileReader) ![]const u8 {
		for (self.b, 0..) |b, i| {
			if (b == '\n') {
				const result = self.b[0..i];
				self.b = self.b[i+1..];
				self.line += 1;
				return result;
			}
		}
		return AoCError.UnexpectedEOF;
	}

	fn fromFile(name: []const u8) !FileReader {
		return FileReader{
			.b = try std.fs.cwd().readFileAlloc(gpa, name, std.math.maxInt(usize)),
		};
	}
};
