//
//  NSObject+KVO.m
//  CustomKVODemo
//
//  Created by 李传熔 on 2021/5/19.
//

#import "NSObject+KVO.h"
#import <objc/message.h>

static NSString *const kLCRPrefix = @"LcrKVONotifying_";
static NSString *const kLcrKVOAssiociateKay = @"kLcrKVO_AssociateKey";

@interface LcrInfo : NSObject

@property (nonatomic, weak) NSObject *observer;
@property (nonatomic, copy) NSString *keyPath;
@property (nonatomic, copy) LcrKVOBlock handleBlock;

@end

@implementation LcrInfo

-(instancetype)initWithObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath handleBlock:(LcrKVOBlock)block{
    if (self = [super init]) {
        self.observer = observer;
        self.keyPath = keyPath;
        self.handleBlock = block;
    }
    return self;
}

@end

@implementation NSObject (KVO)


-(void)lcr_addObserver:(NSObject *)obserer forKayPath:(NSString *)keyPath block:(nonnull LcrKVOBlock)block
{
    // 1. 验证是否存在setter方法： 不让实例进来
    [self judgeSetterMethodFromKeyPath:keyPath];
    
    //2. 生成当前的子类
    Class newClass = [self createChildClassWithKeyPath:keyPath];
    
    SEL setterSel = NSSelectorFromString(setterForGetter(keyPath));
    Method setterMethod = class_getInstanceMethod([self class], setterSel);
    const char *setterTypes = method_getTypeEncoding(setterMethod);
    class_addMethod(newClass, setterSel, (IMP)lcr_setter, setterTypes);
    
    object_setClass(self, newClass);
    
    LcrInfo *info = [[LcrInfo alloc]initWithObserver:obserer forKeyPath:keyPath handleBlock:block];
    
    NSMutableArray *mArray = objc_getAssociatedObject(self, (__bridge const void * _Nonnull)(kLcrKVOAssiociateKay));
    if (!mArray) {
        mArray = [[NSMutableArray alloc]init];
        objc_setAssociatedObject(self, (__bridge const void * _Nonnull)(kLcrKVOAssiociateKay), mArray, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    [mArray addObject:info];
    
}

-(void)lcr_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath
{
    NSMutableArray *observerArr = objc_getAssociatedObject(self, (__bridge const void * _Nonnull)(kLcrKVOAssiociateKay));
    if (observerArr.count <= 0) {
        return;;
    }
    for (LcrInfo *info in observerArr) {
        if ([info.keyPath isEqualToString:keyPath]) {
            [observerArr removeObject:info];
            objc_setAssociatedObject(self, (__bridge const void * _Nonnull)(kLcrKVOAssiociateKay), observerArr, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            break;
        }
    }
    
    if (observerArr.count <= 0) {
        Class superClass = [self class];
        object_setClass(self, superClass);
    }
}

-(Class)createChildClassWithKeyPath:(NSString *)keyPath
{
    NSString *oldClassName = NSStringFromClass([self class]);
    NSString *newClassName = [NSString stringWithFormat:@"%@%@",kLCRPrefix,oldClassName];
    Class newClass = NSClassFromString(newClassName);
    
    //防止重复生成
    if (newClass) {
        return newClass;
    }
    
    //如果不存在 创建子类
    //参数1: 父类
    //参数2: 新类的名称
    //参数3: 新类的开辟的额外的空间
 
    //申请类
    newClass = objc_allocateClassPair([self class], newClassName.UTF8String, 0);
    //注册类
    objc_registerClassPair(newClass);
    // 添加class ，相当于重写了class 方法， 指向Person
    SEL classSel = NSSelectorFromString(@"class");
    Method classMethod = class_getInstanceMethod([self class], classSel);
    const char *classTypes = method_getTypeEncoding(classMethod);
    class_addMethod(newClass, classSel,(IMP)lcr_class,classTypes);
    
    SEL deallocSel = NSSelectorFromString(@"dealloc");
    Method deallocMethod = class_getInstanceMethod([self class], deallocSel);
    const char * deallocTypes = method_getTypeEncoding(deallocMethod);
    class_addMethod(newClass, deallocSel, (IMP)lcr_dealloc, deallocTypes);
    
    return newClass;
}

static void lcr_setter(id self,SEL _cmd, id newVlaue){
    NSLog(@"来了 setter 方法:%@",newVlaue);
    
    NSString *keyPath = getterForSetter(NSStringFromSelector(_cmd));
    id oldVlaue = [self valueForKey:keyPath];
    //消息转发 : 转发给父类
    
    void (*lcr_msgSendSuper)(void *,SEL , id)  = (void *)objc_msgSendSuper;
    // void /* struct objc_super *super, SEL op, ... */
    struct objc_super superStruct = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self)),
    };
    //objc_msgSendSuper(&superStruct,_cmd,newValue)
    lcr_msgSendSuper(&superStruct, _cmd, newVlaue);
    
    // 信息数据 回调
    NSMutableArray *mArray = objc_getAssociatedObject(self, (__bridge const void * _Nonnull)(kLcrKVOAssiociateKay));
    for (LcrInfo *info in mArray) {
        if ([info.keyPath isEqualToString:keyPath] && info.handleBlock) {
            info.handleBlock(info.observer, keyPath, oldVlaue, newVlaue);
        }
    }
    
}

static void lcr_dealloc(id self, SEL _cmd){
    NSLog(@"来了");
    Class superClass = [self class];
    object_setClass(self, superClass);
}

Class lcr_class(id self, SEL _cmd){
    return class_getSuperclass(object_getClass(self));
}


-(void)judgeSetterMethodFromKeyPath:(NSString *)keyPath
{
    Class superClass = object_getClass(self);
    SEL setterSelector = NSSelectorFromString(setterForGetter(keyPath));
    Method setterMethod = class_getInstanceMethod(superClass, setterSelector);
    if (!setterMethod) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"老铁没有当前%@的setter",keyPath] userInfo:nil];
    }
}
#pragma mark - 从get方法获取set方法的名称 key ===>>> setKey:
static NSString *setterForGetter(NSString *getter){
    if (getter.length <= 0) return nil;
    
    NSString *firstString = [[getter substringToIndex:1] uppercaseString];
    NSString *leaveString = [getter substringFromIndex:1];
    
    return [NSString stringWithFormat:@"set%@%@:",firstString,leaveString];
    
}
#pragma mark - 从set方法获取getter方法的名称 set<Key>:===> key
static NSString *getterForSetter(NSString *setter){
    
    if (setter.length <= 0 || ![setter hasPrefix:@"set"] || ![setter hasSuffix:@":"]) { return nil;}
    
    NSRange range = NSMakeRange(3, setter.length-4);
    NSString *getter = [setter substringWithRange:range];
    NSString *firstString = [[getter substringToIndex:1] lowercaseString];
    return  [getter stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:firstString];
}


@end
