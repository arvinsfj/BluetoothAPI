//
//  BLEConnView.h
//  AJJ-Measure
//
//  Created by vin on 2018/6/15.
//

#import <UIKit/UIKit.h>

@interface BLEConnView : UIView
@property (nonatomic, copy) void (^closeAction)(void);
@property (nonatomic, copy) void (^connAction)(NSInteger);

- (void)refreshDeviceList;

@end

@interface DeviceTableCell : UITableViewCell

@property (nonatomic, strong) UILabel* nameLbl;
@property (nonatomic, strong) UIButton* flagBtn;
@property (nonatomic, strong) UIImageView* line;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier andFrame:(CGRect)frame;

@end
