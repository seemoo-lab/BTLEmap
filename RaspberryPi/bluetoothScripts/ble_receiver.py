#!/usr/bin/env python3

from bluepy.btle import Scanner, DefaultDelegate, ScanEntry, Peripheral, UUID, Service, Characteristic, AssignedNumbers
from enum import IntEnum
from zeroconf import ServiceBrowser, Zeroconf
import socket
import sys
import json
import datetime
from threading import Timer, Lock, Thread
import daemon
import asyncio
import argparse
import logging
import typing
import time 

# Get all ADV Types here 
# https://www.bluetooth.com/specifications/assigned-numbers/generic-access-profile/
# ScanEntry.AdvType

# https://www.bluetooth.com/specifications/gatt/services/
class BLEServicesUUIDs: 
    deviceInformation =  UUID(0x180A)

class BLECharacteristicUUIDs: 
    deviceInformation_modelNumber =  UUID(0x2A24)


class LogLevel(IntEnum): 
    ERR = 0
    DEBUG = 1 
    INFO = 3

Debugging = True
gl_log_level = LogLevel.INFO

def DBG(*args, logLevel=LogLevel.INFO):
    if Debugging:
        if gl_log_level >= logLevel:
            msg = " ".join([str(a) for a in args])
            print(msg)

# class BLERelayConf: 

#     def __init__(self): 
#         self.scanning = False 
#         # If true the raspberry pi connects automatically to all devices that it can connect to 
#         self.autoconnect = True 
#         self.ble_timeout = 2.0 
    
