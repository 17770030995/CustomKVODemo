//
//  Person.m
//  CustomKVODemo
//
//  Created by 李传熔 on 2021/5/19.
//

#import "Person.h"

@implementation Person

-(void)setNickName:(NSString *)nickName
{
    NSLog(@"来到Person 的setter 方法:%@",nickName);
    _nickName = nickName;
}

-(void)dealloc
{
    NSLog(@"%s",__func__);
}

@end
