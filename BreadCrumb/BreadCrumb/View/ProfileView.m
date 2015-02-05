//
//  ProfileView.m
//  testProfileView
//
//  Created by verysmall on 12-12-10.
//  Copyright (c) 2012年 verysmall. All rights reserved.
//

#import "ProfileView.h"
#import <QuartzCore/QuartzCore.h>
#import "BreadCrumbData.h"
#import "AppDelegate.h"

#define MARGIN						(10)
#define EMAIL_HEIGHT				(30)
#define AVATAR_HEIGHT				(90)
#define SCREENWIDTH					(320)
#define LABEL_HEIGHT				(26)
#define TEXT_HEIGHT					(26)
#define TEXT_FIELD_LEFT_MARGIN		(15)
#define TEXT_FIELD_RIGHT_MARGIN		(15)
#define TEXT_FIELD_TOP_MARGIN		(5)
#define TEXT_FIELD_BOTTOM_MARGIN	(5)
#define EXPANDIBLE_LABEL_LEFT		(70)
#define EXPANDIBLE_LABEL_WIDTH		(230)
#define EXPANDIBLE_LABEL_HEIGHT		(35)
#define EXPANDIBLE_IMAGE_LEFT		(50)
#define EXPANDIBLE_IMAGE_TOP		(18)
#define EXPANDIBLE_IMAGE_WIDTH		(9)
#define EXPANDIBLE_IMAGE_HEIGHT		(13)
#define EXPANDIBLE_IMAGE_TAG		(12345)
#define MEDICAL_ROW_HEIGHT			(120)
#define SETTING_ROW_HEIGHT			(60)
#define CHECKBOX_WIDTH				(25)
#define HEADER_FOOTER_HEIGHT		(5)
#define PRIVACY_HEIGHT				(50)
#define NORMAL_ROW_TITLE_LEFT		(5)
#define NORMAL_ROW_TITLE_TOP		(3)
#define NORMAL_ROW_TITLE_WIDTH		(150)
#define NORMAL_ROW_CONTENT_LEFT		(20)
#define NORMAL_ROW_CONTENT_TOP		(10)
#define NORMAL_ROW_CONTENT_BOTTOM	(10)
#define NORMAL_ROW_CONTENT_WIDTH	(260)
#define NORMAL_ROW_CONTENT_HEIGHT	(20)

#define CELL_MARGIN					(25)
#define CELL_PERSONAL_TITLE_WIDTH	(80)
#define CELL_VEHICLE_TITLE_WIDTH	(95)
#define CELL_CONTENT_WIDTH			(150)
#define NORMAL_ROW_HEIGHT			(35)
#define GROUPED_MARGIN_TOPBOTTOM	(7)
#define NORMAL_ROW_TITLE_HEIGHT		(15)

#define PRIVACY_URL					(@"http://gobugle.com/privacy")
#define EMAIL_URL					(@"mailto:support@gobugle.com")


@implementation CustomPickerView

@synthesize datas = _datas;

-(void) setDatas:(NSArray*)newDatas
{
	if( _datas )
	{
		[_datas release];
		_datas = nil;
	}
	if( newDatas )
	{
		_datas = [newDatas retain];
		[self reloadAllComponents];
	}
}

-(NSInteger) numberOfComponentsInPickerView:(UIPickerView*)pickerView
{
	return 1;
}

-(NSInteger) pickerView:(UIPickerView*)pickerView numberOfRowsInComponent:(NSInteger)component
{
	if( !_datas ) return 0;
	return _datas.count;
}

-(NSString*) pickerView:(UIPickerView*)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	return [_datas objectAtIndex:row];
}

-(void) dealloc
{
	if( _datas ) [_datas release];
	[super dealloc];
}

-(id) init
{
	if( self = [super init] )
	{
		self.showsSelectionIndicator = YES;
		self.delegate = self;
		self.dataSource = self;
	}
	return self;
}

@end





@implementation CustomEditView

@synthesize titleLabel = _titleLabel;
@synthesize contentLabel = _contentLabel;
@synthesize contentType = _contentType;
@synthesize contentControl = _contentControl;

-(void) dealloc
{
	[_titleLabel removeFromSuperview];
	_titleLabel = nil;
	
	[_contentLabel removeFromSuperview];
	_contentLabel = nil;
	
	[_contentControl removeFromSuperview];
	_contentControl = nil;
	
	[super dealloc];
}

-(id) initWithContentType:(ContentType) contentType
{
	if( self = [super init] )
	{
		_titleLabel = [[UILabel alloc] init];
		[self addSubview:_titleLabel];
		[_titleLabel release];
		
		_contentLabel = [[UILabel alloc] init];
		[self addSubview:_contentLabel];
		[_contentLabel release];
		
		_contentType = contentType;
		if( _contentType == ContentTypeButton )
		{
			_contentControl = [UIButton buttonWithType:UIButtonTypeCustom];
			[self addSubview:_contentControl];
		}
		else if( _contentType == ContentTypeTextField )
		{
			_contentControl = (id)[[UITextField alloc] init];
			[self addSubview:_contentControl];
			[_contentControl release];
		}
		else if( _contentType == ContentTypeTextView )
		{
			_contentControl = (id)[[UITextView alloc] init];
			[self addSubview:_contentControl];
			[_contentControl release];
		}
	}
	return self;
}

@end





@implementation ProfileView

@synthesize editMode = _editMode;

#pragma mark
#pragma mark member functions

-(void) setEditMode:(BOOL)bEditMode
{
	_editMode = bEditMode;
	
	_fullName.hidden = bEditMode;
	_phone.hidden = bEditMode;
	_changeAvatar.hidden = !bEditMode;
	_nameTableView.hidden = !bEditMode;
	
	if( _editingText )
	{
		[self saveValueToProfile];
	}
	_fullName.text = [NSString stringWithFormat:@"%@ %@", _editingProfile.firstname, _editingProfile.lastname];
	_phone.text = _editingProfile.phone;
	
	[self reloadData];
	
	// recalc _scrollView's contentSize
	CGSize contentSize = _scrollView.contentSize;
	contentSize.height = _infoTableView.frame.origin.y + _infoTableView.contentSize.height;
	_scrollView.contentSize = contentSize;
}

-(void) setFrame:(CGRect)frame
{
	[super setFrame:frame];
	_scrollView.frame = self.bounds;
}

-(void) setProfile:(User*)profile
{
	if( profile != _profile )
	{
		[_profile release];
		if( profile != nil )
		{
			_profile = [profile retain];
		}
	}
	[_editingProfile set:_profile];
	
	_email.text = _profile.email;
	if( _profile.photoData )
	{
		_avatar.image = [UIImage imageWithData:_profile.photoData];
	}
	else
	{
		[_avatar imageFromURL:_profile.photoURL Delegate:self];
	}
	
	[self reloadData];
	
	_profileChanged = NO;
}

-(User*) getEditedProfile
{
	if( _editingText )
	{
		[self editDoneButtonClicked:nil];
	}
	return _editingProfile;
}

-(BOOL) isPickingImage
{
	return _pickingImage;
}

-(void) cleanPickingImage
{
	_pickingImage = NO;
}