class BLERelay( DefaultDelegate): 

    ########################
    ##  BLE SCANNING
    ########################
    def __init__(self):
        self.packets_sent = 0
        self.scanning = False
        self.scanner = None 
        self.sock = None 
        self.sock_recv_thread = None
        self.current_service_info = None 
        self.connected_peripherals = list()
        self.isConnecting = False
        self.connected_scan_entry: ScanEntry = None 
        self.ble_timeout = 2.0 
        self.autoconnect = True
        self.readable_services = [AssignedNumbers.device_information, AssignedNumbers.generic_access, AssignedNumbers.generic_attribute]
        # List of characteristics UUIDs that hav failed. Created dynamically such that they won't be read a second time 
        self.failing_characteristics: typing.List[UUID] = list()
        DefaultDelegate.__init__(self)

    def handleDiscovery(self, dev, isNewDev, isNewData):
        """
        A BLE signal has been received. The content is part of the dev parameter 
        """
        self.relay_ble_advertisement(dev)
            


    def start_ble_scanning(self): 
        """
        Start the BLE Scanner
        """
        # Setup BLE Scanner 
        
        self.scanner =  Scanner().withDelegate(self)
        self.scanning = True
        t = Thread(target=self.scan_forever,  name="ble_scanning")
        t.start()
        

    def scan_forever(self):
        """
        Scan for BLE signals forever. Uses a short scannning time and a Timer to restart scanning quickly
        """

        while self.scanning:
            try: 
                # Scan for scan_time. Then scan again 
                DBG("Start scanning", logLevel=LogLevel.DEBUG)
                scan_time = 1.0
                devices = self.scanner.scan(scan_time, passive=False)
                connectable_devices = [dev for dev in devices if dev.connectable and not next((d for d in self.connected_peripherals if d == dev.addr), None)]
                DBG("Scan finished. Discovered {} devices".format(len(devices)))

                # Connect on a different thread 
                if self.autoconnect and len(connectable_devices) > 0: 
                    DBG("Connecting to device", logLevel=LogLevel.DEBUG)
                    # Connect to one device and read info before performing a scan again 
                    self.connected_scan_entry = connectable_devices[0]
                    self.read_info_from_ble_device(self.connected_scan_entry)
                elif len(connectable_devices) == 0: 
                    DBG("No connectable devices found", logLevel=LogLevel.DEBUG)
                else: 
                    DBG("Postponing connection. Already connecting", logLevel=LogLevel.DEBUG)

            except Exception as e: 
                DBG("Scan error", logLevel=LogLevel.ERR)
                logging.exception(e)

        DBG("Stopping BLE Scan", logLevel=LogLevel.DEBUG)

            #asyncio.create_task
            #asyncio.run_coroutine_threadsafe(self.connect_to_devices_async(connectable_devices), loop=asyncio.get_event_loop())


    def read_info_from_ble_device(self, dev: ScanEntry): 
        peripheral = self.connect_to_ble_device(dev)
        if peripheral:
            services = self.read_services_from_peripheral(peripheral, dev)
            self.read_characteristics(peripheral, dev, services)
            self.disconnect_from_peripheral(peripheral)
    
    def connect_to_ble_device(self, dev:  ScanEntry) -> Peripheral :
        """
        Connect to a BLE device. 
        This is used to discover services running on this device 
        """

        DBG("Connecting to {}".format(dev.addr), logLevel=LogLevel.DEBUG)

        ## Try connecting 
        try:
            self.connected_peripherals.append(dev.addr) 
            peripheral =  Peripheral(dev, timeout=self.ble_timeout)
            return peripheral
        except Exception as e:
            DBG("Connecting to {} failed".format(dev.addr), logLevel=LogLevel.ERR) 
            logging.exception(e)
            return None 
        
    def reconnect_to_device(self, dev: ScanEntry, old_peripheral: Peripheral) -> Peripheral: 
        try:
            # old_peripheral.disconnect() 
            time.sleep(0.5)
            DBG("Reconnecting to {}".format(dev.addr))
            peripheral =  Peripheral(dev, timeout=3.0)
            return peripheral
        except Exception as e:
            DBG("Reconnecting to {} failed".format(dev.addr), logLevel=LogLevel.ERR) 
            logging.exception(e)
            return None 
        
    def disconnect_from_peripheral(self, peripheral: Peripheral):
        try: 
            if peripheral: 
                peripheral.disconnect(timeout=self.ble_timeout)
        except Exception as e: 
            DBG("Disconnecting failed", logLevel=LogLevel.ERR)
            # DBG(e, logLevel=LogLevel.ERR)

    def read_services_from_peripheral(self, peripheral: Peripheral, dev: ScanEntry) -> typing.List[Service]:
        ## Try getting servicex
        try: 
            services = peripheral.getServices()
            self.relay_discovered_services(peripheral, services)
            return services
        except Exception as e:
            DBG("Getting services from {} failed".format(dev.addr), logLevel=LogLevel.ERR) 
            logging.exception(e)
            services = list() 
            return services
    
    def read_characteristics(self, peripheral: Peripheral, dev: ScanEntry, services:typing.List[Service]): 
        if len(services) > 0: 
            #Discovered services 
            DBG("Discovered services {}".format([s.uuid.getCommonName() for s in services]), logLevel=LogLevel.INFO)

            for s in services:
                try: 
                    DBG("Accessing service: {}".format(s.uuid.getCommonName()))
                    characteristics = s.getCharacteristics()
                    DBG("Discovered characteristics:\n\t{}".format([c.uuid.getCommonName() for c in characteristics]))
                    ## characteristics_info = [(c, b'') for c in characteristics]

                    if s.uuid in self.readable_services: 
                        self.read_value_for_charateristics(characteristics, s, peripheral, dev)     
                    else: 
                        characteristics_info = [(c, b'') for c in characteristics]
                        self.relay_service_information(dev, s, characteristics_info)

                    ## self.relay_service_information(peripheral, s, characteristics_info)
                except Exception as e: 
                    DBG("Accessing service  failed {}".format(s.uuid.getCommonName()), logLevel=LogLevel.ERR)
                    logging.exception(e)

                    # peripheral = self.reconnect_to_device(dev, old_peripheral=peripheral)
                    # if not peripheral:
                    #     break

    def read_value_for_charateristics(self, characteristics: typing.List[Characteristic], service: Service, peripheral: Peripheral, device: ScanEntry):
        characteristics_info = list()

        for c in characteristics: 
            try:
                # Check if Extended properties 
                DBG("Characteristic {} Properties {}".format(c, c.propertiesToString()),  logLevel=LogLevel.DEBUG)
                if c.properties & Characteristic.props["EXTENDED"]: 
                    DBG("Uses extended properties", logLevel=LogLevel.DEBUG)
                    characteristics_info.append((c, b''))
                    continue

                if c.supportsRead() and not c.uuid in self.failing_characteristics: 
                    value = peripheral.readCharacteristic(c.valHandle, timeout=self.ble_timeout)
                    characteristics_info.append((c, value))
                    DBG("Read {} and received {}".format(c.uuid.getCommonName(), value))
                else: 
                    characteristics_info.append((c, b''))
            except Exception as e: 
                DBG("Could not read characteristic {} - {}".format(c.uuid.getCommonName(), c.uuid.binVal), logLevel=LogLevel.DEBUG)
               #  DBG(e.with_traceback(), logLevel=LogLevel.ERR)
                characteristics_info.append((c, b''))
                # peripheral = self.reconnect_to_device(device, old_peripheral=peripheral)
                # if not peripheral:
                #         break
        
        self.relay_service_information(device, service, characteristics_info)
                



    def handleNotification(self, cHandle, data):
        """
        BTLE Peripheral delegate callback 
        """
        DBG("Received notification from cHandle: {} with data {}".format(cHandle, data), logLevel=LogLevel.INFO)


    ########################
    ##  ZEROCONF 
    ########################
    def remove_service(self, zeroconf, type, name): 
        """
        A service has been removed with mDNS/DNS-SD
        """
        if self.current_service_info and self.current_service_info.name == name: 
            # Service removed. Disconnect 
            self.disconnected_from_socket()

        DBG("Service %s removed" % (name,))

    def add_service(self, zeroconf, type, name):
        """
        A service has been resolved with mDNS / DNS-SD
        """
        info = zeroconf.get_service_info(type, name)
        #print("Service %s added, service info: %s" % (name, info))
        # Found service. Connect to it 
        self.connect_to_service(info)
        
    
    def connect_to_service(self, info): 
        """
        Connect to a service that has been detected 
        """
        self.current_service_info = info
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        addr_string = socket.inet_ntop(socket.AF_INET, info.addresses[0])
        #print("Service IP address {}".format(addr_string))
        service_address = (addr_string, info.port)
        DBG("Connecting to {}".format(service_address), logLevel=LogLevel.DEBUG)
        try:
            self.sock.settimeout(5.0)
            self.sock.connect(service_address)
            
            # Start receiving thread 
            t = Thread(target=self.receive_control_commands,  name="sock_receiving")
            t.start()

        except Exception as e: 
            DBG("Socket connection failed", logLevel=LogLevel.ERR)
            logging.exception(e)
            self.disconnected_from_socket()
    


    def disconnected_from_socket(self): 
        """
        Called when the socket disconnected. Clearing up the internal state 
        """
        DBG("Stopping...", logLevel=LogLevel.DEBUG)
        self.sock.close()
        self.scanning = False
        self.sock = None
        DBG("Cleaning up...")
        self.current_service_info = None 
        # Clear the lists for scanned peripherals 
        self.connected_peripherals = list()
            

    def receive_control_commands(self): 
        """
        Loop to receive data from the socket. 
        Run in it's own thread 
        """
        DBG("Waiting for incomming messages", logLevel=LogLevel.DEBUG)
        while self.sock:
            try: 
                header = self.sock.recv(5)
                if header: 
                    DBG("Received incoming message header ", header)
                    # Received header 
                    message_type = header[0]
                    message_length = int.from_bytes(header[1:], byteorder="little")
                    # Read the full message 
                    message = self.sock.recv(message_length)
                    self.control_command_received(message_type, message)
            except Exception as e:
                # Sockets can timeout. No worries to get an exception here
                # DBG("Error occured while receiving from socket", logLevel=LogLevel.ERR)
                # DBG(e, logLevel=LogLevel.ERR)
                continue  
    
    def control_command_received(self, message_type: bytes, message: bytes): 
        """
        The control commands have been received. They will be parsed
        """
        
        DBG("Received message\n type: {}, message: {}".format(message_type,message))

        # 0xfe is the message type for standard control commands 
        if message_type == 0xef: 
            # Decode message to JSON 
            json_message = json.loads(message)
            # {
            #   scanning: true | false, autoconnect: true | false  
            # }
            DBG("Received control command \n{}".format(json_message), logLevel=LogLevel.DEBUG)

            scanning = json_message["scanning"]
            if scanning == True: 
                self.start_ble_scanning()
            elif scanning == False: 
                self.scanning = False
                

            autoconnect = json_message["autoconnect"]
            if autoconnect == True : 
                self.autoconnect = True
            elif autoconnect == False: 
                self.autoconnect = False  


    ########################
    ##  RELAY BLE INFO
    ########################

    ## Sending BLE Packets 
    def relay_ble_advertisement(self, scanEntry:  ScanEntry): 
        """
        Send the BLE packet to the connected service running on iOS 
        """
        ### Message format 
        # 1 byte type - 4 bytes message length - message 
        ###

        name = scanEntry.getValueText( ScanEntry.COMPLETE_LOCAL_NAME)
        if not name: 
            name = scanEntry.getValueText( ScanEntry.SHORT_LOCAL_NAME)
        
        # services_16 = scanEntry.getValueText(ScanEntry.INCOMPLETE_16B_SERVICES)
        # services_32 = scanEntry.getValueText(ScanEntry.INCOMPLETE_32B_SERVICES)
        # services_128 = scanEntry.getValueText(ScanEntry.INCOMPLETE_128B_SERVICES)
        # print("Services 16B: \n\t{}\nServices 32B: \n\t{}\nServices 128B: \n\t{}".format(services_16, services_32 , services_128 ))
        DBG("Raw Data: {}".format(scanEntry.rawData), logLevel=LogLevel.DEBUG)
        raw_data_hex = ""
        if scanEntry.rawData: 
            raw_data_hex = scanEntry.rawData.hex()

        packet_content = {
            "manufacturerDataHex": scanEntry.getValueText(ScanEntry.MANUFACTURER), 
            "macAddress": scanEntry.addr, 
            "rssi": scanEntry.rssi,
            "name": name, 
            "flags": scanEntry.getValueText( ScanEntry.FLAGS), 
            "addressType": scanEntry.addrType,
            "connectable": scanEntry.connectable, 
            "rawData": raw_data_hex, 
            "scanData": {tag: scanEntry.getValueText(k) for k, tag in scanEntry.dataTags.items()}
        }
        DBG("Encoding json: ", packet_content)
        json_packet = json.dumps(packet_content).encode() 
        
        # Message type for advertisements is 0
        self.send_packet_over_socket(packet_type=0, packet_data=json_packet)

    def relay_discovered_services(self, device:  Peripheral, services:typing.List[ Service]):
        """
        Relay a packet with all services discovered for a peripheral
        """
        packet_content = {
            "macAddress": device.addr,
            "services": [{
                "uuid": s.uuid.binVal.hex(), 
                "commonName": s.uuid.getCommonName()
            } for s in services]
        }

        json_packet = json.dumps(packet_content).encode() 

        self.send_packet_over_socket(packet_type=1, packet_data=json_packet)

    def relay_service_information(self, device: ScanEntry, service: Service, characteristic_info: typing.List[typing.Tuple[Characteristic, bytes]]):

        packet_content = {
            "macAddress": device.addr, 
            "service": {
                "uuid": service.uuid.binVal.hex(), 
                "commonName": service.uuid.getCommonName() 
            }, 
            "characteristics": [{
                "serviceUUID": service.uuid.binVal.hex(),
                "uuid": c[0].uuid.binVal.hex(), 
                "commonName": c[0].uuid.getCommonName(), 
                "value": c[1].hex()
            } for c in characteristic_info]
        }
        json_packet = json.dumps(packet_content).encode() 

        self.send_packet_over_socket(packet_type=2, packet_data=json_packet)

    def send_packet_over_socket(self, packet_type: int, packet_data: bytes):
        """
        Send information over the connected socket

        Parameters: 
            packet_type (int): The integer representing the packet type that should be sent (e.g. 0 for a BLE advertisment)
            packer_data (bytes): The data for a packet that should be sent 
        """

        message_length = len(packet_data).to_bytes(4, byteorder="little")
        message_type = packet_type.to_bytes(1, byteorder="little")

        sendable_packet = message_type + message_length + packet_data

        DBG("Sending packet with content\n\t{}".format(packet_data.decode()))

        if not self.sock: 
            # No socket available 
            return 

        try: 
            self.packets_sent += 1
            # print("Sending no. {} at: {}".format(self.packets_sent, datetime.datetime.now()))
            self.sock.send(sendable_packet)
        except Exception as e: 
            DBG("Sending over socket failed", logLevel=LogLevel.ERR)
            DBG("Reason: {}".format(e), logLevel=LogLevel.ERR)
            self.disconnected_from_socket()


