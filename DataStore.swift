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


func alert(_ text: String, title: String = "Alert") -> Void {
  let alert = NSAlert()
  alert.messageText = title
  alert.informativeText = text
  alert.alertStyle = .warning
  alert.addButton(withTitle: "OK")
  alert.runModal()
}

func bookmarkKey(_ path: String) -> String{
//  return "bm:\(path.hasSuffix("/") ? path : path + "/")"
  return "bm2:\(path)"
}

func bookmarkKey(url: URL) -> String{
  return bookmarkKey(url.path)
}

func humanize(_ fileSize: UInt64) -> String{
  var humanize = ""
  
  // bytes
  if fileSize < 1023 {
    return String(format: "%luB", CUnsignedLong(fileSize))
  }
  // KB
  var floatSize = Float(fileSize / 1024)
  if floatSize < 1023 {
    return String(format: "%dK", floatSize)
  }
  // MB
  floatSize = floatSize / 1024
  if floatSize < 1023 {
    return String(format: "%.0fM", floatSize)
  }
  // GB
  floatSize = floatSize / 1024
  humanize = String(format: "%.1fG", floatSize)
  
  return humanize
}

enum AnalysisGroup: String{
  case archives, simulators, iosDeviceSupport, watchOsDeviceSupport, derivedData, previews, coreSimulatorCaches;
  
  func describe() -> (title: String, summary: String) {
    switch self {
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
      return ("Caches", "analysis.simulators.caches")
    }
  }
}

class Analysis: ObservableObject {
  let group: AnalysisGroup
  
  @Published var itemsCount: Int = 0
  @Published var analyzedCount: Int = 0
  
  @Published var totalSize: UInt64 = 0
  @Published var items = [AnalysisItem]()
  
  var progress: Double {
    return itemsCount == 0 ? 1 : Double(analyzedCount) / Double(itemsCount)
  }

  init(group: AnalysisGroup) {
    self.group = group
  }
}

struct AnalysisItem: Identifiable {
  var id = UUID()
  
  let path: String
  let displayName: String
  let totalSize: UInt64
  let modifyDate: Date
}

enum AppError: Error, Identifiable {
  var id: String {
    switch self {
    case .analyzeError(let error):
      return error
    case .invalidDeveloperPath:
      return "invalidDeveloeprPath"
    }
  }
  
  case invalidDeveloperPath
  case analyzeError(String)
}


class AppData: ObservableObject {
  @Published var iosDeviceSupport = Analysis(group: .iosDeviceSupport)
  @Published var watchOsDeviceSupport = Analysis(group: .watchOsDeviceSupport)
  @Published var archives = Analysis(group: .archives)
  @Published var simulators = Analysis(group: .simulators)
  @Published var derivedData = Analysis(group: .derivedData)
  @Published var previews = Analysis(group: .previews)
  @Published var coreSimulatorCaches = Analysis(group: .coreSimulatorCaches)

  @Published var selectedGroup: Analysis?
  @Published var selectedDeveloperPath: String?
  
  @Published var isAnalyzed: Bool = false
  @Published var isAnalyzing: Bool = false

  @Published var lastError: AppError?
  
  var totalSize: UInt64 {
    groups.reduce(0) {
      $0 + $1.0.totalSize
    }
  }
  
  var analyzedCount: Int {
    groups.reduce(0) {
      $0 + $1.0.analyzedCount
    }
  }
  
  var totalCount: Int {
    groups.reduce(0) {
      $0 + $1.0.itemsCount
    }
  }

  var progress: Double {
    return totalCount == 0 ? 0 : Double(analyzedCount) / Double(totalCount)
  }
  
  var groups: [(Analysis, String)] {
    [
      (iosDeviceSupport, "Xcode/iOS DeviceSupport/"),
      (watchOsDeviceSupport, "Xcode/watchOS DeviceSupport/"),
      (simulators, "CoreSimulator/Devices/"),
      (previews, "Xcode/UserData/Previews/Simulator Devices/"),
      (derivedData, "Xcode/DerivedData/"),
      (archives, "Xcode/Archives/"),
      (coreSimulatorCaches, "CoreSimulator/Caches/dyld/"),
    ]
  }
  
