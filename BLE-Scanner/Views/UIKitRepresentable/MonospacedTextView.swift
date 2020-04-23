//
//  MonospacedTextView.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 23.04.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

struct BytesTextView: UIViewRepresentable {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    var width: CGFloat
    var text: String
    var textColor: UIColor?
    var textStyle: UIFont.TextStyle
    
    init(text: String, width: CGFloat, textColor: UIColor?=nil, textStyle: UIFont.TextStyle) {
        self.text = text
        self.textColor = textColor
        self.width = width
        self.textStyle = textStyle
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
        
        textView.font = UIFont.monospacedSystemFont(ofSize: UIFont.preferredFont(forTextStyle: self.textStyle).pointSize, weight: .regular)

        return textView
    }
    
    
    func updateUIView(_ textView: UITextView, context: Context) {
        textView.sizeToFit()
        textView.layoutSubviews()
    }
}

class MonospacedUITextView: UITextView {
    
    override func copy() -> Any {
        //Remove the spaces, because they are just for representing bytes in hex
        let t = self.text.replacingOccurrences(of: " ", with: "")
        UIPasteboard.general.string = t
        return t
    }
}

