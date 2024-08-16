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
import Combine
import os

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

let log = Logger(subsystem: "org.bsc.swiftymonaco", category: "webview" )

extension UIView {
    
    func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }
}

class MonacoWebView : WKWebView {
    var myAccessoryView : UIView?
    private var executionQueue = ScriptQueue()
    
    override init(frame: CGRect,configuration : WKWebViewConfiguration) {
        super.init(frame: frame, configuration:configuration)
        #if os(iOS)
        self.backgroundColor = .none
        #else
        self.layer?.backgroundColor = NSColor.clear.cgColor
        #endif

        let stackView = UIStackView( frame: CGRect(x: 0, y: 0, width: 0, height: 20) )
//        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 50, bottom: 0, right: 10)
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = 10
//        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(createButtonSelectAll())
        stackView.addArrangedSubview(createHSpacer())
        myAccessoryView = stackView
        

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var inputAccessoryView: UIView? {
         return myAccessoryView
    }
    
    func loadMonaco() {
        let myURL = Bundle.module.url(forResource: "index", withExtension: "html", subdirectory: "_Resources")
        let myRequest = URLRequest(url: myURL!)
        self.load(myRequest)
    }

    func initMonaco( text: String, options: SwiftyMonaco.Options, for userInterfaceStyle: UIUserInterfaceStyle ) -> Void {
        
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
        
        // [Options](https://microsoft.github.io/monaco-editor/typedoc/interfaces/editor.IEditorOptions.html)
        let monacoOptions = """
        theme: "\(detectTheme( for: userInterfaceStyle, defaultTheme: options.theme ))",
        minimap: { enabled: \(options.minimap) },
        scrollbar: { vertical: "\(options.scrollbar.jsValue)" },
        cursorSmoothCaretAnimation: \(options.smoothCursor),
        cursorBlinking: "\(options.cursorBlink)",
        fontSize: \(options.fontSize),
        lineNumbers: "\(options.lineNumbers.jsValue)",
        contextmenu: false,
        dragAndDrop: false,
        glyphMargin: false,
        automaticLayout: true,
        folding: false,
        showFoldingControls: "never"
        """
        

        // Code itself
        let b64 = text.data(using: .utf8)?.base64EncodedString()
        let javascript =
        """
        (() => {
            \(syntaxJS)

            editor.create({
                value: atob('\(b64 ?? "")'),
                \(language ?? "")
                \(monacoOptions)
            });
            //let meta = document.createElement('meta');
            //meta.setAttribute('name', 'viewport');
            //meta.setAttribute('content', 'width=device-width');
            //document.getElementsByTagName('head')[0].appendChild(meta);
            
            return true; })();
        """
        evaluateJavascript(javascript)

        // evaluate enqueud javascripts
        while( !executionQueue.isEmpty ) {
            evaluateJavascript(executionQueue.pop()!)
        }
    }
    

    private func evaluateJavascript(_ javascript: String ) {
        
        guard !self.isLoading  else {
            executionQueue.push( javascript )
            return;
        }

        self.evaluateJavaScript(javascript, in: nil, in: WKContentWorld.page) { result in
        switch result {
        case .failure(let error):
            var errorDescription = error.localizedDescription
            #if os(macOS)
            let alert = NSAlert()
            alert.messageText = "Error"
            alert.informativeText = "Something went wrong while evaluating javascript\(errorDescription): \(javascript)"
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
            #else
            if let err = error as NSError?, let desc = err.userInfo["WKJavaScriptExceptionMessage"] as? String {
              errorDescription = desc
            }

            log.error( "Something went wrong while evaluating javascript\n\(errorDescription)" )

            guard let controller = self.findViewController() else {
                return
            }
            let alert = UIAlertController(title: "Error",
                                          message: "Something went wrong while evaluating javascript\n\(errorDescription)",
                                          preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default, handler: nil))
            controller.present(alert, animated: true, completion: nil)
            #endif
            break
          case .success(_):
            break
          }
        }
    }

    
    private func createStandardButtonConfiguration() -> UIButton.Configuration {
        var configuration = UIButton.Configuration.plain()
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 10, trailing: 0)
        configuration.background.cornerRadius = 2
        return configuration
    }

    private func createButtonSelectAll() -> UIButton {
        let button = UIButton( configuration: createStandardButtonConfiguration(), primaryAction: nil)
        
        button.setTitle("select all", for: .normal)
//        buttonSelectAll.backgroundColor = .red
        button.addTarget(self, action: #selector(monacoSelectAll(_:)), for: .touchUpInside)
        return button
    }
    
    private func createHSpacer() -> UIView {
        let spacerView = UIView()
        spacerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
//        spacerView.setContentHuggingPriority(.defaultLow, for: .vertical)
        spacerView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
//        spacerView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return spacerView
    }

}

extension MonacoWebView { // methods
    
    @objc func monacoSelectAll(_ sender: UIButton?) {
        self.evaluateJavascript("window.editor.selectAll();")
    }
    
    func setTheme( _ theme: String ) {
        evaluateJavascript("""
            window.editor.setTheme('\(theme)');
        """)

    }
   
    private func detectTheme( for userInterfaceStyle: UIUserInterfaceStyle, defaultTheme: String ) -> String {
        
        #if os(macOS)
        if UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark" {
            return "\(defaultTheme)-dark"
        } else {
            return defaultTheme
        }
        #else
        switch userInterfaceStyle {
            case .light, .unspecified:
                return defaultTheme
            case .dark:
                return "\(defaultTheme)-dark"
            @unknown default:
                return defaultTheme
        }
        #endif
    }

    func setTheme( _ theme: String, for userInterfaceStyle: UIUserInterfaceStyle) {
        setTheme( detectTheme( for: userInterfaceStyle, defaultTheme: theme ) )
    }
    
    func updateOptions( _ options: [String:Any] ) {
        guard  !options.isEmpty  else {
            return
        }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: options)
            
            if let jsonOptions = String(data: jsonData, encoding: .utf8) {
                let js = "editor.updateOptions( \(jsonOptions) );"
                evaluateJavascript( js )
            }
        }
        catch {
            log.error( "ERROR converting options in jason data: \(error)")
        }
 
    }
    

}


public class MonacoViewController: ViewController, WKUIDelegate, WKNavigationDelegate {
    
    var delegate: MonacoViewControllerDelegate?
    var webView: MonacoWebView!
    var options: SwiftyMonaco.Options
    
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

        webView.updateOptions(result)
    }
    
    
    public override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.userContentController.add(UpdateTextScriptHandler(self), name: "updateText")
        webView = MonacoWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        view = webView
        #if os(macOS)
        DistributedNotificationCenter.default.addObserver(self, selector: #selector(interfaceModeChanged(sender:)), name: NSNotification.Name(rawValue: "AppleInterfaceThemeChangedNotification"), object: nil)
        #endif
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.loadMonaco()
        
    }
    
//    deinit {
//    }
    
    #if os(macOS)
    @objc private func interfaceModeChanged(sender: NSNotification) {
        updateTheme()
    }
    #else
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            webView.setTheme( options.theme, for: traitCollection.userInterfaceStyle )
        }
        
    }
    #endif
    
    
    // MARK: - WKWebView
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        self.webView.initMonaco( text: self.delegate?.monacoView(readText: self) ?? "",
                                 options: options,
                                 for: traitCollection.userInterfaceStyle  )

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
