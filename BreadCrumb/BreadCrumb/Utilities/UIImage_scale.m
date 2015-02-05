//
//  UIImage_scale.m
//  MaiPin
//
//  Created by Hugh on 9/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "UIImage_scale.h"

static CGFloat DegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};
static CGFloat RadiansToDegrees(CGFloat radians) {return radians * 180/M_PI;};

@implementation UIImage (scale)

-(CGFloat) getScaleWidthByHeight:(NSUInteger)height withSize:(CGSize)orgSize
{
	return orgSize.width * height / orgSize.height;
}

-(CGFloat) getScaleHeightByWidth:(NSUInteger)width withSize:(CGSize)orgSize
{
	return orgSize.height * width / orgSize.width;
}

-(UIImage*) scaleImage:(CGSize)canvasSize imgSize:(CGSize)imgSize
{
	// 创建一个bitmap的context
    // 并把它设置成为当前正在使用的context
    UIGraphicsBeginImageContext(canvasSize);
	
    // 绘制改变大小的图片，居中显示
	CGRect newFrame = CGRectMake(0, 0, imgSize.width, imgSize.height);
	if( imgSize.width != canvasSize.width )
	{
		newFrame.origin.x = (canvasSize.width-imgSize.width)/2;
	}
	if( imgSize.height != canvasSize.height )
	{
		newFrame.origin.y = (canvasSize.height-imgSize.height)/2;
	}
    [self drawInRect:newFrame];
	
    // 从当前context中创建一个改变大小后的图片
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
	
    // 使当前的context出堆栈
    UIGraphicsEndImageContext();
	
    // 返回新的改变大小后的图片
    return scaledImage;
}

-(UIImage*) stretchToSize:(CGSize)givenSize
{
	return [self scaleImage:givenSize imgSize:givenSize];
}

-(UIImage*) scaleBySize:(CGSize)givenSize
{
	CGFloat width = [self getScaleWidthByHeight:givenSize.height withSize:self.size];
	CGFloat height = [self getScaleHeightByWidth:givenSize.width withSize:self.size];
	
	// 计算不超过给定区域时图像缩放的最大尺寸
	CGSize newSize = CGSizeZero;
	if( width > givenSize.width )
	{
		newSize = CGSizeMake(givenSize.width, height);
	}
	else
	{
		newSize = CGSizeMake(width, givenSize.height);
	}
	
	return [self scaleImage:newSize imgSize:newSize];
}

-(UIImage*) scaleToSize:(CGSize)givenSize
{	
	CGFloat width = [self getScaleWidthByHeight:givenSize.height withSize:self.size];
	CGFloat height = [self getScaleHeightByWidth:givenSize.width withSize:self.size];
	
	// 计算不超过给定区域时图像缩放的最大尺寸
	CGSize newSize = CGSizeZero;
	if( width > givenSize.width )
	{
		newSize = CGSizeMake(givenSize.width, height);
	}
	else
	{
		newSize = CGSizeMake(width, givenSize.height);
	}
	
	return [self scaleImage:givenSize imgSize:newSize];
}

-(UIImage*) scaleWidthByHeight:(NSUInteger)height
{
	CGSize newSize = CGSizeMake([self getScaleWidthByHeight:height withSize:self.size], height);
	
	return [self scaleImage:newSize imgSize:newSize];
}

-(UIImage*) scaleHeightByWidth:(NSUInteger)width
{
	CGSize newSize = CGSizeMake(width, [self getScaleHeightByWidth:width withSize:self.size]);
	
	return [self scaleImage:newSize imgSize:newSize];
}

+(UIImage*) loadImage:(NSString*)imageName
{
	if( imageName == nil ) return nil;
	
	NSString* name = @"";
	NSString* ext = @"";
	for( NSInteger i=imageName.length-1; i>=0; i-- )
	{
		unichar cr = [imageName characterAtIndex:i];
		if( cr == '.' )
		{
			name = [imageName substringToIndex:i];
			ext = [imageName substringFromIndex:i+1];
			break;
		}
	}
//	name = @"replyHint";
	NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:ext];
	return [UIImage imageWithContentsOfFile:path];
}

