//
//  ConnectingView.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 27.03.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import SwiftUI
import BLETools

struct ConnectingView: View {
    @EnvironmentObject var bleScanner: BLEScanner
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.2))
                .transition(AnyTransition.opacity.animation(.linear))
            
            VStack {
                Spacer()
                VStack {
                    Text("Connecting...")
                        .padding()
                    HStack {
                        Spacer()
                        ActivitySpinner(animating: Binding.constant(true), style: .large)
                            .padding()
                        Spacer()
                    }
                    .padding([.bottom])
                    
                    Button("Cancel", action: {
                        self.bleScanner.receiverType = .coreBluetooth
                    })
                        .padding([.bottom])
                }
                .frame(maxWidth: 450)
                .background(
                    ZStack {
                        BlurView(style: self.colorScheme == .light ? .light : .dark )
                        RoundedRectangle(cornerRadius: 25.0, style: .continuous).stroke(Color.black.opacity(0.3), lineWidth: 0.5)
                })
                    .cornerRadius(25.0)
                    .shadow(radius: 20.0)
            }
            .transition(AnyTransition.move(edge: .bottom).animation(.linear))
            .padding()
            .padding(.bottom, 10.0)
            
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct ConnectingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ConnectingView().environmentObject(BLEScanner()).environment(\.colorScheme, .light)
            ConnectingView().environmentObject(BLEScanner()).environment(\.colorScheme, .dark)
        }
        
    }
}
