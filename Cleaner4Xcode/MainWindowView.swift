//
//  MainWindow.swift
//  Cleaner4Xcode
//
//  Created by Baye Wayly on 2019/9/23.
//  Copyright © 2019 Baye. All rights reserved.
//

import SwiftUI

let revealIcon = Image(nsImage: NSImage.init(named: NSImage.revealFreestandingTemplateName)!)
let trashIcon = Image(nsImage: NSImage.init(named: NSImage.stopProgressFreestandingTemplateName)!)

func ItemRow(
  item: AnalysisItem,
  onReveal: @escaping () -> Void,
  onTrash: @escaping () -> Void
) -> some View {
  
  let dateFormatter = DateFormatter()
  dateFormatter.dateFormat = "yyyy-MM-dd"
  
  return HStack {
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
//      Image(systemName: "magnifyingglass.circle.fill")
//      Image(nsImage: NSImage.init(named: NSImage.revealFreestandingTemplateName)!)
    }
    
    Button(action: onTrash) {
      trashIcon
//      Image(systemName: "trash.circle.fill")
//      Image(nsImage: NSImage.init(named: NSImage.stopProgressFreestandingTemplateName)!)
    }
  }
  .padding(.vertical, 5)
}


struct MainWindowView: View {
//  @ObservedObject var data = AppData()
  @EnvironmentObject var data: AppData
  
  func onAppear(){
//    self.data.selectedGroup = data.archives
  }
  
  func revealPath(path: String){
    let url = URL.init(fileURLWithPath: path, isDirectory: true)
    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
  }
  
  func trashPath(path: String, analysis: Analysis, groupStr: String = ""){
    let url = URL.init(fileURLWithPath: path, isDirectory: true)
    do {
      try FileManager.default.trashItem(at: url, resultingItemURL: nil)
      self.data.objectWillChange.send()

      if groupStr != "" {
        analysis.groupedItems = analysis.groupedItems.compactMap { group in
          guard group.group == groupStr, let index = group.items.firstIndex(where: { $0.path == path }) else {
            return group
          }
          print("\(path), \(index)")
          analysis.items.remove(at: index)
          analysis.totalSize = analysis.items.reduce(0) {
            $0 + $1.totalSize
          }
          return nil
        }
      } else {
        if let index = analysis.items.firstIndex(where: { $0.path == path }) {
          analysis.items.remove(at: index)
          analysis.totalSize = analysis.items.reduce(0) {
            $0 + $1.totalSize
          }
        }
      }
    } catch {
      print("\(error.localizedDescription)")
      print("\(error)")
    }
  }
  
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
            self.data.selectedGroup = nil;
          }
        
        
        ForEach(groups, id: \.group) { group in
          AnalysisView(analysis: group)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .background(self.data.selectedGroup === group ? selectedColor : nil)
//            .foregroundColor(self.data.selectedGroup === group ? .primary : .secondary)
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
                .foregroundColor(.secondary)
              
              Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom)
            
            Divider()
            
            
            List {
              if data.selectedGroup!.groupedItems.count > 0 {
                ForEach(data.selectedGroup!.groupedItems) { group in
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
                          self.trashPath(path: item.path, analysis: self.data.selectedGroup!, groupStr: group.group)
                        }
                      )
                    }
                  }
                }
                
              } else {
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
              .id(UUID())
              // magic fix see: https://stackoverflow.com/questions/62745198
//            .background(Color(UIColor.backgroundColor))
              .background(Color(NSColor.underPageBackgroundColor))
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