-(UIImage*) getRoundedRectImage
{
    int w = self.size.width;
    int h = self.size.height;
    
    UIImage *img = self;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, w, h, 8, 4 * w, colorSpace, kCGImageAlphaPremultipliedFirst);
    CGRect rect = CGRectMake(0, 0, w, h);
    
    CGContextBeginPath(context);
	
	float fw, fh;
	
	CGContextSaveGState(context);
	CGContextTranslateCTM(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
	CGContextScaleCTM(context, 10, 10);
	fw = CGRectGetWidth(rect) / 10;
	fh = CGRectGetHeight(rect) / 10;
		
	CGContextMoveToPoint(context, fw, fh/2);  // Start at lower right corner
	CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 1);  // Top right corner
	CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 1); // Top left corner
	CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 1); // Lower left corner
	CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 1); // Back to lower right
	
	CGContextClosePath(context);
	CGContextRestoreGState(context);
	
    CGContextClosePath(context);
    CGContextClip(context);
    CGContextDrawImage(context, CGRectMake(0, 0, w, h), img.CGImage);
    CGImageRef imageMasked = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    UIImage* image = [UIImage imageWithCGImage:imageMasked];
    CGImageRelease(imageMasked);
    return image;
}

+(UIImage*) imageWithColor:(UIColor*)color
{
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
	
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
	
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
	
    return image;
}


-(UIImage *)imageRotatedByRadians:(CGFloat)radians
{
    return [self imageRotatedByDegrees:RadiansToDegrees(radians)];
}

-(UIImage *)imageRotatedByDegrees:(CGFloat)degrees 
{   
    // calculate the size of the rotated view's containing box for our drawing space
    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.size.width, self.size.height)];
    CGAffineTransform t = CGAffineTransformMakeRotation(DegreesToRadians(degrees));
    rotatedViewBox.transform = t;
    CGSize rotatedSize = rotatedViewBox.frame.size;
    [rotatedViewBox release];
    
    // Create the bitmap context
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    
    // Move the origin to the middle of the image so we will rotate and scale around the center.
    CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
    
    //   // Rotate the image context
    CGContextRotateCTM(bitmap, DegreesToRadians(degrees));
    
    // Now, draw the rotated/scaled image into the context
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-self.size.width / 2, -self.size.height / 2, self.size.width, self.size.height), [self CGImage]);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (UIImage*) cropImage:(UIImage*)inImage
{
	if (inImage)
	{
        if (inImage.size.width < inImage.size.height) 
        {
            //potrait
            CGFloat croppedWidth = inImage.size.width;
            CGFloat croppedHeight = inImage.size.width;
            
            CGImageRef croppedImage = CGImageCreateWithImageInRect([inImage CGImage], CGRectMake(0, (inImage.size.height-croppedHeight)/2, croppedWidth, croppedHeight));
            inImage = [UIImage imageWithCGImage:croppedImage];
            CGRect thumbRect = CGRectMake(0, 0, 200, 200);
            UIGraphicsBeginImageContext(CGSizeMake(200, 200));
            [inImage drawInRect:thumbRect];
            UIImage *thumbImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            return thumbImage;
        }
        else
        {
            //landscape
            CGFloat croppedHeight = inImage.size.height;
            CGFloat croppedWidth = inImage.size.height;
            
            CGImageRef croppedImage = CGImageCreateWithImageInRect([inImage CGImage], CGRectMake((inImage.size.width-croppedWidth)/2, 0, croppedWidth, croppedHeight));
            inImage = [UIImage imageWithCGImage:croppedImage];
            CGRect thumbRect = CGRectMake(0, 0, 200, 200);
            UIGraphicsBeginImageContext(CGSizeMake(200, 200));
            [inImage drawInRect:thumbRect];
            UIImage *thumbImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            return thumbImage;
        }
	}
	else 
		return nil;
}

@end
