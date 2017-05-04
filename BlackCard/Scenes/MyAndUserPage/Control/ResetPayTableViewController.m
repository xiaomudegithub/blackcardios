//
//  ResetPayTableViewController.m
//  BlackCard
//
//  Created by abx’s mac on 2017/4/27.
//  Copyright © 2017年 abx’s mac. All rights reserved.
//

#import "ResetPayTableViewController.h"
#import "SendVerifyCodeButton.h"
#import "WXPay.h"
#import "ValidateHelper.h"
@interface ResetPayTableViewController ()<PayHelperDelegate>
@property (weak, nonatomic) IBOutlet UITextField *phoneField;

@property (weak, nonatomic) IBOutlet UITextField *verifyField;
@property (weak, nonatomic) IBOutlet SendVerifyCodeButton *verifyCodeButton;
@property (weak, nonatomic) IBOutlet UIButton *payButton;
@property (nonatomic)BOOL isRepay;

@property(copy,nonatomic)NSString *phoneNum;
@property(copy,nonatomic)NSString *verifyToken;
@end

@implementation ResetPayTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [WXPay shared].delegate = self;
    self.phoneField.text = _phoneNum;
 
    
}
- (IBAction)sendVerifyButtonAction:(SendVerifyCodeButton *)sender {
    


        
        [_verifyCodeButton startWithCount];
        WEAKSELF
        [[AppAPIHelper shared].getMyAndUserAPI sendVerifyCode:_phoneNum andType:@"3" complete:^(id data) {
            weakSelf.verifyToken = data[@"codeToken"];
            [weakSelf showTips:@"验证码已发送"];
            
        } error:^(NSError *error) {
            [weakSelf.verifyCodeButton stopWithCount];
            [weakSelf showError:error];
        }];
         
    
        
    
}
- (IBAction)payButtonAction:(UIButton *)sender {
    NSError *error = nil;
    if (_verifyToken == nil) {
        [self showTips:@"请先获取验证码"];
        
    }else if (![[ValidateHelper shared] checkNumber:_verifyField.text emptyString:@"请输入验证码" errorString:@"请输入正确的验证码" error:&error]){
        [self showError:error];
    }else {
        
        NSDictionary *dic = @{@"phoneNum" : _phoneNum,@"phoneCode" :_verifyField.text ,@"codeToken" : _verifyToken};
        [self payWithDic:dic];
        
        
    }
    
    
    
    
    
}

- (void)payHelperWithType:(PayType)type withPayStatus:(PayStatus)payStatus withData:(id)data {
    switch (payStatus) {
        case PayError: {  //支付失败
             UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"支付失败" message:@"请重新支付" delegate:self cancelButtonTitle:@"确定" otherButtonTitles: nil];
            [alert show];
            [self payButtonSetting];
        }
            break;
        case PayOK:{ //支付成功
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"支付成功" message:@"" delegate:self cancelButtonTitle:@"确定" otherButtonTitles: nil];
            WEAKSELF
            [alert showWithCompleteBlock:^(NSInteger buttonIndex) {
                [weakSelf.navigationController  dismissViewControllerAnimated:YES completion:nil];
                
                
            }];
            
            
            
        }
            break;
        case PayCancel:{//支付取消
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"支付已取消" message:@"" delegate:self cancelButtonTitle:@"确定" otherButtonTitles: nil];
            [alert show];
            [self payButtonSetting];
        }
            break;
        case PayHandle:{ //处理中
            APPLOG(@"处理中");
            
        }
            break;
    }
    
}

- (void)payStart {
    
}

- (void)payError:(NSString *)error {
    
    [self showTips:error];
    [self payButtonSetting];
}

- (void)payButtonSetting {
    _isRepay = YES;

    [self.payButton setTitle:@"重新支付" forState:UIControlStateNormal];
    
}

- (void)payWithDic:(NSDictionary *)dic {
    WEAKSELF
        [self showLoader:@"支付中..."];
    
    [[AppAPIHelper shared].getMyAndUserAPI registerWithPay:dic complete:^(PayInfoModel *model) {
        [weakSelf hiddenProgress];
        [[WXPay shared] payWithWXModel:model.wxPayInfo];
        
    } error:^(NSError *error) {
        [weakSelf showError:error];
        [weakSelf payButtonSetting];
    }];
    
    
}

@end