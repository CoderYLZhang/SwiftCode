//
//  ContentView.swift
//  SwiftCode
//
//  Created by yinlong on 2025/12/16.
//

import SwiftUI

struct ContentView: View {
    /// SwiftUI 推荐使用 NavigationStack（iOS16+）做声明式导航
    @State private var path: [Route] = []

    /// 数据驱动的菜单模型：title + 点击回调（你说的“闭包记录下来”）
    struct MenuItem: Identifiable {
        let id = UUID()
        let title: String
        let onSelected: () -> Void
    }

    /// 用“路由”来描述要去哪个页面（可 Hashable，方便 NavigationStack 管理）
    enum Route: Hashable {
        case combine
    }

    /// 路由注册表：集中维护「路由 -> 页面」，避免在 `body` 里写很长的 switch
    private let destinations: [Route: () -> AnyView] = [
        .combine: { AnyView(CombineCodeView()) }
    ]

    private var items: [MenuItem] {
        [
            MenuItem(title: "Combine") {
                push(.combine)
            }
        ]
    }

    var body: some View {
        NavigationStack(path: $path) {
            List(items) { item in
                Button {
                    item.onSelected()
                } label: {
                    Text(item.title)
                }
            }
            .navigationTitle("SwiftCode")
            .navigationDestination(for: Route.self) { route in
                if let closure = destinations[route] {
                    closure()
                } else {
                    AnyView(EmptyView())
                }
            }
        }
    }

    private func push(_ route: Route) {
        path.append(route)
    }
}

#Preview {
    ContentView()
}
