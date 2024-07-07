//
//  ContentView.swift
//  SwiftyMonacoSample
//
//  Created by bsorrentino on 04/07/24.
//

import SwiftUI
import SwiftyMonaco

struct ContentView: View {
    @State var text: String = ""
    
    var body: some View {
        SwiftyMonaco(text: $text)
            .language(.mermaid)
            .theme("mermaid")
    }
}

#Preview {
    ContentView(text: 
"""
flowchart LR
    Start --> Stop
""")
}
