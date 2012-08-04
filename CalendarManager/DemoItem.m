//
//  DemoItem.m
//  CalendarManager
//
//  Created by Paolo Quadrani on 04/08/12.
//  Copyright (c) 2012 Paolo Quadrani. All rights reserved.
//

#import "DemoItem.h"

@implementation DemoItem

- (id)initWithName:(NSString *)n target:(id)t andSelectoToExecute:(SEL)selector
{
    self = [super init];
    if (self) {
        self.name = n;
        self.selectorToExecute = selector;
        self.target = t;
    }
    return self;
}

- (void)executeSelector
{
    [self.target performSelectorInBackground:self.selectorToExecute withObject:nil];
}

@end
