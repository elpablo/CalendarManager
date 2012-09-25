//
//  PQCalendarManager.m
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

#import "PQCalendarManager.h"

@interface PQCalendarManager () <EKEventEditViewDelegate>

@property (nonatomic, strong) EKEventStore *eventStore;
@property (nonatomic, strong) EKCalendar *defaultCalendar;

- (NSArray *)extractCalendarsFromSourceArray:(NSArray *)sources;

@end


@implementation PQCalendarManager

@synthesize eventStore = _eventStore;
@synthesize defaultCalendar = _defaultCalendar;
@synthesize delegate = _delegate;

- (void)_initParameters {
    // Initialize an event store object with the init method. Initilize the array for events.
    self.eventStore = [[EKEventStore alloc] init];
    
    // Get the default calendar from store.
    self.defaultCalendar = [self.eventStore defaultCalendarForNewEvents];
}

+ (PQCalendarManager *)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
        [sharedInstance _initParameters];
    });
    return sharedInstance;
}

#pragma mark - Memory Management

#if __has_feature(objc_arc)
#else
- (NSUInteger)retainCount {
    return (NSUIntegerMax);
}

- (oneway void)release {
}

- (id)autorelease {
    return (self);
}

- (id)retain {
    return (self);
}

- (void)dealloc {
    self.eventStore = nil;
    self.defaultCalendar = nil;

    [super dealloc];
}
#endif

#pragma mark - Calendar API

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
}

- (BOOL)removeCalendar:(EKCalendar *)calendar error:(NSError **)error
{
    if (calendar) {
        BOOL result = YES;
        result = [self.eventStore removeCalendar:calendar commit:NO error:error];
        result = result && [self.eventStore commit:error];
        return result;
    }
    return NO;
}

- (NSArray *)calendarSources
{
    return self.eventStore.sources;
}

- (NSArray *)calendarSourcesOfType:(EKSourceType)type
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sourceType==%d", type];
    NSArray *sourceTypeArr = [self.eventStore.sources filteredArrayUsingPredicate:predicate];
    return sourceTypeArr;
}

- (NSArray *)extractCalendarsFromSourceArray:(NSArray *)sources
{
    NSArray *calendars = nil;
    if ([sources count] != 0) {
        NSMutableArray *allCalendars = [[NSMutableArray alloc] init];
        for (EKSource *source in sources) {
            [allCalendars addObjectsFromArray:[source.calendars allObjects]];
        }
        calendars = [allCalendars copy];
#if __has_feature(objc_arc)
#else
        [allLocalCalendars release];
#endif
    } else {
        NSLog(@"Empty sources passed...");
    }
    
    return calendars;
}

- (NSArray *)localCalendars
{
    NSArray *sources = [self calendarSourcesOfType:EKSourceTypeLocal];
    return [self extractCalendarsFromSourceArray:sources];
}

- (NSArray *)calDavCalendars
{
    NSArray *sources = [self calendarSourcesOfType:EKSourceTypeCalDAV];
    return [self extractCalendarsFromSourceArray:sources];
}

- (NSArray *)birthdaysCalendars
{
    NSArray *sources = [self calendarSourcesOfType:EKSourceTypeBirthdays];
    return [self extractCalendarsFromSourceArray:sources];
}

- (void)addCalendarWithSource:(EKSource *)source name:(NSString *)calName color:(UIColor *)color makeDefault:(BOOL)def error:(NSError **)error
{
    EKCalendar *newCal = nil;
    if (source) {
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
        newCal = [EKCalendar calendarWithEventStore:self.eventStore];
#else
        newCal = [EKCalendar calendarForEntityType:EKEntityTypeEvent eventStore:self.eventStore];
#endif
        newCal.title = calName;
        newCal.CGColor = [color CGColor];
        // Should be only one iCloud calendar source.
        newCal.source = source;
        
        [self.eventStore saveCalendar:newCal commit:YES error:error];
        if (*error == nil) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(calendarManager:didCreateCalendar:)]) {
                [self.delegate calendarManager:self didCreateCalendar:newCal];
            }
            if (def) {
                self.defaultCalendar = newCal;
            }
        } else {
            NSLog(@"%@", [*error localizedDescription]);
        }
    } else {
        NSLog(@"nil source passed!!");
    }
}

#pragma mark - Events API

