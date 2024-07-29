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
    
    struct OptionValue<T : Equatable> : Equatable {
        static func == (lhs: SwiftyMonaco.OptionValue<T>, rhs: SwiftyMonaco.OptionValue<T>) -> Bool {
            lhs.value == rhs.value
        }
        
        var value: T
        private var _jsValue:((T) -> String)
        
        var jsValue:String {
            _jsValue( value )
        }
        
        init( _ value: T, jsValue: @escaping ((T) -> String)) {
            self.value = value
            self._jsValue = jsValue
        }
    }
    public struct Options {
        var syntax: LanguageSupport?
        var minimap: Bool
        var scrollbar: OptionValue<Bool>
        var smoothCursor: Bool
        var cursorBlink: CursorBlink
        var fontSize: Int
        var theme: String
        var lineNumbers: OptionValue<Bool>
        
        public init(
            syntax: LanguageSupport? = nil,
            minimap: Bool = true,
            scrollbar: Bool = true,
            smoothCursor: Bool = false,
            cursorBlink: CursorBlink = .blink,
            fontSize: Int = 15,
            theme: String = "vs",
            lineNumbers: Bool
        ) {
            self.syntax = syntax
            self.minimap = minimap
            self.scrollbar = OptionValue<Bool>( scrollbar, jsValue: {
                $0 ? "visible" : "hidden"
            })
            self.smoothCursor = smoothCursor
            self.cursorBlink = cursorBlink
            self.fontSize = fontSize
            self.theme = theme
            self.lineNumbers = OptionValue<Bool>( lineNumbers, jsValue: {
                $0 ? "on" : "off"
            })
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
