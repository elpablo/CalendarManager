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
@property (strong) NSPredicate *predicateTitle;
@property (strong) NSPredicate *predicateSourceType;
@property (strong) NSPredicate *predicateTitleSourceType;
@property (strong) NSPredicate *predicateTitleType;
@property BOOL ios6;

- (void)storeChanged:(NSNotification *)notification;
- (NSArray *)extractCalendarsFromSourceArray:(NSArray *)sources;

@end


@implementation PQCalendarManager

@synthesize eventStore = _eventStore;
@synthesize defaultCalendar = _defaultCalendar;
@synthesize delegate = _delegate;


- (void)_initParameters {
    NSString *version = [[UIDevice currentDevice] systemVersion];
    self.ios6 = [version floatValue] >= 6.0;

    self.defaultCalendar = nil;

    // Initialize an event store object with the init method. Initilize the array for events.
    self.eventStore = [[EKEventStore alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(storeChanged:)
                                                 name:EKEventStoreChangedNotification
                                               object:self.eventStore];
    self.defaultCalendar = nil;

    NSString *predicateTitleString = [NSString stringWithFormat:@"title == $CALENDAR_TITLE"];
    _predicateTitle = [NSPredicate predicateWithFormat:predicateTitleString];
    
    NSString *predicateSourceTypeString = [NSString stringWithFormat:@"sourceType == $CALENDARSOURCE_TYPE"];
    _predicateSourceType = [NSPredicate predicateWithFormat:predicateSourceTypeString];
    
    NSString *predicateTitleSourceTypeString = [NSString stringWithFormat:@"(title == $CALENDAR_TITLE) AND (sourceType == $CALENDARSOURCE_TYPE)"];
    _predicateTitleSourceType = [NSPredicate predicateWithFormat:predicateTitleSourceTypeString];
    
    NSString *predicateTitleTypeString = [NSString stringWithFormat:@"(title == $CALENDAR_TITLE) AND (type == $CALENDAR_TYPE)"];
    _predicateTitleType = [NSPredicate predicateWithFormat:predicateTitleTypeString];
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

- (void)grantAccessWithComplitionHandler:(AuthorizedCompletionHandler)handler
{
    if (self.ios6) {
        [self.eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
            if (granted) {
                // Get the default calendar from store.
                self.defaultCalendar = [self.eventStore defaultCalendarForNewEvents];
            }
            handler(granted);
        }];
    } else {
        // Get the default calendar from store.
        self.defaultCalendar = [self.eventStore defaultCalendarForNewEvents];
        handler(YES);
    }
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

- (void)storeChanged:(NSNotification *)notification
{
    NSString *info = [notification.userInfo description];
    NSRange range = [info rangeOfString:@"x-apple-eventkit:///Calendar"];
    if (range.location != NSNotFound) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(calendarManagerInvalidatedCalendars:)]) {
            [self.delegate calendarManagerInvalidatedCalendars:self];
        }
        return;
    }
    range = [info rangeOfString:@"x-apple-eventkit:///Event"];
    if (range.location != NSNotFound) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(calendarManagerInvalidatedEvents:)]) {
            [self.delegate calendarManagerInvalidatedEvents:self];
        }
        return;
    }
}

- (BOOL)iCloudCalendarIsPresent
{
    NSDictionary *variables = @{@"CALENDAR_TITLE":@"iCloud",
                                @"CALENDARSOURCE_TYPE":[NSNumber numberWithInt:EKSourceTypeCalDAV]};
    NSPredicate *localPredicate = [self.predicateTitleSourceType predicateWithSubstitutionVariables:variables];
    NSArray *sourceTypeArr = [self.eventStore.sources filteredArrayUsingPredicate:localPredicate];
    return [sourceTypeArr count] != 0;
}

- (void)setDefaultCalendarWithName:(NSString *)calName
{
    NSDictionary *variables = @{@"CALENDAR_TITLE":calName};
    NSPredicate *localPredicate = [self.predicateTitle predicateWithSubstitutionVariables:variables];
    NSArray *evCal = [self allCalendars];
    NSArray *cal = [evCal filteredArrayUsingPredicate:localPredicate];
    if ([cal count] == 1) {
        self.defaultCalendar = (EKCalendar *)[cal objectAtIndex:0];
    } else if ([cal count] > 1) {
        NSLog(@"Too many calendars with this name: %@", [cal description]);
    } else {
        NSLog(@"'%@' calendar doesn't exists.", calName);
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
    NSDictionary *variables = @{@"CALENDARSOURCE_TYPE":[NSNumber numberWithInt:type]};
    NSPredicate *localPredicate = [self.predicateSourceType predicateWithSubstitutionVariables:variables];
    NSArray *sourceTypeArr = [self.eventStore.sources filteredArrayUsingPredicate:localPredicate];
    return sourceTypeArr;
}

- (NSMutableArray *)calendarsWithTitlesAndTypes:(NSArray *)title_type_dic
{
    NSArray *allCal = [self allCalendars];
    NSMutableArray *resultArray = nil;
#if __has_feature(objc_arc)
    resultArray = [[NSMutableArray alloc] init];
#else
    resultArray = [[[NSMutableArray alloc] init] autorelease];
#endif
    [title_type_dic enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *calName = [obj objectForKey:@"title"];
        NSNumber *type = [obj objectForKey:@"type"];
        NSDictionary *variables = @{@"CALENDAR_TITLE":calName,
                                    @"CALENDAR_TYPE":type};
        NSPredicate *localPredicate = [self.predicateTitleType predicateWithSubstitutionVariables:variables];
        NSArray *calTitleTypeArr = [allCal filteredArrayUsingPredicate:localPredicate];
        if ([calTitleTypeArr count] != 0) {
            [resultArray addObjectsFromArray:calTitleTypeArr];
        }
    }];
    return resultArray;
}