-(void) collectAll
{
	if( _personalInfoExpanded )
	{
		[self tableView:_infoTableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
	}
	if( _vehicleInfoExpanded )
	{
		[self tableView:_infoTableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
	}
	if( _medicalInfoExpaned )
	{
		[self tableView:_infoTableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
	}
	if( _settingInfoExpanded )
	{
		[self tableView:_infoTableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:3]];
	}
}

#pragma mark
#pragma mark utils

-(NSArray*) getBirthYearArray
{
	NSMutableArray* array = [NSMutableArray array];
	NSDateComponents* comp = [[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:[NSDate date]];
	for( long i=comp.year; i>=1910; i-- )
	{
		[array addObject:[NSString stringWithFormat:@"%ld", i]];
	}
	return array;
}

-(NSArray*) getGenderArray{return [NSArray arrayWithObjects:@"Male", @"Female", nil];}

-(NSArray*) getEthnicityArray{return [NSArray arrayWithObjects:@"Asian or Pacific Islander",
									  @"Black/African American",
									  @"Caucasian",
									  @"East Indian",
									  @"Hispanic",
									  @"Native American Indian",
									  @"Other", nil];}

-(NSArray*) getEyeColorArray{return [NSArray arrayWithObjects:@"Amber",
									 @"Blue",
									 @"Brown",
									 @"Gray",
									 @"Green",
									 @"Hazel",
									 @"Other", nil];}

-(NSArray*) getHairColorArray{return [NSArray arrayWithObjects:@"Black",
									  @"Brown",
									  @"Blonde",
									  @"Auburn",
									  @"Chestnut",
									  @"Red",
									  @"Gray / White",
                                      @"Bald",
                                      nil];}

-(NSArray*) getVehicleYearArray
{
	NSMutableArray* array = [NSMutableArray array];
	NSDateComponents* comp = [[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:[NSDate date]];
	for( long i=comp.year; i>=1900; i-- )
	{
		[array addObject:[NSString stringWithFormat:@"%ld", i]];
	}
	return array;
}

-(void) saveValueToProfile
{
	if( _editingText == nil ) return;
	
	if( _editingText == _firstEditor ) _editingProfile.firstname = _firstEditor.text;
	else if( _editingText == _lastEditor ) _editingProfile.lastname = _lastEditor.text;
	else if( _editingText == _phoneEditor ) _editingProfile.phone = _phoneEditor.text;
	
	else if( _editingText == _birthYear.contentControl )
	{
		_editingProfile.birthYear = [[self getBirthYearArray] objectAtIndex:[_picker selectedRowInComponent:0]];
		_birthYear.contentLabel.text = _editingProfile.birthYear;
		_birthYear.contentLabel.textColor = [UIColor colorWithRed:55.0/255.0 green:96.0/255.0 blue:146.0/255.0 alpha:1.0f];
	}
	else if( _editingText == _gender.contentControl )
	{
		_editingProfile.gender = [[self getGenderArray] objectAtIndex:[_picker selectedRowInComponent:0]];
		_gender.contentLabel.text = _editingProfile.gender;
		_gender.contentLabel.textColor = [UIColor colorWithRed:55.0/255.0 green:96.0/255.0 blue:146.0/255.0 alpha:1.0f];
	}
	else if( _editingText == _ethnicity.contentControl )
	{
		_editingProfile.ethnicity = [[self getEthnicityArray] objectAtIndex:[_picker selectedRowInComponent:0]];
		_ethnicity.contentLabel.text = _editingProfile.ethnicity;
		_ethnicity.contentLabel.textColor = [UIColor colorWithRed:55.0/255.0 green:96.0/255.0 blue:146.0/255.0 alpha:1.0f];
	}
	else if( _editingText == _height.contentControl ) _editingProfile.height = _height.contentControl.text;
	else if( _editingText == _weight.contentControl ) _editingProfile.weight = _weight.contentControl.text;
	else if( _editingText == _eyes.contentControl )
	{
		_editingProfile.eyes = [[self getEyeColorArray] objectAtIndex:[_picker selectedRowInComponent:0]];
		_eyes.contentLabel.text = _editingProfile.eyes;
		_eyes.contentLabel.textColor = [UIColor colorWithRed:55.0/255.0 green:96.0/255.0 blue:146.0/255.0 alpha:1.0f];
	}
	else if( _editingText == _hair.contentControl )
	{
		_editingProfile.hair = [[self getHairColorArray] objectAtIndex:[_picker selectedRowInComponent:0]];
		_hair.contentLabel.text = _editingProfile.hair;
		_hair.contentLabel.textColor = [UIColor colorWithRed:55.0/255.0 green:96.0/255.0 blue:146.0/255.0 alpha:1.0f];
	}
	else if( _editingText == _homeStreet.contentControl ) _editingProfile.homeStreet = _homeStreet.contentControl.text;
	else if( _editingText == _homeCity.contentControl ) _editingProfile.homeCity = _homeCity.contentControl.text;
	else if( _editingText == _homeState.contentControl ) _editingProfile.homeState = _homeState.contentControl.text;
	else if( _editingText == _homeZip.contentControl ) _editingProfile.homeZip = _homeZip.contentControl.text;
	else if( _editingText == _homeCountry.contentControl ) _editingProfile.homeCountry = _homeCountry.contentControl.text;
	
	else if( _editingText == _vehicleYear.contentControl )
	{
		_editingProfile.vehicleYear = [[self getVehicleYearArray] objectAtIndex:[_picker selectedRowInComponent:0]];
		_vehicleYear.contentLabel.text = _editingProfile.vehicleYear;
		_vehicleYear.contentLabel.textColor = [UIColor colorWithRed:55.0/255.0 green:96.0/255.0 blue:146.0/255.0 alpha:1.0f];
	}
	else if( _editingText == _vehicleMake.contentControl ) _editingProfile.vehicleMake = _vehicleMake.contentControl.text;
	else if( _editingText == _vehicleModel.contentControl ) _editingProfile.vehicleModel = _vehicleModel.contentControl.text;
	else if( _editingText == _vehicleColor.contentControl ) _editingProfile.vehicleColor = _vehicleColor.contentControl.text;
	else if( _editingText == _vehicleLP.contentControl ) _editingProfile.vehicleLP = _vehicleLP.contentControl.text;
	else if( _editingText == _vehicleLS.contentControl ) _editingProfile.vehicleLS = _vehicleLS.contentControl.text;
	
	else if( _editingText == _medicalAllergies.contentControl ) _editingProfile.medicalAllergies = _medicalAllergies.contentControl.text;
	else if( _editingText == _medicalMedications.contentControl ) _editingProfile.medicalMedications = _medicalMedications.contentControl.text;
	else if( _editingText == _medicalConditions.contentControl ) _editingProfile.medicalConditions = _medicalConditions.contentControl.text;
}

#pragma mark
#pragma mark views

-(void) updateSubviewsOfView:(UIView*)view
				   itemCount:(NSInteger)itemCount
					   items:(CustomEditView***)items
					   types:(ContentType*)types
					 titiles:(NSString**)titles
					  values:(NSString**)values
{
	CGRect newFrame = CGRectMake(0, GROUPED_MARGIN_TOPBOTTOM, _personalView.bounds.size.width, NORMAL_ROW_HEIGHT);
	
	for( int i=0; i<itemCount; i++, newFrame.origin.y+=newFrame.size.height )
	{
		BOOL firstCreate = NO;
		if( !*items[i] )
		{
			(*items[i]) = [[CustomEditView alloc] initWithContentType:types[i]];
			(*items[i]).frame = newFrame;
			[view addSubview:(*items[i])];
			[(*items[i]) release];
			firstCreate = YES;
		}
		
		CustomEditView* editView = (*items[i]);
		
		editView.contentLabel.hidden = (_editMode && (editView.contentType != ContentTypeButton));
		editView.contentControl.hidden = (!_editMode);
		
		editView.titleLabel.backgroundColor = [UIColor clearColor];
		editView.titleLabel.font = [UIFont boldSystemFontOfSize:14];
		editView.titleLabel.textColor = [UIColor colorWithRed:125.0/255.0 green:125.0/255.0 blue:125.0/255.0 alpha:1.0f];
		editView.titleLabel.text = titles[i];
		
		editView.contentLabel.numberOfLines = 0;
		editView.contentLabel.backgroundColor = [UIColor clearColor];
		editView.contentLabel.font = [UIFont boldSystemFontOfSize:14];
		editView.contentLabel.textColor = [UIColor colorWithRed:55.0/255.0 green:96.0/255.0 blue:146.0/255.0 alpha:1.0f];
		editView.contentLabel.text = values[i];
		
		if( (view == _personalView) || (view == _vehicleView)  )
		{
			editView.titleLabel.textAlignment = NSTextAlignmentRight;
			editView.titleLabel.frame = CGRectMake(CELL_MARGIN, 0,
												   (view == _personalView)?CELL_PERSONAL_TITLE_WIDTH:CELL_VEHICLE_TITLE_WIDTH,
												   NORMAL_ROW_HEIGHT);
			editView.contentLabel.frame = CGRectMake(view.bounds.size.width-CELL_MARGIN-CELL_CONTENT_WIDTH,
													 (NORMAL_ROW_HEIGHT-NORMAL_ROW_CONTENT_HEIGHT)/2,
													 CELL_CONTENT_WIDTH,
													 NORMAL_ROW_CONTENT_HEIGHT);
			if( (editView == _homeStreet) ||
			   (editView == _homeCity) ||
			   (editView == _homeCountry) ||
			   (editView == _homeState) ||
			   (editView == _homeZip) )
			{
				if( (!_editMode) && editView.contentLabel.text.length == 0 )
				{
					editView.contentLabel.text = titles[i];
					editView.contentLabel.textColor = [UIColor colorWithRed:179.0/255.0
																	  green:179.0/255.0
																	   blue:179.0/255.0
																	  alpha:1.0];
				}
				
				editView.contentLabel.frame = CGRectMake(CELL_MARGIN+MARGIN,
														 editView.contentLabel.frame.origin.y,
														 newFrame.size.width-CELL_MARGIN*2-MARGIN*2,
														 editView.contentLabel.frame.size.height);
				editView.titleLabel.hidden = YES;
				if( editView == _homeStreet )
				{
					newFrame.origin.y += GROUPED_MARGIN_TOPBOTTOM;
					editView.frame = newFrame;
				}
				else if( editView == _homeState )
				{
					editView.frame = CGRectMake(newFrame.origin.x,
												newFrame.origin.y,
												newFrame.size.width-130,
												newFrame.size.height);
					editView.contentLabel.frame = CGRectMake(editView.contentLabel.frame.origin.x,
															 editView.contentLabel.frame.origin.y,
															 editView.frame.size.width-editView.contentLabel.frame.origin.x-MARGIN,
															 editView.contentLabel.frame.size.height);
				}
				else if( editView == _homeZip )
				{
					newFrame.origin.y -= newFrame.size.height;
					editView.frame = CGRectMake(newFrame.origin.x+newFrame.size.width-130,
												newFrame.origin.y,
												130,
												newFrame.size.height);
					editView.contentLabel.frame = CGRectMake(MARGIN,
															 editView.contentLabel.frame.origin.y,
															 130-CELL_MARGIN-MARGIN*2,
															 editView.contentLabel.frame.size.height);
				}
			}
			else
			{
				editView.contentLabel.textAlignment = NSTextAlignmentCenter;
				if( editView.tag )
				{
					CALayer* layer = (CALayer*)(editView.tag);
					[layer removeFromSuperlayer];
				}
				CALayer* subLayer = [CALayer layer];
				subLayer.backgroundColor = [UIColor clearColor].CGColor;
				subLayer.borderWidth = 1;
				subLayer.borderColor = [UIColor colorWithRed:55.0/255.0 green:96.0/255.0 blue:146.0/255.0 alpha:1.0f].CGColor;
				subLayer.frame = CGRectMake(editView.contentLabel.frame.origin.x-3,
											editView.contentLabel.frame.origin.y-3,
											editView.contentLabel.frame.size.width+6,
											editView.contentLabel.frame.size.height+6);
				[editView.layer addSublayer:subLayer];
				editView.tag = (int)subLayer;
			}
		}
		else if( view == _medicalView )
		{
			editView.titleLabel.frame = CGRectMake(CELL_MARGIN,
												   GROUPED_MARGIN_TOPBOTTOM+MARGIN,
												   newFrame.size.width-CELL_MARGIN*2,
												   NORMAL_ROW_TITLE_HEIGHT);
			
			if( _editMode )
			{
				newFrame.size.height = MEDICAL_ROW_HEIGHT;
			}
			else
			{
				newFrame.size.height = editView.titleLabel.frame.origin.y+editView.titleLabel.frame.size.height+MARGIN/2;
				CGSize contentSize = [values[i] sizeWithFont:[UIFont boldSystemFontOfSize:14.0]
										   constrainedToSize:CGSizeMake(editView.titleLabel.frame.size.width, 99999)];
				if( contentSize.height == 0 ) newFrame.size.height = MEDICAL_ROW_HEIGHT;
				else
				{
					newFrame.size.height += contentSize.height;
				}
			}
			editView.contentLabel.frame = CGRectMake(CELL_MARGIN,
													 editView.titleLabel.frame.origin.y+editView.titleLabel.frame.size.height+MARGIN/2,
													 editView.titleLabel.frame.size.width,
													 newFrame.size.height-
													 (editView.titleLabel.frame.origin.y+editView.titleLabel.frame.size.height+MARGIN/2));
			newFrame.size.height += GROUPED_MARGIN_TOPBOTTOM+MARGIN;
			editView.frame = newFrame;
			
			if( editView.tag )
			{
				CALayer* layer = (CALayer*)(editView.tag);
				[layer removeFromSuperlayer];
			}
			CALayer* subLayer = [CALayer layer];
			subLayer.backgroundColor = [UIColor clearColor].CGColor;
			subLayer.borderWidth = 1;
			subLayer.borderColor = [UIColor colorWithRed:55.0/255.0 green:96.0/255.0 blue:146.0/255.0 alpha:1.0f].CGColor;
			subLayer.frame = CGRectMake(MARGIN,
										GROUPED_MARGIN_TOPBOTTOM,
										newFrame.size.width-MARGIN*2,
										editView.frame.size.height - 12);
			[editView.layer addSublayer:subLayer];
			editView.tag = (int)subLayer;
		}
		
		if( editView.contentType == ContentTypeTextField )
		{
			UITextField* editor = (UITextField*)editView.contentControl;
			editor.backgroundColor = [UIColor clearColor];
			editor.delegate = self;
			editor.returnKeyType = UIReturnKeyDone;
//			editor.clearButtonMode = UITextFieldViewModeWhileEditing;
			editor.textColor = editView.contentLabel.textColor;
			editor.textAlignment = editView.contentLabel.textAlignment;
			editor.font = editView.contentLabel.font;
			CGRect editorFrame = editView.contentLabel.frame;
			editorFrame.origin.y += 3;
			editor.frame = editorFrame;
			editor.text = editView.contentLabel.text;
			if( editView.titleLabel.hidden )
			{
				editor.placeholder = editView.titleLabel.text;
			}
			else
			{
				editor.placeholder = @"<Enter>";
			}
		}
		else if( editView.contentType == ContentTypeTextView )
		{
			UITextView* editor = (UITextView*)editView.contentControl;
			editor.backgroundColor = [UIColor clearColor];
			editor.delegate = self;
			editor.textColor = editView.contentLabel.textColor;
			editor.font = [UIFont boldSystemFontOfSize:14];
			editor.frame = CGRectMake(editView.contentLabel.frame.origin.x-8,
									  editView.contentLabel.frame.origin.y-4,
									  editView.contentLabel.frame.size.width+8*2,
									  editView.contentLabel.frame.size.height+4*2);
			editor.text = editView.contentLabel.text;
		}
		else if( editView.contentType == ContentTypeButton )
		{
			UIButton* button = (UIButton*)editView.contentControl;
			button.frame = CGRectMake(0, 0, 300, NORMAL_ROW_HEIGHT);
			[button addTarget:self action:@selector(selectorDidClicked:) forControlEvents:UIControlEventTouchUpInside];
			
			if( (_editMode) && (editView.contentLabel.text.length == 0) )
			{
				editView.contentLabel.textColor = [UIColor colorWithRed:179.0/255.0
																  green:179.0/255.0
																   blue:179.0/255.0
																  alpha:1.0];
				editView.contentLabel.text = @"<Select>";
			}
		}
	}
	
	if( view == _personalView )
	{
		if( view.tag )
		{
			NSArray* layers = (NSArray*)(view.tag);
			for( CALayer* layer in layers )
			{
				[layer removeFromSuperlayer];
			}
			[layers release];
		}
		NSMutableArray* layers = [[NSMutableArray alloc] init];
		view.tag = (int)layers;
		
		CALayer* subLayer = [CALayer layer];
		subLayer.backgroundColor = [UIColor clearColor].CGColor;
		subLayer.borderWidth = 1;
		subLayer.borderColor = [UIColor colorWithRed:55.0/255.0 green:96.0/255.0 blue:146.0/255.0 alpha:1.0f].CGColor;
		subLayer.frame = CGRectMake(CELL_MARGIN,
									_homeStreet.frame.origin.y,
									view.bounds.size.width - CELL_MARGIN*2+2,
									_homeCountry.frame.origin.y+_homeCountry.frame.size.height-_homeStreet.frame.origin.y);
		[view.layer addSublayer:subLayer];
		[layers addObject:subLayer];
		
		subLayer = [CALayer layer];
		subLayer.backgroundColor = [UIColor clearColor].CGColor;
		subLayer.borderWidth = 1;
		subLayer.borderColor = [UIColor colorWithRed:55.0/255.0 green:96.0/255.0 blue:146.0/255.0 alpha:1.0f].CGColor;
		subLayer.frame = CGRectMake(CELL_MARGIN,
									_homeCity.frame.origin.y,
									view.bounds.size.width - CELL_MARGIN*2+2,
									_homeCity.frame.size.height);
		[view.layer addSublayer:subLayer];
		[layers addObject:subLayer];
		
		subLayer = [CALayer layer];
		subLayer.backgroundColor = [UIColor clearColor].CGColor;
		subLayer.borderWidth = 1;
		subLayer.borderColor = [UIColor colorWithRed:55.0/255.0 green:96.0/255.0 blue:146.0/255.0 alpha:1.0f].CGColor;
		subLayer.frame = CGRectMake(CELL_MARGIN,
									_homeCity.frame.origin.y+_homeCity.frame.size.height-1,
									view.bounds.size.width - CELL_MARGIN - 130,
									_homeState.frame.size.height+1);
		[view.layer addSublayer:subLayer];
		[layers addObject:subLayer];
		
		subLayer = [CALayer layer];
		subLayer.backgroundColor = [UIColor clearColor].CGColor;
		subLayer.borderWidth = 1;
		subLayer.borderColor = [UIColor colorWithRed:55.0/255.0 green:96.0/255.0 blue:146.0/255.0 alpha:1.0f].CGColor;
		subLayer.frame = CGRectMake(view.bounds.size.width-130-1,
									_homeCity.frame.origin.y+_homeCity.frame.size.height-1,
									130-CELL_MARGIN+1+2,
									_homeState.frame.size.height+1);
		[view.layer addSublayer:subLayer];
		[layers addObject:subLayer];
		
		newFrame.origin.y += GROUPED_MARGIN_TOPBOTTOM;
	}
	
	view.frame = CGRectMake(view.frame.origin.x,
							view.frame.origin.y,
							view.frame.size.width,
							newFrame.origin.y+GROUPED_MARGIN_TOPBOTTOM);
}

-(void) createPersonalView
{
	if( _personalView ) return;
	
	_personalView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREENWIDTH-MARGIN*2, NORMAL_ROW_HEIGHT*12)];
	[_personalView setBackgroundColor:[UIColor clearColor]];
}

-(void) createVehicleView
{
	if( _vehicleView ) return;
	
	_vehicleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREENWIDTH-MARGIN*2, NORMAL_ROW_HEIGHT*6)];
	[_vehicleView setBackgroundColor:[UIColor clearColor]];
}

