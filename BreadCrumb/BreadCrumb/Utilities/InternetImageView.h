//
//  InternetImageView.h
//
//  Created by verysmall on 9/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//


/********************************************************************
 * 全局图像缓存类
 * 用户可以继承该图像缓存类实现将图片保存到文件或文件夹，基类只实现将图片缓存
 * 在内存，程序结束时自动清除缓存中的图像
 *******************************************************************/
@interface GlobalImageBuffer : NSObject
{
	NSCondition* _lockOfBufferImage;
	NSMutableDictionary* _bufferImages;
}

// 将图像添加到缓冲区，下次如果同样的URL请求则直接在缓冲区中返回，节省网络资源
-(void) addImageToBuffer:(UIImage*)image URL:(NSString*)url;

// 根据图像的URL查找缓冲区的图像
-(UIImage*) findImageFromBuffer:(NSString*)url;

// 清空图片缓存
-(void) clearImageBuffer;

@end

/********************************************************************
 * 全局图像缓存类-缓存到文件夹中文件夹由调用者提供或更改
 *******************************************************************/
@interface GlobalImageBufferToLocal : GlobalImageBuffer{
	NSString* _pathString;
}

-(id) initWithPathString:(NSString*)pathString;

@end




/********************************************************************
 * 网络图片下载类
 * 异步下载网络图片，并可以设置全局图片缓冲
 *******************************************************************/
#import "ASIHTTPRequest.h"
@interface InternetImageView : UIImageView {
	id _userdata;
	id _delegate;
	
	GlobalImageBuffer* _imageBuffer;
	NSCondition* _locker;
	NSString* _url;
	ASIHTTPRequest* _request;
	
	UIActivityIndicatorView* _aiView;
}

+(void) setGlobalImageBuffer:(GlobalImageBuffer*)imageBuffer;
+(GlobalImageBuffer*) getGlobalImageBuffer;

@property (nonatomic, readonly) NSString* url;
@property (nonatomic, retain) id userdata;

/**
 * 从网络路径加载图片，加载完成后通知delegate对象，如果不设置delegate则自动设置为
 * 下载的图片（此时如果加载失败则默认显示名为："defaultInternetImage.png"的图片）
 **/
-(void) imageFromURL:(NSString*)urlString;
-(void) imageFromURL:(NSString*)urlString Delegate:(id)delegate;
-(void) imageFromURL:(NSString*)urlString ImageBuffer:(GlobalImageBuffer *)imageBuff;
-(void) imageFromURL:(NSString*)urlString ImageBuffer:(GlobalImageBuffer *)imageBuff Delegate:(id)delegate;
-(void) cancel;

@end

/********************************************************************
 * 下载完毕后的回调
 *******************************************************************/
@protocol InternetImageViewDelegate

@required
-(void) InternetImageView:(InternetImageView*)imageView Image:(UIImage*)image;

@end