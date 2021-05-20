//
//  Person.h
//  CustomKVODemo
//
//  Created by 李传熔 on 2021/5/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Person : NSObject {
    @public
    NSString *name;
}

@property (nonatomic, copy) NSString *nickName;

@end

NS_ASSUME_NONNULL_END
