//
//  DataStore.swift
//  Cleaner4Xcode
//
//  Created by Baye Wayly on 2019/9/23.
//  Copyright © 2019 Baye. All rights reserved.
//
import Combine
import Foundation

enum AnalysisGroup: String{
    case archives, simulators, deviceSupport, derivedData;
    
    func describe() -> (String, String) {
        switch self {
        case .archives:
            return ("Archives", "analysis.archives.summary")
        case .simulators:
            return ("Simulators", "analysis.simulators.summary")
        case .deviceSupport:
            return ("Device Support", "analysis.deviceSupport.summary")
        case .derivedData:
            return ("DerivedData", "analysis.derivedData.summary")
//        default:
//            ""
        }
    }
}

class Analysis: ObservableObject {
    let group: AnalysisGroup
    var totalSize: Int64 = 0
    var progress: Double = 0
    
    init(group: AnalysisGroup) {
        self.group = group
    }
}

struct AnalysisItem {
    let path: URL
    let totalSize: Int64
}

class AppData: ObservableObject {
    @Published var archives = Analysis(group: .archives)
    @Published var simulators = Analysis(group: .simulators)
    @Published var deviceSupport = Analysis(group: .deviceSupport)
    @Published var derivedData = Analysis(group: .derivedData)
}
