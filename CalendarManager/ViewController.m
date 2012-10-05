//
//  ViewController.m
//  CalendarManager
//
//  Created by Paolo Quadrani on 03/08/12.
//  Copyright (c) 2012 Paolo Quadrani. All rights reserved.
//

#import "ViewController.h"
#import "PQCalendarManager/PQCalendarManager.h"

#import "DemoItem.h"
#import "ItemsViewerViewController.h"

@interface ViewController () <PQCalendarManagerDelegate>

@property (nonatomic, strong) PQCalendarManager *calendarManager;

@property (nonatomic, strong) ItemsViewerViewController *viewer;
@property (nonatomic, strong) NSArray *calendarAPIExamples;
@property (nonatomic, strong) NSArray *eventAPIExamples;

@property (nonatomic, strong) EKCalendar *testCalendar;

- (void)showItemViewer;

// Calendar API demo methods
- (void)showAllCalendars;
- (void)showLocalCalendars;
- (void)showCalDAVCalendars;
- (void)showBirthdaysCalendars;
- (void)addNewCalendar;
- (void)removeCalendar;
- (void)removeAllTestCalendars;

// Event API demo methods
- (void)showTodayEvents;
- (void)showTodayEventsInCalendar;
- (void)showEventsForCurrentMonth;
- (void)addNewEvent;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    _calendarManager = [PQCalendarManager sharedInstance];
    [self.calendarManager setDelegate:(id<PQCalendarManagerDelegate>)self];
    
    self.testCalendar = nil;

    _calendarAPIExamples = [NSArray arrayWithObjects:
                            [[DemoItem alloc] initWithTitle:@"All Calendars" target:self andSelectoToExecute:@selector(showAllCalendars)],
                            [[DemoItem alloc] initWithTitle:@"Local Calendars" target:self andSelectoToExecute:@selector(showLocalCalendars)],
                            [[DemoItem alloc] initWithTitle:@"CalDAV Calendars" target:self andSelectoToExecute:@selector(showCalDAVCalendars)],
                            [[DemoItem alloc] initWithTitle:@"Birthdays Calendars" target:self andSelectoToExecute:@selector(showBirthdaysCalendars)],
                            [[DemoItem alloc] initWithTitle:@"New Calendar (TestCalendar)" target:self andSelectoToExecute:@selector(addNewCalendar)],
                            [[DemoItem alloc] initWithTitle:@"Remove Calendar (TestCalendar)" target:self andSelectoToExecute:@selector(removeCalendar)],
                            [[DemoItem alloc] initWithTitle:@"Remove all TestCalendar" target:self andSelectoToExecute:@selector(removeAllTestCalendars)],
                            nil];

    _eventAPIExamples = [NSArray arrayWithObjects:
                         [[DemoItem alloc] initWithTitle:@"Today Events (default cal)" target:self andSelectoToExecute:@selector(showTodayEvents)],
                         [[DemoItem alloc] initWithTitle:@"Today Events (TestCalendar)" target:self andSelectoToExecute:@selector(showTodayEventsInCalendar)],
                         [[DemoItem alloc] initWithTitle:@"Month Events (default cal)" target:self andSelectoToExecute:@selector(showEventsForCurrentMonth)],
                         [[DemoItem alloc] initWithTitle:@"New Event (to TestCalendar)" target:self andSelectoToExecute:@selector(addNewEvent)],
                         nil];
    
    NSDictionary *dic = @{@"title":@"TestCalendar", @"type":[NSNumber numberWithInt:EKCalendarTypeLocal]};
    NSMutableArray *arr = [[PQCalendarManager sharedInstance] calendarsWithTitlesAndTypes:@[dic]];
    if ([arr count] != 0) {
        self.testCalendar = [arr objectAtIndex:0];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (ItemsViewerViewController *)viewerWithTitle:(NSString *)t itemsToShow:(NSArray *)items
{
    if (_viewer == nil) {
        _viewer = [[ItemsViewerViewController alloc] initWithNibName:@"ItemsViewerViewController" bundle:nil];
    }
    _viewer.title = t;
    _viewer.items = items;

    return _viewer;
}

- (void)showItemViewer
{
    if (self.viewer) {
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.viewer];
        [self presentModalViewController:navController animated:YES];
    }
}

#pragma mark - PQCalendarManager Delegate

- (void)calendarManager:(PQCalendarManager *)manager didCreateCalendar:(EKCalendar *)calendar
{
    NSLog(@"%s", __FUNCTION__);
    self.testCalendar = calendar;
}

- (void)calendarManager:(PQCalendarManager *)adder didCreateEvent:(EKEvent *)ev
{
    NSLog(@"%s", __FUNCTION__);
    NSLog(@"Event created: %@", ev);
}

- (void)calendarManagerDidDismissCalendarEditController:(PQCalendarManager *)manager
{
    NSLog(@"%s", __FUNCTION__);
    [self dismissModalViewControllerAnimated:YES];
}

- (void)calendarManagerInvalidatedCalendars:(PQCalendarManager *)manager
{
    NSLog(@"%s", __FUNCTION__);
}

