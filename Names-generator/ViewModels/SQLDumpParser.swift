//
//  SQLDumpParser.swift
//  Names-generator
//

import Foundation

/// A table read from a .sql file. Every row has one value per column; `nil` is SQL NULL.
nonisolated struct SQLTable: Sendable {
    let name: String
    var columns: [String] = []
    var rows: [[String?]] = []
}

nonisolated enum SQLDumpError: LocalizedError {
    case noTables

    var errorDescription: String? {
        "No tables with data were found in this file."
    }
}

/// Reads tables from a SQL dump (MySQL, PostgreSQL, SQLite, ...) without running it.
/// Columns come from CREATE TABLE and INSERT column lists, rows from INSERT ... VALUES
/// and PostgreSQL COPY ... FROM stdin blocks. Every other statement is ignored.
nonisolated enum SQLDumpParser {
    /// Tables that have at least one row, in the order they appear in the file.
    static func parse(_ data: Data) throws -> [SQLTable] {
        // Dumps are almost always UTF-8; Latin-1 accepts any bytes, so it's the fallback.
        let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) ?? ""
        var scanner = Scanner(bytes: Array(text.utf8))
        var builder = TableBuilder()

        while let statement = scanner.nextStatement() {
            guard let first = statement.first, first.kind == .word else { continue }
            switch first.upper {
            case "CREATE":
                readCreateTable(statement, into: &builder)
            case "INSERT", "REPLACE":
                readInsert(statement, into: &builder)
            case "COPY":
                readCopy(statement, scanner: &scanner, into: &builder)
            default:
                break
            }
        }

        let tables = builder.finishedTables.filter { !$0.rows.isEmpty }
        guard !tables.isEmpty else { throw SQLDumpError.noTables }
        return tables
    }

    // MARK: - Statements

    /// Table-level definitions inside CREATE TABLE that aren't columns.
    private static let constraintKeywords: Set<String> = [
        "CONSTRAINT", "PRIMARY", "UNIQUE", "KEY", "INDEX", "FOREIGN", "CHECK", "FULLTEXT", "SPATIAL", "EXCLUDE", "PERIOD", "LIKE",
    ]

    /// CREATE [TEMPORARY ...] TABLE [IF NOT EXISTS] name (column definitions)
    private static func readCreateTable(_ tokens: [Token], into builder: inout TableBuilder) {
        // Only words may come between CREATE and TABLE, so CREATE INDEX ... ON t (...) is skipped.
        guard let tableIndex = tokens.firstIndex(where: { $0.kind != .word || $0.upper == "TABLE" }),
              tokens[tableIndex].isWord("TABLE") else { return }
        var index = tableIndex + 1
        if index + 2 < tokens.count, tokens[index].isWord("IF"), tokens[index + 1].isWord("NOT"), tokens[index + 2].isWord("EXISTS") {
            index += 3
        }
        guard case let (name, afterName)? = readTableName(tokens, at: index),
              afterName < tokens.count, tokens[afterName].isSymbol("("),
              case let (definitions, _)? = readParenthesizedList(tokens, at: afterName) else { return }

        let columns = definitions.compactMap { definition -> String? in
            guard let first = definition.first, first.isName,
                  !(first.kind == .word && constraintKeywords.contains(first.upper)) else { return nil }
            return first.text
        }
        builder.defineColumns(columns, ofTable: name)
    }

    /// INSERT [IGNORE | OR REPLACE ...] INTO name [(columns)] VALUES (...), (...)
    private static func readInsert(_ tokens: [Token], into builder: inout TableBuilder) {
        guard let intoIndex = tokens.firstIndex(where: { $0.kind != .word || $0.upper == "INTO" }),
              tokens[intoIndex].isWord("INTO"),
              case let (name, afterName)? = readTableName(tokens, at: intoIndex + 1) else { return }

        var index = afterName
        var columns: [String]?
        if index < tokens.count, tokens[index].isSymbol("(") {
            guard case let (list, next)? = readParenthesizedList(tokens, at: index) else { return }
            columns = list.compactMap { $0.first?.text }
            index = next
        }
        guard index < tokens.count, tokens[index].isWord("VALUES") else { return }
        index += 1

        // Stops at anything after the last row, e.g. ON DUPLICATE KEY UPDATE.
        while index < tokens.count, tokens[index].isSymbol("("),
              case let (values, next)? = readParenthesizedList(tokens, at: index) {
            builder.addRow(values.map(value(of:)), columns: columns, toTable: name)
            index = next
            guard index < tokens.count, tokens[index].isSymbol(",") else { break }
            index += 1
        }
    }

    /// COPY name [(columns)] FROM stdin; followed by tab-separated rows ending with "\.".
    private static func readCopy(_ tokens: [Token], scanner: inout Scanner, into builder: inout TableBuilder) {
        guard tokens.contains(where: { $0.isWord("STDIN") }),
              case let (name, afterName)? = readTableName(tokens, at: 1) else { return }
        var columns: [String]?
        if afterName < tokens.count, tokens[afterName].isSymbol("("),
           case let (list, _)? = readParenthesizedList(tokens, at: afterName) {
            columns = list.compactMap { $0.first?.text }
        }
        for line in scanner.readCopyLines() {
            let values = line.split(separator: "\t", omittingEmptySubsequences: false).map { field -> String? in
                field == "\\N" ? nil : unescapeCopyField(field)
            }
            builder.addRow(values, columns: columns, toTable: name)
        }
    }

    // MARK: - Token helpers

    /// Reads `name` or `schema.name` and returns the last part.
    private static func readTableName(_ tokens: [Token], at start: Int) -> (String, Int)? {
        guard start < tokens.count, tokens[start].isName else { return nil }
        var name = tokens[start].text
        var index = start + 1
        while index + 1 < tokens.count, tokens[index].isSymbol("."), tokens[index + 1].isName {
            name = tokens[index + 1].text
            index += 2
        }
        return (name, index)
    }

    /// Splits "(a, b(c, d), e)" starting at the opening parenthesis into its top-level items.
    /// Returns the items and the index after the closing parenthesis.
    private static func readParenthesizedList(_ tokens: [Token], at start: Int) -> ([[Token]], Int)? {
        var items: [[Token]] = []
        var current: [Token] = []
        var depth = 0
        var index = start + 1
        while index < tokens.count {
            let token = tokens[index]
            if token.isSymbol("(") {
                depth += 1
            } else if token.isSymbol(")") {
                if depth == 0 {
                    items.append(current)
                    return (items, index + 1)
                }
                depth -= 1
            } else if token.isSymbol(","), depth == 0 {
                items.append(current)
                current = []
                index += 1
                continue
            }
            current.append(token)
            index += 1
        }
        return nil
    }

    /// A single string, number or NULL. Anything longer (e.g. "-5") is joined as written.
    private static func value(of tokens: [Token]) -> String? {
        if tokens.count == 1, tokens[0].isWord("NULL") { return nil }
        return tokens.map(\.text).joined()
    }

    private static func unescapeCopyField(_ field: Substring) -> String {
        guard field.contains("\\") else { return String(field) }
        var result = ""
        var isEscaped = false
        for character in field {
            if isEscaped {
                switch character {
                case "t": result.append("\t")
                case "n": result.append("\n")
                case "r": result.append("\r")
                default: result.append(character)
                }
                isEscaped = false
            } else if character == "\\" {
                isEscaped = true
            } else {
                result.append(character)
            }
        }
        return result
    }
}