  init() {
    if let path = UserDefaults.standard.string(forKey: "selectedDeveloperPath") {
      self.selectedDeveloperPath = path
    }
  }

  func startAnalyze() {
    let fh = FileHelper.standard
    
    if let path = selectedDeveloperPath {
      fh.authorize(path, callback: self.authorized)
      return
    }
    
    let defaultPath = fh.getDefaultXcodePath()
    self.chooseLocation(defaultPath: defaultPath)
  }
  
  func chooseLocation(defaultPath: String? = nil) {
    let fh = FileHelper.standard
    fh.authorize(defaultPath, callback: self.authorized)
  }
  
  private func authorized(at authorizedPath: String) {
    let fh = FileHelper.standard
    
    if !fh.validateDeveloperPath(path: authorizedPath) {
      self.lastError = .invalidDeveloperPath
      return
    }
    
    UserDefaults.standard.set(authorizedPath, forKey: "selectedDeveloperPath")
    self.selectedDeveloperPath = authorizedPath
    self.analyze()
  }

  private func analyze() {
    isAnalyzed = false
    isAnalyzing = true

    let fm = FileManager.default
    
    if let path = self.selectedDeveloperPath {
      for (analysis, subPath) in groups {
        
        let fullPath = path.joinPath(subPath)
        var isDirectory = ObjCBool(true)
        
        guard fm.fileExists(atPath: fullPath, isDirectory: &isDirectory) && isDirectory.boolValue else {
          continue
        }
        
        analysis.items = []
        
        do {
          try analyzeGroup(analysis: analysis, developerPath: fullPath)
        } catch let error {
          self.lastError = .analyzeError(error.localizedDescription)
        }
      }
    }
  }
  
  func analyzeGroup(analysis: Analysis, developerPath path: String) throws {
    let fm = FileHelper.standard
    var subDirectories = [String]()
    
    subDirectories = try fm.listDirectory(path, onlyDirectory: true)

    analysis.totalSize = 0
    analysis.itemsCount = subDirectories.count
    analysis.analyzedCount = 0

    DispatchQueue.global(qos: .userInitiated).async {
      for var subDirectory in subDirectories{
        if !subDirectory.hasSuffix("/"){
          subDirectory += "/"
        }
        
        guard let totalSize = try? fm.getDirectorySize(subDirectory) else {
          DispatchQueue.main.async {
            analysis.analyzedCount += 1
          }
          
          continue
        }
        
        var display = String(subDirectory.split(separator: "/").last!)
        
        if analysis.group == .simulators || analysis.group == .previews {
          if let plist = NSDictionary(contentsOf: URL(fileURLWithPath: subDirectory + "device.plist")){
            let name: String = plist["name"] as! String
            var version = String((plist["runtime"] as! String).split(separator: ".").last!)
            version = version.replacingOccurrences(of: "OS-", with: "OS ").replacingOccurrences(of: "-", with: ".")
            display = "\(name) (\(version))"
          }
        }
        
        DispatchQueue.main.async {
          self.objectWillChange.send()
          
          analysis.items.append(
            AnalysisItem(
              path: subDirectory, displayName: display,
              totalSize: totalSize,
              modifyDate: (try? fm.getDirectoryUpdateDate(subDirectory)) ?? Date(timeIntervalSince1970: 0)
              )
          )
          
          analysis.items.sort {
            $0.totalSize > $1.totalSize
          }
          
          analysis.analyzedCount += 1
          analysis.totalSize += totalSize
        }
      }
      
      DispatchQueue.main.async {
        if self.analyzedCount == self.totalCount {
          self.isAnalyzing = false
          self.isAnalyzed = true
        }
      }
    }
  }
}
