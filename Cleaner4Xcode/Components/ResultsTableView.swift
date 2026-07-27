//
//  ResultsTableView.swift
//  Cleaner4Xcode
//
//  Created by Baye Wayly on 2019/9/23.
//  Copyright © 2019 Baye. All rights reserved.
//

import SwiftUI

/// 某个分类的扫描结果列表。
///
/// 存在二级分组（`groupedItems` 非空，如 deviceSupport / coreSimulatorCaches）时按分组分 Section 渲染，
/// 否则直接渲染扁平的 `items`。
struct ResultsTableView: View {
  @ObservedObject var analysis: Analysis

  func revealPath(path: String){
    let url = URL.init(fileURLWithPath: path, isDirectory: true)
    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
  }

  func trashPath(path: String, analysis: Analysis){
    let url = URL.init(fileURLWithPath: path, isDirectory: true)
    do {
      try FileManager.default.trashItem(at: url, resultingItemURL: nil)
      analysis.objectWillChange.send()

      if let index = analysis.items.firstIndex(where: { $0.path == path }) {
        // 重新计算 analysi 的总大小
        let item = analysis.items.remove(at: index)
        analysis.totalSize = analysis.items.reduce(0) {
          $0 + $1.totalSize
        }

        // 如果有分组，重新计算分组的大小
        if item.groupLabel != nil {
          if let index = analysis.groupedItems.firstIndex(where: { $0.group == item.groupLabel }) {

//            analysis.groupedItems[index].totalSize -= item.totalSize
            analysis.groupedItems[index].items.removeAll {
              $0.id == item.id
            }

            analysis.groupedItems[index].totalSize = analysis.groupedItems[index].items.reduce(0) {
              $0 + $1.totalSize
            }
          }
        }
      }
    } catch {
      print("\(error.localizedDescription)")
      print("\(error)")
    }
  }

  var body: some View {
    List {
      if analysis.groupedItems.count > 0 {
        ForEach(analysis.groupedItems) { group in
          Section(header:
            Text(group.group)
              .foregroundColor(.secondary)
          ) {
            ForEach(group.items) { item in
              ItemRow(
                item: item,
                onReveal: {
                  self.revealPath(path: item.path)
                },
                onTrash: {
                  self.trashPath(path: item.path, analysis: analysis)
                }
              )
            }
          }
        }

      } else {
        ForEach(analysis.items) { item in
          ItemRow(
            item: item,
            onReveal: {
              self.revealPath(path: item.path)
            },
            onTrash: {
              self.trashPath(path: item.path, analysis: analysis)
            }
          )
        }
      }
    }
  }
}
