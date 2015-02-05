//
//  UIImage_scale.h
//  MaiPin
//
//  Created by Hugh on 9/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

/********************************************************************
 * 按比例缩放的UIImage类扩展
 *******************************************************************/
@interface UIImage (scale)

/**
 * 拉伸到指定尺寸
 **/
-(UIImage*) stretchToSize:(CGSize)size;

/**
 * 根据给定的尺寸为最大尺寸，高和宽按比例缩放，高和宽不会超出给定的尺寸
 **/
-(UIImage*) scaleBySize:(CGSize)size;

/**
 * 根据给定的尺寸为最终尺寸，高和宽按比例缩放，空出的部分背景透明
 **/
-(UIImage*) scaleToSize:(CGSize)size;

/**
 * 根据给定的高度等比例缩放图像
 **/
-(UIImage*) scaleWidthByHeight:(NSUInteger)height;

/**
 * 根据给定的宽度等比例缩放图像
 **/
-(UIImage*) scaleHeightByWidth:(NSUInteger)width;

/**
 * 安全的加载图片方法，使用imageNamed加载图片会造成庞大的CACHE
 **/
+(UIImage*) loadImage:(NSString*)imageName;

/**
 * 获取圆角图片
 **/
-(UIImage*) getRoundedRectImage;

/**
 * 将颜色转换成图像
 **/
+(UIImage*) imageWithColor:(UIColor*)color;


-(UIImage *)imageRotatedByRadians:(CGFloat)radians;
-(UIImage *)imageRotatedByDegrees:(CGFloat)degrees;
-(UIImage *)cropImage:(UIImage*)inImage;

@end

