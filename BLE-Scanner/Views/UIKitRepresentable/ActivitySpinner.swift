//
//  ActivitySpinner.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 27.03.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import SwiftUI
import UIKit

struct ActivitySpinner: UIViewRepresentable {
    @Binding var animating: Bool
    var color: UIColor? = nil
    var style: UIActivityIndicatorView.Style? = nil
    
    
    func makeUIView(context: Context) -> UIActivityIndicatorView {
        let actInd = UIActivityIndicatorView()
        actInd.hidesWhenStopped = true
        return actInd
    }
    
    func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {
        if let color = self.color {
            uiView.color = color
        }
        
        if let style = self.style {
            uiView.style = style
        }
        
        
        if animating {
            uiView.startAnimating()
        }else {
            uiView.stopAnimating()
        }
    }
    
    
}

struct ActivitySpinner_Previews: PreviewProvider {
    @State static var animating = true
    
    static var previews: some View {
        ActivitySpinner(animating: $animating)
    }
}
