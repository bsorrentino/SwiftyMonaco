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
    
    var options:SwiftyMonaco.Options {
        SwiftyMonaco.Options(
            syntax: .mermaid,
            fontSize: fontSize,
            theme: "mermaid" )
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Divider()
                
                Divider()
                SwiftyMonaco(text: $text,
                             options: options )
                Divider()
                Text( text )
            }
            .toolbar{
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button {
                        fontSize += 1
                    } label: {
                        Text("font +")
                    }
                    Button {
                        fontSize -= 1
                    } label: {
                        Text("font -")
                    }
                }
            }
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
