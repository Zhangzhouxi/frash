//
//  PluginFlashView.m
//  Player2
//
//  Created by Nicholas Allegra on 6/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PluginFlashView.h"
#import <QuartzCore/QuartzCore.h>
#include "food_rpc2.h"

@interface NSObject (FakeMethodsToMakeGCCShutUp)

- (id)webFrame;
- (id)windowObject;

@end


@implementation PluginFlashView

- (void)makeServer {
	[self.server teardown];
	self.server = [[[Server alloc] initWithDelegate:self] autorelease];
	rpcfd = self.server.rpc_fd;	
}

- (id)initWithArguments:(NSDictionary *)arguments_ {
	if(self = [super init]) {
		arguments = [arguments_ retain];
		self.backgroundColor = [UIColor grayColor];
		NSLog(@"Making server...");
		[self makeServer];
	}
	return self;	   
}

+ (UIView *)plugInViewWithArguments:(NSDictionary *)arguments
{
	
	NSLog(@"IPAD WEB VIEW ARGS = %@", [arguments description]);
	
	//NSDictionary *pluginDict = [newArguments objectForKey:@"WebPlugInAttributesKey"];	
	//NSString *flashURL = [pluginDict objectForKey:@"src"];
	
    return [[[PluginFlashView alloc] initWithArguments:arguments] autorelease];
}



- (id)getWindowObject {
	return [[[arguments objectForKey:@"WebPlugInContainerKey"] webFrame] windowObject];
}

- (id)evaluateWebScript:(NSString *)script {
	NSLog(@"Evaluate %@", script);
	return [[self getWindowObject] evaluateWebScript:script];
}

- (void)useSurface:(IOSurfaceRef)sfc_ {
	sfc = sfc_;
	if(provider) CGDataProviderRelease(provider);
	provider = CGDataProviderCreateWithData(NULL, IOSurfaceGetBaseAddress(sfc), IOSurfaceGetAllocSize(sfc), NULL);
	oldContents = NULL;
	
}

- (void)displaySync {
	CGImageRef image = CGImageCreate(
									 IOSurfaceGetWidth(sfc),
									 IOSurfaceGetHeight(sfc),
									 8,
									 32,
									 4 * IOSurfaceGetWidth(sfc),
									 CGColorSpaceCreateDeviceRGB(),
									 kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast,
									 provider,
									 NULL,
									 true,
									 kCGRenderingIntentDefault);
	self.layer.contents = (id) image;
	if(oldContents) CGImageRelease(oldContents);
	oldContents = image;
}

- (NSDictionary *)paramsDict {
	return [arguments objectForKey:@"WebPlugInAttributesKey"];
}

- (CGSize)movieSize {
	return self.frame.size;
}

- (void)diedWithError:(NSString *)error {
	NSLog(@"Error: %@", error);
	
	label = [[UILabel alloc] init];
	label.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3]; // dim the image
	label.text = error;		
	label.frame = self.bounds;
	label.textAlignment = UITextAlignmentCenter;
	label.shadowColor = [UIColor blackColor];
	label.shadowOffset = CGSizeMake(0, 1);
	[self addSubview:label];
}


- (void)dealloc {
	[arguments release];
	[label release];
	if(oldContents) CGImageRelease(oldContents);	
    [super dealloc];
}

#define kDown_ANPTouchAction        0
#define kUp_ANPTouchAction          1
#define kMove_ANPTouchAction        2
#define kCancel_ANPTouchAction      3

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
		CALayer *lyr = self.layer;
		lyr.backgroundColor = [[UIColor blackColor] CGColor];
		self.multipleTouchEnabled = YES;
    }
    return self;
}

#define foo(func, num) \
- (void)func:(NSSet *)touches withEvent:(UIEvent *)event { \
for(UITouch *t in touches) { \
CGPoint location = [t locationInView:self]; \
touch(rpcfd, num, location.x, location.y); \
} \
} 

foo(touchesBegan, kDown_ANPTouchAction)
foo(touchesMoved, kMove_ANPTouchAction)
foo(touchesEnded, kUp_ANPTouchAction)
foo(touchesCancelled, kCancel_ANPTouchAction)


@synthesize server;
@end