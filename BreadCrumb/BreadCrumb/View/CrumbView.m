//
//  CrumbView.m
//  BreadCrumb
//
//  Created by apple on 2/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CrumbView.h"
#import "Macros.h"
#import <QuartzCore/QuartzCore.h>

@implementation CrumbViewTableView

-(void) touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
	_track = YES;
	[super touchesBegan:touches withEvent:event];
}

-(void) touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
	_track = NO;
	[super touchesMoved:touches withEvent:event];
}

-(void) touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
	if( _track )
	{
		[self.superview performSelector:@selector(backgroundClicked)];
	}
	[super touchesEnded:touches withEvent:event];
}

@end

@implementation CrumbContactsTextView

-(void) touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
	_track = YES;
	[super touchesBegan:touches withEvent:event];
}

-(void) touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
	_track = NO;
	[super touchesMoved:touches withEvent:event];
}

-(void) touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
	if( _track )
	{
		if( self.delegate &&
		   [self.delegate respondsToSelector:@selector(textViewShouldBeginEditing:)] )
		{
			[self.delegate performSelector:@selector(textViewShouldBeginEditing:) withObject:self];
		}
	}
	[super touchesEnded:touches withEvent:event];
}

@end

@implementation CrumbView

@synthesize delegate = _delegate;
@synthesize tableView = _tableView;
@synthesize crumbTitle = _crumbTitle;
@synthesize details = _details;
@synthesize contacts = _contacts;
@synthesize checkInDatetime = _checkInDatetime;
@synthesize buttonsView = _buttonsView;
@synthesize cancelButton = _cancelButton;
@synthesize checkInButton = _checkInButton;
@synthesize editBar = _editBar;
@synthesize prevNextButton = _prevNextButton;

#pragma mark
#pragma mark keyboard events

-(void) moveEditingControlToVisible
{
//	if( _editingText == _crumbTitle )
//	{
//		[_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]
//						  atScrollPosition:UITableViewScrollPositionTop
//								  animated:NO];
//	}
//	else if( _editingText == _details )
//	{
//		[_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]
//						  atScrollPosition:UITableViewScrollPositionMiddle
//								  animated:YES];
//	}
	if( _editingText == _checkInDatetime )
	{
		[_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:3]
						  atScrollPosition:UITableViewScrollPositionTop
								  animated:NO];
	}
}

-(void) keyboardWillShow:(NSNotification*)notification
{
	if( _editingText != nil )
	{
		CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
		
		CGRect newFrame = _editBar.frame;
		newFrame.origin.y = self.bounds.size.height - keyboardSize.height - newFrame.size.height;
		_editBar.frame = newFrame;
		
		newFrame = _tableView.frame;
		newFrame.size.height = _originHeight - keyboardSize.height - _editBar.frame.size.height;
		_tableView.frame = newFrame;
        
		_keyboardStillShown = YES;
		_editBar.hidden = NO;
		
		[self moveEditingControlToVisible];
	}
}

-(void) keyboardWillHide:(NSNotification*)notification
{
	if( _editingText != nil )
	{
		if( (_editingText != _checkInDatetime) )
		{
			CGRect newFrame = _tableView.frame;
			newFrame.size.height = _originHeight;
			_tableView.frame = newFrame;
		}
        
		_keyboardStillShown = NO;
		_editBar.hidden = YES;
	}
}

-(BOOL) pickerShouldShow:(id)sender
{
	return( sender == _checkInDatetime );
}

