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
    
    
    /// Present a popver or a sheet depending on the device the app is running on.
    /// On iPhones this will present a sheet, because popovers do not work correclty. On iPads / Catalyst it will display a popover
    /// - Parameters:
    ///   - isPresented: Binding that is true when presented
    ///   - attachmentAnchor: Potential anchor at which the popover can be attached
    ///   - arrowEdge: Edge at which the popover arrow will be displayed
    ///   - content: Content of the Presented popover/sheet
    public func popoverSheet<Content>(isPresented: Binding<Bool>, attachmentAnchor: PopoverAttachmentAnchor = .rect(.bounds), arrowEdge: Edge = .top, @ViewBuilder content: @escaping () -> Content) -> some View where Content : View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                self
                    .popover(isPresented: isPresented, attachmentAnchor: attachmentAnchor, arrowEdge: arrowEdge, content:content)
            }else {
                self
                    .sheet(isPresented: isPresented, content: content)
            }
        }
    }
}
