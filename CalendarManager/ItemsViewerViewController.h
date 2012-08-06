//
//  ItemsViewerViewController.h
//  CalendarManager
//
//  Created by Paolo Quadrani on 04/08/12.
//  Copyright (c) 2012 Paolo Quadrani. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <EventKit/EventKit.h>

@interface ItemsViewerViewController : UITableViewController

@property (nonatomic, strong) NSArray *items;
@property (nonatomic) id selectedItem;

@end
