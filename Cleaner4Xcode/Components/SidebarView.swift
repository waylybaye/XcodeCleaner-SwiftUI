//
//  SidebarView.swift
//  Cleaner4Xcode
//
//  Created by Baye Wayly on 2019/9/23.
//  Copyright © 2019 Baye. All rights reserved.
//

import SwiftUI

/// 左侧分类导航栏：顶部为欢迎项（对应 `selectedGroup == nil`），下方逐条列出各清理分类。
struct SidebarView: View {
  @ObservedObject var data: AppData

  private let selectedColor = Color.pink.opacity(0.2)

  var body: some View {
    let groups = data.groups.map { $0.0 }

    return VStack {
      Text("sidebar.welcome")
        .font(.body)
        .foregroundColor(.primary)
        .multilineTextAlignment(.leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(minWidth: 80, maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .background(self.data.selectedGroup === nil ? selectedColor : nil)
        .cornerRadius(5)
        .padding(.vertical, 10)
        .onTapGesture {
          self.data.selectedGroup = nil
        }

      ForEach(groups, id: \.group) { group in
        AnalysisView(analysis: group)
          .padding(.horizontal, 10)
          .padding(.vertical, 8)
          .contentShape(Rectangle())
          .background(self.data.selectedGroup === group ? selectedColor : nil)
          .cornerRadius(5)
          .onTapGesture {
            if self.data.selectedGroup !== group {
              self.data.selectedGroup = group
            }
          }
      }
    }
    .padding(.horizontal)
//      .listStyle(SidebarListStyle())
    .frame(width: 200)
  }
}
