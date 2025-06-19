//
//  AssetItem.swift
//  Cleaner for Xcode
//
//  Created by Baye Wayly on 2025/6/19.
//  Copyright © 2025 Baye. All rights reserved.
//


import Cocoa
import Combine
import Foundation
import SwiftUI

struct AssetItem: Identifiable {
  var id = UUID()
  
  let path: String
  let displayName: String
  let totalSize: UInt64
  let modifyDate: Date
  let groupLabel: String?
}
