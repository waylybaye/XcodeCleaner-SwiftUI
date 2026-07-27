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
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .top) {
        Text(LocalizedStringKey(analysis.group.describe().summary))
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
  }
}
