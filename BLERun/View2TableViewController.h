//
//  View2TableViewController.h
//  BLERun
//
//  Created by jv on 2018/9/3.
//  Copyright © 2018年 yolo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface View2TableViewController : UIViewController

@property (strong, nonatomic) CBPeripheral *peripheral;

@end

@interface MessageModel : NSObject

@property (copy, nonatomic) NSString *content;
@property (assign, nonatomic) BOOL me;

@end
