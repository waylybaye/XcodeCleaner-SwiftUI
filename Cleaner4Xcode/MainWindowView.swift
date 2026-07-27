//
//  MainWindow.swift
//  Cleaner4Xcode
//
//  Created by Baye Wayly on 2019/9/23.
//  Copyright © 2019 Baye. All rights reserved.
//

import SwiftUI

/// 主窗口：左侧 `SidebarView` 选择分类，右侧根据选中状态展示欢迎页或分类详情。
struct MainWindowView: View {
  @ObservedObject var data = AppData()

  func onAppear(){
  }

  var detailWidth: CGFloat = 550

  var body: some View {
    NavigationView {
      SidebarView(data: data)

      if data.selectedGroup == nil {
        WelcomeView()
          .frame(minWidth: detailWidth, maxWidth: .infinity, maxHeight: .infinity)
          .navigationTitle("Cleaner for Xcode")
          .toolbar {
            EmptyView()
          }

      } else {
        // 详情面板沿用原有的 500 最小宽度（与欢迎页的 550 不同）
        CategoryDetailView(analysis: data.selectedGroup!)
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
