//
//  AnalysisView.swift
//  Cleaner4Xcode
//
//  Created by Baye Wayly on 2019/10/2.
//  Copyright © 2019 Baye. All rights reserved.
//

import SwiftUI

struct AnalysisView: View {
  @EnvironmentObject var appData: AppData
  @ObservedObject var analysis: Analysis
  
  var body: some View {
    let (title, _) = analysis.group.describe()
    
    return
      HStack{
        VStack(alignment: .leading, spacing: 5) {
          Text(title).font(.footnote)
            .foregroundColor(.primary)
          
          Text(humanize(analysis.totalSize))
            .font(Font.headline.monospacedDigit())
            .bold()
            .foregroundColor(.pink)
          
          if analysis.progress > 0 && analysis.progress < 1{
            ProgressBar(progress: CGFloat(analysis.progress), height: 4)
              .frame(width: 80, height: 3, alignment: .leading)
              .animation(.easeIn)
          } else {
            Text("").frame(height: 3)
          }
        }
        Spacer()
      }
      .frame(maxWidth: .infinity)
  }
}

struct AnalysisView_Previews: PreviewProvider {
  static var previews: some View {
    let data = AppData()
    return VStack{
      AnalysisView(analysis: data.iosDeviceSupport)
      AnalysisView(analysis: data.watchOsDeviceSupport)
      AnalysisView(analysis: data.archives)
      AnalysisView(analysis: data.archives)
      AnalysisView(analysis: data.previews)
    }
    .padding()
    .environmentObject(data)
  }
}
