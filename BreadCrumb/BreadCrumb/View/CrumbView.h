//
//  CrumbView.h
//  BreadCrumb
//
//  Created by apple on 2/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BreadCrumbData.h"

@interface CrumbViewTableView : UITableView{
	BOOL _track;
}
@end

@interface CrumbContactsTextView : UITextView{
	BOOL _track;
}
@end

enum{
	CrumbDetailStyleNone = 0,
	CrumbDetailStyleCreateNew,
	CrumbDetailStyleCheckIn,
	CrumbDetailStyleEdit,
	CrumbDetailStyleShow,
	CrumbDetailStyleReuse
};

@protocol CrumbViewDelegate <NSObject>
@optional
-(void) cancelButtonClick;
-(void) checkInButtonClick;
-(void) showContactPicker;
@end

@interface CrumbView : UIView<UITextFieldDelegate, UITextViewDelegate> {
	id _editingText;
	BOOL _keyboardStillShown;
	CGFloat _originHeight;
	UIDatePicker* _datePicker;
	NSInteger _style;
	
	UITextView* _detailsPlaceHolder;
	UITextView* _contactsPlaceHolder;
}

@property (assign, nonatomic) id<CrumbViewDelegate>        delegate;
@property (strong, nonatomic) IBOutlet CrumbViewTableView* tableView;
@property (strong, nonatomic) IBOutlet UITextField*        crumbTitle;
@property (strong, nonatomic) IBOutlet UITextView*         details;
@property (strong, nonatomic) CrumbContactsTextView*       contacts;
@property (strong, nonatomic) IBOutlet UITextField*        checkInDatetime;
@property (strong, nonatomic) IBOutlet UIView*             buttonsView;
@property (strong, nonatomic) IBOutlet UIButton*           cancelButton;
@property (strong, nonatomic) IBOutlet UIButton*           checkInButton;
@property (strong, nonatomic) IBOutlet UIToolbar*		   editBar;
@property (strong, nonatomic) IBOutlet UISegmentedControl* prevNextButton;

-(IBAction) cancelButtonClick:(id)sender;
-(IBAction) checkInButtonClick:(id)sender;
-(IBAction) prevNextButtonClick:(id)sender;
-(IBAction) doneButtonClick:(id)sender;

// this function called by CrumbViewTableView
-(void) backgroundClicked;

-(void) changeStyle:(NSInteger)style andCrumb:(Crumb*)crumb andCrumbContact:(NSArray*)contacts;

@end
