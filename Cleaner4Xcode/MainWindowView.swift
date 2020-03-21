//
//  MainWindow.swift
//  Cleaner4Xcode
//
//  Created by Baye Wayly on 2019/9/23.
//  Copyright © 2019 Baye. All rights reserved.
//

import SwiftUI


func ItemRow(
  item: AnalysisItem,
  onReveal: @escaping () -> Void,
  onTrash: @escaping () -> Void
) -> some View {
  
  return HStack{
    Text(item.displayName)
      .lineLimit(1)
    
    Spacer()
    
    Text(humanize(item.totalSize))
      .padding(.horizontal)
    
    Button(action: onReveal) {
      Image(nsImage: NSImage.init(named: NSImage.revealFreestandingTemplateName)!)
    }
    
    Button(action: onTrash) {
      Image(nsImage: NSImage.init(named: NSImage.stopProgressFreestandingTemplateName)!)
    }
  }
}


struct MainWindowView: View {
  @ObservedObject var data = AppData()
  
  func onAppear(){
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
      
      data.recalculateTotal()
    } catch {
      print("\(error.localizedDescription)")
      print("\(error)")
    }
  }
  
  var body: some View {
    let groups = data.groups.map {$0.0}
    
    return HStack(alignment: .top, spacing: 0){
      
      VStack(alignment: .leading, spacing: 0){
        Text("sidebar.welcome")
          .font(.body)
          .foregroundColor(.primary)
          .multilineTextAlignment(.leading)
          .padding(.horizontal)
          .padding(.vertical, 10)
          .frame(minWidth: 80, maxWidth: .infinity, alignment: .leading)
          .contentShape(Rectangle())
          .background(self.data.selectedGroup == nil ? Color("underpageBackground") : Color.clear)
          .cornerRadius(20)
          .padding(.bottom, 15)
          .onTapGesture {
            self.data.selectedGroup = nil;
        }
        
        
        ForEach(groups, id: \.group) { group in
          AnalysisView(analysis: group)
            .padding(.horizontal)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .background(self.data.selectedGroup === group ? Color("underpageBackground") : Color.clear)
            .cornerRadius(5)
            .onTapGesture {
              if self.data.selectedGroup !== group{
                withAnimation{
                  self.data.selectedGroup = group
                }
              }
          }
        }
      }
      .frame(width: 220)
      .padding()
      
      ZStack{
        if data.selectedGroup === nil {
          WelcomeView()
            .frame(minWidth: 400, maxWidth: .infinity, maxHeight: .infinity)
          
        } else {
          List {
            VStack(alignment: .leading){
              Text(LocalizedStringKey(
                data.selectedGroup!.group.describe().summary))
                .foregroundColor(.secondary)
                .padding(.top)
              
              Divider()
              
              ForEach(data.selectedGroup!.items) { item in
                ItemRow(
                  item: item,
                  onReveal: {
                    self.revealPath(path: item.path)
                },
                  onTrash: {
                    self.trashPath(path: item.path, analysis: self.data.selectedGroup!)
                }
                )
              }
            }
          }
          .frame(minWidth: 400, maxWidth: .infinity)
        }
      }
    }
    .background(Color(NSColor.windowBackgroundColor))
    .onAppear(perform: self.onAppear)
    .environmentObject(data)
  }
}

struct MainWindow_Previews: PreviewProvider {
  static var previews: some View {
    MainWindowView()
  }
}
