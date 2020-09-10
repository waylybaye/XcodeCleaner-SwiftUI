//
//  CollapsableListView.swift
//  Cleaner for Xcode
//
//  Created by Baye Wayly on 2020/9/10.
//  Copyright © 2020 Baye. All rights reserved.
//

import SwiftUI

struct CollapsableListView: View {
  @ObservedObject var analysis: Analysis
  @State var selected: String? = nil
  
  var body: some View {
    VStack {
      Picker("Items", selection: self.$selected) {
        ForEach(analysis.groupedItems) { item in
          Text(item.group)
            .tag(item.group)
        }
      }
    }
  }
}

struct CollapsableListView_Previews: PreviewProvider {
  static var previews: some View {
    CollapsableListView(
      analysis: Analysis(group: .archives)
    )
  }
}
