# BTLEmap 

<div style="text-align:center">
<img src="./BLE-Scanner/Assets.xcassets/AppIcon.appiconset/Icon Mac-512pt.png" width=256px>
</div>

## Installation 

Pull the GitHub repository, open it in Xcode and run it on iOS or macOS. The linked libraries should be fetched automatically with the Swift Package Manager integration of Xcode. 

## Features 

The main app is divided in three parts: (1) BLE Devices, (2) Proximity View, (3) RSSI Graph. 

### BLE Devices 
This view shows a list of BLE Devices discovered in your surrounding. Every device has an icon, either a Bluetooth logo or an icon representing the identified device class.
You can click on a device to show all advertisements  that have been received by this device. The advertisements are dissected at best effort. If no dissector is available or parts of the data are encrypted the binary data will be shown. 
If the BLE scanner has been able to detect services on this devices it lists them in the detail view as well. This includes all detected characteristics. 

Using the Button with 3 Dots on the right of the list the settings are accessible. 

### Proximity View  

The proximity view presents the same data on a circular plane. All devices are positioned on this plane according to the measured RSSI value. RSSI values do not allow distance measurement, but they give an estimation on the relative distance between all devices discovered in the area. 
The devices animate in real-time to new RSSI values received. A user can click on a device to show its detail view as possible on the *BLE Devices* view. 

### RSSI Graph

The RSSI graph plots a graph automatically on all received RSSI values for each device. On the left side all devices are listed and they can be select to be highlighted. 

### PCAP support

All received advertisements can be exported into the pcap format. This allows them to be opened in Wireshark. The export can be started from the Settings view. 
Pcap files can also be imported to show previous measurements. 

### External scanners 

The app allows to get its Bluetooth scanning data from an external scanner. In our example implementation this is performed by an Raspberry Pi. 
How to setup the Raspberry Pi can be seen in a section below. 
Other scanners are generally supported, too. For this the scanner needs to support the same protocol as the Raspberry Pi and be able to communicate over TCP to the device running the app. 
This communication could be handled over WiFi or Ethernet. 


## WiSec Demo Paper 

This project has been accepted as a demo on WiSec 2020. You can find the demo paper on [arxiv](https://arxiv.org/abs/2007.00349). 

## Limits 

Due to Apple's CoreBluetooth API the app has certain limits to the Bluetooth Low Energy access. These limits are based on the operating system and mostly apply to iOS. 

1. No access to manufacturer data starting with the Apple company id (0x4c00). This issue is only present on iOS / iPadOS 
2. No access to certain Apple specific GATT services. Present on iOS and macOS. The services will not be listed if requested 
3. No access to the device MAC address. The MAC address is replaces with a UUID that is generated on demand and not linked to a MAC address  

### Removing the limits 
Those limits are introduced by Apple's entitlement scheme that grants certain permissions to apps that are signed with a specific set of entitlements. 
Certain Apple daemons and apps have full access to all Bluetooth data, e.g. the sharingd. To assign this entitlements to any app, Apple would need to create a provisioning profile that is signed by apple and grants the priviliges to a specific app or development team. It is possible to resign an application with any entitlements and install it on devices that supports running unsigned apps, e.g. a jailbroken iPhone.  

## Raspberry Pi Setup

The app supports a Raspberry pi (Rpi) as an external scanner. 
We created a shell script that allows setup the raspberry pi as a scanner as easy as possible. We are currently tweaking some last things before this will be released. 


## Icons 

Icons are from 

*Laura Reen* using creative commons license as stated in https://creativecommons.org/licenses/by/3.0/

*Icons8* - https://icons8.com/license 

*Apple Inc* - https://developer.apple.com/design/human-interface-guidelines/sf-symbols/overview/

