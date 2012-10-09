//
//  PQCalendarManager.h
//

/***************************************************************************
 Copyright (C) [2012-2020] [Paolo Quadrani]
 
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

typedef void (^AuthorizedCompletionHandler)(BOOL authorized);


+ (PQCalendarManager *)sharedInstance;

/// Function used to grant access to the Calendar DB. Call this function as first call to the PQCalendarManager singleton.
- (void)grantAccessWithComplitionHandler:(AuthorizedCompletionHandler)handler;

/////////////////////// Calendar API ///////////////////////

/// Returns all the calendar sources.
- (NSArray *)calendarSources;

/// Returns the array of calendar source given the source type (EKSourceTypeLocal, ...)
- (NSArray *)calendarSourcesOfType:(EKSourceType)type;

/// Returns all the available calendars (local, CalDVA...).
- (NSArray *)allCalendars;

/// Commodity method that returns the array of local calendars.
- (NSArray *)localCalendars;

/// Commodity method that return the array of CalDAV calendars.
- (NSArray *)calDavCalendars;

/// Commodity method that return the array of birthdays calendars.
- (NSArray *)birthdaysCalendars;

/// Returns the list of calendars associated with the {title, type} NSDictionary list passed as argument.
- (NSMutableArray *)calendarsWithTitlesAndTypes:(NSArray *)title_type_dic;

/// Allows to set a default calendar with a given name.
- (void)setDefaultCalendarWithName:(NSString *)calName;

/// Check the existance of any iCloud calendar.
- (BOOL)iCloudCalendarIsPresent;

/// Allows to add a new calendar to the given calendar source. The created calendar is returned through the delegate method if no errors occourred.
- (void)addCalendarWithSource:(EKSource *)source name:(NSString *)calName color:(UIColor *)c makeDefault:(BOOL)def error:(NSError **)error;

/// Allows to remove the given calendar.
- (BOOL)removeCalendar:(EKCalendar *)calendar error:(NSError **)error;


/////////////////////// Event API ///////////////////////

/// Show the events for today from the given calendar array. Pass nil to fetch events from default calendar.
- (NSArray *)eventsForTodayInCalendars:(NSArray *)calendars;

/// Show the events for a given date from the given calendar array. Pass nil to fetch events from default calendar.
- (NSArray *)eventsForDate:(NSDate *)day inCalendars:(NSArray *)calendars;

/// Show the events for current month from the given calendar array. Pass nil to fetch events from default calendar.
- (NSArray *)eventsForCurrentMonthInCalendars:(NSArray *)calendars;

/// Show the events for month containing the given date from the given calendar array. Pass nil to fetch events from default calendar.
- (NSArray *)eventsForMonth:(NSDate *)day_in_month inCalendars:(NSArray *)calendars;

/// fetch all the events between the startDate and endDate associated to the given calendar array.
- (NSArray *)eventsForCalendars:(NSArray *)calendars fromDate:(NSDate *)startDate toDate:(NSDate *)endDate;

/// Allows to create a new event with given parameters.
/**
 EKEventEditViewController pointer will be returned to the caller, so it can presented to the user as modal view controller or in a popover.
 */
- (EKEventEditViewController *)addEventToCalendar:(EKCalendar *)cal withTitle:(NSString *)t location:(NSString *)loc startDate:(NSDate *)start endDate:(NSDate *)end description:(NSString *)note;

/// This method allows to save the created event.
/** 
 This method is called when the used save the event from the edit event view controller presented from the addEventToCalendar method or can be called by the user
 is the controller has not been presented.
 */
- (BOOL)saveEvent:(EKEvent *)ev error:(NSError **)error;

/// This method allows to create an alarm with the given time duration in minutes. Then it can be passed to a created event.
- (EKAlarm *)createAlarmOfMinutes:(NSUInteger)min;

@end



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// PQCalendarManagerDelegate protocol
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@protocol PQCalendarManagerDelegate <NSObject>

@optional

/// Inform the delegate that a new calendar has been created.
- (void)calendarManager:(PQCalendarManager *)manager didCreateCalendar:(EKCalendar *)calendar;

/// Inform the delegate that a new event has been created.
- (void)calendarManager:(PQCalendarManager *)adder didCreateEvent:(EKEvent *)ev;

/// Inform the delegate that calendars are invalid (something is changed into the Calendar DB), so needs a refresh.
- (void)calendarManagerInvalidatedCalendars:(PQCalendarManager *)manager;

/// Inform the delegate that events are invalid (something is changed into the Calendar DB), so needs a refresh.
- (void)calendarManagerInvalidatedEvents:(PQCalendarManager *)manager;

/// Ask the user to dismiss the EKEventEditViewController needs to be dismissed because the user finished to edit the created event.
- (void)calendarManagerDidDismissCalendarEditController:(PQCalendarManager *)manager;

@end