-(void) createMedicalView
{
	if( _medicalView ) return;
	
	_medicalView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREENWIDTH-MARGIN*2, (NORMAL_ROW_CONTENT_TOP+5)*3)];
	[_medicalView setBackgroundColor:[UIColor clearColor]];
}

-(void) reloadData
{
	{
		NSString* personalTitles[] = {
			@"Birth Year",
			@"Gender",
			@"Ethnicity",
			@"Height",
			@"Weight",
			@"Eye Color",
			@"Hair Color",
			@"Street Address",
			@"City",
			@"State or Province",
			@"Postal Code",
			@"Country"
		};
		
		NSString* personalValues[] = {
			_editingProfile.birthYear,
			_editingProfile.gender,
			_editingProfile.ethnicity,
			_editingProfile.height,
			_editingProfile.weight,
			_editingProfile.eyes,
			_editingProfile.hair,
			_editingProfile.homeStreet,
			_editingProfile.homeCity,
			_editingProfile.homeState,
			_editingProfile.homeZip,
			_editingProfile.homeCountry
		};
		
		CustomEditView** personalItems[] = {
			&_birthYear,
			&_gender,
			&_ethnicity,
			&_height,
			&_weight,
			&_eyes,
			&_hair,
			&_homeStreet,
			&_homeCity,
			&_homeState,
			&_homeZip,
			&_homeCountry
		};
		
		ContentType personalTypes[] = {
			ContentTypeButton,
			ContentTypeButton,
			ContentTypeButton,
			ContentTypeTextField,
			ContentTypeTextField,
			ContentTypeButton,
			ContentTypeButton,
			ContentTypeTextField,
			ContentTypeTextField,
			ContentTypeTextField,
			ContentTypeTextField,
			ContentTypeTextField
		};
		
		[self updateSubviewsOfView:_personalView
						 itemCount:12
							 items:personalItems
							 types:personalTypes
						   titiles:personalTitles
							values:personalValues];
	}
	
	{
		NSString* vehicleTitles[] = {
			@"Year",
			@"Make",
			@"Model",
			@"Color",
			@"License #",
			@"License State"
		};
		
		NSString* vehicleValues[] = {
			_editingProfile.vehicleYear,
			_editingProfile.vehicleMake,
			_editingProfile.vehicleModel,
			_editingProfile.vehicleColor,
			_editingProfile.vehicleLP,
			_editingProfile.vehicleLS
		};
		
		CustomEditView** vehicleItems[] = {
			&_vehicleYear,
			&_vehicleMake,
			&_vehicleModel,
			&_vehicleColor,
			&_vehicleLP,
			&_vehicleLS
		};
		
		ContentType vehicleTypes[] = {
			ContentTypeButton,
			ContentTypeTextField,
			ContentTypeTextField,
			ContentTypeTextField,
			ContentTypeTextField,
			ContentTypeTextField
		};
		
		[self updateSubviewsOfView:_vehicleView
						 itemCount:6
							 items:vehicleItems
							 types:vehicleTypes
						   titiles:vehicleTitles
							values:vehicleValues];
	}
	
	{
		NSString* medicalTitles[] = {
			@"Allergies:",
			@"Medications:",
			@"Other Conditions:"
		};
		
		NSString* medicalValues[] = {
			_editingProfile.medicalAllergies,
			_editingProfile.medicalMedications,
			_editingProfile.medicalConditions
		};
		
		CustomEditView** medicalItems[] = {
			&_medicalAllergies,
			&_medicalMedications,
			&_medicalConditions
		};
		
		ContentType medicalTypes[] = {
			ContentTypeTextView,
			ContentTypeTextView,
			ContentTypeTextView
		};
		
		[self updateSubviewsOfView:_medicalView
						 itemCount:3
							 items:medicalItems
							 types:medicalTypes
						   titiles:medicalTitles
							values:medicalValues];
	}
	
	
	[_nameTableView reloadData];
	[_infoTableView reloadData];
	[self hidePicker];
	_editingText = nil;
}

