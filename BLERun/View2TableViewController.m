//
//  View2TableViewController.m
//  BLERun
//
//  Created by jv on 2018/9/3.
//  Copyright © 2018年 yolo. All rights reserved.
//

#import "View2TableViewController.h"
#import "ChatKeyBoard.h"
#import <Masonry/Masonry.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import "MessageTableViewCell.h"

static NSString* const kCellIdn = @"cell";

static NSString* const kServiceId = @"77777777-7777-7777-7777-777777777777";
static NSString* const kNotifyId = @"99999999-9999-9999-9999-999999999999";
static NSString* const kWriteId = @"88888888-8888-8888-8888-888888888888";

@interface View2TableViewController ()<CBPeripheralDelegate,UITableViewDataSource,UITableViewDelegate,ChatKeyBoardDelegate, ChatKeyBoardDataSource>
{
    NSMutableArray *_messages;
    
    CBService *_ser;
    CBCharacteristic *_notifyCha;
    CBCharacteristic *_writeCha;
}

@property (strong, nonatomic) ChatKeyBoard *chatKeyBoard;
@property (strong, nonatomic) UITableView *messageTableView;

@end

@implementation View2TableViewController

- (void)dealloc {
    
#ifdef DEBUG
    NSLog(@"%s",__FUNCTION__);
#endif
    
    [_peripheral setNotifyValue:NO forCharacteristic:_notifyCha];
    _notifyCha = nil;
    _writeCha = nil;
    _ser = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    _messages = [NSMutableArray array];
    
    
    _messageTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _messageTableView.delegate = self;
    _messageTableView.dataSource = self;
    [self.view addSubview:_messageTableView];
    [_messageTableView mas_makeConstraints:^(MASConstraintMaker *make){
        make.edges.mas_equalTo(0);
    }];

    [_messageTableView registerNib:[UINib nibWithNibName:NSStringFromClass(MessageTableViewCell.class) bundle:nil] forCellReuseIdentifier:kCellIdn];
    
    self.chatKeyBoard = [ChatKeyBoard keyBoard];
    self.chatKeyBoard.delegate = self;
    self.chatKeyBoard.dataSource = self;
    self.chatKeyBoard.associateTableView = _messageTableView;
    [self.view addSubview:self.chatKeyBoard];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self _autoConnect];
    [self.chatKeyBoard.chatToolBar.textView becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MessageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdn forIndexPath:indexPath];
    
    MessageModel *model = _messages[indexPath.row];
    
    cell.model = model;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}


#pragma mark - cs delegate

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

//设备服务更改了
- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray<CBService *> *)invalidatedServices {
#ifdef DEBUG
    NSLog(@"peripheral modified.");
#endif
}

//扫描到Services
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    //  NSLog(@">>>扫描到服务：%@",peripheral.services);
    if (error)
    {
        NSLog(@">>>Discovered services for %@ with error: %@", peripheral.name, [error localizedDescription]);
        [self _autoConnect];
        return;
    }
    
    for (CBService *service in peripheral.services) {
        if ([service.UUID.UUIDString isEqualToString:kServiceId]) {
            _ser = service;
            [peripheral discoverCharacteristics:nil forService:_ser];
            break;
        }
    }
    
    if (!_ser) {
        [peripheral discoverCharacteristics:nil forService:_ser];
    }
    
}

//扫描到Characteristics
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    if (error)
    {
        NSLog(@"error Discovered characteristics for %@ with error: %@", service.UUID, [error localizedDescription]);
        [peripheral discoverCharacteristics:nil forService:service];
        return;
    }
    
    NSArray *chars = service.characteristics;
    
    for (CBCharacteristic *cha in chars) {
        if ([cha.UUID.UUIDString isEqualToString:kNotifyId]) {
            _notifyCha = cha;
            [_peripheral setNotifyValue:YES forCharacteristic:_notifyCha];
        }
        
        if ([cha.UUID.UUIDString isEqualToString:kWriteId]) {
            _writeCha = cha;
        }
    }
    
    if (_notifyCha && _writeCha) {
        [SVProgressHUD dismiss];
    }else{
        [peripheral discoverCharacteristics:nil forService:service];
    }
}


#pragma mark - value delegate

//获取的charateristic的值
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    
    //打印出characteristic的UUID和值
    //!注意，value的类型是NSData，具体开发时，会根据外设协议制定的方式去解析数据
    NSData *v = characteristic.value;
//    int k;
//    [v getBytes:&k length:[v length]];
//    NSLog(@"v:%i value:%@ s:%@ int:%lu",k,v,[self hexadecimalString:v],strtoul([[self hexadecimalString:v] UTF8String],0,16));
#ifdef DEBUG
    NSLog(@"收到了 ：%@ 长度：%ul",[[NSString alloc] initWithData:v encoding:NSUTF8StringEncoding],v.length);
#endif
    
    MessageModel *model = [MessageModel new];
    model.content = [[NSString alloc] initWithData:v encoding:NSUTF8StringEncoding];
    
    [_messages addObject:model];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_messages.count - 1 inSection:0];
    [_messageTableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationBottom];
    [_messageTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];

}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
#ifdef DEBUG
    NSLog(@"written. error: %@",error);
#endif
    
    if (!error) {
//        NSData *v = characteristic.value;
    }else{
        [SVProgressHUD showErrorWithStatus:@"发送失败"];
    }
    
}

