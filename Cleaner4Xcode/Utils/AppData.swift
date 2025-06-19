//
//  AppData.swift
//  Cleaner for Xcode
//
//  Created by Baye Wayly on 2025/6/19.
//  Copyright © 2025 Baye. All rights reserved.
//


import Cocoa
import Combine
import Foundation
import SwiftUI

class AppData: ObservableObject {
  @Published var deviceSupport = Analysis(group: .deviceSupport)

//  @Published var iosDeviceSupport = Analysis(group: .iosDeviceSupport)
//  @Published var watchOsDeviceSupport = Analysis(group: .watchOsDeviceSupport)
  
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
//      (iosDeviceSupport, "Xcode/iOS DeviceSupport/"),
//      (watchOsDeviceSupport, "Xcode/watchOS DeviceSupport/"),
      (deviceSupport, "Xcode/"),
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
  
  func analyzeGroup(analysis: Analysis, developerPath path: String, depth: Int = 0) throws {
    let fm = FileHelper.standard
    var subDirectories = [String]()
    
    subDirectories = try fm.listDirectory(path, onlyDirectory: true)

    if analysis.group == .coreSimulatorCaches {
      subDirectories = subDirectories.flatMap { parentPath in
        (try? fm.listDirectory(parentPath, onlyDirectory: true)) ?? []
      }
      
    //} else if analysis.group == .archives {
    //  subDirectories = subDirectories.flatMap { parentPath in
    //    (try? fm.listDirectory(parentPath, onlyDirectory: true)) ?? []
    //  }
      
    } else if analysis.group == .deviceSupport {
      subDirectories = [
        path.joinPath("iOS DeviceSupport"),
        path.joinPath("watchOS DeviceSupport"),
        path.joinPath("tvOS DeviceSupport"),
        path.joinPath("macOS DeviceSupport"),
        path.joinPath("nonExist DeviceSupport"),
      ]
      
      subDirectories = subDirectories.flatMap { parentPath in
        (try? fm.listDirectory(parentPath, onlyDirectory: false)) ?? []
      }
    }
    
    analysis.totalSize = 0
    analysis.itemsCount = subDirectories.count
    analysis.analyzedCount = 0
    analysis.items = []
    analysis.groupedItems = []
    
    DispatchQueue.global(qos: .userInitiated).async {
      for subDirectory in subDirectories{
        guard let totalSize = try? fm.getDirectorySize(subDirectory) else {
          DispatchQueue.main.async {
            analysis.analyzedCount += 1
          }
          
          continue
        }
        
        var display = String(subDirectory.split(separator: "/").last!)
        
        if analysis.group == .simulators || analysis.group == .previews {
          if let plist = NSDictionary(contentsOf: URL(fileURLWithPath: subDirectory.joinPath("device.plist"))){
            let name: String = plist["name"] as! String
            var version = String((plist["runtime"] as! String).split(separator: ".").last!)
            version = version.replacingOccurrences(of: "OS-", with: "OS ").replacingOccurrences(of: "-", with: ".")
            display = "\(name) (\(version))"
          }
        }
        
        DispatchQueue.main.async {
          self.objectWillChange.send()
          var groupLabel: String? = nil
          
          var names = subDirectory.split(separator: "/")
          names.removeLast()
          let parentDirName = String(names.last!)
          
          switch analysis.group {
          case .deviceSupport:
            groupLabel = parentDirName

          case .coreSimulatorCaches:
            groupLabel = parentDirName
            
          //case .archives:
          //  if let plist = NSDictionary(contentsOf: URL(fileURLWithPath: subDirectory.joinPath("Info.plist"))){
          //    let name: String = plist["Name"] as! String
          //    groupLabel = name
          //    display = plist["ArchiveVersion"] as? String ?? "unknown"
          //  }
            
          default:
            groupLabel = nil
          }
          
          let item = AssetItem(
            path: subDirectory,
            displayName: display,
            totalSize: totalSize,
            modifyDate: (try? fm.getDirectoryUpdateDate(subDirectory)) ?? Date(timeIntervalSince1970: 0),
            groupLabel: groupLabel
          )
          
          analysis.items.append(item)
          analysis.groupItem(item)
          
          analysis.items.sort {
            $0.totalSize > $1.totalSize
          }
          
          analysis.analyzedCount += 1
          analysis.totalSize += totalSize
        }
      }
      
      DispatchQueue.main.async {
        analysis.groupedItems.sort {
          $0.totalSize > $1.totalSize
        }
        
        for index in analysis.groupedItems.indices {
          analysis.groupedItems[index].items.sort {
            $0.totalSize > $1.totalSize
          }
        }
        
        if self.analyzedCount == self.totalCount {
          self.isAnalyzing = false
          self.isAnalyzed = true
        }
      }
    }
  }
}
