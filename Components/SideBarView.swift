//
//  SideBarView.swift
//  Cleaner4Xcode
//
//  Created by Baye Wayly on 2019/9/23.
//  Copyright © 2019 Baye. All rights reserved.
//

import SwiftUI

struct SideBarView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10){
            Text("Items")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("iOS DeviceSupport")
            Text("watchOS DeviceSupport")
        }
    }
}

struct SideBarView_Previews: PreviewProvider {
    static var previews: some View {
        HStack{
            ZStack(alignment: .topTrailing){
                
                
                VStack(alignment: .leading, spacing: 10){
                    Text("").frame(width: 80, height: 80)
                        .border(Color.red)
                        .background(Color(NSColor.windowBackgroundColor))
                    
                    Text("").frame(width: 80, height: 80)
                        .border(Color.red)
                        .background(Color(NSColor.underPageBackgroundColor))
                    
                    Text("").frame(width: 80, height: 80)
                        .border(Color.red)
                        .background(Color(NSColor.controlBackgroundColor))
                    
                    List{
                        Text("11")
                    }.frame(width: 80, height: 80)
                    
                    
                }
                .padding()
                .border(Color.green)
                .background(Color.white)
                .colorScheme(.light)
                
                Rectangle()
                    .foregroundColor(Color.yellow)
                    //                    .background(Color.red)
                    .frame(width: 20, height: 20)
                                        .rotationEffect(.degrees(45))
                    .offset(x: CGFloat(20 / 2) * CGFloat(1.414 / 2), y: 50)
                .zIndex(0)
            }
            
            
            SideBarView()
                .frame(width: 120, height: 500, alignment: .center)
                .background(Color.white)
                .colorScheme(.dark)
                .zIndex(1)
            
            SideBarView()
                .frame(width: 120, height: 500, alignment: .center)
                .colorScheme(.light)
        }
    }
}
