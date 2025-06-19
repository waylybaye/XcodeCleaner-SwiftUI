//
//  AssetsCategory.swift
//  Cleaner for Xcode
//
//  Created by Baye Wayly on 2025/6/19.
//  Copyright © 2025 Baye. All rights reserved.
//


import Cocoa
import Combine
import Foundation
import SwiftUI

enum AssetsCategory: String {
  case archives, simulators, deviceSupport, iosDeviceSupport, watchOsDeviceSupport, derivedData, previews, coreSimulatorCaches;
  
  func describe() -> (title: String, summary: String) {
    switch self {
    case .deviceSupport:
      return ("Device Support", "analysis.iOSDeviceSupport.summary")
    case .archives:
      return ("Archives", "analysis.archives.summary")
    case .simulators:
      return ("Simulators", "analysis.simulators.summary")
    case .iosDeviceSupport:
      return ("iOS DeviceSupport", "analysis.iOSDeviceSupport.summary")
    case .derivedData:
      return ("DerivedData", "analysis.derivedData.summary")
    case .watchOsDeviceSupport:
      return ("watchOS DeviceSupport", "analysis.watchOSDeviceSupport.summary")
    case .previews:
      return ("SwiftUI Previews", "analysis.previews.summary")
    case .coreSimulatorCaches:
      return ("Caches", "analysis.simulatorCaches.summary")
    }
  }
}
