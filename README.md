# SwiftyMonaco

SwiftyMonaco is a wrapper for Monaco Editor from Microsoft.

<img width="1012" alt="image" src="https://user-images.githubusercontent.com/17158860/111897521-60620800-8a31-11eb-9250-ec45b40e56cf.png">

# How to use?
There is a simple example of how to use `SwiftyMonaco`
```swift
import SwiftUI

struct EditorView: View {
    @State var text: String
    
    var body: some View {
        SwiftyMonaco(text: $text)
    }
}
```
**Remember!** You should allow outgoing internet connections in your app before using this library, because Monaco Editor runs inside `WKWebView` and macOS considers it as an outgoing internet connection (`Network -> Outgoing connections (Client)`):

<img width="1512" alt="image" src="https://user-images.githubusercontent.com/17158860/131391125-996cf6de-228b-41f4-b240-722437a62f64.png">

## Language Support
Also you can use `SwiftyMonaco` adding support for new languages using `LanguageSupport` class:
```swift
import SwiftUI

struct EditorView: View {
    @State var text: String
    
    var body: some View {
        SwiftyMonaco(text: $text)
            .language(.mermaid)
    }
}
```
### Default `SyntaxHighlight`s
| `language` | Language |
| --- | --- |
| `swift` | Swift |
| `cpp` | C++ |
| `mermaid` | [Mermaid] |

### How to create your own `LanguageSupport`?
To create your own `LanguageSupport` you can use available initializers:
```swift
// With JS file containing language support registration code
let syntax = LanguageSupport(title: "<my lang>>", fileURL: Bundle.module.url(forResource: "<my lang>", withExtension: "js", subdirectory: "Languages")!)
// With a String containing language support registration code
let syntax = LanguageSupport(title: "My custom language", registrationJSCode: "...")
```
You can create your own syntax at [Monaco Editor Monarch](https://microsoft.github.io/monaco-editor/monarch.html) website. take a look at [Languages Folder](Sources/SwiftyMonaco/Languages for examples. 

# Interface theme detection
`SwiftyMonaco` automatically detects interface theme changes and updates Monaco Editor theme according to it without dropping the current state of the editor.
<img width="1012" alt="image" src="https://user-images.githubusercontent.com/17158860/111897521-60620800-8a31-11eb-9250-ec45b40e56cf.png">
<img width="1012" alt="image" src="https://user-images.githubusercontent.com/17158860/111897745-b7b4a800-8a32-11eb-8783-d21d96b4cc10.png">


[Mermaid]: https://mermaid.js.org