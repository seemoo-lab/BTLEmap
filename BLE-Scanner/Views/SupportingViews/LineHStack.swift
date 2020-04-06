////
////  LineableHStack.swift
////  BLE-Scanner
////
////  Created by Alex - SEEMOO on 06.04.20.
////  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
////
//
//import Foundation
//import SwiftUI
//
//struct LineHStack: View {
//    
//    let alignment: VerticalAlignment
//    let spacing: CGFloat?
//    
//    
//    /// Creates an instance with the given `spacing` and Y axis `alignment`.
//    ///
//    /// - Parameters:
//    ///     - alignment: the guide that will have the same horizontal screen
//    ///       coordinate for all children.
//    ///     - spacing: the distance between adjacent children, or nil if the
//    ///       stack should choose a default distance for each pair of children.
//    @inlinable public init(alignment: VerticalAlignment = .leading, spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
//        
//    }
//    
//    var body: some View {
//        
//    }
//    
//    private func generateContent(in g: GeometryProxy) -> some View {
//        var width = CGFloat.zero
//        var height = CGFloat.zero
//        
//        return ZStack(alignment: .topLeading) {
//            ForEach(self.platforms, id: \.self) { platform in
//                self.item(for: platform)
//                    .padding([.horizontal, .vertical], 4)
//                    .alignmentGuide(.leading, computeValue: { d in
//                        if (abs(width - d.width) > g.size.width)
//                        {
//                            width = 0
//                            height -= d.height
//                        }
//                        let result = width
//                        if platform == self.platforms.last! {
//                            width = 0 //last item
//                        } else {
//                            width -= d.width
//                        }
//                        return result
//                    })
//                    .alignmentGuide(.top, computeValue: {d in
//                        let result = height
//                        if platform == self.platforms.last! {
//                            height = 0 // last item
//                        }
//                        return result
//                    })
//            }
//        }
//    }
//}
//