#pragma mark
#pragma mark UITableViewDelegate & UITableViewDataSource

-(CGFloat) tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
	if( tableView == _nameTableView )
	{
		return (tableView.frame.size.height-3) / 3;
	}
	else if( tableView == _infoTableView )
	{
		if( indexPath.row == 0 )
		{
			return EXPANDIBLE_LABEL_HEIGHT;
		}
		else if( indexPath.section == 0 )
		{
			return _personalView.bounds.size.height;
		}
		else if( indexPath.section == 1 )
		{
			return _vehicleView.bounds.size.height;
		}
		else if( indexPath.section == 2 )
		{
			return _medicalView.bounds.size.height;
		}
		else if( indexPath.section == 3 )
		{
			return SETTING_ROW_HEIGHT;
		}
	}
	return 0;
}

-(CGFloat) tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section
{
	if( tableView == _nameTableView )
	{
		return 1;
	}
	else
	{
		return HEADER_FOOTER_HEIGHT;
	}
}

-(CGFloat) tableView:(UITableView*)tableView heightForFooterInSection:(NSInteger)section
{
	if( tableView == _nameTableView )
	{
		return 1;
	}
	else if( tableView == _infoTableView )
	{
		if( section == 3 )
		{
			return PRIVACY_HEIGHT + 10;
		}
	}
	return HEADER_FOOTER_HEIGHT;
}

-(NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
	if( tableView == _nameTableView )
	{
		return 1;
	}
	else
	{
		return 4;
	}
}

-(NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	if( tableView == _nameTableView )
	{
		return 3;
	}
	else if( tableView == _infoTableView )
	{
		if( (section == 0) && _personalInfoExpanded ) return 2;
		else if( (section == 1) && _vehicleInfoExpanded ) return 2;
		else if( (section == 2) && _medicalInfoExpaned ) return 2;
		else if( (section == 3) && _settingInfoExpanded ) return 3;
		else return 1;
	}
	return 0;
}