- (NSArray *)extractCalendarsFromSourceArray:(NSArray *)sources
{
    NSMutableArray *allCalendars = nil;
#if __has_feature(objc_arc)
    allCalendars = [[NSMutableArray alloc] init];
#else
    allCalendars = [[[NSMutableArray alloc] init] autorelease];
#endif

    [sources enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        EKSource *source = obj;
        [allCalendars addObjectsFromArray:[[source calendarsForEntityType:EKEntityTypeEvent] allObjects]];
    }];
    return [allCalendars count] != 0 ? allCalendars : nil;
}

- (NSArray *)allCalendars
{
    if (self.ios6) {
        return [self.eventStore calendarsForEntityType:EKEntityTypeEvent];
    } else {
        return [self.eventStore calendars];
    }
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
        if (self.ios6) {
            newCal = [EKCalendar calendarForEntityType:EKEntityTypeEvent eventStore:self.eventStore];
        } else {
            newCal = [EKCalendar calendarWithEventStore:self.eventStore];
        }

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

- (NSArray *)eventsForTodayInCalendars:(NSArray *)calendars
{
    return [self eventsForDate:[NSDate date] inCalendars:calendars];
}

- (NSArray *)eventsForDate:(NSDate *)day inCalendars:(NSArray *)calendars
{
    NSCalendar *gregorian = [NSCalendar currentCalendar];
    NSDateComponents *components = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:day];
    [components setHour:0];
    [components setMinute:0];
    [components setSecond:0];
    NSDate *startDate = [gregorian dateFromComponents:components];
    [components setHour:23];
    [components setMinute:59];
    [components setSecond:59];
    NSDate *endDate = [gregorian dateFromComponents:components];
    
	return [self eventsForCalendars:calendars fromDate:startDate toDate:endDate];
}

- (NSArray *)eventsForCurrentMonthInCalendars:(NSArray *)calendars
{
    return [self eventsForMonth:[NSDate date] inCalendars:calendars];
}

- (NSArray *)eventsForMonth:(NSDate *)day_in_month inCalendars:(NSArray *)calendars
{
    // Retrieve the calendar to calculate the first and last day of the current month
    NSCalendar *calendar = [NSCalendar currentCalendar];
    [calendar setTimeZone:[NSTimeZone localTimeZone]];
    
    NSDateComponents *components = [calendar components: NSMonthCalendarUnit|NSYearCalendarUnit
                                               fromDate:day_in_month];
    components.day = 1;
    [components setHour:0];
    [components setMinute:0];
    [components setSecond:0];
    NSDate *startDate = [calendar dateFromComponents: components];
    
    NSRange range = [calendar rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit
                                  forDate:startDate];
    components.day = range.length;
    [components setHour:23];
    [components setMinute:59];
    [components setSecond:59];
    
	// endDate is last day of month
	NSDate *endDate = [calendar dateFromComponents: components];
    
    return [self eventsForCalendars:calendars fromDate:startDate toDate:endDate];
}

- (NSArray *)eventsForCalendars:(NSArray *)calendars fromDate:(NSDate *)startDate toDate:(NSDate *)endDate
{
	NSArray *calendarArray = calendars ? calendars : [NSArray arrayWithObject:_defaultCalendar];
	// Create the predicate. Pass it the calendar.
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

- (EKEventEditViewController *)addEventToCalendar:(EKCalendar *)cal withTitle:(NSString *)t location:(NSString *)loc startDate:(NSDate *)start endDate:(NSDate *)end description:(NSString *)note
{
    // When add button is pushed, create an EKEventEditViewController to display the event.
	EKEventEditViewController *editEventController = nil;
#if __has_feature(objc_arc)
    editEventController = [[EKEventEditViewController alloc] initWithNibName:nil bundle:nil];
#else
    editEventController = [[[EKEventEditViewController alloc] initWithNibName:nil bundle:nil] autorelease];
#endif
	
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

    return editEventController;
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
			
		case EKEventEditViewActionSaved: {
			// When user hit "Done" button, save the newly created event to the event store
            BOOL ok = [self saveEvent:controller.event error:&error];
            if (ok) {
                if ([self.delegate respondsToSelector:@selector(calendarManager:didCreateEvent:)]) {
                    [self.delegate calendarManager:self didCreateEvent:controller.event];
                }
            }
        }
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
