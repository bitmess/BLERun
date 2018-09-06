//
//  ViewController.m
//  BLERun
//
//  Created by jv on 2018/9/3.
//  Copyright © 2018年 yolo. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "View2TableViewController.h"

static NSString* const kCellIdn = @"cell";

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource,CBCentralManagerDelegate>
{
    //系统蓝牙设备管理对象，可以把他理解为主设备，通过他，可以去扫描和链接外设
    CBCentralManager *_manager;
    //用于保存被发现设备
    NSMutableArray *_discoverPeripherals;

    CBPeripheral *_connectedP;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //初始化并设置委托和线程队列，最好一个线程的参数可以为nil，默认会就main线程
    _manager = [[CBCentralManager alloc]initWithDelegate:self queue:dispatch_get_main_queue()];
    
    //持有发现的设备,如果不持有设备会导致CBPeripheralDelegate方法不能正确回调
    _discoverPeripherals = [[NSMutableArray alloc]init];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self refreshAction:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - table view delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return _discoverPeripherals.count;
    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdn forIndexPath:indexPath];
    
    CBPeripheral *p = _discoverPeripherals[indexPath.row];
    
    cell.textLabel.text = p.name;
    
    return cell;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CBPeripheral *p = _discoverPeripherals[indexPath.row];

    [_manager connectPeripheral:p options:nil];
    
}

#pragma mark - bluetooth delegate

-(void)centralManagerDidUpdateState:(CBCentralManager *)central{
    
    switch (central.state) {
        case CBCentralManagerStateUnknown:
            NSLog(@">>>CBCentralManagerStateUnknown");
            break;
        case CBCentralManagerStateResetting:
            NSLog(@">>>CBCentralManagerStateResetting");
            break;
        case CBCentralManagerStateUnsupported:
            NSLog(@">>>CBCentralManagerStateUnsupported");
            break;
        case CBCentralManagerStateUnauthorized:
            NSLog(@">>>CBCentralManagerStateUnauthorized");
            break;
        case CBCentralManagerStatePoweredOff:
            NSLog(@">>>CBCentralManagerStatePoweredOff");
            break;
        case CBCentralManagerStatePoweredOn:
            NSLog(@">>>CBCentralManagerStatePoweredOn");
            //开始扫描周围的外设
            /*
             第一个参数nil就是扫描周围所有的外设，扫描到外设后会进入
             - (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI;
             */
            [central scanForPeripheralsWithServices:nil options:nil];
            
            break;
        default:
            break;
    }
    
}

//扫描到设备会进入方法
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    
    //接下连接我们的测试设备，如果你没有设备，可以下载一个app叫lightbule的app去模拟一个设备
    //这里自己去设置下连接规则，我设置的是P开头的设备
    //    if ([peripheral.name hasPrefix:@"P"]){
    /*
     一个主设备最多能连7个外设，每个外设最多只能给一个主设备连接,连接成功，失败，断开会进入各自的委托
     - (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral;//连接外设成功的委托
     - (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;//外设连接失败的委托
     - (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;//断开外设的委托
     */
    
    //找到的设备必须持有它，否则CBCentralManager中也不会保存peripheral，那么CBPeripheralDelegate中的方法也不会被调用！！
    if (peripheral.name.length > 0) {
        
        __block BOOL found = NO;
        
        [_discoverPeripherals enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if ([[obj name] isEqualToString:peripheral.name]) {
                found = YES;
                *stop = YES;
            }
            
        }];
        
        if (!found) {
            [_discoverPeripherals addObject:peripheral];
        }

    }
    [self.tableView reloadData];
    //    }
    
    
}

#pragma mark - per delegate

//连接到Peripherals-失败
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@">>>连接到名称为（%@）的设备-失败,原因:%@",[peripheral name],[error localizedDescription]);
}

//Peripherals断开连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@">>>外设连接断开连接 %@: %@\n", [peripheral name], [error localizedDescription]);
    
}
//连接到Peripherals-成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@">>>连接到名称为（%@）的设备-成功",peripheral.name);
//    //设置的peripheral委托CBPeripheralDelegate
//    //@interface ViewController : UIViewController<CBCentralManagerDelegate,CBPeripheralDelegate>
//    [peripheral setDelegate:self];
//    //扫描外设Services，成功后会进入方法：-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
//    [peripheral discoverServices:nil];
    
    _connectedP = peripheral;
    
    View2TableViewController *serviceCtrl = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"service"];
    
    serviceCtrl.peripheral = peripheral;
    
    [self.navigationController pushViewController:serviceCtrl animated:YES];
    
}

#pragma mark - action

- (IBAction)refreshAction:(id)sender {

    if (_connectedP) {
        [_manager cancelPeripheralConnection:_connectedP];
        _connectedP = nil;
    }
    
    [_manager scanForPeripheralsWithServices:nil options:nil];
    
}




@end
