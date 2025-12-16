//
//  ContentView.swift
//  SwiftCode
//
//  Created by yinlong on 2025/12/16.
//

import SwiftUI

struct ContentView: View {
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: CombineCodeView()) {
                    Text("Combine")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
