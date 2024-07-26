//
//  SwiftyMonaco.swift
//
//
//  Created by Pavel Kasila on 20.03.21.
//

import SwiftUI


public enum CursorBlink {
    // cursorBlinking?: "blink" | "smooth" | "phase" | "expand" | "solid"
    case blink, smooth, phase, expand, solid
}

#if os(macOS)
typealias ViewControllerRepresentable = NSViewControllerRepresentable
#else
typealias ViewControllerRepresentable = UIViewControllerRepresentable
#endif

public struct SwiftyMonaco: ViewControllerRepresentable {
    
    public struct Options {
        var syntax: LanguageSupport?
        var minimap: Bool = true
        var scrollbar: Bool = true
        var smoothCursor: Bool = false
        var cursorBlink: CursorBlink
        var fontSize: Int
        var theme: String
        
        public init(
            syntax: LanguageSupport? = nil,
            minimap: Bool = true,
            scrollbar: Bool = true,
            smoothCursor: Bool = false,
            cursorBlink: CursorBlink = .blink,
            fontSize: Int = 15,
            theme: String = "vs"
        ) {
            self.syntax = syntax
            self.minimap = minimap
            self.scrollbar = scrollbar
            self.smoothCursor = smoothCursor
            self.cursorBlink = cursorBlink
            self.fontSize = fontSize
            self.theme = theme
        }
    }
    
    var text: Binding<String>
    var options: Options
    
    public init(text: Binding<String>, options: Options )
    {
        self.text = text
        self.options = options
    }
    
    #if os(macOS)
    public func makeNSViewController(context: Context) -> MonacoViewController {
        let vc = MonacoViewController()
        vc.delegate = self
        return vc
    }
    
    public func updateNSViewController(_ nsViewController: MonacoViewController, context: Context) {
    }
    #endif
    
    #if os(iOS)
    public func makeUIViewController(context: Context) -> MonacoViewController {
        let vc = MonacoViewController( options: options )
        vc.delegate = context.coordinator
        return vc
    }
    
    public func updateUIViewController(_ uiViewController: MonacoViewController, context: Context) {
        
        uiViewController.updateOptions( options: options )
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(owner: self)
    }
    #endif
    
    
    public class Coordinator : MonacoViewControllerDelegate {
        
        var owner: SwiftyMonaco
        
        init( owner: SwiftyMonaco ) {
            self.owner = owner
        }
                
        public func monacoView(readText controller: MonacoViewController) -> String {
            return owner.text.wrappedValue
        }
        
        public func monacoView(controller: MonacoViewController, textDidChange text: String) {
            owner.text.wrappedValue = text
        }
    }
}
