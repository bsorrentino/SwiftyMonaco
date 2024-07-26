//
//  SyntaxHighlight.swift
//  
//
//  Created by Pavel Kasila on 20.03.21.
//

import Foundation

public struct LanguageSupport : Equatable {
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.title == rhs.title
    }
    
    public init(title: String, registrationJSCode: String) {
        self.title = title
        self.registrationJSCode = registrationJSCode
    }
    
    public init(title: String, fileURL: URL) {
        self.title = title
        self.registrationJSCode = String(data: try! Data(contentsOf: fileURL), encoding: .utf8)!
    }
    
    public var title: String
    public var registrationJSCode: String
}

public extension LanguageSupport {
    static let swift = LanguageSupport(title: "swift", fileURL: Bundle.module.url(forResource: "swift", withExtension: "js", subdirectory: "Languages")!)
    static let cpp = LanguageSupport(title: "cpp", fileURL: Bundle.module.url(forResource: "cpp", withExtension: "js", subdirectory: "Languages")!)
    static let systemVerilog = LanguageSupport(title: "verilog", fileURL: Bundle.module.url(forResource: "systemVerilog", withExtension: "js", subdirectory: "Languages")!)
    static let mermaid = LanguageSupport(title: "mermaid", fileURL: Bundle.module.url(forResource: "mermaid", withExtension: "js", subdirectory: "Languages")!)
}