-(void) pickerWillBeginShow:(id)sender
{
	// create a date picker if its not exist
	if( _datePicker == nil )
	{
		_datePicker = [[UIDatePicker alloc] init];
//		NSLocale* locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
//		_datePicker.locale = locale;
//		[locale release];
	}
	
	if( sender == _checkInDatetime )
	{
		_datePicker.datePickerMode = UIDatePickerModeDateAndTime;
	}
    _datePicker.minuteInterval = 5;
	NSDate* minDate = [NSDate dateWithTimeIntervalSinceNow:5 * 60];
	NSUInteger componentFlags = NSYearCalendarUnit | 
								NSMonthCalendarUnit | 
								NSDayCalendarUnit | 
								NSHourCalendarUnit | 
								NSMinuteCalendarUnit | 
								NSSecondCalendarUnit;
	NSDateComponents* dateC = [[NSCalendar currentCalendar] components:componentFlags fromDate:minDate];
	if( [dateC minute] % 5 )
	{
		minDate = [minDate dateByAddingTimeInterval:((5 - [dateC minute] % 5) * 60)];
	}
	
	_datePicker.minimumDate = minDate;
	if( self.checkInDatetime.text.length > 0 )
	{
		_datePicker.date = StringToDate(self.checkInDatetime.text);
	}
	
	if( _datePicker.superview == nil )
	{
		[self addSubview:_datePicker];
		
		// set picker frame & show
		CGRect pickerFrame = CGRectMake(0, 
										_tableView.frame.origin.y+_originHeight,
										320, 
										216);
		_datePicker.frame = pickerFrame;
		[UIView beginAnimations:nil context:nil];
		pickerFrame.origin.y -= pickerFrame.size.height;
		_datePicker.frame = pickerFrame;
		[UIView commitAnimations];
		
		CGRect newFrame = _editBar.frame;
		newFrame.origin.y = self.bounds.size.height - pickerFrame.size.height - newFrame.size.height;
		_editBar.frame = newFrame;
		_editBar.hidden = NO;
		
		// reset the scroll view frame
		newFrame = _tableView.frame;
		newFrame.size.height = _originHeight - pickerFrame.size.height - _editBar.frame.size.height;
		_tableView.frame = newFrame;
	}
	
	// show the editing control visible
	[self moveEditingControlToVisible];
}

-(void) pickerWillEndShow
{
	if( (_datePicker == nil) || (_datePicker.superview == nil) ) return;
	
	// hide picker
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(pickerDidEndShow:finished:context:)];
	CGRect newPickerFrame = _datePicker.frame;
	newPickerFrame.origin.y += newPickerFrame.size.height;
	_datePicker.frame = newPickerFrame;
	[UIView commitAnimations];
	
	// resize the scroll view
	CGRect newFrame = _tableView.frame;
	newFrame.size.height = _originHeight;
	_tableView.frame = newFrame;
	
	_editBar.hidden = YES;
}

-(void) pickerDidEndShow:(NSString*)animationID finished:(NSNumber*)finished context:(void*)context
{
	if( [finished boolValue] ) [_datePicker removeFromSuperview];
}

-(BOOL) textFieldShouldBeginEditing:(id)sender
{
	[_prevNextButton setEnabled:(sender!=_crumbTitle) forSegmentAtIndex:0];
	[_prevNextButton setEnabled:(sender!=_checkInDatetime) forSegmentAtIndex:1];
	
	if( [self pickerShouldShow:sender] )
	{
		id prevEditingText = _editingText;
		_editingText = sender;
		[prevEditingText resignFirstResponder];
		[self pickerWillBeginShow:sender];
		return NO;
	}
	else if ( sender == _contacts)
	{
		[_editingText resignFirstResponder];
		_editingText = nil;
		
		if( (_style != CrumbDetailStyleCheckIn) &&
		   (_style != CrumbDetailStyleShow) &&
		   (_delegate != nil) &&
		   ([_delegate respondsToSelector:@selector(showContactPicker)]) )
		{
			[_delegate performSelector:@selector(showContactPicker)];
		}
		return NO;
	}
	else
	{
		[self pickerWillEndShow];
		_editingText = sender;
		if( _keyboardStillShown )
		{
			[self moveEditingControlToVisible];
		}
		return YES;
	}
}

-(BOOL) textViewShouldBeginEditing:(UITextView*)textView
{
	[self pickerWillEndShow];
	
	return [self textFieldShouldBeginEditing:(UITextField*)textView];
}

-(void) textViewDidChange:(UITextView*)textView
{
	if( textView == _details )
	{
		if( _details.text.length == 0 )
		{
			_detailsPlaceHolder.text = @"Description (The more details, the better.)";
		}
		else
		{
			_detailsPlaceHolder.text = @"";
		}
	}
	else if( textView == _contacts )
	{
		if( _contacts.text.length == 0 )
		{
			_contactsPlaceHolder.text = @"Select the people who will be notified if you are overdue.";
		}
		else
		{
			_contactsPlaceHolder.text = @"";
		}
	}
}

-(BOOL) textView:(UITextView*)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString*)text
{
	if( textView != _details ) return YES;
	
	if( [textView.text stringByReplacingCharactersInRange:range withString:text].length > 5000 )
	{
		return NO;
	}
	else
	{
		return YES;
	}
}

