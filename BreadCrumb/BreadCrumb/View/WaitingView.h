//
//  WaitingView.h
//  YAroundMe_Telecom
//
//  Created by Hugh on 10/14/10.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WaitingView : UIView
{
	UIImageView*				_background;
	UIImageView*				_foreground;
	UILabel*					_instruction;
	UIActivityIndicatorView*	_waitingAnimation;
}

+(void) popWaiting;
+(void) dismissWaiting;
+(void) moveToTopMost;

@end
