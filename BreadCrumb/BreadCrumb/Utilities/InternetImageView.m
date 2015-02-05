//
//  InternetImageView.m
//
//  Created by verysmall on 9/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "InternetImageView.h"
#include <sys/xattr.h>

@implementation GlobalImageBuffer

#pragma mark
#pragma mark 图片缓冲-内存缓冲

/**
 * 将图像添加到缓冲区，下次如果同样的URL请求则直接在缓冲区中返回，节省网络资源
 **/
-(void) addImageToBuffer:(UIImage*)image URL:(NSString*)url
{
	if( (image == nil) || (url == nil) || (url.length == 0) ) return;
	
	if( _lockOfBufferImage == nil ) _lockOfBufferImage = [[NSCondition alloc] init];
	
	[_lockOfBufferImage lock];
	if( _bufferImages == nil ) _bufferImages = [[NSMutableDictionary alloc] init];
	[_bufferImages setObject:image forKey:url];
	[_lockOfBufferImage unlock];
}

/**
 * 根据图像的URL查找缓冲区的图像
 **/
-(UIImage*) findImageFromBuffer:(NSString*)url
{
	if( (url == nil) || (url.length == 0) ) return nil;
	
	if( _lockOfBufferImage == nil ) _lockOfBufferImage = [[NSCondition alloc] init];
	
	[_lockOfBufferImage lock];
	UIImage* img = [_bufferImages objectForKey:url];
	[_lockOfBufferImage unlock];
	
	return img;
}

/**
 * 清空图片缓存
 **/
-(void) clearImageBuffer
{
	if( _lockOfBufferImage == nil ) _lockOfBufferImage = [[NSCondition alloc] init];
	
	[_lockOfBufferImage lock];
	[_bufferImages removeAllObjects];
	[_lockOfBufferImage unlock];
}

@end

#pragma mark
#pragma mark 图片缓冲-本地文件缓冲

@implementation GlobalImageBufferToLocal

-(void) dealloc
{
	[_pathString release];
	
	[super dealloc];
}

-(id) initWithPathString:(NSString*)pathString
{
	if( self = [super init] )
	{
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"image"];
		_pathString = [[documentsDirectory stringByAppendingPathComponent:pathString] retain];
	}
	return self;
}

-(NSString*) getSavePathFromURL:(NSString*)url andName:(NSString**)pName
{
	NSString* path = _pathString;
	
	NSArray *arrPartOfURL = [url pathComponents];
	if( arrPartOfURL.count < 2 ) return @"";
	
	path = [path stringByAppendingPathComponent:[arrPartOfURL objectAtIndex:arrPartOfURL.count-2]];
	if( pName != nil ) *pName = [path stringByAppendingPathComponent:[arrPartOfURL objectAtIndex:arrPartOfURL.count-1]];
	return path;
}

