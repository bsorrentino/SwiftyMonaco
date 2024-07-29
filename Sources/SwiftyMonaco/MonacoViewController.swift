//
//  MonacoViewController.swift
//  
//
//  Created by Pavel Kasila on 20.03.21.
//

#if os(macOS)
import AppKit
public typealias ViewController = NSViewController
#else
import UIKit
public typealias ViewController = UIViewController
#endif
import WebKit

fileprivate class ScriptQueue {
    
    var _scripts:Array<String> = []
    
    var elements:Array<String> {
        get { _scripts }
    }
    
    var isEmpty:Bool {
        _scripts.isEmpty
    }
    
    func push( _ item: String ) {
        _scripts.append( item )
    }
    
    func pop() -> String? {
        guard  !_scripts.isEmpty else {
            return nil
        }
        
        return _scripts.removeLast()
    }
    
    public func clear() {
        _scripts.removeAll()
    }
    
}


public class MonacoViewController: ViewController, WKUIDelegate, WKNavigationDelegate {
    
    var delegate: MonacoViewControllerDelegate?
    var webView: WKWebView!
    var options: SwiftyMonaco.Options
    private var executionQueue = ScriptQueue()
    
    init( options: SwiftyMonaco.Options ) {
        self.options = options
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateOptions( options newOptions: SwiftyMonaco.Options  ) {
        
        var result: [String: Any] = [:]

        if newOptions.fontSize != options.fontSize {
            result["fontSize"] = newOptions.fontSize
            options.fontSize = newOptions.fontSize
        }
        if newOptions.fontSize != options.fontSize {
            result["fontSize"] = newOptions.fontSize
            options.fontSize = newOptions.fontSize
        }
        if newOptions.lineNumbers != options.lineNumbers {
            result["lineNumbers"] = newOptions.lineNumbers.jsValue
            options.lineNumbers = newOptions.lineNumbers
        }

        if !result.isEmpty {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: result)
                
                if let jsonOptions = String(data: jsonData, encoding: .utf8) {
                    let js = "editor.updateOptions( \(jsonOptions) );"
                    // print( js )
                    evaluateJavascript( js )
                }
            }
            catch {
                print( "ERROR converting options in jason data: \(error)")
            }
        }
    }
    public override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.userContentController.add(UpdateTextScriptHandler(self), name: "updateText")
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        #if os(iOS)
        webView.backgroundColor = .none
        #else
        webView.layer?.backgroundColor = NSColor.clear.cgColor
        #endif
        view = webView
        #if os(macOS)
        DistributedNotificationCenter.default.addObserver(self, selector: #selector(interfaceModeChanged(sender:)), name: NSNotification.Name(rawValue: "AppleInterfaceThemeChangedNotification"), object: nil)
        #endif
    }
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        loadMonaco()
    }
    
    private func loadMonaco() {
        let myURL = Bundle.module.url(forResource: "index", withExtension: "html", subdirectory: "_Resources")
        let myRequest = URLRequest(url: myURL!)
        webView.load(myRequest)
    }
    
    // MARK: - Dark Mode
    private func updateTheme(for userInterfaceStyle: UIUserInterfaceStyle) {
        let theme = detectTheme( for: userInterfaceStyle )
        evaluateJavascript("""
            window.editor.setTheme('\(theme)');
        """)
    }
    
    #if os(macOS)
    @objc private func interfaceModeChanged(sender: NSNotification) {
        updateTheme()
    }
    #else
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateTheme( for: traitCollection.userInterfaceStyle)
        }
        
    }
    #endif
    
    private func detectTheme(for userInterfaceStyle: UIUserInterfaceStyle ) -> String {
        
        let themeToApply = options.theme
        
        #if os(macOS)
        if UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark" {
            return "\(themeToApply)-dark"
        } else {
            return themeToApply
        }
        #else
        switch userInterfaceStyle {
            case .light, .unspecified:
                return themeToApply
            case .dark:
                return "\(themeToApply)-dark"
            @unknown default:
                return themeToApply
        }
        #endif
    }
    
    // MARK: - WKWebView
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        initialize()
        
        while( !executionQueue.isEmpty ) { // evaluate enqueud javascripts
            evaluateJavascript(executionQueue.pop()!)
        }


    }

    private func initialize() {
        // Syntax Highlighting
        let syntax = options.syntax

        var syntaxJS = ""
        var language:String?
         
        if let syntax {
            syntaxJS = """
            \(syntax.registrationJSCode)
            
            editor.addCommand( registerLanguage )
            """
            language = "language: '\(syntax.title)',"
        }
        
        // Minimap
        let minimap = "minimap: { enabled: \(options.minimap) }"
        
        // Scrollbar
        let scrollbar = "scrollbar: { vertical: \"\(options.scrollbar.jsValue)\" }"
        // Smooth Cursor
        let smoothCursor = "cursorSmoothCaretAnimation: \(options.smoothCursor)"
        
        // Cursor Blinking
        let cursorBlink = "cursorBlinking: \"\(options.cursorBlink)\""
        
        // Font size
        let fontSize = "fontSize: \(options.fontSize)"
        
        // Line Numbers
        let lineNumbers = "lineNumbers: \"\(options.lineNumbers.jsValue)\""
        
        let theme = detectTheme( for: traitCollection.userInterfaceStyle )
        
        // Code itself
        let text = self.delegate?.monacoView(readText: self) ?? ""
        let b64 = text.data(using: .utf8)?.base64EncodedString()
        let javascript =
        """
        (() => {
            \(syntaxJS)

            editor.create({
                value: atob('\(b64 ?? "")'),
                automaticLayout: true,
                theme: "\(theme)",
                \(language ?? "")
                \(minimap),
                \(scrollbar),
                \(smoothCursor),
                \(cursorBlink),
                \(fontSize),
                \(lineNumbers)
            });
            //let meta = document.createElement('meta');
            //meta.setAttribute('name', 'viewport');
            //meta.setAttribute('content', 'width=device-width');
            //document.getElementsByTagName('head')[0].appendChild(meta);
            
            return true; })();
        """
        evaluateJavascript(javascript)
        
    }

    private func evaluateJavascript(_ javascript: String) {
        
        guard !webView.isLoading  else {
            executionQueue.push( javascript )
            return;
        }

        webView.evaluateJavaScript(javascript, in: nil, in: WKContentWorld.page) {
          result in
          switch result {
          case .failure(let error):
            #if os(macOS)
            let alert = NSAlert()
            alert.messageText = "Error"
            alert.informativeText = "Something went wrong while evaluating \(error.localizedDescription): \(javascript)"
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
            #else
        
            var errorDescription = error.localizedDescription
            if let err = error as NSError?, let desc = err.userInfo["WKJavaScriptExceptionMessage"] as? String {
                errorDescription = desc
            }
            let alert = UIAlertController(title: "Error",
                                          message: "Something went wrong while evaluating\n\(errorDescription)",
                                          preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            #endif
            break
          case .success(_):
            break
          }
        }
    }
}

// MARK: - Handler

private extension MonacoViewController {
    final class UpdateTextScriptHandler: NSObject, WKScriptMessageHandler {
        private let parent: MonacoViewController

        init(_ parent: MonacoViewController) {
            self.parent = parent
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
            ) {
            guard let encodedText = message.body as? String,
            let data = Data(base64Encoded: encodedText),
            let text = String(data: data, encoding: .utf8) else {
                fatalError("Unexpected message body")
            }

            parent.delegate?.monacoView(controller: parent, textDidChange: text)
        }
    }
}

// MARK: - Delegate

public protocol MonacoViewControllerDelegate {
    func monacoView(readText controller: MonacoViewController) -> String
    func monacoView(controller: MonacoViewController, textDidChange: String)
}
