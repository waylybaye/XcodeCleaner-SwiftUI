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
      .padding(.vertical, 8)
      .padding(.horizontal, 15)
      .background(content: {
        RoundedRectangle(cornerRadius: 15)
          .fill(.secondary.opacity(0.1))
      })
      .padding(.horizontal)
      .padding(.bottom,  12)

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

struct CategoryDetailView_Previews: PreviewProvider {
  /// 往 `Analysis` 里灌入假的扫描结果，避免 Preview 依赖真实文件系统。
  private static func fill(
    _ analysis: Analysis,
    items: [(name: String, size: UInt64, groupLabel: String?)]
  ) {
    for (index, item) in items.enumerated() {
      let assetItem = AssetItem(
        path: "/tmp/preview/\(item.name)",
        displayName: item.name,
        totalSize: item.size,
        modifyDate: Date(timeIntervalSince1970: 1_750_000_000 - Double(index) * 86_400),
        groupLabel: item.groupLabel
      )

      analysis.items.append(assetItem)
      analysis.groupItem(assetItem)
      analysis.totalSize += assetItem.totalSize
    }

    analysis.itemsCount = items.count
    analysis.analyzedCount = items.count
  }

  /// 一份填好数据的 `AppData`，让 Preview 能连同侧栏一起呈现真实的窗口结构。
  private static func stubAppData() -> AppData {
    let data = AppData()

    fill(data.derivedData, items: [
      ("OpenCat-Agent", 16_900_000_000, nil),
      ("ServerCat-Agent", 13_200_000_000, nil),
      ("ModuleCache.noindex", 8_800_000_000, nil),
    ])

    fill(data.deviceSupport, items: [
      ("iPhone16,2 27.0 (24A5370h)", 6_300_000_000, "iOS DeviceSupport"),
      ("iPad13,6 27.0 (24A5355q)", 6_200_000_000, "iOS DeviceSupport"),
      ("Watch6,18 26.2 (23S303)", 2_100_000_000, "watchOS DeviceSupport"),
    ])

    fill(data.simulators, items: [
      ("iPhone 17 (iOS 26.5)", 5_700_000_000, nil),
    ])

    data.isAnalyzed = true
    return data
  }

  /// 把详情页放回 `NavigationSplitView` 里，这样侧栏、标题栏和详情的关系与真实窗口一致。
  private struct PreviewWindow: View {
    @StateObject var data: AppData
    let selected: (AppData) -> Analysis

    var body: some View {
      NavigationSplitView {
        SidebarView(data: data)
          .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 260)

      } detail: {
        CategoryDetailView(analysis: data.selectedGroup ?? selected(data))
      }
      .environmentObject(data)
      .onAppear { data.selectedGroup = selected(data) }
    }
  }

  static var previews: some View {
    // 扁平列表
    PreviewWindow(data: stubAppData()) { $0.derivedData }
      .frame(width: 700, height: 500)
      .previewDisplayName("扁平列表")

    // 二级分组
    PreviewWindow(data: stubAppData()) { $0.deviceSupport }
      .frame(width: 700, height: 500)
      .previewDisplayName("二级分组")

    // 空结果
    PreviewWindow(data: stubAppData()) { $0.archives }
      .frame(width: 700, height: 500)
      .previewDisplayName("空结果")
  }
}
