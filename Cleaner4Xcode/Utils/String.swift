//
//  String.swift
//  Cleaner for Xcode
//
//  Created by Baye Wayly on 2025/6/19.
//  Copyright © 2025 Baye. All rights reserved.
//


import Cocoa
import Foundation

extension String {
  func joinPath(_ subPath: String) -> String {
    if self.hasSuffix("/") {
      return self + subPath
    }
    return self + "/" + subPath
  }
}
