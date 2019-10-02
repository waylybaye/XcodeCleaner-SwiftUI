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


func alert(_ text: String, title: String = "Alert") -> Void {
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = text
    alert.alertStyle = .warning
    alert.addButton(withTitle: "OK")
    alert.runModal()
}

func bookmarkKey(_ path: String) -> String{
    return "bookmark:\(path.hasSuffix("/") ? path : path + "/")"
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
    case archives, simulators, iosDeviceSupport, watchOsDeviceSupport, derivedData;
    
    func describe() -> (String, String) {
        switch self {
        case .archives:
            return ("Archives", "analysis.archives.summary")
        case .simulators:
            return ("Simulators", "analysis.simulators.summary")
        case .iosDeviceSupport:
            return ("iOS DeviceSupport", "analysis.deviceSupport.summary")
        case .derivedData:
            return ("DerivedData", "analysis.derivedData.summary")
            //        default:
            //            ""
        case .watchOsDeviceSupport:
            return ("watchOS DeviceSupport", "analysis.derivedData.summary")
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
    @Published var activeGroup: AnalysisGroup?
    
    var chosenDeveloperPath: String?
    
    func start(developerPath: URL){
        
    }
    

    func refresh(){
        if chosenDeveloperPath == nil{
            return
        }
        
        let xcodePath = chosenDeveloperPath! + "Xcode/";
        self.calculateSubDirectory(xcodePath + "iOS DeviceSupport/", .iosDeviceSupport);
        self.calculateSubDirectory(xcodePath + "DerivedData/", .derivedData);
        self.calculateSubDirectory(xcodePath + "Archives/", .archives);
        self.calculateSubDirectory(chosenDeveloperPath! + "CoreSimulator/Devices/", .simulators);
    }
    
    func updateProgress(){
//        DispatchQueue.main.async {
//            for (key, tuple) in self.progress{
//                var view: GroupSummaryView = self.groupDeviceSupport
//                var totalSize: UInt64 = 0;
//
//                switch key{
//                case .deviceSupport:
//                    view = self.groupDeviceSupport
//                case .deviredData:
//                    view = self.groupDeviredData
//                case .simulators:
//                    view = self.groupSimulators
//                case .archives:
//                    view = self.groupArchives
//                }
//
//                if tuple.finished == tuple.total{
//                    view.progressBar.isHidden = true
//                } else {
//                    view.progressBar.startAnimation(view)
//                    view.progressBar.isHidden = false
//                    view.progressBar.doubleValue = Double(tuple.finished * 100 / (tuple.total > 0 ? tuple.total : 1))
//                }
//
//                for tuple in self.calculatedData[key]!{
//                    totalSize += tuple.size;
//                }
//
//                view.totalSizeField.stringValue = humanize(totalSize)
//            }
//
//            if !self.currentPanel.isEmpty{
//                self.tableView.reloadData()
//            }
//        }
    }
    
    func calculateSubDirectory(_ path : String, _ key: AnalysisGroup){
//        do{
//            let subDirectories = try XCFileUtils.listDirectory(path, onlyDirectory: true)
//            progress[key] = (0, subDirectories.count)
//            calculatedTotal[key] = 0
//            calculatedData[key] = [(String, String, UInt64)]()
//
//            DispatchQueue.global(qos: .userInitiated).async {
//                do{
//                    for var subDirectory in subDirectories{
//                        print("calculate subD", subDirectory)
//                        if !subDirectory.hasSuffix("/"){
//                            subDirectory += "/"
//                        }
//
//                        let totalSize = try XCFileUtils.getDirectorySize(subDirectory)
//
//                        var display = String(subDirectory.split(separator: "/").last!)
//
//                        if key == GroupKey.simulators{
//                            if let plist = NSDictionary(contentsOf: URL(fileURLWithPath: subDirectory + "device.plist")){
//                                let name: String? = plist["name"] as! String
//                                let uuid: String? = plist["UUID"] as? String
//                                var version = String((plist["runtime"] as! String).split(separator: ".").last!)
//                                //                                version = version.replacingOccurrences(of: "-", with: ".")
//                                display = "\(name ?? uuid ?? "") (\(version))"
//
//                            }
//                        }
//
//                        self.calculatedData[key]!.append((subDirectory, display, totalSize))
//
//                        self.calculatedData[key]!.sort(by: {
//                            $0.size > $1.size
//                        })
//
//                        self.progress[key]?.finished += 1
//                        self.calculatedTotal[key] = self.calculatedTotal[key]! + totalSize
//
//                        self.updateProgress()
//                    }
//                } catch {
//                    print("\(error)")
//                }
//            }
//        } catch {
//            print("\(error)")
//        }
    }
    
 
}