-(void) addImageToBuffer:(UIImage*)image URL:(NSString*)url
{
	NSString* name;
	NSString* path;
	path = [self getSavePathFromURL:url andName:&name];
	
	[[NSFileManager defaultManager]createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
	[[NSFileManager defaultManager]createFileAtPath:name contents:UIImagePNGRepresentation(image) attributes:nil];
	
	const char* filePath = [name fileSystemRepresentation];
    const char* attrName = "com.apple.MobileBackup";
    u_int8_t attrValue = 1;
    setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
}

-(UIImage*) findImageFromBuffer:(NSString*)url
{
	if( url.length == 0 ) return nil;
	
	NSString* name;
	[self getSavePathFromURL:url andName:&name];
	
	if( [[NSFileManager defaultManager] fileExistsAtPath:name] )
	{
		return [UIImage imageWithContentsOfFile:name];
	}
	else return nil;
}


-(void) clearImageBuffer
{
	[[NSFileManager defaultManager] removeItemAtPath:_pathString error:nil];
}

@end


@implementation InternetImageView

@synthesize url = _url;
@synthesize userdata = _userdata;

#pragma mark
#pragma mark 设置全局图片缓冲类

GlobalImageBuffer* g_globalImageBuffer = nil;
+(void) setGlobalImageBuffer:(GlobalImageBuffer*)imageBuffer
{
	if( g_globalImageBuffer != nil )
	{
		[g_globalImageBuffer release];
		g_globalImageBuffer = nil;
	}
	if( imageBuffer != nil ) g_globalImageBuffer = [imageBuffer retain];
}

+(GlobalImageBuffer*) getGlobalImageBuffer
{
	return g_globalImageBuffer;
}

#pragma mark
#pragma mark 工具函数

-(void) stopActivityIndicator
{
	if( _aiView != nil )
	{
		[_aiView stopAnimating];
		[_aiView removeFromSuperview];
		[_aiView release];
		_aiView = nil;
	}
}

-(void) startActivityIndicator
{
	if( _aiView == nil )
	{
		_aiView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		CGRect newFrame = self.frame;
		newFrame.origin = CGPointMake(0, 0);
		if( newFrame.size.width > 45 )
		{
			newFrame.origin.x = (newFrame.size.width-45)/2;
			newFrame.size.width = 45;
		}
		if( newFrame.size.height > 45 )
		{
			newFrame.origin.y = (newFrame.size.height-45)/2;
			newFrame.size.height = 45;
		}
		_aiView.frame = newFrame;
		[_aiView startAnimating];
		[self addSubview:_aiView];
	}
}

// 查看是否是网络图片
-(BOOL) isInternetImage:(NSString*)l_url
{
	if( l_url == nil )
	{
		return NO;
	}
	if( l_url.length == 0 )
	{
		return YES;
	}
	
	l_url = [l_url lowercaseString];
	return ( [l_url hasPrefix:@"http://"] );
}

#pragma mark
#pragma mark 成员函数

-(void) dealloc
{
	[self cancel];
	[_locker release];
	
	if( _imageBuffer != nil )
	{
		[_imageBuffer release];
		_imageBuffer = nil;
	}
	
    //add by zhang xinling
    [_url release];
    _url = nil;
	[super dealloc];
}

-(id) init
{
	if( self = [super init] )
	{
		_locker = [[NSCondition alloc] init];
	}
	return self;
}

-(void) cancel
{
	[_locker lock];
//	if( ![_request isFinished] )
	{
		[_request clearDelegatesAndCancel];
		if( _delegate != nil )
		{
			_delegate = nil;
		}
	}
	[_request release];
	_request = nil;
	[self stopActivityIndicator];
	[_locker unlock];
}

-(void) imageFromURL:(NSString*)urlString
{
	[self imageFromURL:urlString Delegate:self];
}

-(void) imageFromURL:(NSString*)urlString Delegate:(id)delegate
{
    GlobalImageBuffer* buff = [g_globalImageBuffer retain];
    [self imageFromURL:urlString  ImageBuffer:buff Delegate:delegate];
    [buff release];
}

-(void) imageFromURL:(NSString*)urlString ImageBuffer:(GlobalImageBuffer *)imageBuff
{
    GlobalImageBuffer* buff = [imageBuff retain];
    [self imageFromURL:urlString  ImageBuffer:buff Delegate:self];
    [buff release];
}

-(void) imageFromURL:(NSString*)urlString ImageBuffer:(GlobalImageBuffer *)imageBuff Delegate:(id)delegate
{
	// 清除以前的图片
	self.image = nil;
	
	UIImage* img = nil;
    
    //modify by Xinling Zhang
    if( _url != nil )
    {
        [_url release];
    }
	_url = [urlString copy];
	
	// 判断是否是本地图片
	if( ![self isInternetImage:urlString] )
	{
		if( delegate != nil )
		{
			img = [UIImage imageNamed:urlString];
			if( (delegate != nil) &&
			   ([delegate respondsToSelector:@selector(InternetImageView:Image:)]) )
			{
				[delegate performSelector:@selector(InternetImageView:Image:) withObject:self withObject:img];
			}
		}
		return;
	}
	
    if( _imageBuffer != nil )
	{
		[_imageBuffer release];
	}
	_imageBuffer = [imageBuff ? imageBuff : g_globalImageBuffer retain];
	// 判断图片是否在缓冲区中
    
	if( _imageBuffer != nil )
	{
		img = [_imageBuffer findImageFromBuffer:urlString];
	}
	if( img != nil )
	{
		if( (delegate != nil) && 
		   ([delegate respondsToSelector:@selector(InternetImageView:Image:)]) )
		{
			[delegate performSelector:@selector(InternetImageView:Image:) withObject:self withObject:img];
		}
		return;
	}
	
	// 设置默认图片
	//	self.image = [UIImage imageNamed:@"defaultUserImage.png"];
	
	NSLog(@"正在加载图片：%@", urlString);

//	if( _url != nil ) [_url release];
//	_url = urlString;
	_delegate = delegate;
	
	[_locker lock];
	
	[self startActivityIndicator];
	
	if( (_request != nil) && (![_request isFinished]) )
	{
		[_request clearDelegatesAndCancel];
	}
	
	_request = [[ASIHTTPRequest requestWithURL:[NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]] retain];
	
	[_request setDelegate:self];
    [_request setDidFinishSelector:@selector(successDownloadImage:)];
    [_request setDidFailSelector:@selector(failedDownloadImage:)];
	
	[_request startAsynchronous];
	
	[_locker unlock];
}

-(void) successDownloadImage:(ASIHTTPRequest*)request
{
	NSLog(@"%@", [request isFinished]?@"1":@"2");
	[_locker lock];
	
	UIImage* img = [UIImage imageWithData:_request.responseData];
	
	if( img != nil )
	{
		NSLog(@"图片加载成功:%@", _url);
	}
	else
	{
		NSLog(@"图片加载失败:%@", _url);
	}
	
	if( (img != nil) && (_imageBuffer != nil) )
	{
		[_imageBuffer addImageToBuffer:img URL:_url];
		[_imageBuffer release];
		_imageBuffer = nil;
	}
	
	if( (_delegate != nil) &&
	   ([_delegate respondsToSelector:@selector(InternetImageView:Image:)]) )
	{
		[_delegate performSelector:@selector(InternetImageView:Image:) withObject:self withObject:img];
	}
	
	[self stopActivityIndicator];
	
	[_locker unlock];
	
	_delegate = nil;
}

-(void) failedDownloadImage:(ASIHTTPRequest*)request
{
	NSLog(@"%@", [request isFinished]?@"1":@"2");
	[_locker lock];
	
	NSLog(@"图片加载失败:%@ [%@]", _url, request.error);
	
	if( (_delegate != nil) &&
	   ([_delegate respondsToSelector:@selector(InternetImageView:Image:)]) )
	{
		[_delegate performSelector:@selector(InternetImageView:Image:) withObject:self withObject:nil];
	}
	
	[self stopActivityIndicator];
	
	[_locker unlock];
	
	_delegate = nil;
}

-(void) InternetImageView:(InternetImageView*)imageView Image:(UIImage*)image
{
	if( image == nil )
	{
		image = [UIImage imageNamed:@"defaultInternetImage.png"];
	}
	imageView.image = image;
}

@end