//
//  PQCalendarManager.m
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

#import "PQCalendarManager.h"

@interface PQCalendarManager () <EKEventEditViewDelegate>

@property (nonatomic, strong) EKEventStore *eventStore;
@property (nonatomic, strong) EKCalendar *defaultCalendar;

@end


@implementation PQCalendarManager

@synthesize eventStore = _eventStore;
@synthesize defaultCalendar = _defaultCalendar;
@synthesize delegate = _delegate;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialize an event store object with the init method. Initilize the array for events.
        self.eventStore = [[EKEventStore alloc] init];
        
        // Get the default calendar from store.
        self.defaultCalendar = [self.eventStore defaultCalendarForNewEvents];
    }
    return self;
}

- (void)dealloc
{
    self.eventStore = nil;
    self.defaultCalendar = nil;
    
#if __has_feature(objc_arc)
#else
    [super dealloc];
#endif
}

- (NSArray *)eventsForToday
{
	NSDate *startDate = [NSDate date];
	
	// endDate is 1 day = 60*60*24 seconds = 86400 seconds from startDate
	NSDate *endDate = [NSDate dateWithTimeIntervalSinceNow:86400];
	
	// Create the predicate. Pass it the default calendar.
	NSArray *calendarArray = [NSArray arrayWithObject:_defaultCalendar];
	NSPredicate *predicate = [self.eventStore predicateForEventsWithStartDate:startDate endDate:endDate 
                                                                    calendars:calendarArray]; 
	
	// Fetch all events that match the predicate.
	NSArray *events = [self.eventStore eventsMatchingPredicate:predicate];
    
	return events;
}

- (NSArray *)eventsForCalendar:(EKCalendar *)cal fromDate:(NSDate *)startDate toDate:(NSDate *)endDate
{
	// Create the predicate. Pass it the calendar.
	NSArray *calendarArray = [NSArray arrayWithObject:cal];
	NSPredicate *predicate = [self.eventStore predicateForEventsWithStartDate:startDate endDate:endDate
                                                                    calendars:calendarArray];
	
	// Fetch all events that match the predicate.
	NSArray *events = [self.eventStore eventsMatchingPredicate:predicate];
    
	return events;
}

- (BOOL)iCloudCalendarIsPresent
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sourceType==%d && title==%@", EKSourceTypeCalDAV, @"iCloud"];
    NSArray *sourceTypeArr = [self.eventStore.sources filteredArrayUsingPredicate:predicate];
    return [sourceTypeArr count] != 0;
}

- (void)setDefaultCalendarWithName:(NSString *)calName
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title==%@", calName];
    NSArray *cal = [self.eventStore.calendars filteredArrayUsingPredicate:predicate];
    if ([cal count] == 1) {
        self.defaultCalendar = (EKCalendar *)[cal objectAtIndex:0];
    } else if ([cal count] > 1) {
        NSLog(@"Too many calendars with this name: %@", [cal description]);
    }
//    BOOL res;
//    NSError *err;
//    for (EKCalendar *c in cal) {
//        res = [self.eventStore removeCalendar:c commit:NO error:&err];
//    }
//    res = [self.eventStore commit:&err];
//    if (err) {
//        NSLog(@"Err: %@", err);
//    }
}

- (NSArray *)calendarSourcesOfTypes:(EKSourceType)type
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sourceType==%d", type];
    NSArray *sourceTypeArr = [self.eventStore.sources filteredArrayUsingPredicate:predicate];
    return sourceTypeArr;
}

- (NSArray *)localCalendars
{
    return [self calendarSourcesOfTypes:EKSourceTypeLocal];
}

- (NSArray *)calDavCalendars
{
    return [self calendarSourcesOfTypes:EKSourceTypeCalDAV];
}

- (NSArray *)birthdayCalendars
{
    return [self calendarSourcesOfTypes:EKSourceTypeBirthdays];
}