// MARK: - Table builder

/// Collects tables by name (case-insensitive). Rows can be shorter than their table's
/// columns while building (a later INSERT may add a column); `finishedTables` pads them.
nonisolated private struct TableBuilder {
    private var tables: [SQLTable] = []
    private var indexByName: [String: Int] = [:]

    var finishedTables: [SQLTable] {
        tables.map { table in
            var table = table
            table.rows = table.rows.map { $0 + Array(repeating: nil, count: table.columns.count - $0.count) }
            return table
        }
    }

    mutating func defineColumns(_ columns: [String], ofTable name: String) {
        let index = tableIndex(for: name)
        if tables[index].columns.isEmpty {
            tables[index].columns = columns
        }
    }

    /// `columns` is the INSERT/COPY column list; without one, values follow the table's column order.
    mutating func addRow(_ values: [String?], columns: [String]?, toTable name: String) {
        let index = tableIndex(for: name)
        guard let columns else {
            while tables[index].columns.count < values.count {
                tables[index].columns.append("column \(tables[index].columns.count + 1)")
            }
            tables[index].rows.append(values)
            return
        }

        var row: [String?] = Array(repeating: nil, count: tables[index].columns.count)
        for (column, value) in zip(columns, values) {
            if let position = tables[index].columns.firstIndex(where: { $0.caseInsensitiveCompare(column) == .orderedSame }) {
                row[position] = value
            } else {
                tables[index].columns.append(column)
                row.append(value)
            }
        }
        tables[index].rows.append(row)
    }

    private mutating func tableIndex(for name: String) -> Int {
        let key = name.lowercased()
        if let index = indexByName[key] { return index }
        tables.append(SQLTable(name: name))
        indexByName[key] = tables.count - 1
        return tables.count - 1
    }
}