- (void)ContactList:(id)sender
{
    if( (_delegate != nil) &&
       ([_delegate respondsToSelector:@selector(showContactPicker)]) )
    {
        [_delegate performSelector:@selector(showContactPicker)];
    }
}

#pragma mark
#pragma mark setter & getter

-(void) setDelegate:(id<CrumbViewDelegate>)newDelegate
{
	_delegate = newDelegate;
	
	// init text controls
	_crumbTitle = [[UITextField alloc] initWithFrame:CGRectMake(17, 10, 293, 25)];
	_details = [[UITextView alloc] initWithFrame:CGRectMake(10, 3, 300, 120)];
	_contacts = [[CrumbContactsTextView alloc] initWithFrame:CGRectMake(10, 3, 300, 90)];
	_checkInDatetime = [[UITextField alloc] initWithFrame:CGRectMake(17, 10, 293, 25)];
	
	_crumbTitle.font = [UIFont systemFontOfSize:16];
	_crumbTitle.clearButtonMode = UITextFieldViewModeWhileEditing;
	_crumbTitle.adjustsFontSizeToFitWidth = YES;
	_crumbTitle.backgroundColor = [UIColor clearColor];
	_crumbTitle.placeholder = @"Title (e.g. Tiger Mtn. run w/Sandy)";
	_crumbTitle.delegate = self;
	
	_details.font = [UIFont systemFontOfSize:16];
	_details.backgroundColor = [UIColor clearColor];
	_details.text = @"";
	_details.delegate = self;
	
	_detailsPlaceHolder = [[UITextView alloc] init];
	_detailsPlaceHolder.frame = _details.frame;
	_detailsPlaceHolder.font = [UIFont systemFontOfSize:16];
	_detailsPlaceHolder.backgroundColor = [UIColor clearColor];
	_detailsPlaceHolder.text = @"";
	_detailsPlaceHolder.textColor = [UIColor lightGrayColor];
	_detailsPlaceHolder.editable = NO;
	
	_contacts.font = [UIFont systemFontOfSize:16];
	_contacts.backgroundColor = [UIColor clearColor];
	_contacts.text = @"";
	_contacts.delegate = self;
	
	_contactsPlaceHolder = [[UITextView alloc] init];
	_contactsPlaceHolder.frame = _details.frame;
	_contactsPlaceHolder.font = [UIFont systemFontOfSize:16];
	_contactsPlaceHolder.backgroundColor = [UIColor clearColor];
	_contactsPlaceHolder.text = @"Select the people who will be notified if you are overdue.";
	_contactsPlaceHolder.textColor = [UIColor lightGrayColor];
	_contactsPlaceHolder.editable = NO;
	
	_checkInDatetime.font = [UIFont systemFontOfSize:16];
	_checkInDatetime.clearButtonMode = UITextFieldViewModeWhileEditing;
	_checkInDatetime.adjustsFontSizeToFitWidth = YES;
	_checkInDatetime.backgroundColor = [UIColor clearColor];
	_checkInDatetime.placeholder = @"Select a new check-in time";
	_checkInDatetime.delegate = self;
//	_checkInDatetime.text = DateToString([NSDate dateWithTimeIntervalSinceNow:15 * 60]);
    
    for (UIView *subView in self.buttonsView.subviews) {
        if ([subView isKindOfClass:[UIButton class]]) {
            UIButton *btn = (UIButton*)subView;
            btn.backgroundColor = [UIColor colorWithRed:232.0/255.0 green:143.0/255.0 blue:37.0/255.0 alpha:1.0];
            btn.titleLabel.textColor = [UIColor whiteColor];
            btn.layer.borderColor = [[UIColor colorWithRed:186.0/255.0 green:115.0/255.0 blue:30.0/255.0 alpha:1.0] CGColor];
            btn.layer.borderWidth = 1.0f;
        }
    }
	
	_editBar.hidden = YES;
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillShow:)
												 name:UIKeyboardWillShowNotification
                                               object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillHide:)
												 name:UIKeyboardWillHideNotification
                                               object:nil];

}

#pragma mark
#pragma mark InterfaceBuilder Actions

-(IBAction) cancelButtonClick:(id)sender
{
	if( (_delegate != nil) &&
	   ([_delegate respondsToSelector:@selector(cancelButtonClick)]) )
	{
		[_delegate performSelector:@selector(cancelButtonClick)];
	}
}

