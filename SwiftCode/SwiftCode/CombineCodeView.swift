//
//  CombineCodeView.swift
//  SwiftCode
//
//  Created by yinlong on 2025/12/16.
//

import Combine
import SwiftUI

struct CombineCodeView: View {
    struct Example: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let build: (_ log: @escaping (String) -> Void) -> AnyCancellable?
    }

    private let examples: [Example] = [
        Example(
            title: "Just + sink",
            subtitle: "最基础的 Publisher 订阅",
            build: { log in
                log("订阅 Just(\"Hello\")")
                return Just("Hello")
                    .sink { value in
                        log("收到 value: \(value)")
                    }
            }
        ),
        Example(
            title: "map",
            subtitle: "把 Int 映射成 String",
            build: { log in
                log("订阅 [1,2,3].publisher.map")
                return [1, 2, 3].publisher
                    .map { $0 * 10 }
                    .sink(
                        receiveCompletion: { completion in
                            log("completion: \(String(describing: completion))")
                        },
                        receiveValue: { value in
                            log("value: \(value)")
                        }
                    )
            }
        ),
        Example(
            title: "filter",
            subtitle: "只保留偶数",
            build: { log in
                log("订阅 [1,2,3,4,5].publisher.filter")
                return [1, 2, 3, 4, 5].publisher
                    .filter { $0 % 2 == 0 }
                    .sink(
                        receiveCompletion: { completion in
                            log("completion: \(String(describing: completion))")
                        },
                        receiveValue: { value in
                            log("value: \(value)")
                        }
                    )
            }
        ),
        Example(
            title: "PassthroughSubject",
            subtitle: "手动 send + cancel",
            build: { log in
                let subject = PassthroughSubject<String, Never>()
                log("创建 subject，开始订阅")
                let c = subject.sink { value in
                    log("sink 收到: \(value)")
                }
                log("subject.send(A)")
                subject.send("A")
                log("subject.send(B)")
                subject.send("B")
                log("cancel 订阅后再 send(C) 不会收到")
                c.cancel()
                subject.send("C")
                return nil
            }
        ),
        Example(
            title: "merge",
            subtitle: "两个 publisher 合并为一个流",
            build: { log in
                let a = [1, 3, 5].publisher
                let b = [2, 4, 6].publisher
                log("订阅 a.merge(with: b)")
                return a.merge(with: b)
                    .sink(
                        receiveCompletion: { completion in
                            log("completion: \(String(describing: completion))")
                        },
                        receiveValue: { value in
                            log("value: \(value)")
                        }
                    )
            }
        ),
        Example(
            title: "combineLatest",
            subtitle: "两个 subject 任一更新就产出最新组合",
            build: { log in
                let s1 = PassthroughSubject<Int, Never>()
                let s2 = PassthroughSubject<String, Never>()
                log("订阅 s1.combineLatest(s2)")
                let c = s1.combineLatest(s2)
                    .sink { (a, b) in
                        log("value: (\(a), \(b))")
                    }
                log("s1.send(1)")
                s1.send(1)
                log("s2.send(A)")
                s2.send("A")
                log("s2.send(B)")
                s2.send("B")
                log("s1.send(2)")
                s1.send(2)
                return c
            }
        ),
        Example(
            title: "debounce",
            subtitle: "短时间内频繁输入只取最后一次（需要 RunLoop）",
            build: { log in
                let subject = PassthroughSubject<String, Never>()
                log("订阅 subject.debounce(for: 0.3s, scheduler: RunLoop.main)")
                let c = subject
                    .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
                    .sink { value in
                        log("debounced value: \(value)")
                    }

                log("模拟快速输入：A -> AB -> ABC")
                Task {
                    subject.send("A")
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                    subject.send("AB")
                    try? await Task.sleep(nanoseconds: 100_000_000) // 再等 0.1s（总 0.2s）
                    subject.send("ABC")
                    try? await Task.sleep(nanoseconds: 400_000_000) // 总 0.6s
                    log("（0.6s 后你应该只看到 ABC 输出）")
                }
                return c
            }
        )
    ]

    var body: some View {
        List(examples) { example in
            NavigationLink {
                CombineExampleDetailView(example: example)
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    Text(example.title)
                        .font(.headline)
                    Text(example.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Combine")
    }
}

private final class CombineExampleRunner: ObservableObject {
    @Published var output: String = ""

    private var cancellable: AnyCancellable?
    private var bag = Set<AnyCancellable>()

    func reset() {
        cancellable?.cancel()
        cancellable = nil
        bag.removeAll()
        output = ""
    }

    func run(_ example: CombineCodeView.Example) {
        reset()
        append("开始运行：\(example.title)")

        let c = example.build { [weak self] line in
            Task { @MainActor in
                self?.append(line)
            }
        }

        // 有的示例直接内部 cancel/同步完成，因此可能返回 nil；也可能返回一个订阅句柄
        cancellable = c

        // 防止某些示例返回的订阅需要长期持有，也支持未来扩展为多个 cancellable
        if let c {
            c.store(in: &bag)
        }
    }

    private func append(_ line: String) {
        if output.isEmpty {
            output = line
        } else {
            output += "\n" + line
        }
    }
}

private struct CombineExampleDetailView: View {
    let example: CombineCodeView.Example
    @StateObject private var runner = CombineExampleRunner()

    var body: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(example.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(example.subtitle)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                Button("运行") {
                    runner.run(example)
                }
                .buttonStyle(.borderedProminent)

                Button("清空") {
                    runner.reset()
                }
                .buttonStyle(.bordered)

                Spacer()
            }

            ScrollView {
                Text(runner.output.isEmpty ? "点击「运行」查看输出…" : runner.output)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(12)
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Spacer(minLength: 0)
        }
        .padding()
        .navigationTitle("用例")
        .navigationBarTitleDisplayMode(.inline)
    }
}
