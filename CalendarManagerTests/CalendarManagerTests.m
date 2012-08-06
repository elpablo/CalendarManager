//
//  CalendarManagerTests.m
//  CalendarManagerTests
//
//  Created by Paolo Quadrani on 04/08/12.
//  Copyright (c) 2012 Paolo Quadrani. All rights reserved.
//

#import "CalendarManagerTests.h"

#import "../CalendarManager/PQCalendarManager/PQCalendarManager.h"

@interface CalendarManagerTests ()

@property (nonatomic, strong) PQCalendarManager *manager;

@end

@implementation CalendarManagerTests

- (void)setUp
{
    [super setUp];
    
    self.manager = [PQCalendarManager sharedInstance];
    STAssertNotNil(self.manager, @"Some problem occourred during PQCalendarManager allocation");
}

- (void)tearDown
{
    [super tearDown];
}

- (void)test_1_CalendarAPI
{
    // Test the existance of source for local calendars
    NSArray *sourcesLocal = [self.manager calendarSourcesOfType:EKSourceTypeLocal];
    STAssertTrue([sourcesLocal count] == 1, @"There should be only one source for a given type...");

    // There should be the Default calendar (at least in Simulator)
    NSArray *localCalendars = [self.manager localCalendars];
    STAssertTrue([localCalendars count] != 0, @"Should exists at least the Default calendar...");

    // Add a new calendar to the local source.
    NSError *err;
    EKCalendar *pqCal = [self.manager addCalendarWithSource:[sourcesLocal objectAtIndex:0] name:@"PQCalendar" color:[UIColor greenColor] makeDefault:YES error:&err];
    STAssertNotNil(pqCal, @"Problem adding new calendar...");
    
    BOOL res = [self.manager removeCalendar:pqCal error:&err];
    STAssertTrue(res, @"Problems removing calendar...");
}

- (void)test_2_EventAPI
{
    STAssertTrue(YES, @"Fake Test...");
}


@end