-(IBAction) checkInButtonClick:(id)sender
{
	if( (_delegate != nil) &&
	   ([_delegate respondsToSelector:@selector(checkInButtonClick)]) )
	{
		[_delegate performSelector:@selector(checkInButtonClick)];
	}
}

-(IBAction) prevNextButtonClick:(id)sender
{
	NSInteger step = +1;
	if( ((UISegmentedControl*)sender).selectedSegmentIndex == 0 ) step = -1;
	
	id controls[] = {
		_crumbTitle,
		_details,
		_checkInDatetime
	};
	
	int newEdit = 0;
	
	for( int i=0; i<sizeof(controls)/sizeof(id); i++ )
	{
		if( _editingText == controls[i] )
		{
			newEdit = i;
			break;
		}
	}
	newEdit += step;
	if( newEdit == -1 ) return;
	if( newEdit == sizeof(controls)/sizeof(id) ) return;
	
	[_editingText resignFirstResponder];
	[controls[newEdit] becomeFirstResponder];
}

-(IBAction) doneButtonClick:(id)sender
{
	if( _editingText != nil )
	{
		if( _editingText == _checkInDatetime )
		{
			[self pickerWillEndShow];
			((UITextField*)_editingText).text = DateToString(_datePicker.date);
		}
		else
		{
			[_editingText resignFirstResponder];
		}
	}
}

-(void) backgroundClicked
{
	[_crumbTitle resignFirstResponder];
	[_details resignFirstResponder];
	[_contacts resignFirstResponder];
	[_checkInDatetime resignFirstResponder];
	
	[self pickerWillEndShow];
}

#pragma mark
#pragma mark change style

-(void) changeStyle:(NSInteger)style andCrumb:(Crumb*)crumb andCrumbContact:(NSArray*)contacts
{
	BOOL enableEdit = YES;
	switch( style )
	{
		case CrumbDetailStyleCreateNew:
		case CrumbDetailStyleEdit:
		case CrumbDetailStyleReuse:
		{
			enableEdit = YES;
			break;
		}
		case CrumbDetailStyleCheckIn:
		case CrumbDetailStyleShow:
		{
			enableEdit = NO;
			break;
		}
	}
	
	if( style != CrumbDetailStyleCreateNew )
	{
		_crumbTitle.text = SafeCopy(crumb.name);
		_details.text = SafeCopy(crumb.alertMessage);
		_checkInDatetime.text = crumb.deadline;
	}
	[self textViewDidChange:_details];
	
	_contacts.text = @"";
	for( NSString* contact in contacts )
	{
		_contacts.text = [_contacts.text stringByAppendingFormat:@"%@\n", contact];
	}
	[self textViewDidChange:_contacts];
	
	[_crumbTitle resignFirstResponder];
	[_details resignFirstResponder];
	[_contacts resignFirstResponder];
	[_checkInDatetime resignFirstResponder];
	[self pickerWillEndShow];
	
	_crumbTitle.enabled = enableEdit;
	_details.editable = enableEdit;
	_contacts.editable = NO;
	_checkInDatetime.enabled = enableEdit;
	
	if( (style == CrumbDetailStyleCheckIn) && 
	   (_buttonsView.hidden) )
	{
		_buttonsView.hidden = NO;
		_originHeight -= _buttonsView.frame.size.height;
		CGRect newFrame = _tableView.frame;
		newFrame.size.height = _originHeight;
		_tableView.frame = newFrame;
	}
	else if( (style != CrumbDetailStyleCheckIn) &&
			(!_buttonsView.hidden) )
	{
		_buttonsView.hidden = YES;
		_originHeight += _buttonsView.frame.size.height;
		CGRect newFrame = _tableView.frame;
		newFrame.size.height = _originHeight;
		_tableView.frame = newFrame;
	}
	
	if( (style != _style) && (style == CrumbDetailStyleReuse) )
	{
		_checkInDatetime.text = @"";
		[_checkInDatetime becomeFirstResponder];
	}
	
	if( style == CrumbDetailStyleCreateNew )
	{
		_checkInDatetime.placeholder = @"Select a check-in time";
	}
	
	_style = style;
	[_tableView reloadData];
}


#pragma mark
#pragma mark UITableViewDataSource & UITableViewDelegate

-(CGFloat) tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section
{
	if( section == 0 ) return 1.0;
	else return 20.0;
}

