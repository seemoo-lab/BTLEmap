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
            
            InfoView {
                
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
            }
            
        }
        .edgesIgnoringSafeArea(.all)
    }
}

/// Shows a small view from the bottom of the parent (if used in a ZStack)
struct InfoView<Content> : View where Content : View  {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    let content: () -> Content
    let onDismissed: (()->())?
    let enableSwipeDown: Bool
    let importance: Importance
    
    @State var dismissed = false
    
    init(importance: Importance = .info, enableSwipeDown: Bool = false, onDismissed:(()->())? = nil, @ViewBuilder content: @escaping () -> Content){
        self.content = content
        self.enableSwipeDown = enableSwipeDown
        self.onDismissed = onDismissed
        self.importance = importance
    }
    
    var swipeDownGesture: some Gesture {
        DragGesture(minimumDistance: 10.0, coordinateSpace: .local)
            .onChanged({ (value) in
                if value.translation.height > 30.0 && !self.dismissed {
                    self.onDismissed?()
                    self.dismissed = true
                }
            })
            .onEnded { (value) in
                if value.translation.height > 30.0 && !self.dismissed {
                    self.onDismissed?()
                    self.dismissed = true
                }
            }
    }
    
    var backgroundTint: Color  {
        switch self.importance {
        case .info:
            return Color.clear
        case .error:
            return Color("ErrorTint").opacity(0.5)
        }
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack {
                VStack {
                    self.content()
                }
                .padding()
            }
                .frame(maxWidth: 450)
                .background(
                    ZStack {
                        BlurView(style: self.colorScheme == .light ? .light : .dark )
                            .background(self.backgroundTint)
                        RoundedRectangle(cornerRadius: 25.0, style: .continuous).stroke(Color.black.opacity(0.3), lineWidth: 0.5)
                })
                .cornerRadius(25.0)
                .shadow(radius: 20.0)
                .transition(AnyTransition.move(edge: .bottom).animation(.easeIn))
                .padding()
                .padding(.bottom, 10.0)
                .gesture(self.swipeDownGesture)
        }
    }
    
    /// Describes how importance the info view is. Will be reflect in a different background tint
    enum Importance {
        case info
        case error
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
