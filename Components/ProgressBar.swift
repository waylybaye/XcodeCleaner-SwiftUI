//
//  ProgressBar.swift
//  Cleaner4Xcode
//
//  Created by Baye Wayly on 2019/10/5.
//  Copyright © 2019 Baye. All rights reserved.
//

import SwiftUI

struct ProgressBar: View {
  var progress: CGFloat = 0.5
  var height: CGFloat = 8
  
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
          Color(NSColor.controlBackgroundColor)
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
            gradient: .init(colors: [Color.pink, Color.orange]),
            startPoint: .init(x: 0, y: 0),
            endPoint: .init(x: 1, y: 1)
          )
        ).animation(.easeInOut)
      }
      .frame(width: proxy.size.width, height: self.height)
    }
    .frame(height: self.height)
  }
}


struct ProgressBar_Previews: PreviewProvider {
  static var previews: some View {
    VStack(alignment: .leading, spacing: 20){
      ProgressBar()
      
      ProgressBar(progress: 0.9, height: 10)
    }
    .padding()
  }
}
