//
//  CategoryDetailView.swift
//  Cleaner4Xcode
//
//  Created by Baye Wayly on 2019/9/23.
//  Copyright © 2019 Baye. All rights reserved.
//

import SwiftUI

/// 选中某个分类后的详情面板：顶部是该分类的本地化说明文案，下方是扫描结果列表。
struct CategoryDetailView: View {
  @ObservedObject var analysis: Analysis

  var minWidth: CGFloat = 500

  var body: some View {
    let (title, summary) = analysis.group.describe()

    return VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .top) {
        Text(LocalizedStringKey(summary))
          .font(.footnote)
          .foregroundColor(.secondary)

        Spacer()
      }
      .padding(.horizontal)
      .padding(.bottom)

      Divider()

      ResultsTableView(analysis: analysis)
        .background(Color(NSColor.underPageBackgroundColor))
    }
    .frame(minWidth: minWidth, maxWidth: .infinity)
    // 分类名显示在窗口标题栏，而非内容区，避免和下方的 summary 说明挤在一起。
    // 体积不重复显示，侧栏里已经有了。
    .navigationTitle(title)
  }
}
