//
//  AWDLScannerView.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 12.03.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import Foundation
import SwiftUI
import AWDLScanner

struct AWDLScannerView: View {
    @EnvironmentObject var netBrowser: AWDLNetServiceBrowser
    @Environment(\.horizontalSizeClass) var sizeClass
    
    var awdlSpoofer = AWDLServiceSpoofer()
    
    var displayedServices: [AWDLNetService] {
        return netBrowser.foundServices
    }
    
    var cols: CGFloat = 3
    @State var isSpoofing = false
    
    
    var largeView: some View {
        Group {
            ZStack {
                HStack {
                    Text("Service_Name")
                        .font(.headline)
                    Spacer()
                }
                
                HStack {
                    Spacer()
                    Text("Service_Type")
                        .font(.headline)
                    Spacer()
                    Spacer()
                }
                
                HStack {
                    Spacer()
                    Spacer()
                    Text("Port")
                        .font(.headline)
                    Spacer()
                }
                
                HStack {
                    Spacer()
                    Text("Runs on AWDL")
                        .font(.headline)
                }
            }
            .padding([.leading, .trailing])
            
            List {
                ForEach(self.displayedServices, id: \.name) { service in
                    
                    AWDLServiceRowView(service: service, cols: 4)
                    
                }
            }
        }
    }
    
    var smallView: some View {
        List {
            ForEach(self.displayedServices, id: \.name) { service in
                NavigationLink(destination: AWDLServiceDetailView(service: service)) {
                    VStack(alignment: .leading) {
                        Text("Name:\t").font(.headline) + Text(service.name)
                        Text("Type:\t").font(.headline) + Text(service.type)
                        Text("Port:\t").font(.headline) + Text("\(service.service.port)")
                        Text("AWDL:\t").font(.headline) + Text("\(service.includesAWDL ? "true" : "false")")
                    }
                }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if self.sizeClass == .compact {
                    self.smallView
                }else {
                    self.largeView
                }
            }
            .navigationBarTitle("AWDL Scanner")
            .navigationBarItems(trailing: Button(action: {
                self.spoofServices()
            }, label: {
                Text(self.isSpoofing ? "Stop spoofing" :  "Spoof services")
            }))
            
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    func spoofServices() {
        if !isSpoofing {
            //Turn on spoofer
            self.awdlSpoofer.spoofAllServices(withTypes: self.netBrowser.foundServices.map{$0.type})
            self.isSpoofing = true
        }else {
            self.isSpoofing = false
            self.awdlSpoofer.stopSpoofing()
            self.netBrowser.stopSearching()
            self.netBrowser.startSearching()
        }
    }
}

struct AWDLServiceRowView: View {
    @ObservedObject var service: AWDLNetService
    var cols: Int = 1
    
    var navigationView: some View {
        NavigationLink(destination: AWDLServiceDetailView(service: service)) {
            self.contentView
        }
    }
    
    var windowView: some View {
        Group {
            self.contentView
        }
        .contentShape(Rectangle())
        .onTapGesture {
            let ua = NSUserActivity(activityType: "de.tu-darmstadt.seemoo.awdlService.detail")
            ua.userInfo = ["awdlServiceName" : self.service.name]

            UIApplication.shared.requestSceneSessionActivation(nil, userActivity: ua, options: nil)
        }
    }
    
    var contentView: some View {
        VStack {
            ZStack {
                HStack {
                    Text(service.name)
                    Spacer()
                }
                
                HStack {
                    Spacer()
                    Text(service.type)
                    Spacer()
                    Spacer()
                }
                
                HStack {
                    Spacer()
                    Spacer()
                    Text("\(service.service.port)")
                    Spacer()
                }
                
                HStack {
                    Spacer()
                    Text("\(service.includesAWDL ? "true" : "false")")
                    
                }
            }
            
        }
    }
    
    var body: some View {
        self.navigationView
//        #if targetEnvironment(macCatalyst)
//        return self.windowView
//        #else
//        return self.navigationView
//        #endif
    }
}
