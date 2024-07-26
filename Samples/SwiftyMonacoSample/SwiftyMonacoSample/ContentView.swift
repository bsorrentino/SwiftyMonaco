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
    @State var fontSize:Int = 20
    
    var body: some View {
        VStack {
            Divider()
            Button {
                fontSize += 1
            } label: {
                Text("font")
            }
            Divider()
            SwiftyMonaco(text: $text,
                         options: SwiftyMonaco.Options(syntax: .mermaid,
                                                       fontSize: fontSize,
                                                       theme: "mermaid" )
                        )
            Divider()
            Text( text )
        }
    }
}

#Preview {
    ContentView(text: 
"""
flowchart LR
    Start --> Stop
""")
}