-(void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	if( (tableView == _infoTableView) && (indexPath.row == 0) )
	{
		BOOL* bpExpanded = NULL;
		int heightInc = 0;
		
		if( indexPath.section == 0 )
		{
			bpExpanded = &_personalInfoExpanded;
		}
		else if( indexPath.section == 1 )
		{
			bpExpanded = &_vehicleInfoExpanded;
		}
		else if( indexPath.section == 2 )
		{
			bpExpanded = &_medicalInfoExpaned;
		}
		else if( indexPath.section == 3 )
		{
			bpExpanded = &_settingInfoExpanded;
		}
		
		if( bpExpanded && (!*bpExpanded) )
		{
			[self collectAll];
		}
		
		if( *bpExpanded )
		{
			NSMutableArray* indexPaths = [NSMutableArray array];
			for( int i=1; i<[self tableView:tableView numberOfRowsInSection:indexPath.section]; i++ )
			{
				[indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
				heightInc -= [self tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
			}
			*bpExpanded = NO;
//			[tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationBottom];
		}
		else
		{
			*bpExpanded = YES;
			NSMutableArray* indexPaths = [NSMutableArray array];
			for( int i=1; i<[self tableView:tableView numberOfRowsInSection:indexPath.section]; i++ )
			{
				[indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
				heightInc += [self tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
			}
//			[tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationBottom];
		}
		
		UIImageView* iv = nil;
		UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
		for( UIView* v in cell.subviews )
		{
			if( v.tag == EXPANDIBLE_IMAGE_TAG )
			{
				iv = (UIImageView*)v;
				break;
			}
		}
		if( iv )
		{
			if( *bpExpanded )
			{
				iv.frame = CGRectMake(EXPANDIBLE_IMAGE_LEFT-EXPANDIBLE_IMAGE_HEIGHT/2,
									  EXPANDIBLE_IMAGE_TOP-EXPANDIBLE_IMAGE_WIDTH/2,
									  EXPANDIBLE_IMAGE_HEIGHT, EXPANDIBLE_IMAGE_WIDTH);
				iv.image = [UIImage imageNamed:@"expand.png"];
			}
			else
			{
				iv.frame = CGRectMake(EXPANDIBLE_IMAGE_LEFT-EXPANDIBLE_IMAGE_WIDTH/2,
									  EXPANDIBLE_IMAGE_TOP-EXPANDIBLE_IMAGE_HEIGHT/2,
									  EXPANDIBLE_IMAGE_WIDTH, EXPANDIBLE_IMAGE_HEIGHT);
				iv.image = [UIImage imageNamed:@"collect.png"];
			}
		}
		
		[UIView animateWithDuration:0.3
						 animations:^{
							 CGRect newFrame = tableView.frame;
							 newFrame.size.height += heightInc;
							 tableView.frame = newFrame;
							 
							 newFrame.size = _scrollView.contentSize;
							 newFrame.size.height += heightInc;
							 _scrollView.contentSize = newFrame.size;
							 
							 if( *bpExpanded )
							 {
								 CGPoint visibleOffset = CGPointMake(0, _infoTableView.frame.origin.y);
								 switch( indexPath.section )
								 {
									 case 2:
										 visibleOffset.y += [self tableView:_infoTableView heightForHeaderInSection:1];
										 visibleOffset.y += [self tableView:_infoTableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
										 visibleOffset.y += [self tableView:_infoTableView heightForFooterInSection:1];
									 case 1:
										 visibleOffset.y += [self tableView:_infoTableView heightForHeaderInSection:0];
										 visibleOffset.y += [self tableView:_infoTableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
										 visibleOffset.y += [self tableView:_infoTableView heightForFooterInSection:0];
										 break;
									 case 3:
										 visibleOffset.y = _scrollView.contentSize.height-_scrollView.frame.size.height;
										 break;
								 }
								 if( (visibleOffset.y+_scrollView.frame.size.height) > _scrollView.contentSize.height )
								 {
									 visibleOffset.y = _scrollView.contentSize.height-_scrollView.frame.size.height;
								 }
								 if( visibleOffset.y < 0 ) visibleOffset.y = 0;
								 [_scrollView setContentOffset:visibleOffset animated:YES];
							 }
						 } completion:^(BOOL finished) {
						 }];
		
		[_nameTableView reloadData];
		[_infoTableView reloadData];
		[self hidePicker];
	}
}

-(UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString* CellIdentifier = @"Cell";
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
	if( cell != nil ) return cell;
	
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_3_0
	cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];
#else
	cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:nil] autorelease];
#endif
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	
	if( tableView == _nameTableView )
	{
		CGRect newFrame = CGRectMake(TEXT_FIELD_LEFT_MARGIN,
									 TEXT_FIELD_TOP_MARGIN,
									 tableView.frame.size.width-TEXT_FIELD_LEFT_MARGIN-TEXT_FIELD_RIGHT_MARGIN,
									 [self tableView:tableView heightForRowAtIndexPath:indexPath]-TEXT_FIELD_TOP_MARGIN-TEXT_FIELD_BOTTOM_MARGIN);
		
		UITextField** pTextField = NULL;
		if( indexPath.row == 0 )
		{
			pTextField = &_firstEditor;
		}
		else if( indexPath.row == 1 )
		{
			pTextField = &_lastEditor;
		}
		else if( indexPath.row == 2 )
		{
			pTextField = &_phoneEditor;
		}
		
		if( pTextField && (*pTextField == nil) )
		{
			*pTextField = [[UITextField alloc] initWithFrame:newFrame];
			(*pTextField).clearButtonMode = UITextFieldViewModeWhileEditing;
			(*pTextField).textColor = [UIColor colorWithRed:55.0/255.0 green:96.0/255.0 blue:146.0/255.0 alpha:1.0f];
			(*pTextField).font = [UIFont boldSystemFontOfSize:14];
			(*pTextField).returnKeyType = UIReturnKeyDone;
			(*pTextField).delegate = self;
		}
		
		switch( indexPath.row )
		{
			case 0:
				(*pTextField).text = _editingProfile.firstname;
				(*pTextField).placeholder = @"first name";
				break;
			case 1:
				(*pTextField).text = _editingProfile.lastname;
				(*pTextField).placeholder = @"last name";
				break;
			case 2:
				(*pTextField).text = _editingProfile.phone;
				(*pTextField).placeholder = @"phone";
				break;
		}
		
		[cell addSubview:(*pTextField)];
	}
	else if( tableView == _infoTableView )
	{
		if( indexPath.row == 0 )
		{
			BOOL expanded = ([self tableView:tableView numberOfRowsInSection:indexPath.section] > 1);
			CGRect newFrame = CGRectMake(EXPANDIBLE_IMAGE_LEFT,
										 EXPANDIBLE_IMAGE_TOP,
										 EXPANDIBLE_IMAGE_WIDTH,
										 EXPANDIBLE_IMAGE_HEIGHT);
			UIImageView* iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"collect.png"]];
			if( expanded )
			{
				newFrame.size = CGSizeMake(EXPANDIBLE_IMAGE_HEIGHT, EXPANDIBLE_IMAGE_WIDTH);
				iv.image = [UIImage imageNamed:@"expand.png"];
			}
			newFrame.origin.x -= newFrame.size.width / 2;
			newFrame.origin.y -= newFrame.size.height / 2;
			iv.frame = newFrame;
			iv.tag = EXPANDIBLE_IMAGE_TAG;
			[cell addSubview:iv];
			[iv release];
			
			UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(EXPANDIBLE_LABEL_LEFT,
																	   0,
																	   EXPANDIBLE_LABEL_WIDTH,
																	   EXPANDIBLE_LABEL_HEIGHT)];
			label.font = [UIFont boldSystemFontOfSize:14];
			label.backgroundColor = [UIColor clearColor];
			label.textColor = [UIColor colorWithRed:55.0/255.0 green:96.0/255.0 blue:146.0/255.0 alpha:1.0f];
			[cell addSubview:label];
			[label release];
			
			label.text = (indexPath.section==0)?@"Personal Information":
			(indexPath.section==1)?@"Vehicle Information":
			(indexPath.section==2)?@"Medical Information":
			(indexPath.section==3)?@"Settings":@"";
		}
		else if( indexPath.section == 0 )
		{
			if( _personalView.superview )
			{
				[_personalView removeFromSuperview];
			}
			[cell.contentView addSubview:_personalView];
		}
		else if( indexPath.section == 1 )
		{
			if( _vehicleView.superview )
			{
				[_vehicleView removeFromSuperview];
			}
			[cell.contentView addSubview:_vehicleView];
		}
		else if( indexPath.section == 2 )
		{
			if( _medicalView.superview )
			{
				[_medicalView removeFromSuperview];
			}
			[cell.contentView addSubview:_medicalView];
		}
		else // index.section == 3
		{
			CGRect newFrame = CGRectZero;
			
			UIButton** pButton = nil;
			BOOL buttonChecked = NO;
			
			UILabel* prompt = [[UILabel alloc] init];
			prompt.backgroundColor = [UIColor clearColor];
			prompt.numberOfLines = 2;
			prompt.textColor = [UIColor colorWithRed:127.0/255.0 green:127.0/255.0 blue:127.0/255.0 alpha:1.0f];
			prompt.textAlignment = NSTextAlignmentRight;
			if( indexPath.row == 1 )
			{
				prompt.text = @"Prompt to send itinerary on\nActivity activation";
				pButton = &_promptButton;
				buttonChecked = _editingProfile.sendItinerary;
			}
			else if( indexPath.row == 2 )
			{
				prompt.text = @"Send overview email when\nadding new contacts";
				pButton = &_sendButton;
				buttonChecked = _editingProfile.sendOverview;
			}
			newFrame.size = [prompt.text sizeWithFont:prompt.font constrainedToSize:CGSizeMake(99999, 99999)];
			newFrame.origin.x = (320-newFrame.size.width-MARGIN-CHECKBOX_WIDTH)/2;
			newFrame.origin.y = (SETTING_ROW_HEIGHT-newFrame.size.height)/2;
			prompt.frame = newFrame;
			[cell addSubview:prompt];
			[prompt release];
			if( *pButton == nil )
			{
				*pButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
				(*pButton).frame = CGRectMake(prompt.frame.origin.x+prompt.frame.size.width+MARGIN,
											  (SETTING_ROW_HEIGHT-CHECKBOX_WIDTH)/2,
											  CHECKBOX_WIDTH, CHECKBOX_WIDTH);
				[(*pButton) setBackgroundImage:[UIImage imageNamed:@"uncheck.png"] forState:UIControlStateNormal];
				[(*pButton) setBackgroundImage:[UIImage imageNamed:@"check.png"] forState:UIControlStateSelected];
				[(*pButton) addTarget:self action:@selector(promptChanged:) forControlEvents:UIControlEventTouchUpInside];
			}
			(*pButton).selected = buttonChecked;
			[cell addSubview:(*pButton)];
		}
	}
	
	return cell;
}

