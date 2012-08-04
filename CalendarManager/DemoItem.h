//
//  DemoItem.h
//  CalendarManager
//
//  Created by Paolo Quadrani on 04/08/12.
//  Copyright (c) 2012 Paolo Quadrani. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DemoItem : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) SEL selectorToExecute;
@property (nonatomic, assign) id target;

- (id)initWithName:(NSString *)n target:(id)t andSelectoToExecute:(SEL)selector;
- (void)executeSelector;

@end
