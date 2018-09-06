//
//  MessageTableViewCell.m
//  BLERun
//
//  Created by jv on 2018/9/5.
//  Copyright © 2018年 yolo. All rights reserved.
//

#import "MessageTableViewCell.h"

#pragma mark - Class Extension
#pragma mark -

@interface MessageTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *messageLabel;

@end

@implementation MessageTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - setter

- (void)setModel:(MessageModel *)model {
    _model = model;
    
    _messageLabel.textAlignment = _model.me ? NSTextAlignmentRight : NSTextAlignmentLeft;
    _messageLabel.textColor = _model.me ? UIColor.blueColor : UIColor.blackColor;
    _messageLabel.text = _model.content;
    
}

@end
