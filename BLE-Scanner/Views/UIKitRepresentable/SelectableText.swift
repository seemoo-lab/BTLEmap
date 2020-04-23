//
//  SelectableText.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 22.04.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

struct SelectableText: UIViewRepresentable {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    var width: CGFloat
    var text: String
    var textColor: UIColor?

    var font: UIFont?
    
    init(text: String, width: CGFloat, textColor: UIColor?=nil, font: UIFont?=nil) {
        self.text = text
        self.textColor = textColor
        self.font = font
        self.width = width
    }
    
    func makeUIView(context: Context) ->  UITextView {
        let textView = UITextView()
        
        textView.isSelectable = true
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.contentInset = .zero
        textView.text = self.text
        textView.translatesAutoresizingMaskIntoConstraints = false 
        textView.widthAnchor.constraint(equalToConstant: self.width).isActive = true
        
        
        if let textColor = self.textColor {
            textView.textColor = textColor
        }else {
            switch self.colorScheme {
            case .dark:
                textView.textColor = UIColor.white
            case .light:
                textView.textColor = UIColor.black
            @unknown default:
                textView.textColor = .gray
            }
        }
        
        if let font = self.font {
            textView.font = font
        }
        
        
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        textView.sizeToFit()
        textView.layoutSubviews()
    }
}
