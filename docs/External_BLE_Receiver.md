# External BLE Receiver 

The app supports to be connected to an external data source for receiving BLE advertisements and connecting to BLE devices. 
In our implementation this external receiver is a Raspberry Pi, but the format is specified and we can basically connect any external source that follows the data format. 
The devices need to connect to the app over a local network connection. This can be an Ethernet connection (Raspberry Pi), WiFi or AWDL. 

## Connecting to BLE Scanner App

The BLE Scanner App will advertise a service using DNS-SD and mDNS (Bonjoiur). Any capable device can query for `_ble_relay_recv._tcp.local`. 
The connection is a TCP Stream socket connection. The data format of messages sent over the socket is defined in the following sections

## Communication with the BLE Scanner App 

### Message Structure 
As the communication is socket based we need to define a message structure to send and receive messages. The structure is a simple Type-Length-Value structure. 
The Type uses one byte, the length 4 bytes (little-endian), and the value is a variable JSON encoded in binary. 

```
 --------------- ------------------ -------------------------
| Type (1 byte) | Length (4 bytes) | Value (x bytes) in JSON |
 --------------- ------------------ -------------------------
```

### Available Message types 

| Type Byte | Description |
|:----------|:------------|
| 0x00      | BLE Advertisement | 
| 0x01      | BLE Services      | 
| 0x02      | BLE Service Charactersitics Info | 
| 0xef      | Control Command |


### Control Commands
The App is able to send control commands to the external receiver, e.g. to start or stop BLE Scanning. 
Before the external receiver scans the app will send such a command to the receiver to set it up. 

The JSON structure is defined as: 
```
{
    // If true: Start scanning. If false: Stop any ongoing scans 
    "scanning": Boolean, 
    // If true: The receiver should automatically connect to all discovered devices to request more information, like services, characteristics and characteristic values 
    "autoconnect": Boolean,
}
```