// MARK: - Scanner

nonisolated private struct Token {
    enum Kind {
        /// Keyword or unquoted name.
        case word
        /// `name`, "name" or [name].
        case quotedName
        case string
        case number
        case symbol
    }

    let kind: Kind
    let text: String

    var upper: String { text.uppercased() }
    var isName: Bool { kind == .word || kind == .quotedName }

    func isWord(_ keyword: String) -> Bool {
        kind == .word && text.caseInsensitiveCompare(keyword) == .orderedSame
    }

    func isSymbol(_ symbol: String) -> Bool {
        kind == .symbol && text == symbol
    }
}

/// Splits SQL text into statements of tokens, skipping comments. Works on UTF-8 bytes
/// for speed; every delimiter is ASCII, so multi-byte characters pass through untouched.
nonisolated private struct Scanner {
    let bytes: [UInt8]
    private var position = 0

    init(bytes: [UInt8]) {
        self.bytes = bytes
    }

    /// Tokens up to the next top-level ";". `nil` at the end of the text.
    mutating func nextStatement() -> [Token]? {
        var tokens: [Token] = []
        while let token = nextToken() {
            if token.isSymbol(";") {
                if tokens.isEmpty { continue }
                return tokens
            }
            tokens.append(token)
        }
        return tokens.isEmpty ? nil : tokens
    }

    /// Raw lines after a COPY ... FROM stdin; statement, up to the "\." line.
    mutating func readCopyLines() -> [Substring] {
        // The rest of the COPY line.
        while position < bytes.count, bytes[position] != newline { position += 1 }
        position += 1

        var lines: [Substring] = []
        while position < bytes.count {
            let start = position
            while position < bytes.count, bytes[position] != newline { position += 1 }
            var end = position
            if end > start, bytes[end - 1] == carriageReturn { end -= 1 }
            position += 1
            let line = String(decoding: bytes[start..<end], as: UTF8.self)
            if line == "\\." { break }
            lines.append(Substring(line))
        }
        return lines
    }

    private let newline = UInt8(ascii: "\n")
    private let carriageReturn = UInt8(ascii: "\r")

    private func byte(at offset: Int = 0) -> UInt8? {
        position + offset < bytes.count ? bytes[position + offset] : nil
    }

    private mutating func nextToken() -> Token? {
        skipWhitespaceAndComments()
        guard let current = byte() else { return nil }

        switch current {
        case UInt8(ascii: "'"):
            return Token(kind: .string, text: readQuoted(closing: UInt8(ascii: "'"), allowsBackslash: true))
        case UInt8(ascii: "\""):
            return Token(kind: .quotedName, text: readQuoted(closing: UInt8(ascii: "\""), allowsBackslash: false))
        case UInt8(ascii: "`"):
            return Token(kind: .quotedName, text: readQuoted(closing: UInt8(ascii: "`"), allowsBackslash: false))
        case UInt8(ascii: "["):
            return Token(kind: .quotedName, text: readQuoted(closing: UInt8(ascii: "]"), allowsBackslash: false))
        case UInt8(ascii: "0")...UInt8(ascii: "9"):
            return Token(kind: .number, text: readWhile(isWordByte))
        default:
            // N'...' (SQL Server) and E'...' (PostgreSQL) are plain strings here.
            if [UInt8(ascii: "N"), UInt8(ascii: "n"), UInt8(ascii: "E"), UInt8(ascii: "e")].contains(current),
               byte(at: 1) == UInt8(ascii: "'") {
                position += 1
                return Token(kind: .string, text: readQuoted(closing: UInt8(ascii: "'"), allowsBackslash: true))
            }
            if isWordByte(current) {
                return Token(kind: .word, text: readWhile(isWordByte))
            }
            position += 1
            return Token(kind: .symbol, text: String(UnicodeScalar(current)))
        }
    }

    private func isWordByte(_ byte: UInt8) -> Bool {
        byte >= 0x80 || byte == UInt8(ascii: "_") || byte == UInt8(ascii: "$")
            || (UInt8(ascii: "a")...UInt8(ascii: "z")).contains(byte)
            || (UInt8(ascii: "A")...UInt8(ascii: "Z")).contains(byte)
            || (UInt8(ascii: "0")...UInt8(ascii: "9")).contains(byte)
    }

    private mutating func readWhile(_ predicate: (UInt8) -> Bool) -> String {
        let start = position
        while let current = byte(), predicate(current) { position += 1 }
        return String(decoding: bytes[start..<position], as: UTF8.self)
    }

    /// Reads from the opening quote to the closing one. A doubled closing quote is a literal
    /// quote; with `allowsBackslash`, backslash escapes (MySQL style) are decoded too.
    private mutating func readQuoted(closing: UInt8, allowsBackslash: Bool) -> String {
        position += 1
        var buffer: [UInt8] = []
        while let current = byte() {
            position += 1
            if current == closing {
                if byte() == closing {
                    buffer.append(closing)
                    position += 1
                    continue
                }
                break
            }
            if allowsBackslash, current == UInt8(ascii: "\\"), let escaped = byte() {
                position += 1
                switch escaped {
                case UInt8(ascii: "n"): buffer.append(newline)
                case UInt8(ascii: "r"): buffer.append(carriageReturn)
                case UInt8(ascii: "t"): buffer.append(UInt8(ascii: "\t"))
                case UInt8(ascii: "0"): break
                default: buffer.append(escaped)
                }
                continue
            }
            buffer.append(current)
        }
        return String(decoding: buffer, as: UTF8.self)
    }

    /// Skips spaces and --, # and /* */ comments.
    private mutating func skipWhitespaceAndComments() {
        while let current = byte() {
            if current == UInt8(ascii: " ") || current == UInt8(ascii: "\t") || current == newline || current == carriageReturn {
                position += 1
            } else if (current == UInt8(ascii: "-") && byte(at: 1) == UInt8(ascii: "-")) || current == UInt8(ascii: "#") {
                while byte() != nil, byte() != newline { position += 1 }
            } else if current == UInt8(ascii: "/") && byte(at: 1) == UInt8(ascii: "*") {
                position += 2
                while byte() != nil, !(byte() == UInt8(ascii: "*") && byte(at: 1) == UInt8(ascii: "/")) { position += 1 }
                position += 2
            } else {
                return
            }
        }
    }
}
