//
//  AWDLServiceDetailView.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 13.03.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import SwiftUI
import AWDLScanner

struct AWDLServiceDetailView: View {
    @ObservedObject var service: AWDLNetService
    
    var txtRecord: [TXTEntry]? {
        guard let txtData = service.txtRecord else {return nil}
        return NetService.dictionary(fromTXTRecord: txtData).map({TXTEntry(key: $0.key ,value: $0.value)})
    }
    
    var body: some View {
        
        ScrollView {
            VStack(alignment: .center) {
                Text(service.name)
                    .font(.title)
                Text(service.type)
                Text("\(service.service.port)")
                Text("AWDL")
                    .foregroundColor(service.includesAWDL ? Color("isOnColor") : Color("isOffColor"))
                
                Divider()
                
                VStack(alignment: .leading) {
                    Text("IP Addresses")
                        .font(.headline)
                    service.ipAddressStrings.map { (addresses)  in
                        ForEach(addresses, id: \.self, content: { address in
                            Text(address)
                        })
                    }
                    
                    Spacer()
                    
                    if txtRecord != nil {
                        Text("TXT Record")
                            .font(.headline)
                        ForEach(self.txtRecord!, id: \.key, content: { element in
                            Text("\(element.key): \t")
                                .bold()
                                +
                                Text(element.value.hexadecimal)
                        })
                    }
                }
            }.padding()
        }
        
    }
    
    struct TXTEntry {
        let key: String
        let value: Data
    }
}

//struct AWDLServiceDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        AWDLServiceDetailView()
//    }
//}
