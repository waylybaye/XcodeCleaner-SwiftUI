//
//  MainWindow.swift
//  Cleaner4Xcode
//
//  Created by Baye Wayly on 2019/9/23.
//  Copyright © 2019 Baye. All rights reserved.
//

import SwiftUI


struct ProgressBar: View {
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
                        in: .init(x: 0, y: 0, width: proxy.size.width / 2, height: self.height),
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
    @ObservedObject var analysis: Analysis
    
    var body: some View {
        let (title, summary) = analysis.group.describe()
        
        return VStack(alignment: .leading, spacing: 10) {
            HStack{
                VStack(alignment: .leading){
                    Text(title).font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(summary).font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(analysis.totalSize.description)
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.red)
            }
            ProgressBar()
                .frame(height: 8)
                .frame(maxWidth: .infinity)
        }.padding()
    }
}

struct MainWindow: View {
    var data = AppData()
    
    var body: some View {
        VStack{
            AnalysisView(analysis: data.deviceSupport)
            AnalysisView(analysis: data.simulators)
            AnalysisView(analysis: data.archives)
            AnalysisView(analysis: data.derivedData)
        }
    }
}

struct MainWindow_Previews: PreviewProvider {
    static var previews: some View {
        Group{
            
            
            MainWindow()
                .frame(width: 400, height: 600)
            
            ProgressBar()
                .frame(width: 300, height: 20)
                .padding()
        }
    }
}
