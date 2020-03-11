//
//  SharingBLEManager.h
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 11.03.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SharingBLEHandler : NSObject

+ (SharingBLEHandler *) sharedInstance;
- (void) startScan;

@end

NS_ASSUME_NONNULL_END
