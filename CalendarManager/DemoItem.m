//
//  DemoItem.m
//  CalendarManager
//
//  Created by Paolo Quadrani on 04/08/12.
//  Copyright (c) 2012 Paolo Quadrani. All rights reserved.
//

#import "DemoItem.h"

@implementation DemoItem

- (id)initWithTitle:(NSString *)n target:(id)t andSelectoToExecute:(SEL)selector
{
    self = [super init];
    if (self) {
        self.title = n;
        self.selectorToExecute = selector;
        self.target = t;
    }
    return self;
}

- (void)executeSelector
{
    [self.target performSelectorOnMainThread:self.selectorToExecute withObject:nil waitUntilDone:NO];
}

@end
