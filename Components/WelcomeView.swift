//
//  WelcomeView.swift
//  Cleaner4Xcode
//
//  Created by Baye Wayly on 2019/10/5.
//  Copyright © 2019 Baye. All rights reserved.
//

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var appData: AppData
    
    func onAnalyze() {
        withAnimation{
            
            
            if appData.selectedDeveloperPath == nil {
                let fh = FileHelper.standard
                let defaultPath = fh.getDefaultXcodePath()
                
                fh.validateDeveloperPath(default: defaultPath) {path in
                    self.appData.selectedDeveloperPath = path
                    self.appData.analyze()
                }
                
            } else {
                self.appData.analyze()
            }
        }
    }
    
    func choseDeveloperPath() {
        appData.selectedDeveloperPath = nil
        onAnalyze()
    }
    
    var body: some View {
        VStack{
            Spacer()
            
            Image("icon512")
                .resizable()
                .frame(width: 128, height: 128, alignment: .center)
            
            Text("Cleaner for Xcode")
                .font(.largeTitle)
                .padding(.top)
            
            Text("welcome.need_authorize")
                .multilineTextAlignment(.center)
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.top, 5)
            
            Spacer()
            
            if appData.totalSize > 0 {
                VStack{
                    Spacer()
                    Text(humanize(appData.totalSize))
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.pink)
                        .padding(.bottom)
                    
                    if appData.isAnalyzing {
                        ProgressBar(progress: CGFloat(appData.progress), height: 6)
                            .frame(height: 6, alignment: .top)
                        
                        
                    } else {
                        Text("welcome.button_analyze_again")
                            .foregroundColor(.white)
                            .padding(.horizontal, 25)
                            .padding(.vertical, 10)
                            .background(Color.pink)
                            .cornerRadius(25)
                            .contentShape(Rectangle())
                            .onTapGesture(perform: onAnalyze)
                    }
                    
                    Spacer()
                }.frame(maxWidth: .infinity, minHeight: 140)
                
            } else {
                VStack{
                    Spacer()
                    
                    Text("welcome.button_analyze")
                        .foregroundColor(.white)
                        .padding(.horizontal, 25)
                        .padding(.vertical, 10)
                        .background(Color.pink)
                        .cornerRadius(25)
                        .contentShape(Rectangle())
                        .onTapGesture(perform: onAnalyze)
                    
                    if appData.selectedDeveloperPath != nil {
                        VStack{
                            Text("Selected \(appData.selectedDeveloperPath!)")
                                .foregroundColor(.secondary)
                                .padding()
                            
                            Text("welcome.button_change_location")
                                .foregroundColor(.pink)
                                .padding()
                                .contentShape(Rectangle())
                                .onTapGesture(perform: choseDeveloperPath)
                        }
                    }
                    
                    Spacer()
                }
                .frame(height: 140)
            }
            
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 25)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        let appData = AppData()
        appData.isAnalyzing = true
        appData.totalCount = 500
        appData.analyzedCount = 400
        appData.totalSize = 6 * 10 * 1000 * 1000 * 1000
        
        return Group{
            HStack{
                WelcomeView()
                    .frame(width: 400, height: 500)
                    .environmentObject(appData)
                
                WelcomeView()
                    .frame(width: 400, height: 500)
                    .environmentObject(AppData())
            }.environment(\.locale, Locale(identifier: "zh"))
            
            HStack{
                WelcomeView()
                    .frame(width: 400, height: 500)
                    .environmentObject(appData)
                
                WelcomeView()
                    .frame(width: 400, height: 500)
                    .environmentObject(AppData())
            }
        }
        
    }
}
