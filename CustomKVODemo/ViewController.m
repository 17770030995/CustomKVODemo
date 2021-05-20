//
//  ViewController.m
//  CustomKVODemo
//
//  Created by 李传熔 on 2021/5/19.
//

#import "ViewController.h"
#import "Person.h"
#import <objc/runtime.h>

@interface ViewController ()

@property (nonatomic, strong) Person *person;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self printClasses:[Person class]];
}

-(void)printClasses:(Class)cls
{
    int count = objc_getClassList(NULL, 0);
    
    NSMutableArray *mArray = [NSMutableArray arrayWithObject:cls];
    Class* classes = (Class *)malloc(sizeof(Class)*count);
    objc_getClassList(classes, count);
    
    for (int i = 0; i < count; i ++) {
        if (cls == class_getSuperclass(classes[i])) {
            [mArray addObject:classes[i]];
        }
    }
    
    free(classes);
    NSLog(@"ViewController classes = %@",mArray);
    
}


@end
