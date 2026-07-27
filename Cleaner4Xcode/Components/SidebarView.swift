//
//  SidebarView.swift
//  Cleaner4Xcode
//
//  Created by Baye Wayly on 2019/9/23.
//  Copyright © 2019 Baye. All rights reserved.
//

import SwiftUI

/// 左侧分类导航栏：顶部为欢迎项（对应 `selectedGroup == nil`），下方逐条列出各清理分类。
///
/// 不使用 `List`，改为自绘行以便完全控制样式；关键是整体要填满侧栏列
/// （`maxWidth/maxHeight: .infinity` + 顶对齐），否则在 macOS 26 的内缩侧栏里
/// 会缩成一块悬浮卡片。
struct SidebarView: View {
  @ObservedObject var data: AppData

  /// 行间距与行内留白，集中在这里方便调整。
  private let rowSpacing: CGFloat = 6
  private let rowPadding = EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10)

  private let selectedColor = Color.pink.opacity(0.15)
  private let cornerRadius: CGFloat = 8

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: rowSpacing) {
        row(isSelected: data.selectedGroup == nil, shortcutIndex: 1) {
          data.selectedGroup = nil
        } content: {
          Text("sidebar.welcome")
            .font(.body)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        ForEach(Array(data.groups.enumerated()), id: \.element.0.group) { index, pair in
          let analysis = pair.0

          // 欢迎项占用 ⌘1，分类从 ⌘2 开始。
          row(isSelected: data.selectedGroup === analysis, shortcutIndex: index + 2) {
            if data.selectedGroup !== analysis {
              data.selectedGroup = analysis
            }
          } content: {
            AnalysisView(analysis: analysis)
          }
        }
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 10)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
  }

  /// 统一的行容器：负责留白、选中背景与点击区域。
  ///
  /// 用 `Button` 而非 `onTapGesture`，这样可以直接挂 `.keyboardShortcut`，
  /// 让 ⌘1~⌘9 与鼠标点击走完全相同的一条选中逻辑。
  /// `shortcutIndex` 超出 1...9 时不绑定快捷键（预留分类继续增加的情况）。
  private func row<Content: View>(
    isSelected: Bool,
    shortcutIndex: Int,
    action: @escaping () -> Void,
    @ViewBuilder content: () -> Content
  ) -> some View {
    Button(action: action) {
      content()
        .padding(rowPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
          RoundedRectangle(cornerRadius: cornerRadius)
            .fill(isSelected ? selectedColor : .clear)
        )
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .modifier(NumberKeyShortcut(index: shortcutIndex))
  }
}

/// 把序号映射为 ⌘<数字> 快捷键；序号不在 1...9 内则原样返回视图。
private struct NumberKeyShortcut: ViewModifier {
  let index: Int

  func body(content: Content) -> some View {
    if let character = (1...9).contains(index) ? Character("\(index)") : nil {
      content.keyboardShortcut(KeyEquivalent(character), modifiers: .command)
    } else {
      content
    }
  }
}
