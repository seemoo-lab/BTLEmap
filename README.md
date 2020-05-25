# BLE Scanner 

## Installation 

Pull the GitHub repository, open it in Xcode and run it on iOS or macOS. The linked libraries should be fetched automatically with the Swift Package Manager integration of Xcode. 

## Features 

The main app is divided in three parts: (1) BLE Devices, (2) Proximity View, (3) RSSI Graph. 

### BLE Devices 
This view shows a list of BLE Devices discovered in your surrounding. Every device has an icon, either a Bluetooth logo or an icon representing the identified device class.
You can click on a device to show all advertisements  that have been received by this device. The advertisements are dissected at best effort. If no dissector is available or parts of the data are encrypted the binary data will be shown. 
If the BLE scanner has been able to detect services on this devices it lists them in the detail view as well. This includes all detected characteristics. 

Using the Button with 3 Dots on the right of the list the settings are accessible. 

### Settings 


## Icons 

Icons are from 

*Laura Reen* using creative commons license as stated in https://creativecommons.org/licenses/by/3.0/

*Icons8* - https://icons8.com/license 

*Apple Inc* - https://developer.apple.com/design/human-interface-guidelines/sf-symbols/overview/

