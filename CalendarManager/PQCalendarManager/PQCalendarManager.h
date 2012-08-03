//
//  PQCalendarManager.h
//  TestEvent
//
//  Created by Quadrani Paolo on 27/05/12.
//  Copyright (c) 2012 Paolo Quadrani. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>

@protocol PQCalendarManagerDelegate;

@interface PQCalendarManager : NSObject

@property (nonatomic, assign) id<PQCalendarManagerDelegate> delegate;

// Calendar API
- (BOOL)iCloudCalendarIsPresent;
- (void)setDefaultCalendarWithName:(NSString *)calName;

- (NSArray *)calendarSourcesOfTypes:(EKSourceType)type;
- (NSArray *)localCalendars;
- (NSArray *)calDavCalendars;
- (NSArray *)birthdayCalendars;

- (BOOL)addCalendarWithSourceType:(EKSource *)source name:(NSString *)calName makeDefault:(BOOL)def;

// Event API
- (NSArray *)eventsForToday;
- (NSArray *)eventsForCalendar:(EKCalendar *)cal fromDate:(NSDate *)startDate toDate:(NSDate *)endDate;
- (void)addEventWithTitle:(NSString *)t location:(NSString *)loc startDate:(NSDate *)start endDate:(NSDate *)end description:(NSString *)note;
- (BOOL)saveEvent:(EKEvent *)ev;
- (EKAlarm *)createAlarmOfMinutes:(NSInteger)min;

@end


@protocol PQCalendarManagerDelegate <NSObject>

- (void)calendarManager:(PQCalendarManager *)adder didCreateEvent:(EKEvent *)ev;

@optional

- (void)calendarManager:(PQCalendarManager *)manager didCreateCalendarWithIdentifier:(NSString *)identifier;
- (void)calendarManager:(PQCalendarManager *)manager needToPresentController:(EKEventEditViewController *)controller;
- (void)calendarManagerDidDismissCalendarEditController:(PQCalendarManager *)manager;

@end
