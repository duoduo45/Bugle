//
//  CrumbListItem.m
//  BreadCrumb
//
//  Created by dongwen on 12-1-14.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "CrumbListItem.h"
#import "CrumbDetailViewController.h"


@implementation CrumbListItem {
    BOOL _isDeleteBtnShow;
}

@synthesize title = _title;
@synthesize content = _content;
@synthesize button = _button;
@synthesize crumb = _crumb;

-(void) setEditing:(BOOL)editing animated:(BOOL)animated
{
//    BOOL oldEditing = self.editing;
//    [super setEditing:editing animated:animated];
//    if( editing == oldEditing ) return;
//    
//    UIView* maskView = [[UIView alloc] initWithFrame:CGRectZero];
//    maskView.backgroundColor = [UIColor redColor];
//    [self.button addSubview:maskView];
//    [maskView release];
//    
//    UIImageView* iv = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 72, 50)];
//    iv.image = [UIImage imageNamed:@"deleteButton.png"];
//    [maskView addSubview:iv];
//    [iv release];
//    
//    
//    if( editing )
//    {
//        maskView.frame = CGRectMake(self.button.bounds.size.width,
//                                    0,
//                                    0,
//                                    self.button.bounds.size.height);
//        
//        [UIView animateWithDuration:0.3 animations:^{
//            maskView.frame = self.button.bounds;
//        } completion:^(BOOL finished) {
//            if( finished )
//            {
//                [maskView removeFromSuperview];
//                self.button.hidden = YES;
//            }
//        }];
//    }
//    else
//    {
//        maskView.frame = self.button.bounds;
//        self.button.hidden = NO;
//        [UIView animateWithDuration:0.3 animations:^{
//            maskView.frame = CGRectMake(self.button.bounds.size.width,
//                                        0,
//                                        0,
//                                        self.button.bounds.size.height);
//        } completion:^(BOOL finished) {
//            if( finished )
//            {
//                [maskView removeFromSuperview];
//            }
//        }];
//    }
}

-(void) dealloc
{
	if( _crumb )
	{
		[_crumb release];
	}
	[super dealloc];
}

-(void) setCrumb:(Crumb*)newCrumb
{
	if( _crumb != nil )
	{
		[_crumb release];
		_crumb = nil;
	}
	if( newCrumb != nil ) _crumb = [newCrumb retain];
	
    self.title.text = newCrumb.name;
	
	if( [newCrumb isCheckedOrCanceled] )
	{
		self.content.text = newCrumb.alertMessage;
		[self.button setImage:[UIImage imageNamed:@"reUseButton.png"] forState:UIControlStateNormal];
	}
	else if( [newCrumb isOverdue] )
	{
		self.content.textColor = [UIColor blackColor];
		self.content.text = @"Overdue. Check in now if you are safe.";
		[self.button setImage:[UIImage imageNamed:@"checkInButtonRed.png"] forState:UIControlStateNormal];
	}
	else if( [newCrumb isPending] )
	{
		NSDate* deadline = StringToDate(newCrumb.deadline);
		NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"YYYY-MM-dd"];
		if( [[formatter stringFromDate:deadline] isEqualToString:[formatter stringFromDate:[NSDate date]]] )
		{
			[formatter setDateFormat:@"'Check in by' hh:mma' today'"];
			self.content.text = [formatter stringFromDate:deadline];
		}
		else
		{
			[formatter setDateFormat:@"'Check in by' ccc, MMM dd 'at' hh:mma"];
			self.content.text = [formatter stringFromDate:deadline];
		}
		[formatter release];
		if( [newCrumb isWarned] )
		{
			[self.button setImage:[UIImage imageNamed:@"checkInButtonOrange.png"] forState:UIControlStateNormal];
		}
		else
		{
			[self.button setImage:[UIImage imageNamed:@"checkInButton.png"] forState:UIControlStateNormal];
		}
	}
	else
	{
		UIAlertView* av = [[UIAlertView alloc] initWithTitle:newCrumb.status
													 message:@"unknow status"
													delegate:nil
										   cancelButtonTitle:@"Ok"
										   otherButtonTitles:nil];
		[av show];
		[av release];
		NSLog(@"%@", newCrumb.status);
	}
    
    UISwipeGestureRecognizer *swipeGestureLeft = [[UISwipeGestureRecognizer alloc]
                                                  initWithTarget:self action:@selector(handleSwipeGestureLeft:)];
    swipeGestureLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    [self addGestureRecognizer:swipeGestureLeft];
    
    UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc]
                                              initWithTarget:self action:@selector(handleSwipeGestureRight:)];
    swipeGesture.direction = UISwipeGestureRecognizerDirectionRight;
    [self addGestureRecognizer:swipeGesture];
}


- (void)handleSwipeGestureLeft:(UISwipeGestureRecognizer *)gestureRecognizer {
    
    if (_isDeleteBtnShow) {
        return;
    }
    
    _deleteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _deleteBtn.frame = CGRectMake(self.frame.size.width+72, 0, 72, 50);
    [_deleteBtn setImage:[UIImage imageNamed:@"deleteButton.png"] forState:UIControlStateNormal];
    [_deleteBtn addTarget:self action:@selector(deleteBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_deleteBtn];
    
    if (gestureRecognizer.direction == UISwipeGestureRecognizerDirectionLeft) {
        
        NSLog(@"left");

        [UIView animateWithDuration:0.3 animations:^{
            self.deleteBtn.frame = CGRectMake(self.frame.size.width-72, 0, 72, 50);
        } completion:^(BOOL finished) {
            if( finished )
            {
                self.button.hidden = YES;
                _isDeleteBtnShow = YES;
            }
        }];
    }
}

- (void)handleSwipeGestureRight:(UISwipeGestureRecognizer *)gestureRecognizer {
    
    if (gestureRecognizer.direction ==UISwipeGestureRecognizerDirectionRight) {
        
        NSLog(@"right");
        self.button.hidden = NO;
        _isDeleteBtnShow = NO;
        [UIView animateWithDuration:0.3 animations:^{
            self.deleteBtn.frame = CGRectMake(self.frame.size.width-72, 0, 72, 50);
        } completion:^(BOOL finished) {
            if( finished )
            {
                [self.deleteBtn removeFromSuperview];
            }
        }];
    }
}

- (IBAction)deleteBtnClick:(id)sender {
    if (_delegate && [_delegate respondsToSelector:@selector(deleteButtonClickWithCrumb:)]) {
		[_delegate deleteButtonClickWithCrumb:_crumb];
	}
}
@end
