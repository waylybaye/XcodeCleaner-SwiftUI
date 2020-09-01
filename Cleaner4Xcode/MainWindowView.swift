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
    self.data.selectedGroup = data.archives
  }
  
  func revealPath(path: String){
    let url = URL.init(fileURLWithPath: path, isDirectory: true)
    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
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
    let detailWidth: CGFloat = 500
//    var columns: [GridItem] =
//            Array(repeating: .init(.flexible()), count: 2)
    
    return NavigationView {
      List {
        Text("sidebar.welcome")
          .font(.body)
          .foregroundColor(.primary)
          .multilineTextAlignment(.leading)
          .padding(.horizontal, 10)
          .padding(.vertical, 8)
          .frame(minWidth: 80, maxWidth: .infinity, alignment: .leading)
          .contentShape(Rectangle())
          .background(self.data.selectedGroup == nil ? Color("underpageBackground") : Color.clear)
          .cornerRadius(5)
          .padding(.vertical, 10)
          .onTapGesture {
            self.data.selectedGroup = nil;
          }
        
        
        ForEach(groups, id: \.group) { group in
          AnalysisView(analysis: group)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .background(self.data.selectedGroup === group ? Color("underpageBackground") : Color.clear)
            .cornerRadius(5)
            .onTapGesture {
              if self.data.selectedGroup !== group{
                self.data.selectedGroup = group
              }
            }
        }
      }
      .listStyle(SidebarListStyle())
      .frame(width: 200)
      
      ZStack {
        if data.selectedGroup === nil {
          WelcomeView()
            .frame(minWidth: detailWidth, maxWidth: .infinity, maxHeight: .infinity)
          
        } else {
          VStack (alignment: .leading, spacing: 0) {
            
            HStack(alignment: .top) {
              
              Text(LocalizedStringKey(
                    data.selectedGroup!.group.describe().summary))
                .font(.footnote)
              
              Spacer()
              
              Button("Reveal in Finder") {
              }
            }
            .padding(.horizontal)
            .padding(.bottom)
            
            List {
              
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
          .frame(minWidth: detailWidth, maxWidth: .infinity)
        }
      }
    }
    .onAppear(perform: self.onAppear)
    .environmentObject(data)
  }
}

struct MainWindow_Previews: PreviewProvider {
  static var previews: some View {
    MainWindowView()
  }
}
