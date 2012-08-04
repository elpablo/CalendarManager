//
//  PQCalendarManager.h
//

/***************************************************************************
 Copyright [2012] [Paolo Quadrani]
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 ***************************************************************************/


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