- (BOOL)addCalendarWithSourceType:(EKSource *)source name:(NSString *)calName makeDefault:(BOOL)def
{
    EKCalendar *newCal = [EKCalendar calendarWithEventStore:self.eventStore];
    newCal.title = calName;
    newCal.CGColor = [[UIColor greenColor] CGColor];
    // Should be only one iCloud calendar.
    newCal.source = source;
    
    NSError *err;
    BOOL ok = [self.eventStore saveCalendar:newCal commit:YES error:&err];
    if (ok && def) {
        [self.delegate calendarManager:self didCreateCalendarWithIdentifier:newCal.calendarIdentifier];
        self.defaultCalendar = newCal;
    }
    
    return ok;
//    BOOL ok = NO;
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sourceType==%d && title==%@", EKSourceTypeCalDAV, @"iCloud"];
//    NSArray *sourceTypeArr = [self.eventStore.sources filteredArrayUsingPredicate:predicate];
//    if ([sourceTypeArr count] != 0) {
//        EKCalendar *newCal = [EKCalendar calendarWithEventStore:self.eventStore];
//        newCal.title = calName;
//        newCal.CGColor = [[UIColor greenColor] CGColor];
//        // Should be only one iCloud calendar.
//        newCal.source = [sourceTypeArr objectAtIndex:0];
//        
//        NSError *err;
//        ok = [self.eventStore saveCalendar:newCal commit:YES error:&err];
//        if (ok && def) {
//            [self setDefaultCalendarWithName:calName];
//        }
//    }
//
//    return ok;
}

- (EKAlarm *)createAlarmOfMinutes:(NSInteger)min
{
    NSTimeInterval offset = -60 * min;
    return [EKAlarm alarmWithRelativeOffset:offset];
}

- (void)addEventWithTitle:(NSString *)t location:(NSString *)loc startDate:(NSDate *)start endDate:(NSDate *)end description:(NSString *)note
{
    // When add button is pushed, create an EKEventEditViewController to display the event.
	EKEventEditViewController *addController = [[EKEventEditViewController alloc] initWithNibName:nil bundle:nil];
	
	// set the addController's event store to the current event store.
	addController.eventStore = self.eventStore;
	addController.editViewDelegate = self;
	
    // now that the event store has been assigned, the event is available and can be customized.
    EKEvent *ev = addController.event;
    ev.title = t;
    ev.location = loc;
    ev.startDate = start;
    ev.endDate = end;
    ev.allDay = NO;
    ev.calendar = self.defaultCalendar;
    ev.notes = note;

    [self.delegate calendarManager:self didCreateEvent:ev];
	// present EventsAddViewController as a modal view controller
    [self.delegate calendarManager:self needToPresentController:addController];
	
#if __has_feature(objc_arc)
#else
	[addController release];
#endif
}

- (BOOL)saveEvent:(EKEvent *)ev
{
    NSError *err;
    BOOL ok = [self.eventStore saveEvent:ev span:EKSpanThisEvent error:&err];
    if (err) {
        NSLog(@"Error: %@", err);
    }
    return ok;
}

#pragma mark - EKEventEditViewDelegate

// Overriding EKEventEditViewDelegate method to update event store according to user actions.
- (void)eventEditViewController:(EKEventEditViewController *)controller 
          didCompleteWithAction:(EKEventEditViewAction)action
{
	NSError *error = nil;
	EKEvent *thisEvent = controller.event;
	
	switch (action) {
		case EKEventEditViewActionCanceled:
			// Edit action canceled, do nothing. 
			break;
			
		case EKEventEditViewActionSaved:
			// When user hit "Done" button, save the newly created event to the event store
            [self saveEvent:controller.event];
			break;
			
		case EKEventEditViewActionDeleted:
			// When deleting an event, remove the event from the event store
			[controller.eventStore removeEvent:thisEvent span:EKSpanThisEvent error:&error];
			break;
			
		default:
			break;
	}
    
	// Dismiss the modal view controller
	[self.delegate calendarManagerDidDismissCalendarEditController:self];
}

// Set the calendar edited by EKEventEditViewController to our chosen calendar - the default calendar.
- (EKCalendar *)eventEditViewControllerDefaultCalendarForNewEvents:(EKEventEditViewController *)controller
{
	EKCalendar *calendarForEdit = self.defaultCalendar;
	return calendarForEdit;
}

@end