#pragma mark - method

- (void)_autoConnect {
    [SVProgressHUD show];
    _peripheral.delegate = self;
    [_peripheral discoverServices:nil];
}

- (NSString*)hexadecimalString:(NSData *)data{
    NSString* result;
    const unsigned char* dataBuffer = (const unsigned char*)[data bytes];
    if(!dataBuffer){
        return nil;
    }
    NSUInteger dataLength = [data length];
    NSMutableString* hexString = [NSMutableString stringWithCapacity:(dataLength * 2)];
    for(int i = 0; i < dataLength; i++){
        [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];
    }
    result = [NSString stringWithString:hexString];
    return result;
}
//将传入的NSString类型转换成NSData并返回
- (NSData*)dataWithHexstring:(NSString *)hexstring{
    NSData* aData;
    return aData = [hexstring dataUsingEncoding: NSASCIIStringEncoding];
}

#pragma mark - message delegate

- (void)chatKeyBoardSendText:(NSString *)text {
    
    if (text.length > 0 && text.length < 182) {
        
        [_peripheral writeValue:[text dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:_writeCha type:CBCharacteristicWriteWithResponse];
        
        MessageModel *model = [MessageModel new];
        model.me = YES;
        //        model.content = [[NSString alloc] initWithData:v encoding:NSUTF8StringEncoding];
        model.content = text;
        
        [_messages addObject:model];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_messages.count - 1 inSection:0];
        [_messageTableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationBottom];
        [_messageTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];

    }else{
        [SVProgressHUD showErrorWithStatus:@"字符长度非法"];
    }
    
}

#pragma mark -- ChatKeyBoardDataSource
- (NSArray<MoreItem *> *)chatKeyBoardMorePanelItems
{
    MoreItem *item1 = [MoreItem moreItemWithPicName:@"sharemore_location" highLightPicName:nil itemName:@"位置"];
    MoreItem *item2 = [MoreItem moreItemWithPicName:@"sharemore_pic" highLightPicName:nil itemName:@"图片"];
    MoreItem *item3 = [MoreItem moreItemWithPicName:@"sharemore_video" highLightPicName:nil itemName:@"拍照"];
    MoreItem *item4 = [MoreItem moreItemWithPicName:@"sharemore_location" highLightPicName:nil itemName:@"位置"];
    MoreItem *item5 = [MoreItem moreItemWithPicName:@"sharemore_pic" highLightPicName:nil itemName:@"图片"];
    MoreItem *item6 = [MoreItem moreItemWithPicName:@"sharemore_video" highLightPicName:nil itemName:@"拍照"];
    MoreItem *item7 = [MoreItem moreItemWithPicName:@"sharemore_location" highLightPicName:nil itemName:@"位置"];
    MoreItem *item8 = [MoreItem moreItemWithPicName:@"sharemore_pic" highLightPicName:nil itemName:@"图片"];
    MoreItem *item9 = [MoreItem moreItemWithPicName:@"sharemore_video" highLightPicName:nil itemName:@"拍照"];
    return @[item1, item2, item3, item4, item5, item6, item7, item8, item9];
}

- (NSArray<ChatToolBarItem *> *)chatKeyBoardToolbarItems
{
    ChatToolBarItem *item1 = [ChatToolBarItem barItemWithKind:kBarItemFace normal:@"face" high:@"face_HL" select:@"keyboard"];
    
    ChatToolBarItem *item2 = [ChatToolBarItem barItemWithKind:kBarItemVoice normal:@"voice" high:@"voice_HL" select:@"keyboard"];
    
    ChatToolBarItem *item3 = [ChatToolBarItem barItemWithKind:kBarItemMore normal:@"more_ios" high:@"more_ios_HL" select:nil];
    
    ChatToolBarItem *item4 = [ChatToolBarItem barItemWithKind:kBarItemSwitchBar normal:@"switchDown" high:nil select:nil];
    
    return @[item1, item2, item3, item4];
}

- (NSArray<FaceThemeModel *> *)chatKeyBoardFacePanelSubjectItems
{
    NSMutableArray *subjectArray = [NSMutableArray array];
    
    NSArray *sources = @[@"face"];
    
    for (int i = 0; i < sources.count; ++i)
    {
        NSString *plistName = sources[i];
        
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:plistName ofType:@"plist"];
        NSDictionary *faceDic = [NSDictionary dictionaryWithContentsOfFile:plistPath];
        NSArray *allkeys = faceDic.allKeys;
        
        FaceThemeModel *themeM = [[FaceThemeModel alloc] init];
        themeM.themeStyle = FaceThemeStyleCustomEmoji;
        themeM.themeDecribe = [NSString stringWithFormat:@"f%d", i];
        
        NSMutableArray *modelsArr = [NSMutableArray array];
        
        for (int i = 0; i < allkeys.count; ++i) {
            NSString *name = allkeys[i];
            FaceModel *fm = [[FaceModel alloc] init];
            fm.faceTitle = name;
            fm.faceIcon = [faceDic objectForKey:name];
            [modelsArr addObject:fm];
        }
        themeM.faceModels = modelsArr;
        
        [subjectArray addObject:themeM];
    }
    
    return subjectArray;
}


@end


@implementation MessageModel

@end



