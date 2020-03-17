//
//  PopoverSheet.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 17.03.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import Foundation
import SwiftUI

extension View {
    
    public func popoverSheet<Content>(isPresented: Binding<Bool>, attachmentAnchor: PopoverAttachmentAnchor = .rect(.bounds), arrowEdge: Edge = .top, @ViewBuilder content: @escaping () -> Content) -> some View where Content : View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                self
                    .popover(isPresented: isPresented, content:content)
            }else {
                self
                    .sheet(isPresented: isPresented, content: content)
            }
        }
    }
}
