//
//  Language.swift
//  NovaSwift
//
//  Created by Mikhail Khinevich on 02.01.26.
//

import Foundation
internal import UniformTypeIdentifiers

/// Represents the programming languages supported by the NovaSwift IDE.
enum Language: String, CaseIterable, Identifiable {
    case swift
    case kotlin
    
    var id: String {
        rawValue
    }
    
    /// The user-friendly display name of the language.
    var displayName: String {
        switch self {
        case .swift: return "Swift"
        case .kotlin: return "Kotlin"
        }
    }
    
    /// The file extension associated with the language.
    var fileExtension: String {
        switch self {
        case .swift: return "swift"
        case .kotlin: return "kts"
        }
    }
    
    /// The Uniform Type Identifier (UTType) for the language source files.
    var utType: UTType {
        switch self {
        case .swift: return .swiftSource
        case .kotlin: 
            // Fallback for systems that don't know .kts
            return UTType(filenameExtension: "kts") ?? .plainText
        }
    }
    
    /// The command-line executable used to run scripts in this language.
    var executableName: String {
        switch self {
        case .swift: return "swift"
        case .kotlin: return "kotlinc"
        }
    }
    
    /// The arguments required to execute a script file.
    /// - Parameter scriptPath: The absolute path to the script file.
    func executionArguments(for scriptPath: String) -> [String] {
        switch self {
        case .swift:
            return [scriptPath]
        case .kotlin:
            return ["-script", scriptPath]
        }
    }
    
    /// Keywords for syntax highlighting.
    var keywords: [String] {
        switch self {
        case .swift:
            return [
                "associatedtype", "class", "deinit", "enum", "extension", "fileprivate", "func", "import", "init", "inout", "internal", "let", "open", "operator", "private", "protocol", "public", "static", "struct", "subscript", "typealias", "var",
                "break", "case", "continue", "default", "defer", "do", "else", "fallthrough", "for", "guard", "if", "in", "repeat", "return", "switch", "where", "while",
                "as", "Any", "catch", "false", "is", "nil", "rethrows", "super", "self", "Self", "throw", "throws", "true", "try",
                "async", "await", "actor"
            ]
        case .kotlin:
            return [
                "as", "as?", "break", "class", "continue", "do", "else", "false", "for", "fun", "if", "in", "!in", "interface", "is", "!is", "null", "object", "package", "return", "super", "this", "throw", "true", "try", "typealias", "typeof", "val", "var", "when", "while",
                "by", "catch", "constructor", "delegate", "dynamic", "field", "file", "finally", "get", "import", "init", "param", "property", "receiver", "set", "setparam", "where",
                "actual", "abstract", "annotation", "companion", "const", "crossinline", "data", "enum", "expect", "external", "final", "infix", "inline", "inner", "internal", "lateinit", "noinline", "open", "operator", "out", "override", "private", "protected", "public", "reified", "sealed", "suspend", "tailrec", "vararg"
            ]
        }
    }
    
    /// Built-in types for syntax highlighting.
    var types: [String] {
        switch self {
        case .swift:
            return [
                "Int", "Double", "Float", "Bool", "String", "Array", "Dictionary", "Set", "Character", "Data", "Date", "URL", "UUID", "CGFloat", "CGRect", "CGPoint", "CGSize", "Void", "Error", "Result", "OptionSet"
            ]
        case .kotlin:
            return [
                "Int", "Double", "Float", "Long", "Short", "Byte", "Boolean", "Char", "String", "Array", "List", "Map", "Set", "Any", "Unit", "Nothing"
            ]
        }
    }
    
    /// Infers the language from a file name or path.
    /// - Parameter fileName: The file name (e.g. "script.kts").
    /// - Returns: The matching `Language`, or `.swift` as default.
    static func from(fileName: String) -> Language {
        if fileName.hasSuffix(".kts") {
            return .kotlin
        }
        return .swift
    }
}
