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
  return "bm:\(path.hasSuffix("/") ? path : path + "/")"
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
  case archives, simulators, iosDeviceSupport, watchOsDeviceSupport, derivedData, previews;
  
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
    }
  }
}

class Analysis: ObservableObject {
  let group: AnalysisGroup
  
  @Published var itemsCount: Int = 0
  @Published var analyzedCount: Int = 0
  
  @Published var totalSize: UInt64 = 0
  @Published var progress: Double = 0
  @Published var items = [AnalysisItem]()
  
  init(group: AnalysisGroup) {
    self.group = group
  }
}

struct AnalysisItem: Identifiable {
  var id: String {
    path
  }
  
  let path: String
  let displayName: String
  let totalSize: UInt64
}

class AppData: ObservableObject {
  @Published var iosDeviceSupport = Analysis(group: .iosDeviceSupport)
  @Published var watchOsDeviceSupport = Analysis(group: .watchOsDeviceSupport)
  @Published var archives = Analysis(group: .archives)
  @Published var simulators = Analysis(group: .simulators)
  @Published var derivedData = Analysis(group: .derivedData)
  @Published var previews = Analysis(group: .previews)
  
  @Published var selectedGroup: Analysis?
  @Published var selectedDeveloperPath: String?
  
  @Published var isAnalyzing: Bool = false
  @Published var totalSize: UInt64 = 0
  @Published var totalCount: Int = 0
  @Published var analyzedCount: Int = 0
  
  var progress: Double {
    return totalCount == 0 ? 0 : Double(analyzedCount) / Double(totalCount)
  }
  
  var groups: [(Analysis, String)] {
    [
      (iosDeviceSupport, "Xcode/iOS DeviceSupport/"),
      (watchOsDeviceSupport, "Xcode/watchOS DeviceSupport/"),
      (derivedData, "Xcode/DerivedData/"),
      (archives, "Xcode/Archives/"),
      (simulators, "CoreSimulator/Devices/"),
      (previews, "Xcode/UserData/Previews/Simulator Devices/"),
    ]
  }
  
  init() {
    if let path = UserDefaults.standard.string(forKey: "selectedDeveloperPath") {
      self.selectedDeveloperPath = path
    }
  }
  
  func recalculateTotal(){
    var totalSize: UInt64 = 0
    
    for (analysis, _) in groups {
      totalSize += analysis.totalSize
    }
    
    self.totalSize = totalSize
  }
  
  func analyze() {
    isAnalyzing = true
    totalSize = 0
    totalCount = 0
    analyzedCount = 0
    
    if let path = self.selectedDeveloperPath {
      for (analysis, subPath) in groups {
        analysis.items = []
        analyzeGroup(analysis: analysis, developerPath: path + subPath)
      }
    }
  }
  
  func analyzeGroup(analysis: Analysis, developerPath path: String){
    do{
      let fm = FileHelper.standard
      let subDirectories = try fm.listDirectory(path, onlyDirectory: true)
      analysis.totalSize = 0
      analysis.itemsCount = subDirectories.count
      analysis.analyzedCount = 0
      analysis.progress = 0
      
      totalCount += analysis.itemsCount
      
      DispatchQueue.global(qos: .userInitiated).async {
        do{
          for var subDirectory in subDirectories{
            if !subDirectory.hasSuffix("/"){
              subDirectory += "/"
            }
            
            let totalSize = try fm.getDirectorySize(subDirectory)
            
            var display = String(subDirectory.split(separator: "/").last!)
            
            if analysis.group == .simulators {
              if let plist = NSDictionary(contentsOf: URL(fileURLWithPath: subDirectory + "device.plist")){
                let name: String = plist["name"] as! String
                //let uuid: String? = plist["UUID"] as? String
                let version = String((plist["runtime"] as! String).split(separator: ".").last!)
                //version = version.replacingOccurrences(of: "-", with: ".")
                display = "\(name) (\(version))"
              }
              
            } else if analysis.group == .previews {
              
            }
            
            DispatchQueue.main.async {
              self.objectWillChange.send()
              
              analysis.items.append(
                AnalysisItem(path: subDirectory, displayName: display, totalSize: totalSize)
              )
              
              analysis.items.sort {
                $0.totalSize > $1.totalSize
              }
              
              analysis.analyzedCount += 1
              analysis.totalSize += totalSize
              analysis.progress = Double(analysis.analyzedCount) / Double(analysis.itemsCount)
              
              self.analyzedCount += 1
              self.totalSize += totalSize
              
              if self.analyzedCount == self.totalCount {
                self.isAnalyzing = false
              }
            }
          }
        } catch {
          print("\(error)")
        }
      }
    } catch {
      print("\(error)")
    }
  }
}
