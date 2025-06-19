//
//  AppError.swift
//  Cleaner for Xcode
//
//  Created by Baye Wayly on 2025/6/19.
//  Copyright © 2025 Baye. All rights reserved.
//


import Cocoa
import Combine
import Foundation
import SwiftUI

enum AppError: Error, Identifiable {
  var id: String {
    switch self {
    case .analyzeError(let error):
      return error
    case .invalidDeveloperPath:
      return "invalidDeveloperPath"
    }
  }
  
  case invalidDeveloperPath
  case analyzeError(String)
}