-(CGFloat) tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
	// use text control's height as cell height
	if( indexPath.section == 1 )
	{
		// title
		if( indexPath.row == 0 )
		{
			return _crumbTitle.frame.size.height + 15;
		}
		// detail
		else if( indexPath.row == 1 )
		{
			return _details.frame.size.height + 6;
		}
	}
	else if( indexPath.section == 2 )
	{
		// contact
		if( indexPath.row == 0 )
		{
			return _contacts.frame.size.height + 6;
		}
	}
	else if( indexPath.section == 3 )
	{
		// checkin date & time
		if( indexPath.row == 0 )
		{
			return _checkInDatetime.frame.size.height + 15;
		}
	}
	
	return 0.0;
}

-(NSString*) tableView:(UITableView*)l_tableView titleForHeaderInSection:(NSInteger)section
{
	section--;
    NSString* titleSections[] = {@"Activity Details",
        @"Contacts",
	    @"Check-In Date & Time"};
    
    if( (section < 0) ||
		(section > sizeof(titleSections)/sizeof(NSString*)) ) return @"";
    else return titleSections[section];
}

//-(NSString*) tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
//{
//	if( section == 2 )
//	{
//	}
//	return nil;
//}

-(NSInteger) numberOfSectionsInTableView:(UITableView*)l_tableView
{
    return 4;
}

-(NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	if( section == 1 )
	{
		return 2;
	}
	else if( section == 2 )
	{
		return 1;
	}
	else if( section == 3 )
	{
		return 1;
	}
	return 0;
}

- (UITableViewCell*) tableView:(UITableView*) tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString* CellIdentifier = @"Cell";
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
	if( cell != nil ) return cell;
	
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_3_0
	cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];
#else
	cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:nil] autorelease];
#endif
    
    cell.backgroundColor = [UIColor whiteColor];
	
    // add text controls to table cell
	if( indexPath.section == 1 )
	{
		// title
		if( indexPath.row == 0 )
		{
			if( _crumbTitle.superview != nil )
			{
				[_crumbTitle removeFromSuperview];
			}
			[cell addSubview:_crumbTitle];
		}
		// detail
		else if( indexPath.row == 1 )
		{
			if( _detailsPlaceHolder.subviews != nil )
			{
				[_detailsPlaceHolder removeFromSuperview];
			}
			[cell addSubview:_detailsPlaceHolder];
			
			if( _details.superview != nil )
			{
				[_details removeFromSuperview];
			}
			[cell addSubview:_details];
		}
	}
	else if( indexPath.section == 2 )
	{
		// contact
		if( indexPath.row == 0 )
		{
			if( _contactsPlaceHolder.subviews != nil )
			{
				[_contactsPlaceHolder removeFromSuperview];
			}
			[cell addSubview:_contactsPlaceHolder];
			
			if( _contacts.superview != nil )
			{
				[_contacts removeFromSuperview];
			}
			[cell addSubview:_contacts];
			
			if( (_style == CrumbDetailStyleCreateNew) ||
			   (_style == CrumbDetailStyleEdit) ||
			   (_style == CrumbDetailStyleReuse) )
			{
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			}
		}
	}
	else if( indexPath.section == 3 )
	{
		// checkin date & time
		if( indexPath.row == 0 )
		{
			if( _checkInDatetime.superview != nil )
			{
				[_checkInDatetime removeFromSuperview];
			}
			[cell addSubview:_checkInDatetime];
			
			if( (_style == CrumbDetailStyleCreateNew) ||
			   (_style == CrumbDetailStyleEdit) ||
			   (_style == CrumbDetailStyleReuse) )
			{
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			}
		}
	}
	
	return cell;
}

#pragma mark
#pragma mark init & dealloc

-(void) setFrame:(CGRect)newFrame
{
	[super setFrame:newFrame];
	
	if( _tableView == nil ) return;
	
    // change content size & frame of the scroll view
	CGRect f = _tableView.frame;
	f.origin.y = 0;
	f.size.height = newFrame.size.height - _buttonsView.frame.size.height;
	_tableView.frame = f;
	_originHeight = f.size.height;
	
    // change frame of the button view
	f = _buttonsView.frame;
	f.origin.y = _tableView.frame.origin.y + _tableView.frame.size.height;
	_buttonsView.frame = f;
}

-(void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[_detailsPlaceHolder release];
	[_contactsPlaceHolder release];
	
	[_datePicker release];
	
	[_checkInDatetime release];
	[_contacts release];
	[_details release];
	[_crumbTitle release];
	
	[super dealloc];
}

@end
