//
//  CustomSheet.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 30.04.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import Foundation
import SwiftUI

struct CustomSheet: ViewModifier {
    @Binding var isShown: Bool
    var sheetView: Content
    
    func body(content: Content) -> some View {
        ZStack {
            content
            if self.isShown {
                self.sheetView
            }
        }
    }
}

extension View {
    public func modalView<T: View>(_ isShown: Binding<Bool>,modal: @escaping  ()->T) -> some View {
        
        #if targetEnvironment(macCatalyst)

        return
            GeometryReader { g in
                ZStack {
                    self
                    
                    if isShown.wrappedValue {
                        Rectangle()
                            .fill(Color.black.opacity(0.1))
                            .onTapGesture {
                                withAnimation(.easeIn) {
                                    isShown.wrappedValue = false
                                }
                            }
                            .transition(AnyTransition.opacity)
                        
                        modal()
                            .edgesIgnoringSafeArea(.all)
                            .frame(width: g.size.smaller * 0.7, height: g.size.smaller * 0.9)
                            .cornerRadius(10.0)
                            .shadow(radius: 30.0)
                            .transition(AnyTransition.move(edge: .bottom))
                        
                    }
                }
                .edgesIgnoringSafeArea(.all)
            }
        
        
        
        #else
        return self.sheet(isPresented: isShown, content: modal)
        #endif
        
    }
}
