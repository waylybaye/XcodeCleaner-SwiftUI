//
//  MainWindow.swift
//  Cleaner4Xcode
//
//  Created by Baye Wayly on 2019/9/23.
//  Copyright © 2019 Baye. All rights reserved.
//

import SwiftUI

//let revealIcon = Image(nsImage: NSImage.init(named: NSImage.revealFreestandingTemplateName)!)
//let trashIcon = Image(nsImage: NSImage.init(named: NSImage.stopProgressFreestandingTemplateName)!)

let revealIcon = Image(systemName: "magnifyingglass.circle.fill")
let trashIcon = Image(systemName: "trash.circle.fill")

struct ItemRow: View {
  var item: AnalysisItem
  var onReveal: () -> Void
  var onTrash: () -> Void
  
  var dateFormatter: DateFormatter {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    return dateFormatter
  }
  
  var body: some View {
    HStack {
      Text(item.displayName)
        .font(.subheadline)
        .lineLimit(1)
    
      Spacer()
    
      Text(humanize(item.totalSize))
        .font(.subheadline)
        .padding(.horizontal)
    
      Text(dateFormatter.string(from: item.modifyDate))
        .foregroundColor(.secondary)
        .font(Font.subheadline.monospacedDigit())
        .lineLimit(1)
    
      Button(action: onReveal) {
        revealIcon
      }
    
      Button(action: onTrash) {
        trashIcon
      }
    }
    .padding(.vertical, 5)
    .padding(.horizontal, 5)
  }
}


struct ResultsTableView: View {
  @ObservedObject var analysis: Analysis
  
  func revealPath(path: String){
    let url = URL.init(fileURLWithPath: path, isDirectory: true)
    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
  }
  
  func trashPath(path: String, analysis: Analysis){
    let url = URL.init(fileURLWithPath: path, isDirectory: true)
    do {
      try FileManager.default.trashItem(at: url, resultingItemURL: nil)
      analysis.objectWillChange.send()
      
      if let index = analysis.items.firstIndex(where: { $0.path == path }) {
        // 重新计算 analysi 的总大小
        let item = analysis.items.remove(at: index)
        analysis.totalSize = analysis.items.reduce(0) {
          $0 + $1.totalSize
        }
        
        // 如果有分组，重新计算分组的大小
        if item.groupLabel != nil {
          if let index = analysis.groupedItems.firstIndex(where: { $0.group == item.groupLabel }) {

//            analysis.groupedItems[index].totalSize -= item.totalSize
            analysis.groupedItems[index].items.removeAll {
              $0.id == item.id
            }
            
            analysis.groupedItems[index].totalSize = analysis.groupedItems[index].items.reduce(0) {
              $0 + $1.totalSize
            }
          }
        }
      }
    } catch {
      print("\(error.localizedDescription)")
      print("\(error)")
    }
  }
  
  var body: some View {
    List {
      if analysis.groupedItems.count > 0 {
        ForEach(analysis.groupedItems) { group in
          Section(header:
            Text(group.group)
              .foregroundColor(.secondary)
          ) {
            ForEach(group.items) { item in
              ItemRow(
                item: item,
                onReveal: {
                  self.revealPath(path: item.path)
                },
                onTrash: {
                  self.trashPath(path: item.path, analysis: analysis)
                }
              )
            }
          }
        }
      
      } else {
        ForEach(analysis.items) { item in
          ItemRow(
            item: item,
            onReveal: {
              self.revealPath(path: item.path)
            },
            onTrash: {
              self.trashPath(path: item.path, analysis: analysis)
            }
          )
        }
      }
    }
  }
}


struct MainWindowView: View {
  @ObservedObject var data = AppData()
  
  func onAppear(){
  }
  
  var dataView: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .top) {
        Text(LocalizedStringKey(
          data.selectedGroup!.group.describe().summary))
          .font(.footnote)
          .foregroundColor(.secondary)
      
        Spacer()
      }
      .padding(.horizontal)
      .padding(.bottom)
    
      Divider()
    
      ResultsTableView(analysis: data.selectedGroup!)
        .background(Color(NSColor.underPageBackgroundColor))
    }
    .frame(minWidth: detailWidth, maxWidth: .infinity)
  }
  
  var detailWidth: CGFloat = 500
  
  var body: some View {
    let groups = data.groups.map {$0.0}
    let detailWidth: CGFloat = 550
    let selectedColor = Color.pink.opacity(0.2)
    
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
          .background(self.data.selectedGroup === nil ? selectedColor : nil)
          .cornerRadius(5)
          .padding(.vertical, 10)
          .onTapGesture {
            self.data.selectedGroup = nil
          }
        
        ForEach(groups, id: \.group) { group in
          AnalysisView(analysis: group)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .background(self.data.selectedGroup === group ? selectedColor : nil)
            .cornerRadius(5)
            .onTapGesture {
              if self.data.selectedGroup !== group {
                self.data.selectedGroup = group
              }
            }
        }
      }
      .listStyle(SidebarListStyle())
      .frame(width: 200)
      
      if data.selectedGroup == nil {
        WelcomeView()
          .frame(minWidth: detailWidth, maxWidth: .infinity, maxHeight: .infinity)
          .navigationTitle("Cleaner for Xcode")
          .toolbar {
            EmptyView()
          }
          
      } else {
        dataView
      }
    }
    .onAppear(perform: self.onAppear)
    .environmentObject(data)
    .navigationViewStyle(DefaultNavigationViewStyle())
  }
}

struct MainWindow_Previews: PreviewProvider {
  static var previews: some View {
    MainWindowView()
  }
}