- (NSArray *)eventsForTodayInCalendar:(EKCalendar *)cal
{
    // Now is the start date
	NSDate *startDate = [NSDate date];
	
	// endDate is 1 day = 60*60*24 seconds = 86400 seconds from startDate
	NSDate *endDate = [NSDate dateWithTimeIntervalSinceNow:86400];
    
	return [self eventsForCalendar:cal fromDate:startDate toDate:endDate];
}

- (NSArray *)eventsForCurrentMonthInCalendar:(EKCalendar *)cal
{
    // Retrieve the calendar to calculate the first and last day of the current month
    NSCalendar *calendar = [NSCalendar currentCalendar];
    [calendar setTimeZone:[NSTimeZone localTimeZone]];

    NSDateComponents *components = [calendar components: NSMonthCalendarUnit|NSYearCalendarUnit
                                                    fromDate:[NSDate date]];
    components.day = 1;
    NSDate *startDate = [calendar dateFromComponents: components];

    NSRange range = [calendar rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit
                                       forDate:startDate];
    components.day = range.length;
    
	// endDate is last day of month
	NSDate *endDate = [calendar dateFromComponents: components];

    return [self eventsForCalendar:cal fromDate:startDate toDate:endDate];
}

- (NSArray *)eventsForCalendar:(EKCalendar *)cal fromDate:(NSDate *)startDate toDate:(NSDate *)endDate
{
	// Create the predicate. Pass it the calendar.
    EKCalendar *calendar = cal ? cal : _defaultCalendar;
	NSArray *calendarArray = [NSArray arrayWithObject:calendar];
	NSPredicate *predicate = [self.eventStore predicateForEventsWithStartDate:startDate endDate:endDate
                                                                    calendars:calendarArray];
	
	// Fetch all events that match the predicate.
	NSArray *events = [self.eventStore eventsMatchingPredicate:predicate];
    
	return events;
}

- (EKAlarm *)createAlarmOfMinutes:(NSUInteger)min
{
    NSTimeInterval offset = -60 * min;
    return [EKAlarm alarmWithRelativeOffset:offset];
}

- (void)addEventToCalendar:(EKCalendar *)cal withTitle:(NSString *)t location:(NSString *)loc startDate:(NSDate *)start endDate:(NSDate *)end description:(NSString *)note
{
    // When add button is pushed, create an EKEventEditViewController to display the event.
	EKEventEditViewController *editEventController = [[EKEventEditViewController alloc] initWithNibName:nil bundle:nil];
	
	// set the addController's event store to the current event store.
	editEventController.eventStore = self.eventStore;
	editEventController.editViewDelegate = self;
	
    // now that the event store has been assigned, the event is available and can be customized.
    EKEvent *ev = editEventController.event;
    ev.title = t;
    ev.location = loc;
    ev.startDate = start;
    ev.endDate = end;
    ev.allDay = NO;
    ev.calendar = cal ? cal : self.defaultCalendar;
    ev.notes = note;

    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(calendarManager:didCreateEvent:)]) {
            [self.delegate calendarManager:self didCreateEvent:ev];
        }
        if ([self.delegate respondsToSelector:@selector(calendarManager:needToPresentController:)]) {
            // present EventsAddViewController as a modal view controller
            [self.delegate calendarManager:self needToPresentController:editEventController];
        }
    }
	
#if __has_feature(objc_arc)
#else
	[editEventController release];
#endif
}

- (BOOL)saveEvent:(EKEvent *)ev error:(NSError **)error
{
    return [self.eventStore saveEvent:ev span:EKSpanThisEvent error:error];
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
            [self saveEvent:controller.event error:&error];
			break;
			
		case EKEventEditViewActionDeleted:
			// When deleting an event, remove the event from the event store
			[controller.eventStore removeEvent:thisEvent span:EKSpanThisEvent error:&error];
			break;
			
		default:
			break;
	}
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(calendarManagerDidDismissCalendarEditController:)]) {
        // Dismiss the modal view controller
        [self.delegate calendarManagerDidDismissCalendarEditController:self];
    }
}

// Set the calendar edited by EKEventEditViewController to our chosen calendar - the default calendar.
- (EKCalendar *)eventEditViewControllerDefaultCalendarForNewEvents:(EKEventEditViewController *)controller
{
	EKCalendar *calendarForEdit = self.defaultCalendar;
	return calendarForEdit;
}

@end