-(UIView*) tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section
{
	if( (tableView != _infoTableView) || (section != 3) ) return nil;
	
	UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, PRIVACY_HEIGHT)];
	view.backgroundColor = [UIColor clearColor];
	
	CGRect newFrame = CGRectZero;
	
	UILabel* version = [[UILabel alloc] init];
	version.backgroundColor = [UIColor clearColor];
	version.textColor = [UIColor colorWithRed:127.0/255.0 green:127.0/255.0 blue:127.0/255.0 alpha:1.0];
	version.text = @"v1.2.0";
	version.textAlignment = NSTextAlignmentRight;
	version.font = [UIFont systemFontOfSize:10.0];
	version.frame = CGRectMake(10, PRIVACY_HEIGHT-10, view.frame.size.width-20, 10);
	[view addSubview:version];
	[version release];
	
	UIButton* privacy = [UIButton buttonWithType:UIButtonTypeCustom];
	privacy.titleLabel.font = [UIFont boldSystemFontOfSize:14.0];
	[privacy setTitleColor:[UIColor colorWithRed:37.0/255.0 green:64.0/255.0 blue:97.0/255.0 alpha:1.0f] forState:UIControlStateNormal];
	[privacy setTitle:@"Privacy Policy" forState:UIControlStateNormal];
	newFrame.size = [[privacy titleForState:UIControlStateNormal] sizeWithFont:privacy.titleLabel.font constrainedToSize:CGSizeMake(99999, 99999)];
	newFrame.origin.x = (320-newFrame.size.width)/2;
	newFrame.origin.y = PRIVACY_HEIGHT-newFrame.size.height-version.frame.size.height;
	privacy.frame = newFrame;
	[privacy addTarget:self action:@selector(privacyDidClicked:) forControlEvents:UIControlEventTouchUpInside];
	[view addSubview:privacy];
	
	UILabel* needHelp = [[UILabel alloc] init];
	needHelp.backgroundColor = [UIColor clearColor];
	needHelp.textColor = [UIColor colorWithRed:127.0/255.0 green:127.0/255.0 blue:127.0/255.0 alpha:1.0];
	needHelp.text = @"Need help?  ";
	needHelp.font = [UIFont boldSystemFontOfSize:14.0];
	newFrame.size = [needHelp.text sizeWithFont:needHelp.font constrainedToSize:CGSizeMake(999999, 999999)];
	needHelp.frame = newFrame;
	[view addSubview:needHelp];
	[needHelp release];
	
	UIButton* email = [UIButton buttonWithType:UIButtonTypeCustom];
	email.titleLabel.font = [UIFont boldSystemFontOfSize:14.0];
	[email setTitleColor:[UIColor colorWithRed:37.0/255.0 green:64.0/255.0 blue:97.0/255.0 alpha:1.0f] forState:UIControlStateNormal];
	[email setTitle:@"support@gobugle.com" forState:UIControlStateNormal];
	newFrame.size = [[email titleForState:UIControlStateNormal] sizeWithFont:email.titleLabel.font constrainedToSize:CGSizeMake(99999, 99999)];
	email.frame = newFrame;
	[email addTarget:self action:@selector(supportDidClicked:) forControlEvents:UIControlEventTouchUpInside];
	[view addSubview:email];
	
	newFrame = needHelp.frame;
	newFrame.origin.x = (320-newFrame.size.width-email.frame.size.width)/2;
	newFrame.origin.y = privacy.frame.origin.y - newFrame.size.height;
	needHelp.frame = newFrame;
	
	newFrame = email.frame;
	newFrame.origin.x = needHelp.frame.origin.x + needHelp.frame.size.width;
	newFrame.origin.y = privacy.frame.origin.y - newFrame.size.height;
	email.frame = newFrame;
	
	[view autorelease];
	return view;
}

#pragma mark
#pragma mark keyboard events

-(void) moveEditingControlToVisible
{
	CGFloat cellY = 0;
	CGFloat cellHeight = 0;
	
	BOOL bFound = NO;
	
	if( !bFound )
	{
		cellY = _nameTableView.frame.origin.y + [self tableView:_nameTableView heightForHeaderInSection:0];
		id nameEditors[] = {
			_firstEditor,
			_lastEditor,
			_phoneEditor
		};
		for( int i=0; i<sizeof(nameEditors)/sizeof(id); i++ )
		{
			cellHeight = [self tableView:_nameTableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
			if( _editingText == nameEditors[i] )
			{
				bFound = YES;
				break;
			}
			else cellY += cellHeight;
		}
	}
	
	if( !bFound )
	{
		cellY = _infoTableView.frame.origin.y + [self tableView:_infoTableView heightForHeaderInSection:0];
		cellY += [self tableView:_infoTableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
		if( _personalInfoExpanded )
		{
			id personalEditors[] = {
				_birthYear.contentControl,
				_gender.contentControl,
				_ethnicity.contentControl,
				_height.contentControl,
				_weight.contentControl,
				_eyes.contentControl,
				_hair.contentControl,
				_homeStreet.contentControl,
				_homeCity.contentControl,
				_homeState.contentControl,
				_homeZip.contentControl,
				_homeCountry.contentControl
			};
			for( int i=0; i<sizeof(personalEditors)/sizeof(id); i++ )
			{
				cellHeight = NORMAL_ROW_HEIGHT;
				if( _editingText == personalEditors[i] )
				{
					bFound = YES;
					break;
				}
				else cellY += cellHeight;
			}
		}
	}
	
	if( !bFound )
	{
		cellY += [self tableView:_infoTableView heightForFooterInSection:0];
		cellY += [self tableView:_infoTableView heightForHeaderInSection:1];
		cellY += [self tableView:_infoTableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
		if( _vehicleInfoExpanded )
		{
			id vehicleEditors[] = {
				_vehicleYear.contentControl,
				_vehicleMake.contentControl,
				_vehicleModel.contentControl,
				_vehicleColor.contentControl,
				_vehicleLP.contentControl,
				_vehicleLS.contentControl
			};
			for( int i=0; i<sizeof(vehicleEditors)/sizeof(id); i++ )
			{
				cellHeight = NORMAL_ROW_HEIGHT;
				if( _editingText == vehicleEditors[i] )
				{
					bFound = YES;
					break;
				}
				else cellY += cellHeight;
			}
		}
	}
	
	if( !bFound )
	{
		cellY += [self tableView:_infoTableView heightForFooterInSection:1];
		cellY += [self tableView:_infoTableView heightForHeaderInSection:2];
		cellY += [self tableView:_infoTableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
		if( _medicalInfoExpaned )
		{
			id medicalEditors[] = {
				_medicalAllergies.contentControl,
				_medicalMedications.contentControl,
				_medicalConditions.contentControl
			};
			for( int i=0; i<sizeof(medicalEditors)/sizeof(id); i++ )
			{
				cellHeight = ((UIView*)medicalEditors[i]).superview.bounds.size.height;
				if( _editingText == medicalEditors[i] )
				{
					bFound = YES;
					break;
				}
				else cellY += cellHeight;
			}
		}
	}
	
	if( bFound )
	{
		[_scrollView scrollRectToVisible:CGRectMake(0, cellY, SCREENWIDTH, cellHeight+10) animated:YES];
	}
	
	if( (!_profileChanged) &&
	   _delegate &&
	   [_delegate respondsToSelector:@selector(profileDidChanged)] )
	{
		_profileChanged = YES;
		[_delegate profileDidChanged];
	}
}

-(void) keyboardWillShow:(NSNotification*)notification
{
	if( _editingText != nil )
	{
		CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
		
		CGPoint offsetTop = [_viewController.view convertPoint:CGPointMake(0, 0) fromView:self];
		
		CGRect newFrame = _scrollView.frame;
		newFrame.size.height = _viewController.view.bounds.size.height -
		keyboardSize.height -
		offsetTop.y -
		_editBar.frame.size.height;
		_scrollView.frame = newFrame;
		
		newFrame = _editBar.frame;
		newFrame.origin.y = _scrollView.frame.origin.y + _scrollView.frame.size.height;
		_editBar.frame = newFrame;
        
		_keyboardStillShown = YES;
		_editBar.hidden = NO;
		
		[self moveEditingControlToVisible];
	}
}

-(void) keyboardWillHide:(NSNotification*)notification
{
	if( _editingText != nil )
	{
		CGRect newFrame = _scrollView.frame;
		newFrame.size.height = self.bounds.size.height;
		_scrollView.frame = newFrame;
        
		_keyboardStillShown = NO;
		_editBar.hidden = YES;
	}
}

-(void) showPicker:(NSArray*)contents selected:(NSInteger)selected
{
	// create a date picker if its not exist
	if( _picker == nil )
	{
		_picker = [[CustomPickerView alloc] init];
	}
	_picker.datas = contents;
	[_picker selectRow:selected inComponent:0 animated:NO];
	
	if( _picker.superview == nil )
	{
		[_viewController.view addSubview:_picker];
		
		// set picker frame & show
		_picker.frame = CGRectMake(0,
								   _viewController.view.bounds.size.height,
								   SCREENWIDTH,
								   216);
		[UIView animateWithDuration:0.3
						 animations:^{
							 CGRect newFrame = _picker.frame;
							 newFrame.origin.y -= newFrame.size.height;
							 _picker.frame = newFrame;
						 }];
		
		CGPoint offsetTop = [_viewController.view convertPoint:CGPointMake(0, 0) fromView:self];
		
		CGRect newFrame = _scrollView.frame;
		newFrame.size.height = _viewController.view.bounds.size.height -
		_picker.frame.size.height -
		offsetTop.y -
		_editBar.frame.size.height;
		_scrollView.frame = newFrame;
		
		newFrame = _editBar.frame;
		newFrame.origin.y = _scrollView.frame.origin.y + _scrollView.frame.size.height;
		_editBar.frame = newFrame;
		
		_editBar.hidden = NO;
	}
	
	// show the editing control visible
	[self moveEditingControlToVisible];
}

-(void) hidePicker
{
	if( (_picker == nil) || (_picker.superview == nil) ) return;
	
	// hide picker
	[UIView animateWithDuration:0.3
					 animations:^{
						 CGRect newFrame = _picker.frame;
						 newFrame.origin.y += newFrame.size.height;
						 _picker.frame = newFrame;
					 }
					 completion:^(BOOL finished) {
						 if( finished ) [_picker removeFromSuperview];
					 }];
	
	// resize the scroll view
	CGRect newFrame = _scrollView.frame;
	newFrame.size.height = self.bounds.size.height;
	_scrollView.frame = newFrame;
	
	_editBar.hidden = YES;
	_editingText = nil;
}

#pragma mark
#pragma mark InternetImageViewDelegate

-(void) InternetImageView:(InternetImageView*)imageView Image:(UIImage*)image
{
	if( image == nil )
	{
		image = [UIImage imageNamed:@"Default_Profile_Image.png"];
	}
	
	imageView.image = image;
	_editingProfile.photoData = UIImagePNGRepresentation(image);
}

#pragma mark
#pragma mark UINavigationControllerDelegate & UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary*)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
	
    UIImage *image = [info objectForKey:@"UIImagePickerControllerEditedImage"];
    
    [_avatar setImage:image];
	_editingProfile.photoData = UIImagePNGRepresentation(image);
	
	if( (!_profileChanged) &&
	   _delegate &&
	   [_delegate respondsToSelector:@selector(profileDidChanged)] )
	{
		_profileChanged = YES;
		[_delegate profileDidChanged];
	}
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark
#pragma mark UIActionSheetDelegate

-(void) actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // 从相册选取
    if( buttonIndex == 0 )
    {
        UIImagePickerController* ipc = [[UIImagePickerController alloc] init];
        ipc.delegate = self;
        ipc.allowsEditing = YES;
        ipc.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        
		_pickingImage = YES;
        [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:ipc animated:YES completion:nil];
        [AppDelegate getAppDelegate].isPresentModel = YES;
		[ipc release];
    }
    // 新照片
    else if( buttonIndex == 1 )
    {
        if( ![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] )
        {
            [self imagePickerController:nil didFinishPickingMediaWithInfo:[NSDictionary dictionaryWithObject:[UIImage imageNamed:@"bg_mainmenu.png"] forKey:@"UIImagePickerControllerEditedImage"]];
            return;
        }
        
        UIImagePickerController* ipc = [[UIImagePickerController alloc] init];
        ipc.delegate = self;
        ipc.allowsEditing = YES;
        ipc.sourceType = UIImagePickerControllerSourceTypeCamera;
        
		_pickingImage = YES;
        [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:ipc animated:YES completion:nil];
        [AppDelegate getAppDelegate].isPresentModel = YES;
		[ipc release];
    }
}

#pragma mark
#pragma mark button events

-(void) changeAvatarButtonClicked:(id)sender
{
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:@"Add Picture"
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"From Library", @"Take New Photo", nil];
    [actionSheet showInView:self];
    [actionSheet release];
}

-(void) promptChanged:(id)sender
{
	NSLog(@"promptChanged");
	if( !_editMode ) return;
	
	UIButton* button = (UIButton*)sender;
	button.selected = !button.selected;
	if( button == _promptButton )
	{
		_editingProfile.sendItinerary = button.selected;
	}
	else if( button == _sendButton )
	{
		_editingProfile.sendOverview = button.selected;
	}
	
	if( (!_profileChanged) &&
	   _delegate &&
	   [_delegate respondsToSelector:@selector(profileDidChanged)] )
	{
		_profileChanged = YES;
		[_delegate profileDidChanged];
	}
}

-(void) privacyDidClicked:(id)sender
{
	NSLog(@"privacyDidClicked");
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:PRIVACY_URL]];
}

