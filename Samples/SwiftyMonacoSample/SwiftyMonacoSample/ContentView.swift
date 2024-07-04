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
    }
}

#Preview {
    ContentView(text: "test")
}
