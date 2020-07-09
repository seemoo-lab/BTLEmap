//
//  SelectableBytesTextView.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 05.05.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

fileprivate struct CustomUITextViewWrapper: UIViewRepresentable {
    var text: String?
    var attributedString: NSAttributedString?
    @Binding var calculatedHeight: CGFloat
    var presentationMode: SelectableTextView.PresentationMode
    
    @State var selectedRange: NSRange?
    
    func makeUIView(context: Context) -> UITextView {
        
        let textView = { () -> UITextView in
            switch self.presentationMode {
            case .bytes:
                return BytesUITextView()
            case .text:
                return UITextView()
            case .attributedString:
                return UITextView()
            }
        }()
        
        textView.isSelectable = true
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.contentInset = .zero
        if self.text != nil {
            textView.text = self.text
        }else if self.attributedString != nil {
            textView.attributedText = self.attributedString
        }
        
        textView.backgroundColor = .clear
        
        
        switch self.presentationMode {
        case .bytes:
            textView.font = UIFont.monospacedSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .regular)
        case .text:
            textView.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .regular)
        case .attributedString:
            break
        }
        
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: UIViewRepresentableContext<CustomUITextViewWrapper>) {
        if let text = self.text, textView.text != text {
            textView.text = self.text
        }
        if let attributes = self.attributedString, textView.attributedText != attributes {
            textView.attributedText = attributes
        }
        
//        if let selectedRange = self.selectedRange {
//            textView.selectedRange = selectedRange
//        }else {
//            DispatchQueue.main.async {
//                self.selectedRange = textView.selectedRange
//            }
//        }
        
        
        CustomUITextViewWrapper.recalculateHeight(view: textView, result: $calculatedHeight)
    }
    
    fileprivate static func recalculateHeight(view: UIView, result: Binding<CGFloat>) {
        let newSize = view.sizeThatFits(CGSize(width: view.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
        //TextViews are always 4 px to heigh
        let height = newSize.height
        if result.wrappedValue != height {
            DispatchQueue.main.async {
                result.wrappedValue = height // !! must be called asynchronously
            }
        }
    }
}

fileprivate class BytesUITextView: UITextView {
    
    override func copy() -> Any {
        //Remove the spaces, because they are just for representing bytes in hex
        let t = self.text.replacingOccurrences(of: " ", with: "")
        UIPasteboard.general.string = t
        return t
    }
    
    override func copy(_ sender: Any?) {
        //Remove the spaces, because they are just for representing bytes in hex
        let t = self.text.replacingOccurrences(of: " ", with: "")
        UIPasteboard.general.string = t
    }

}

struct SelectableTextView: View {
    var text: String?
    var attributedString: NSAttributedString?
    @State private var dynamicHeight: CGFloat = 100
    var presentationMode: PresentationMode
    
    var body: some View {
        Group {
        if self.presentationMode == .attributedString {
            CustomUITextViewWrapper(text: nil, attributedString: self.attributedString!, calculatedHeight: self.$dynamicHeight, presentationMode: self.presentationMode)
            
        }else {
            CustomUITextViewWrapper(text: self.text!, attributedString: nil, calculatedHeight: self.$dynamicHeight, presentationMode: self.presentationMode)
            }
        }
        .frame(minHeight: self.dynamicHeight, maxHeight: self.dynamicHeight)
                       .padding([.top, .bottom], -10)
                       .padding(.leading, -4)

    }
    
    enum PresentationMode {
        case bytes
        case text
        case attributedString
    }
}

#if DEBUG
struct SelectableBytesTextView_Preview: PreviewProvider {
    static var test:String = ""//some very very very long description string to be initially wider than screen"
    static var testBinding = Binding<String>(get: { test }, set: {
//        print("New value: \($0)")
        test = $0 } )

    static var previews: some View {
        VStack(alignment: .leading) {
            Text("Description:")
            MultilineTextField("Enter some text here", text: testBinding, onCommit: {
                print("Final text: \(test)")
            })
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.black))
            Text("Something static here...")
            Spacer()
        }
        .padding()
    }
}
#endif
