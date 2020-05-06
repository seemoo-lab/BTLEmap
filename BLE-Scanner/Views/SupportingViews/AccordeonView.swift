//
//  AccordeonView.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 04.05.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import Foundation
import SwiftUI

struct AccordeonView<Content: View>: View {
    var title: Text
    var content: Content
    
    @State var opened = false
    
    init(title: Text, @ViewBuilder builder:()->Content) {
        self.content = builder()
        self.title = title
    }
    
    var rowTransition: AnyTransition {
        let insertion = AnyTransition.move(edge: .top).combined(with: .opacity)
        let removal = AnyTransition.move(edge: .top).combined(with: .opacity)

        return .asymmetric(insertion: insertion, removal: removal)
    }
    
    var openCloseButton: some View {
        Button(action: self.openClose) {
            HStack {
                Image(systemName: "arrowtriangle.right.fill")
                .imageScale(.large)
                .padding(4.0)
                .rotationEffect(Angle(degrees: self.opened ? 90.0 : 0.0))
                
                self.title
                    .padding(.leading, 4.0)
                
                Spacer()
            }
            .padding([.top, .bottom], 4.0)
            .background(Rectangle().fill(Color.lightGray))
        }
        .buttonStyle(PlainButtonStyle())
        .padding([.top, .bottom, .trailing], 2.0)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            self.openCloseButton
            
            if opened {
                self.content
                    .padding([.leading, .bottom ], 10.0)
                    .transition(self.rowTransition)
            }
        }
    }
    
    
    func openClose() {
        withAnimation {
            self.opened.toggle()
        }
        
    }
}
