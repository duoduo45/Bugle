//
//  Macros.h
//  MyBabyCare
//
//  Created by Hui Jiang on 12-1-11.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#ifndef MyBabyCare_Macros_h
#define MyBabyCare_Macros_h

#define iPhone5 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size) : NO)

#define XIBBYINCHES(n) ([NSString stringWithFormat:@"%@%@",n,(iPhone5 == YES)?@"_iPhone5":@""])

#define SAFECHECK_RELEASE(x) if(x != nil) {[x release]; x = nil; }

#define UIIMAGE_FROMFILE(filename,type) [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:filename ofType:type]]

#define UIIMAGE_FROMPNG(filename) UIIMAGE_FROMFILE(filename, @"png")

#define STRING_SET_A_WITH_B_ONLYIF_B_IS_NOT_NIL(A,B)  if((B)!=nil) { A = (B);}

#define NUMBER_SET_A_WITH_B_ONLYIF_B_IS_NOT_NIL(A,B)  if((B)!=nil) { A= ([B intValue]);}

#define SET_DICTIONARY_A_OBJ_B_FOR_KEY_C_ONLYIF_B_IS_NOT_NIL(A,B,C) if((B)!=nil){ [A setObject:(B) forKey:(C)];}

#define INT2NUM(x) [NSNumber numberWithInteger:(x)]
#define DOUBLE2NUM(x) [NSNumber numberWithDouble:(x)]
#define INT2STR(x) [NSString stringWithFormat:@"%d", (x)]
#define LONGLONG2NUM(x) [NSNumber numberWithLongLong:(x)]
#define LONGLONG2STR(x) [NSString stringWithFormat:@"%lld", (x)]

#define SAFESTR(x) ((x)==nil)?@"":(x)

///// 矩形相关
#define CGRectTop(rect) rect.origin.y
#define CGRectLeft(rect) rect.origin.x
#define CGRectBottom(rect) (rect.size.height + rect.origin.y)
#define CGRectRight(rect) (rect.size.width + rect.origin.x)
#define CGRectSet(view, xx, yy, ww, hh) [view setFrame:CGRectMake((xx)==-1?view.frame.origin.x:(xx), (yy)==-1?view.frame.origin.y:(yy),(ww)==-1?view.frame.size.width:(ww), (hh)==-1?view.frame.size.height:(hh))]

///// 屏幕大小
#define SCREEN_ORIGIN_Y ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7?0:0)

#define iOS_STATUS_BAR_HEIGHT ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7?0:20)
#define SCREEN_HEIGHT  [[UIScreen mainScreen] bounds].size.height
#define SCREEN_HEIGHT_WITHOUT_STATUS_BAR  ([[UIScreen mainScreen] bounds].size.height-iOS_STATUS_BAR_HEIGHT)
#define SCREEN_WIDTH   [[UIScreen mainScreen] bounds].size.width
#define NAV_AND_STARUS_BAR_HEIGHT  64
#define BOTTOM_TAB_HEIGHT  44
#define isiOS7UP ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7?YES:NO)


////颜色
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
#define RGBCOLOR(r,g,b) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:1]
#define RGBACOLOR(r,g,b,a) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:(a)]

/// URL
#define URL(urlStr) [NSURL URLWithString:urlStr]

/// 屏幕位置
#define V_POS(x,w,s_w,isLeft)  (isLeft?(x):((s_w)-(w)-(x)))   // 离左边x距离，自身宽度w, superview宽度s_w 并且镜面反射到右边

#endif
