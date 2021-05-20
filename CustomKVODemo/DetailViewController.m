//
//  DetailViewController.m
//  CustomKVODemo
//
//  Created by 李传熔 on 2021/5/19.
//

#import "DetailViewController.h"
#import "Person.h"
#import <objc/runtime.h>
#import "NSObject+KVO.h"

@interface DetailViewController ()

@property (nonatomic, strong) Person *person;

@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.person = [[Person alloc]init];
    
    [self.person lcr_addObserver:self forKayPath:@"nickName" block:^(id  _Nonnull observer, NSString * _Nonnull keyPath, id  _Nonnull oldValue, id  _Nonnull newValue) {
        NSLog(@"%@-%@",oldValue,newValue);
    }];
    self.person.nickName = @"Lcr";
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.person.nickName = [NSString stringWithFormat:@"%@ +", self.person.nickName];
}

-(void)dealloc
{
    NSLog(@"界面销毁");
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
