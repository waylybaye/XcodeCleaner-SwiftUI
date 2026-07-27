//
//  ItemRow.swift
//  Cleaner4Xcode
//
//  Created by Baye Wayly on 2019/9/23.
//  Copyright © 2019 Baye. All rights reserved.
//

import SwiftUI

//let revealIcon = Image(nsImage: NSImage.init(named: NSImage.revealFreestandingTemplateName)!)
//let trashIcon = Image(nsImage: NSImage.init(named: NSImage.stopProgressFreestandingTemplateName)!)

let revealIcon = Image(systemName: "magnifyingglass.circle.fill")
let trashIcon = Image(systemName: "trash.circle.fill")

/// 列表中的单条资源行：展示名称、体积、修改日期，并提供「在访达中显示」与「移入废纸篓」两个操作。
struct ItemRow: View {
  var item: AssetItem
  var onReveal: () -> Void
  var onTrash: () -> Void

  var dateFormatter: DateFormatter {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    return dateFormatter
  }

  var body: some View {
    HStack {
      Text(item.displayName)
        .font(.subheadline)
        .lineLimit(1)

      Spacer()

      Text(humanize(item.totalSize))
        .font(.subheadline)
        .padding(.horizontal)

      Text(dateFormatter.string(from: item.modifyDate))
        .foregroundColor(.secondary)
        .font(Font.subheadline.monospacedDigit())
        .lineLimit(1)

      Button(action: onReveal) {
        revealIcon
      }

      Button(action: onTrash) {
        trashIcon
      }
    }
    .padding(.vertical, 5)
    .padding(.horizontal, 5)
  }
}
