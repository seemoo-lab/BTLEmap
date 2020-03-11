//
//  SharingBLEManager.m
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 11.03.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//


#import "SharingBLEHandler.h"
#import "BluetoothDevice.h"
#import "SFBLEScanner.h"

static SharingBLEHandler *_handler = nil;
static SFBLEScanner *_scanner = nil;

//static BluetoothDevice *_device = nil;

@implementation SharingBLEHandler

+ (SharingBLEHandler *) sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSBundle *b = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/Sharing.framework"];
        if (![b load]) {
            NSLog(@"Error"); // maybe throw an exception
        } else {
//            _bluetoothManager = [NSClassFromString(@"BluetoothManager") valueForKey:@"sharedInstance"];
//            _scanner = [[SFBLEScanner alloc] init];
            _handler = [[SharingBLEHandler alloc] init];
            
            
//            _scanner = [[class alloc] init];
        }
    });
    return _handler;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        //Set callbacks for SFBLEScanner
        Class class = NSClassFromString(@"SFBLEScanner");
        _scanner = [[class alloc] initWithType:0x07];
        [_scanner setScanCache:YES];
        [_scanner setRssiThreshold:0xffffffffffffffc4];
        [_scanner setChangeFlags:0x09];
        [_scanner setDispatchQueue:dispatch_get_main_queue()];
        
        [_scanner setScanRate:0x14];
        
        [_scanner setBluetoothStateChangedHandler:^void (id state) {
            NSLog(@"Bluetooth state changed");
        }];
        [_scanner setDeviceFoundHandler:^void (id device){
            NSLog(@"Found device");
        }];
        
        [_scanner setDeviceLostHandler:^void (id device) {
            NSLog(@"Device lost");
        }];
        
        [_scanner setDeviceChangedHandler:^void (id device) {
            NSLog(@"Device changed");
        }];
        
        [_scanner setInvalidationHandler:^void () {
            NSLog(@"Scanner invalidated");
        }];
        
        [_scanner setTimeoutHandler:^void (id device) {
            NSLog(@"Timeout handler");
        }];
        
    }
    return self;
}

- (void) startScan {
    [_scanner activateWithCompletion:^void (NSError * error) {
        if (!error)  {
            NSLog(@"Activated");
        }else {
            NSLog(@"Failed with error %@", error);
        }
    }];
}

@end
