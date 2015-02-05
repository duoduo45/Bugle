//
//  ProfileView.h
//  testProfileView
//
//  Created by verysmall on 12-12-10.
//  Copyright (c) 2012年 verysmall. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BreadCrumbData.h"
#import "InternetImageView.h"


@interface CustomPickerView : UIPickerView <UIPickerViewDataSource, UIPickerViewDelegate> {
	NSArray* _datas;
}

@property(nonatomic, strong) NSArray* datas;

@end



typedef enum {
	ContentTypeButton,
	ContentTypeTextField,
	ContentTypeTextView
} ContentType;
@interface CustomEditView : UIView

@property(nonatomic, strong, readonly) UILabel* titleLabel;
@property(nonatomic, strong, readonly) UILabel* contentLabel;
@property(nonatomic, readonly)		   ContentType contentType;
@property(nonatomic, strong, readonly) UILabel* contentControl;

-(id) initWithContentType:(ContentType) contentType;

@end



@protocol ProfileViewDelegate <NSObject>
@required
-(void) profileDidChanged;
@end



@interface ProfileView : UIView <UITableViewDataSource,
UITableViewDelegate,
UIActionSheetDelegate,
UINavigationControllerDelegate,
UIImagePickerControllerDelegate,
UITextFieldDelegate,
UITextViewDelegate,
InternetImageViewDelegate> {
	User* _profile;
	User* _editingProfile;
	UIViewController* _viewController;
	id<ProfileViewDelegate> _delegate;
	
	UIScrollView* _scrollView;
	
	// show
	UILabel* _email;
	InternetImageView* _avatar;
	UILabel* _fullName;
	UILabel* _phone;
	
	// edit
	UIButton* _changeAvatar;
	UITableView* _nameTableView;
	UITableView* _infoTableView;
	
	BOOL _personalInfoExpanded;
	BOOL _vehicleInfoExpanded;
	BOOL _medicalInfoExpaned;
	BOOL _settingInfoExpanded;
	
	UITextField* _firstEditor;
	UITextField* _lastEditor;
	UITextField* _phoneEditor;
	
	UIView* _personalView;
	CustomEditView* _birthYear;
	CustomEditView* _gender;
	CustomEditView* _ethnicity;
	CustomEditView* _height;
	CustomEditView* _weight;
	CustomEditView* _eyes;
	CustomEditView* _hair;
	CustomEditView* _homeStreet;
	CustomEditView* _homeCity;
	CustomEditView* _homeState;
	CustomEditView* _homeZip;
	CustomEditView* _homeCountry;
	
	UIView* _vehicleView;
	CustomEditView* _vehicleYear;
	CustomEditView* _vehicleMake;
	CustomEditView* _vehicleModel;
	CustomEditView* _vehicleColor;
	CustomEditView* _vehicleLP;
	CustomEditView* _vehicleLS;
	
	UIView* _medicalView;
	CustomEditView* _medicalAllergies;
	CustomEditView* _medicalMedications;
	CustomEditView* _medicalConditions;
	
	UIButton* _promptButton;
	UIButton* _sendButton;
	
	id _editingText;
	UISegmentedControl* _prevNextButton;
	UIToolbar* _editBar;
	BOOL _keyboardStillShown;
	CustomPickerView* _picker;
	
	BOOL _pickingImage;
}

@property(nonatomic) BOOL editMode;
@property(nonatomic, readonly) BOOL profileChanged;

-(id) initWithViewController:(UIViewController*)viewController andDelegate:(id<ProfileViewDelegate>)delegate;
-(void) setProfile:(User*)profile;
-(User*) getEditedProfile;

-(BOOL) isPickingImage;
-(void) cleanPickingImage;
-(void) collectAll;

@end

