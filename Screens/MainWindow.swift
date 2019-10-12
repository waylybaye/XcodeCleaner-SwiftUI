//
//  MainWindow.swift
//  Cleaner4Xcode
//
//  Created by Baye Wayly on 2019/9/23.
//  Copyright © 2019 Baye. All rights reserved.
//

import SwiftUI


func ItemRow(item: AnalysisItem) -> some View {
    return HStack{
        
        Text(item.displayName)
            .lineLimit(1)
        
        Spacer()
        
        Text(humanize(item.totalSize))
            .padding(.horizontal)
        
        Button(action: {
            //            self.revealPath(path: item.path)
        }) {
            Image(nsImage: NSImage.init(named: NSImage.revealFreestandingTemplateName)!)
        }
        
        Button(action: {
            //            self.trashPath(path: item.path, analysis: self.data.selectedGroup!)
        }) {
            Image(nsImage: NSImage.init(named: NSImage.stopProgressFreestandingTemplateName)!)
        }
    }
}


struct MainWindow: View {
    @ObservedObject var data = AppData()
    
    func onAppear(){
        //                let fm = FileDataManager.shared
        //        let defaultPath = fm.getDefaultXcodePath()
        //
        //                fm.findDeveloperPath(default: defaultPath, callback: self.analyze)
    }
    

    
    func toggleGroup(_ group: AnalysisGroup){
        data.activeGroup = data.activeGroup == group ? nil : group;
    }
    
    func revealPath(path: String){
        let url = URL.init(fileURLWithPath: path, isDirectory: true)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    
    func trashPath(path: String, analysis: Analysis){
        let url = URL.init(fileURLWithPath: path, isDirectory: true)
        do {
            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
            self.data.objectWillChange.send()
            
            if let index = analysis.items.firstIndex(where: { $0.path == path }) {
                analysis.items.remove(at: index)
                analysis.totalSize = analysis.items.reduce(0) {
                    $0 + $1.totalSize
                }
            }
        } catch {
            print("\(error.localizedDescription)")
            print("\(error)")
        }
    }
    
    var body: some View {
        let groups = data.groups.map {$0.0}
        
        return HStack(alignment: .top, spacing: 0){
            ZStack(alignment: .topTrailing){
                VStack(alignment: .leading, spacing: 0){
                    Text("sidebar.welcome")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .padding()
                        .frame(width: 250, height: nil, alignment: .leading)
//                        .frame(width: 250, alignment)
                        .contentShape(Rectangle())
                        .background(self.data.selectedGroup == nil ? Color("underpageBackground") : Color.clear)
                        .onTapGesture {
                            self.data.selectedGroup = nil;
                    }
                    
                    ForEach(groups, id: \.group) { group in
                        AnalysisView(analysis: group)
                            .padding()
                            .contentShape(Rectangle())
                            .background(self.data.selectedGroup === group ? Color("underpageBackground") : Color.clear)
                            .onTapGesture {
                                if self.data.selectedGroup !== group{
                                    
                                    self.data.objectWillChange.send()
                                    self.data.selectedGroup = group
                                }
                        }
                    }
                }
                .background(Color("windowBackground"))
                .frame(width: 250)
                .padding(.vertical)
            }
            
            
            if data.selectedGroup === nil {
                WelcomeView()
                    .background(Color("underpageBackground"))
                    .frame(minWidth: 400, maxWidth: .infinity, maxHeight: .infinity)
                
            } else {
                ScrollView {
                    VStack{
                        Text(data.selectedGroup!.group.describe().summary)
                            .foregroundColor(.secondary)
                            .padding(.vertical)
                        
                        ForEach(data.selectedGroup!.items) { item in
                            ItemRow(item: item)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                }
                .background(Color("underpageBackground"))
                .frame(minWidth: 400, maxWidth: .infinity, maxHeight: .infinity)
                
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear(perform: self.onAppear)
        .environmentObject(data)
    }
}

struct MainWindow_Previews: PreviewProvider {
    static var previews: some View {
        MainWindow()
    }
}
