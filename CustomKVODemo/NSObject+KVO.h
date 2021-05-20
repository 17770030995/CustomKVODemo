//
//  NSObject+KVO.h
//  CustomKVODemo
//
//  Created by 李传熔 on 2021/5/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
//id = void *
typedef void(^LcrKVOBlock)(id observer, NSString *keyPath, id oldValue, id newValue);

@interface NSObject (KVO)

-(void)lcr_addObserver:(NSObject *)obserer forKayPath:(NSString *)keyPath block:(LcrKVOBlock)block;

-(void)lcr_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath;

@end

NS_ASSUME_NONNULL_END