async def main(): 
    """
    Sets up the BLE Relay and Zeroconf and waits for an service to which it can connect. 
    If a service is detected it connects and relays all BLE messages
    """
    isRunning = True 
    try: 
        zConf = Zeroconf() 
        bleRelay = BLERelay()
        browser = ServiceBrowser(zConf, "_ble_relay_recv._tcp.local.", bleRelay)
    except Exception as e: 
        DBG(e, logLevel=LogLevel.ERR)
        isRunning = False

    DBG("Looking for ble relay receivers", logLevel=LogLevel.DEBUG)
    while True: 
        try: 
            await asyncio.sleep(1)
        except KeyboardInterrupt:
            break 
    
def syncMain(): 
    """
    Sets up the BLE Relay and Zeroconf and waits for an service to which it can connect. 
    If a service is detected it connects and relays all BLE messages
    """
    zConf = Zeroconf() 
    bleRelay = BLERelay()
    browser = ServiceBrowser(zConf, "_ble_relay_recv._tcp.local.", bleRelay)

    DBG("Looking for ble relay receivers", logLevel=LogLevel.DEBUG)

    input("Cancel with CTRL-D")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Relay BLE advertisements to network services")
    parser.add_argument("-a", dest="async_run", action='store_const', const=True, default=False, help="Pass -a to run asynchronous (useful for when running at startup)")
    parser.add_argument("-s", dest="scan_only", action='store_const', const=True, default=False, help="Pass -s to scan only without forwarding data")
    args = parser.parse_args()

    if args.scan_only:
        relay = BLERelay()
        relay.start_ble_scanning()


    if args.async_run: 
        asyncio.run(main())
    else: 
        syncMain()
    