- (void)calendarManagerInvalidatedEvents:(PQCalendarManager *)manager
{
    NSLog(@"%s", __FUNCTION__);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return section == 0 ? [self.calendarAPIExamples count] : [self.eventAPIExamples count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell_ID";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    // Configure the cell...
    NSArray *sourceArray = indexPath.section == 0 ? self.calendarAPIExamples : self.eventAPIExamples;
    NSString *text = [[sourceArray objectAtIndex:indexPath.row] title];

    [cell.textLabel setText:text];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return section == 0 ? @"Calendar API Demo" : @"Event API Demo";
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        [[self.calendarAPIExamples objectAtIndex:indexPath.row] executeSelector];
    } else if (indexPath.section == 1) {
        [[self.eventAPIExamples objectAtIndex:indexPath.row] executeSelector];
    }
}

#pragma mark - Demo Methods

- (void)showAllCalendars
{
    NSLog(@"%s", __FUNCTION__);
    
    NSArray *allCal = [self.calendarManager allCalendars];
    NSLog(@"%@", allCal);
    
    self.viewer = [self viewerWithTitle:@"All Calendars" itemsToShow:allCal];
    [self showItemViewer];
}

- (void)showLocalCalendars
{
    NSLog(@"%s", __FUNCTION__);

    NSArray *localCal = [self.calendarManager localCalendars];
    NSLog(@"%@", localCal);
    
    self.viewer = [self viewerWithTitle:@"Local Calendars" itemsToShow:localCal];
    [self showItemViewer];
}

- (void)showCalDAVCalendars
{
    NSLog(@"%s", __FUNCTION__);

    NSArray *calDAVCal = [self.calendarManager calDavCalendars];
    NSLog(@"%@", calDAVCal);

    self.viewer = [self viewerWithTitle:@"CalDAV Calendars" itemsToShow:calDAVCal];
    [self showItemViewer];
}

- (void)showBirthdaysCalendars
{
    NSLog(@"%s", __FUNCTION__);
    
    NSArray *birthdayCal = [self.calendarManager birthdaysCalendars];
    NSLog(@"%@", birthdayCal);

    self.viewer = [self viewerWithTitle:@"Birthdays Calendars" itemsToShow:birthdayCal];
    [self showItemViewer];
}

- (void)addNewCalendar
{
    NSLog(@"%s", __FUNCTION__);
    
    NSError *err;
    NSArray *sources = [self.calendarManager calendarSourcesOfType:EKSourceTypeLocal];
    [self.calendarManager addCalendarWithSource:[sources objectAtIndex:0] name:@"TestCalendar" color:[UIColor greenColor] makeDefault:NO error:&err];
}

- (void)removeCalendar
{
    NSLog(@"%s", __FUNCTION__);
    NSError *err;
    if ([self.calendarManager removeCalendar:self.testCalendar error:&err]) {
        self.testCalendar = nil;
    } else {
        NSLog(@"%@", [err localizedDescription]);
    }
}

- (void)removeAllTestCalendars
{
    for (EKCalendar *cal in [self.calendarManager localCalendars]) {
        if ([cal.title isEqualToString:@"TestCalendar"]) {
            NSError *err;
            [self.calendarManager removeCalendar:cal error:&err];
        }
    }
}

#pragma mark - Events Demo Methods

- (void)showTodayEvents
{
    NSLog(@"%s", __FUNCTION__);
    
    NSArray *today = [self.calendarManager eventsForTodayInCalendars:nil];
    NSLog(@"%@", today);
    
    self.viewer = [self viewerWithTitle:@"Today Events" itemsToShow:today];
    [self showItemViewer];
}

- (void)showTodayEventsInCalendar
{
    NSLog(@"%s", __FUNCTION__);
    
    if (self.testCalendar) {
        NSArray *today = [self.calendarManager eventsForTodayInCalendars:@[self.testCalendar]];
        NSLog(@"%@", today);
        
        self.viewer = [self viewerWithTitle:@"Today Events in TestCalendar" itemsToShow:today];
        [self showItemViewer];
    } else {
        NSLog(@"Before this, select \"New calendar (TestCalendar)\" to create test calendar");
    }
}

- (void)showEventsForCurrentMonth
{
    NSLog(@"%s", __FUNCTION__);
    NSArray *events = [self.calendarManager eventsForCurrentMonthInCalendars:nil];
    
    self.viewer = [self viewerWithTitle:@"Events in current month" itemsToShow:events];
    [self showItemViewer];
    
    NSLog(@"%@", events);
}

- (void)addNewEvent
{
    NSLog(@"%s", __FUNCTION__);
    if (self.testCalendar) {
        EKEventEditViewController *controller = [self.calendarManager addEventToCalendar:self.testCalendar withTitle:@"Test Event" location:@"My Home" startDate:[NSDate date] endDate:[NSDate date] description:@"Event taht shows create event API"];
        [self presentModalViewController:controller animated:YES];
    } else {
        NSLog(@"Before this, select \"New calendar (TestCalendar)\" to create test calendar");
    }
}

@end
