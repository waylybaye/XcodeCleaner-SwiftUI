//
//  DataStore.swift
//  Cleaner4Xcode
//
//  Created by Baye Wayly on 2019/9/23.
//  Copyright © 2019 Baye. All rights reserved.
//
import Cocoa
import Combine
import Foundation
import SwiftUI


let XCODE_NOT_FOUND = NSLocalizedString("xcode_not_found_title", comment: "Shows when xcode not found")
let XCODE_NOT_FOUND_MSG = NSLocalizedString("xcode_not_found_body", comment:"No Xcode installation found in selected directory, it's usually at HOME/Library/Developer.")
let CHOOSE_DEVELOPER_DIR = NSLocalizedString("developer_auth_title", comment: "")
let CHOOSE_DEVELOPER_DIR_TIP = NSLocalizedString("developer_auth_tip", comment: "")
let XCODE_CHOOSE_LOCATION = NSLocalizedString("welcome.button_change_location", comment: "")


class Analysis: ObservableObject {
  let group: AssetsCategory
  
  @Published var itemsCount: Int = 0
  @Published var analyzedCount: Int = 0
  
  @Published var totalSize: UInt64 = 0
  @Published var items = [AssetItem]()
  @Published var groupedItems = [AnalysisItemGroup]()

  var progress: Double {
    return itemsCount == 0 ? 1 : Double(analyzedCount) / Double(itemsCount)
  }

  init(group: AssetsCategory) {
    self.group = group
  }
  
  func groupItem(_ item: AssetItem) {
    if let groupLabel = item.groupLabel {
      if let first = groupedItems.firstIndex(where: {$0.group == groupLabel}) {
        groupedItems[first].items.append(item)
        
      } else {
        groupedItems.append(AnalysisItemGroup(group: groupLabel, totalSize: item.totalSize, items: [item]))
      }
    }
  }
}

struct AnalysisItemGroup: Identifiable {
  var group: String
  
  var id: String {
    group
  }
  
  var totalSize: UInt64
  var items: [AssetItem]
}