-(void) supportDidClicked:(id)sender
{
	NSLog(@"supportDidClicked");
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:EMAIL_URL]];
}

-(void) prevNextButtonClicked:(id)sender
{
	NSLog(@"prevNextButtonClicked");
	NSInteger step = +1;
	if( ((UISegmentedControl*)sender).selectedSegmentIndex == 0 ) step = -1;
	
	id editingText = _editingText;
	
	if( (editingText == _firstEditor) && (step < 0) ) return;
	else if( (editingText == _medicalConditions.contentControl) && (step > 0) ) return;
	else if( ((step > 0) && (editingText == _phoneEditor) && (!_personalInfoExpanded)) ||
			((step < 0) && (editingText == _vehicleYear.contentControl) && (!_personalInfoExpanded)) )
	{
		[self tableView:_infoTableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
	}
	else if( ((step > 0) && (editingText == _homeCountry.contentControl) && (!_vehicleInfoExpanded)) ||
			((step < 0) && (editingText == _medicalAllergies.contentControl) && (!_vehicleInfoExpanded)) )
	{
		[self tableView:_infoTableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
	}
	else if( (step > 0) && (editingText == _vehicleLS.contentControl) && (!_medicalInfoExpaned) )
	{
		[self tableView:_infoTableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
	}
	
	id responderChain[] = {
		_firstEditor,
		_lastEditor,
		_phoneEditor,
		
		_birthYear.contentControl,
		_gender.contentControl,
		_ethnicity.contentControl,
		_height.contentControl,
		_weight.contentControl,
		_eyes.contentControl,
		_hair.contentControl,
		_homeStreet.contentControl,
		_homeCity.contentControl,
		_homeState.contentControl,
		_homeZip.contentControl,
		_homeCountry.contentControl,
		
		_vehicleYear.contentControl,
		_vehicleMake.contentControl,
		_vehicleModel.contentControl,
		_vehicleColor.contentControl,
		_vehicleLP.contentControl,
		_vehicleLS.contentControl,
		
		_medicalAllergies.contentControl,
		_medicalMedications.contentControl,
		_medicalConditions.contentControl
	};
	
	id nextResponder = nil;
	for( int i=0; i<sizeof(responderChain)/sizeof(id); i++ )
	{
		if( responderChain[i] == editingText )
		{
			nextResponder = responderChain[i+step];
			break;
		}
	}
	
	if( ([nextResponder class] == [UITextView class]) ||
	   ([nextResponder class] == [UITextField class]) )
	{
		[editingText resignFirstResponder];
		[nextResponder becomeFirstResponder];
	}
	else if( [nextResponder class] == [UIButton class] )
	{
		[self selectorDidClicked:nextResponder];
	}
}

-(void) editDoneButtonClicked:(id)sender
{
	NSLog(@"editDoneButtonClicked");
	if( ([_editingText class] == [UITextView class]) ||
	   ([_editingText class] == [UITextField class]) )
	{
		[_editingText resignFirstResponder];
	}
	else if( [_editingText class] == [UIButton class] )
	{
		[self saveValueToProfile];
		[self hidePicker];
	}
}

-(void) selectorDidClicked:(id)sender
{
	if( sender == _editingText ) return;
	
	NSArray* datas = nil;
	NSString* selected = @"";
	
	if( sender == _birthYear.contentControl )
	{
		datas = [self getBirthYearArray];
		selected = _editingProfile.birthYear;
	}
	else if( sender == _gender.contentControl )
	{
		datas = [self getGenderArray];
		selected = _editingProfile.gender;
	}
	else if( sender == _ethnicity.contentControl )
	{
		datas = [self getEthnicityArray];
		selected = _editingProfile.ethnicity;
	}
	else if( sender == _eyes.contentControl )
	{
		datas = [self getEyeColorArray];
		selected = _editingProfile.eyes;
	}
	else if( sender == _hair.contentControl )
	{
		datas = [self getHairColorArray];
		selected = _editingProfile.hair;
	}
	else if( sender == _vehicleYear.contentControl )
	{
		datas = [self getVehicleYearArray];
		selected = _editingProfile.vehicleYear;
	}
	
	if( datas == nil ) return;
	
	if( _editingText )
	{
		if( ([_editingText class] == [UITextView class]) ||
		   ([_editingText class] == [UITextField class]) )
		{
			[_editingText resignFirstResponder];
		}
		else if( [_editingText class] == [UIButton class] )
		{
			[self saveValueToProfile];
		}
	}
	
	_editingText = sender;
	
	NSInteger selectedIndex = [datas indexOfObject:selected];
	if( selectedIndex >= datas.count ) selectedIndex = 0;
	
	[self showPicker:datas selected:selectedIndex];
}

#pragma mark
#pragma mark UITextFieldDelegate & UITextViewDelegate

-(BOOL) textFieldShouldBeginEditing:(UITextField*)textField
{
	[_prevNextButton setEnabled:(textField!=_firstEditor) forSegmentAtIndex:0];
	[_prevNextButton setEnabled:(textField!=(UITextField*)_medicalConditions.contentControl) forSegmentAtIndex:1];
	
	if( _editingText && ([_editingText class] == [UIButton class]) )
	{
		[self saveValueToProfile];
		[self hidePicker];
	}
	return YES;
}

-(void) textFieldDidBeginEditing:(UITextField*)textField
{
	_editingText = textField;
	if( _keyboardStillShown )
	{
		[self moveEditingControlToVisible];
	}
}

-(BOOL) textFieldShouldEndEditing:(UITextField*)textField
{
//	if( textField == _phoneEditor )
//	{
//		if( _phoneEditor.text.length == 11 )
//		{
//			NSString* org = SafeCopy(_phoneEditor.text);
//			_phoneEditor.text = [NSString stringWithFormat:@"%@(%@)%@-%@",
//								 [org substringWithRange:NSMakeRange(0, 1)],
//								 [org substringWithRange:NSMakeRange(1, 3)],
//								 [org substringWithRange:NSMakeRange(4, 3)],
//								 [org substringWithRange:NSMakeRange(7, 4)]];
//		}
//	}
	
	[self saveValueToProfile];
	return YES;
}

-(BOOL) textFieldShouldReturn:(UITextField*)textField
{
	[self textFieldShouldEndEditing:textField];
	[textField resignFirstResponder];
	return YES;
}

-(BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	if( textField == _phoneEditor )
	{
        NSCharacterSet *numSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789-()"];
        NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        long charCount = [newString length];
        
        if ([string isEqualToString:@""])
        {
            return YES;
        }
        
        if ([newString rangeOfCharacterFromSet:[numSet invertedSet]].location != NSNotFound|| [string rangeOfString:@"-"].location != NSNotFound|| charCount > 14) {
            return NO;
        }
        
        if (charCount == 3)
        {
            newString = [NSString stringWithFormat:@"(%@)-", newString];
        }
        else if (charCount == 9)
        {
            newString = [newString stringByAppendingString:@"-"];
        }
        
        textField.text = newString;
        
        return NO;
	}
	return YES;
}

-(BOOL) textViewShouldBeginEditing:(UITextView*)textView
{
	BOOL bRet = [self textFieldShouldBeginEditing:(UITextField*)textView];
	_editingText = textView;
	return bRet;
}

-(void) textViewDidBeginEditing:(UITextView*)textView
{
	[self textFieldDidBeginEditing:(UITextField*)textView];
}

-(BOOL) textViewShouldEndEditing:(UITextView*)textView
{
	return [self textFieldShouldEndEditing:(UITextField*)textView];
}

-(BOOL) textView:(UITextView*)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString*)text
{
	if( (textView != (UITextView*)_medicalAllergies.contentControl) ||
	   (textView != (UITextView*)_medicalMedications.contentControl) ||
	   (textView != (UITextView*)_medicalConditions.contentControl) ) return YES;
	
	if( (textView.text.length - range.length + text.length) > 1000 ) return NO;
	else return YES;
}

#pragma mark
#pragma mark init & dealloc

-(void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	if( _firstEditor ) [_firstEditor release];
	if( _lastEditor ) [_lastEditor release];
	if( _phoneEditor ) [_phoneEditor release];
	
	if( _personalView.tag ) [((NSArray*)_personalView.tag) release];
	if( _personalView ) [_personalView release];
	
	if( _vehicleView.tag ) [((NSArray*)_vehicleView.tag) release];
	if( _vehicleView ) [_vehicleView release];
	
	if( _medicalView.tag ) [((NSArray*)_medicalView.tag) release];
	if( _medicalView ) [_medicalView release];
	
	if( _promptButton ) [_promptButton release];
	if( _sendButton ) [_sendButton release];
	
	if( _picker ) [_picker release];
	
	[_profile release];
	[_editingProfile release];
	[super dealloc];
}

-(id) initWithViewController:(UIViewController*)viewController andDelegate:(id<ProfileViewDelegate>)delegate
{
	if( self = [super init] )
	{
		_editingProfile = [[User alloc] init];
		_viewController = viewController;
		_delegate = delegate;
		
		_scrollView = [[UIScrollView alloc] init];
		[self addSubview:_scrollView];
		
		self.backgroundColor = [UIColor colorWithRed:240.0/255.0
											   green:240.0/255.0
												blue:240.0/255.0
											   alpha:1.0];
		
		_email = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREENWIDTH, EMAIL_HEIGHT)];
		_email.backgroundColor = [UIColor clearColor];
		_email.font = [UIFont boldSystemFontOfSize:20.0];
		_email.textAlignment = NSTextAlignmentCenter;
		_email.textColor = [UIColor grayColor];
		[_scrollView addSubview:_email];
		[_email release];
		
		_avatar = [[InternetImageView alloc] initWithFrame:CGRectMake(MARGIN, EMAIL_HEIGHT, AVATAR_HEIGHT, AVATAR_HEIGHT)];
		_avatar.backgroundColor = [UIColor grayColor];
		_avatar.layer.borderColor=[[UIColor colorWithRed:36.0/255.0 green:54.0/255.0 blue:77.0/255.0 alpha:1.0] CGColor];
		_avatar.layer.borderWidth= 1.0f;
		_avatar.layer.masksToBounds=YES;
		[_scrollView addSubview:_avatar];
		[_avatar release];
		
		_fullName = [[UILabel alloc] initWithFrame:CGRectMake(AVATAR_HEIGHT + MARGIN * 2,
															  EMAIL_HEIGHT + (AVATAR_HEIGHT - LABEL_HEIGHT*2)/2,
															  SCREENWIDTH - MARGIN * 3 - AVATAR_HEIGHT,
															  LABEL_HEIGHT)];
		_fullName.backgroundColor = [UIColor clearColor];
		_fullName.textColor = [UIColor colorWithRed:55.0/255.0 green:96.0/255.0 blue:146.0/255.0 alpha:1.0f];
		_fullName.font = [UIFont boldSystemFontOfSize:18.0];
		[_scrollView addSubview:_fullName];
		[_fullName release];
		
		_phone = [[UILabel alloc] initWithFrame:CGRectMake(_fullName.frame.origin.x,
														   _fullName.frame.origin.y + LABEL_HEIGHT,
														   _fullName.frame.size.width,
														   LABEL_HEIGHT)];
		_phone.backgroundColor = [UIColor clearColor];
		_phone.textColor = [UIColor colorWithRed:55.0/255.0 green:96.0/255.0 blue:146.0/255.0 alpha:1.0f];
		_phone.font = [UIFont boldSystemFontOfSize:17.0];
		[_scrollView addSubview:_phone];
		[_phone release];
		
		_changeAvatar = [UIButton buttonWithType:UIButtonTypeCustom];
		_changeAvatar.frame = _avatar.frame;
		[_changeAvatar addTarget:self action:@selector(changeAvatarButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
		[_scrollView addSubview:_changeAvatar];
		
		_nameTableView = [[UITableView alloc] initWithFrame:CGRectMake(AVATAR_HEIGHT + MARGIN,
																	   EMAIL_HEIGHT,
																	   SCREENWIDTH - MARGIN - AVATAR_HEIGHT,
																	   AVATAR_HEIGHT)
													  style:UITableViewStyleGrouped];
		_nameTableView.delegate = self;
		_nameTableView.dataSource = self;
		_nameTableView.scrollEnabled = NO;
		[_nameTableView setBackgroundView:nil];
		_nameTableView.separatorColor = [UIColor colorWithRed:55.0/255.0 green:96.0/255.0 blue:146.0/255.0 alpha:1.0f];
        if ([UIApplication respondsToSelector:@selector(setSeparatorInset:)]) {
            _nameTableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
        }
		[_scrollView addSubview:_nameTableView];
		[_nameTableView release];
		
		[self createPersonalView];
		[self createVehicleView];
		[self createMedicalView];
		[self reloadData];
		
		_infoTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
		_infoTableView.delegate = self;
		_infoTableView.dataSource = self;
		_infoTableView.scrollEnabled = NO;
		[_infoTableView setBackgroundView:nil];
		_infoTableView.separatorColor = [UIColor colorWithRed:55.0/255.0 green:96.0/255.0 blue:146.0/255.0 alpha:1.0f];
        if ([UIApplication respondsToSelector:@selector(setSeparatorInset:)]) {
            _infoTableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
        }
		[_infoTableView reloadData];
		_infoTableView.frame = CGRectMake(0,
										  EMAIL_HEIGHT+AVATAR_HEIGHT + MARGIN,
										  SCREENWIDTH,
										  _infoTableView.contentSize.height);
		[_scrollView addSubview:_infoTableView];
		[_infoTableView release];
		
		_scrollView.contentSize = CGSizeMake(SCREENWIDTH, _infoTableView.frame.origin.y + _infoTableView.frame.size.height + MARGIN);
		
		_editBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, SCREENWIDTH, 44)];
		_editBar.barStyle = UIBarStyleBlackTranslucent;
		_editBar.hidden = YES;
		[self addSubview:_editBar];
		[_editBar release];
		_prevNextButton = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Prev", @"Next", nil]];
		_prevNextButton.segmentedControlStyle = UISegmentedControlStyleBar;
        [_prevNextButton setTintColor:[UIColor whiteColor]];
		_prevNextButton.momentary = YES;
		[_prevNextButton addTarget:self action:@selector(prevNextButtonClicked:) forControlEvents:UIControlEventValueChanged];
		UIBarButtonItem* navItem = [[UIBarButtonItem alloc] initWithCustomView:_prevNextButton];
		[_prevNextButton release];
		UIBarButtonItem* sepItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																				 target:nil action:nil];
		UIBarButtonItem* doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																				  target:self action:@selector(editDoneButtonClicked:)];
        [doneItem setTintColor:[UIColor whiteColor]];
		[_editBar setItems:[NSArray arrayWithObjects:navItem, sepItem, doneItem, nil]];
		[navItem release];
		[sepItem release];
		[doneItem release];
		
		
		[self setEditMode:NO];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(keyboardWillShow:)
													 name:UIKeyboardWillShowNotification
												   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(keyboardWillHide:)
													 name:UIKeyboardWillHideNotification
												   object:nil];
	}
	
	return self;
}

@end

