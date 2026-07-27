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
        row(isSelected: data.selectedGroup == nil) {
          data.selectedGroup = nil
        } content: {
          Text("sidebar.welcome")
            .font(.body)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        ForEach(data.groups, id: \.0.group) { pair in
          let analysis = pair.0

          row(isSelected: data.selectedGroup === analysis) {
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
  private func row<Content: View>(
    isSelected: Bool,
    action: @escaping () -> Void,
    @ViewBuilder content: () -> Content
  ) -> some View {
    content()
      .padding(rowPadding)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        RoundedRectangle(cornerRadius: cornerRadius)
          .fill(isSelected ? selectedColor : .clear)
      )
      .contentShape(Rectangle())
      .onTapGesture(perform: action)
  }
}
