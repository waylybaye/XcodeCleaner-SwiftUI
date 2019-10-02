//
//  MainWindow.swift
//  Cleaner4Xcode
//
//  Created by Baye Wayly on 2019/9/23.
//  Copyright © 2019 Baye. All rights reserved.
//

import SwiftUI

struct ProgressBar: View {
    var progress: CGFloat
    let height: CGFloat = 8
    
    var body: some View {
        GeometryReader { proxy in
            ZStack{
                Path{ path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addRoundedRect(
                        in: .init(x: 0, y: 0, width: proxy.size.width, height: self.height),
                        cornerSize: .init(width: self.height / 2 , height: self.height / 2),
                        style: .circular)
                }
                .fill(
                    Color.gray
                )
                
                Path{ path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addRoundedRect(
                        in: .init(x: 0, y: 0, width: proxy.size.width * self.progress, height: self.height),
                        cornerSize: .init(width: self.height / 2, height: self.height / 2),
                        style: .circular)
                }
                .fill(
                    LinearGradient(
                        gradient: .init(colors: [Color.red, Color.orange, Color.red]),
                        startPoint: .init(x: 0, y: 0),
                        endPoint: .init(x: 1, y: 1)
                    )
                )
            }.animation(.easeInOut)
        }
    }
}


struct AnalysisView: View {
    @EnvironmentObject var appData: AppData
    @ObservedObject var analysis: Analysis
    
    var body: some View {
        let (title, summary) = analysis.group.describe()
        
        return VStack(alignment: .leading, spacing: 10) {
            HStack{
                VStack(alignment: .leading){
                    Text(title).font(.headline)
                        .foregroundColor(.primary)
                    
                    if appData.activeGroup == nil || analysis.group == appData.activeGroup {
                        Text(summary).font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text(humanize(analysis.totalSize))
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.red)
            }
            
            if analysis.progress > 0 && analysis.progress < 1{
                ProgressBar(progress: CGFloat(analysis.progress))
                    .frame(height: 6)
                    .frame(maxWidth: .infinity)
            } else {
                EmptyView()
                    .frame(height: 6)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        //        .background(Color(red: 1.0, green: 0, blue: 1.0, opacity: 0))
        //        .background(Color.yellow)
        //            .background(Color(UIColor.red))
    }
}

struct WelcomeView: View {
    var body: some View {
        Text("Welcome")
    }
}


struct MainWindow: View {
    var data = AppData()
    
    func onAppear(){
        let fm = FileDataManager.shared
        let defaultPath = fm.getDefaultXcodePath()
        
        fm.findDeveloperPath(default: defaultPath, callback: self.analyze)
    }
    
    func analyze(path: String) {
        print("Start analyzing ", path)
        
        let groups: [(Analysis, String)] = [
            (data.iosDeviceSupport, path + "Xcode/iOS DeviceSupport/"),
            (data.watchOsDeviceSupport, path + "Xcode/watchOS DeviceSupport/"),
            (data.derivedData, path + "Xcode/DerivedData/"),
            (data.archives, path + "Xcode/Archives/"),
            (data.simulators, path + "CoreSimulator/Devices/"),
        ]
        
        for (analysis, path) in groups{
            analyzeGroup(analysis: analysis, developerPath: path)
        }
    }
    
    func analyzeGroup(analysis: Analysis, developerPath path: String){
        do{
            let fm = FileDataManager.shared
            let subDirectories = try fm.listDirectory(path, onlyDirectory: true)
            analysis.totalSize = 0
            analysis.itemsCount = subDirectories.count
            analysis.analyzedCount = 0
            analysis.progress = 0
            
            DispatchQueue.global(qos: .userInitiated).async {
                do{
                    for var subDirectory in subDirectories{
                        print("calculate subD", subDirectory)
                        if !subDirectory.hasSuffix("/"){
                            subDirectory += "/"
                        }
                        
                        let totalSize = try fm.getDirectorySize(subDirectory)
                        
                        var display = String(subDirectory.split(separator: "/").last!)
                        
                        if analysis.group == .simulators {
                            if let plist = NSDictionary(contentsOf: URL(fileURLWithPath: subDirectory + "device.plist")){
                                let name: String? = plist["name"] as! String
                                let uuid: String? = plist["UUID"] as? String
                                var version = String((plist["runtime"] as! String).split(separator: ".").last!)
                                //                                version = version.replacingOccurrences(of: "-", with: ".")
                                display = "\(name ?? uuid ?? "") (\(version))"
                                
                            }
                        }
                        
                        DispatchQueue.main.async {
                            analysis.items.append(
                                AnalysisItem(path: subDirectory, displayName: display, totalSize: totalSize)
                            )
                            
                            analysis.items.sort {
                                $0.totalSize > $1.totalSize
                            }
                            
                            analysis.analyzedCount += 1
                            analysis.totalSize += totalSize
                            analysis.progress = Double(analysis.analyzedCount) / Double(analysis.itemsCount)
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
    
    func toggleGroup(_ group: AnalysisGroup){
        data.activeGroup = data.activeGroup == group ? nil : group;
    }
    
    var body: some View {
        NavigationView{
            VStack{
                AnalysisView(analysis: data.iosDeviceSupport)
                    .onTapGesture {
                        self.toggleGroup(.iosDeviceSupport)
                }
                
                AnalysisView(analysis: data.watchOsDeviceSupport)
                    .onTapGesture {
                        self.toggleGroup(.watchOsDeviceSupport)
                }
                
                AnalysisView(analysis: data.simulators)
                    .onTapGesture {
                        self.toggleGroup(.simulators)
                }
                
                AnalysisView(analysis: data.archives)
                    .onTapGesture {
                        self.toggleGroup(.archives)
                }
                
                AnalysisView(analysis: data.derivedData)
                    .onTapGesture {
                        self.toggleGroup(.derivedData)
                }
                
                NavigationLink(destination: Text("Inner")){
                    Text("Show")
                }
            }
            .frame(
                minWidth: 500, idealWidth: 500, maxWidth: .infinity,
                minHeight: 500, idealHeight: 600, maxHeight: .infinity,
                alignment: .leading)
                .onAppear(perform: self.onAppear)
                .environmentObject(data)
            
            VStack{
                Text("detail")
            }
        }
    }
}

struct MainWindow_Previews: PreviewProvider {
    static var previews: some View {
        Group{
            
//            MainWindow()
//                .frame(width: 400, height: 600)
            
            ProgressBar(progress: 0.5)
                .frame(width: 300, height: 20)
                .padding()
        }
    }
}
