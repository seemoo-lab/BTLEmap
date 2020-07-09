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
| 0x02      | BLE Service charactersitics Info | 
| 0xef      | Control Command |


### BLE Advertisement 

Every time the external receiver receives an advertisement it should send the advertisement data in a JSON message formatted like this: 

```json
{
    "manufacturerDataHex": "Hex formatted string", 
    "macAddress": "aa:bb:cc:dd:ee:ff", 
    "rssi": -10, 
    "name": "BLE Name" | null,  
    "flags": "" | null,
    "addressType": "random" | "public", 
    "connectable": true | false, 
    "rawData": "Hex formatted raw data", 
    "serviceUUIDs": ["UUID1", "UUID2"], //Strings for service UUIDs advertised  
    "serviceData16Bit": "UUID+UUID_Data" // hex encoded
    "serviceData32Bit": "UUID+UUID_Data"  // hex encoded
    "serviceData128Bit": "UUID+UUID_Data" // hex encoded
    }   
}
```



### BLE Services

After the external receiver has connected to a device and fetched the services supported by the the device. 
It does only contain basic service information, like the UUID and an optional common name. 

```json
{
    "macAddress": "aa:bb:cc:dd",
    "services": [
        {
            "uuid": "Hex formatted UUID", 
            "commonName": "Common name or UUID string"
        }
    ]
}
```

### BLE Service characteristics info 

After the external receiver has accessed a service and fetched the characteristics. Not all characteristics can be read and therefore the value may be null. Otherwise, its a hex formatted value that can be an interger or string depending on the characteristic that has been read. 

```json
{
    "macAddress":  "aa:bb:cc:dd", 
    "service": {
        "uuid": "Hex formatted UUID", 
        "commonName": "Common name or UUID string"
    }, 
    "characteristics": [
        {
            "properties": "READ, WRITE, EXTENDED", // Comma seperated strings 
            "uuid": "Hex formatted UUID", 
            "commonName": "Characteristic common name or UUID string", 
            "value": "Hex formatted read value" | null
        }
    ]
}
```


### Control Commands
The App is able to send control commands to the external receiver, e.g. to start or stop BLE Scanning. 
Before the external receiver scans the app will send such a command to the receiver to set it up. 

The JSON structure is defined as: 
```json
{
    // If true: Start scanning. If false: Stop any ongoing scans 
    "scanning": true | false, 
    // If true: The receiver should automatically connect to all discovered devices to request more information, like services, characteristics and characteristic values 
    "autoconnect": true | false,
}
```

If scanning is set t true the external receiver should start the scan for BLE devices and BLE advertisements.
If the autoconnect is set to true the external receiver should connect to all discovered and connectable devices. Then after a connection the it requests services and characteristics 
