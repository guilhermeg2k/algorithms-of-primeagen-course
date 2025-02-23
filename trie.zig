const std = @import("std");
const expect = std.testing.expect;

const NODE_CHILDREN_LEN = 26;
const DynStr = std.ArrayList(u8);
const DynStrArrayList = std.ArrayList(DynStr);

const Node = struct {
    const Self = @This();

    is_word: bool = false,
    children: [NODE_CHILDREN_LEN]?*Node = .{null} ** NODE_CHILDREN_LEN,

    fn create(alloc: std.mem.Allocator) !*Self {
        const node = try alloc.create(Node);
        node.children = .{null} ** NODE_CHILDREN_LEN;
        return node;
    }
};

const Trie = struct {
    const Self = @This();
    len: usize = 0,
    head: *Node,
    alloc: std.mem.Allocator,

    fn init(alloc: std.mem.Allocator) !Self {
        const head = try Node.create(alloc);
        return .{ .alloc = alloc, .len = 0, .head = head };
    }

    fn deinit(self: *Self) void {
        self.delete_node(self.head);
    }

    fn delete_node(self: *Self, node: ?*Node) void {
        if (node) |n| {
            for (n.children) |nc| {
                self.delete_node(nc);
            }
            self.alloc.destroy(n);
        }
    }

    fn insert(self: *Self, str: []const u8) !void {
        var cur_node = self.head;

        for (str, 0..) |c, i| {
            const c_index = getIndex(c);

            if (c_index >= NODE_CHILDREN_LEN) return;

            if (cur_node.children[c_index]) |n| {
                cur_node = n;
            } else {
                const node = try Node.create(self.alloc);
                node.is_word = i == str.len - 1;

                cur_node.children[c_index] = node;
                cur_node = node;
            }
        }

        self.len += 1;
    }

    fn getSuggestions(self: *Self, str: []const u8) !DynStrArrayList {
        const suggestions = DynStrArrayList.init(self.alloc);

        var curr_node = self.head;
        var curr_node_index: usize = 0;

        for (str) |char| {
            const char_id = getIndex(char);

            if (curr_node.children[char_id] == null) {
                return suggestions;
            } else if (curr_node.children[char_id]) |c| {
                curr_node = c;
                curr_node_index = char_id;
            }
        }

        return self.getNodeWords(curr_node, curr_node_index, str[0 .. str.len - 1]);
    }

    fn getNodeWords(self: *Self, node: *Node, node_index: usize, words_prefix: []const u8) !DynStrArrayList {
        var words = DynStrArrayList.init(self.alloc);
        try self.lookForWordsAndAppend(node, node_index, words_prefix, &words);
        return words;
    }

    fn lookForWordsAndAppend(self: *Self, node: *Node, node_index: usize, current_word: []const u8, words: *DynStrArrayList) !void {
        var current_new_word = DynStr.init(self.alloc);

        for (current_word) |c| {
            try current_new_word.append(c);
        }

        try current_new_word.append(getChar(node_index));

        for (node.children, 0..) |nc, i| {
            if (nc) |c| {
                try self.lookForWordsAndAppend(c, i, current_new_word.items[0..current_new_word.items.len], words);
            }
        }

        if (node.is_word) {
            try words.append(current_new_word);
        } else {
            current_new_word.deinit();
        }
    }

    fn getIndex(c: u8) usize {
        const char = std.ascii.toLower(c);
        return char - 97;
    }

    fn getChar(index: usize) u8 {
        return @min(index + 97, 255);
    }
};

test "a-z trie" {
    var trie = try Trie.init(std.testing.allocator);
    defer trie.deinit();

    try trie.insert("sal");
    try trie.insert("salv");
    try trie.insert("salvador");

    try trie.insert("olim");
    try trie.insert("olimpia");

    const sal_suggestions = try trie.getSuggestions("sal");
    defer sal_suggestions.deinit();

    const expected: [3][]const u8 = .{ "salvador", "salv", "sal" };
    for (expected, 0..) |e, i| {
        const suggestion = sal_suggestions.items[i];
        try expect(std.mem.eql(u8, e, suggestion.items));
    }

    const salv_suggestions = try trie.getSuggestions("Salv");
    defer salv_suggestions.deinit();

    const expected2: [2][]const u8 = .{ "Salvador", "Salv" };
    for (expected2, 0..) |e, i| {
        const suggestion = salv_suggestions.items[i];
        try expect(std.mem.eql(u8, e, suggestion.items));
    }

    const oli_suggestions = try trie.getSuggestions("oli");
    defer oli_suggestions.deinit();
    const expected3: [2][]const u8 = .{ "olimpia", "olim" };

    for (expected3, 0..) |e, i| {
        const suggestion = oli_suggestions.items[i];
        try expect(std.mem.eql(u8, e, suggestion.items));
    }

    for (sal_suggestions.items) |i| {
        defer i.deinit();
    }

    for (salv_suggestions.items) |i| {
        defer i.deinit();
    }

    for (oli_suggestions.items) |i| {
        defer i.deinit();
    }
}
