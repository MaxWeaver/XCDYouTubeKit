//
//  Copyright (c) 2013-2015 Cédric Luthi. All rights reserved.
//

#import "XCDYouTubeVideoPlayerViewController.h"

#import "XCDYouTubeClient.h"

#import <objc/runtime.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"

NSString *const XCDMoviePlayerPlaybackDidFinishErrorUserInfoKey = @"error"; // documented in -[MPMoviePlayerController initWithContentURL:]

NSString *const XCDYouTubeVideoPlayerViewControllerDidReceiveMetadataNotification = @"XCDYouTubeVideoPlayerViewControllerDidReceiveMetadataNotification";
NSString *const XCDMetadataKeyTitle = @"Title";
NSString *const XCDMetadataKeySmallThumbnailURL = @"SmallThumbnailURL";
NSString *const XCDMetadataKeyMediumThumbnailURL = @"MediumThumbnailURL";
NSString *const XCDMetadataKeyLargeThumbnailURL = @"LargeThumbnailURL";

NSString *const XCDYouTubeVideoPlayerViewControllerDidReceiveVideoNotification = @"XCDYouTubeVideoPlayerViewControllerDidReceiveVideoNotification";
NSString *const XCDYouTubeVideoUserInfoKey = @"Video";

@interface XCDYouTubeVideoPlayerViewController ()
@property (nonatomic, weak) id<XCDYouTubeOperation> videoOperation;
@property (nonatomic, assign, getter = isEmbedded) BOOL embedded;
@end

@implementation XCDYouTubeVideoPlayerViewController

/*
 * MPMoviePlayerViewController on iOS 7 and earlier
 * - (id) init
 *        `-- [super init]
 *
 * - (id) initWithContentURL:(NSURL *)contentURL
 *        |-- [self init]
 *        `-- [self.moviePlayer setContentURL:contentURL]
 *
 * MPMoviePlayerViewController on iOS 8 and later
 * - (id) init
 *        `-- [self initWithContentURL:nil]
 *
 * - (id) initWithContentURL:(NSURL *)contentURL
 *        |-- [super init]
 *        `-- [self.moviePlayer setContentURL:contentURL]
 */

- (instancetype) init
{
	return [self initWithVideoIdentifier:nil];
}

- (instancetype) initWithContentURL:(NSURL *)contentURL
{
	@throw [NSException exceptionWithName:NSGenericException reason:@"Use the `initWithVideoIdentifier:` method instead." userInfo:nil];
}

- (instancetype) initWithVideoIdentifier:(NSString *)videoIdentifier
{
	if ([[[UIDevice currentDevice] systemVersion] integerValue] >= 8)
		self = [super init];
	else
		self = [super init];
	
	if (!self)
		return nil;
	
	// See https://github.com/0xced/XCDYouTubeKit/commit/cadec1c3857d6a302f71b9ce7d1ae48e389e6890
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
	self.shouldAutoPlay = YES;
	if(!self.player){
		self.player = [AVPlayer new];
	}
		[self.player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];

	if (videoIdentifier)
		self.videoIdentifier = videoIdentifier;
	
	return self;
}

#pragma mark - Public

- (NSArray *) preferredVideoQualities
{
	if (!_preferredVideoQualities)
		_preferredVideoQualities = @[ XCDYouTubeVideoQualityHTTPLiveStreaming, @(XCDYouTubeVideoQualityHD720), @(XCDYouTubeVideoQualityMedium360), @(XCDYouTubeVideoQualitySmall240) ];
	
	return _preferredVideoQualities;
}

- (void) setVideoIdentifier:(NSString *)videoIdentifier
{
	if ([videoIdentifier isEqual:self.videoIdentifier])
		return;
	
	_videoIdentifier = [videoIdentifier copy];
	
	[self.videoOperation cancel];
	self.videoOperation = [[XCDYouTubeClient defaultClient] getVideoWithIdentifier:videoIdentifier completionHandler:^(XCDYouTubeVideo *video, NSError *error)
	{
		if (video)
		{
			NSURL *streamURL = nil;
			for (NSNumber *videoQuality in self.preferredVideoQualities)
			{
				streamURL = video.streamURLs[videoQuality];
				if (streamURL)
				{
					[self startVideo:video streamURL:streamURL];
					break;
				}
			}
			
			if (!streamURL)
			{
				NSError *noStreamError = [NSError errorWithDomain:XCDYouTubeVideoErrorDomain code:XCDYouTubeErrorNoStreamAvailable userInfo:nil];
				[self stopWithError:noStreamError];
			}
		}
		else
		{
			[self stopWithError:error];
		}
	}];
}

- (void) presentInView:(UIView *)view
{
	static const void * const XCDYouTubeVideoPlayerViewControllerKey = &XCDYouTubeVideoPlayerViewControllerKey;
	
	self.embedded = YES;
	
	self.view.frame = CGRectMake(0.f, 0.f, view.bounds.size.width, view.bounds.size.height);
	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	if (![view.subviews containsObject:self.view])
		[view addSubview:self.view];
	objc_setAssociatedObject(view, XCDYouTubeVideoPlayerViewControllerKey, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Private

- (void) startVideo:(XCDYouTubeVideo *)video streamURL:(NSURL *)streamURL
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	NSMutableDictionary *userInfo = [NSMutableDictionary new];
	if (video.title)
		userInfo[XCDMetadataKeyTitle] = video.title;
	if (video.smallThumbnailURL)
		userInfo[XCDMetadataKeySmallThumbnailURL] = video.smallThumbnailURL;
	if (video.mediumThumbnailURL)
		userInfo[XCDMetadataKeyMediumThumbnailURL] = video.mediumThumbnailURL;
	if (video.largeThumbnailURL)
		userInfo[XCDMetadataKeyLargeThumbnailURL] = video.largeThumbnailURL;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XCDYouTubeVideoPlayerViewControllerDidReceiveMetadataNotification object:self userInfo:userInfo];
#pragma clang diagnostic pop
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XCDYouTubeVideoPlayerViewControllerDidReceiveVideoNotification object:self userInfo:@{ XCDYouTubeVideoUserInfoKey: video }];
	[self.player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:streamURL]];
	
	if (streamURL) {
		[[NSNotificationCenter defaultCenter] postNotificationName:	MPMoviePlayerNowPlayingMovieDidChangeNotification object:self.player userInfo:userInfo];
	}
	[[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(playerItemDidReachEnd:)
												 name: AVPlayerItemDidPlayToEndTimeNotification
											   object: [self.player currentItem]];
}

- (void) playerItemDidReachEnd:(NSNotification *)notification{
	NSDictionary *userInfo = @{ MPMoviePlayerPlaybackDidFinishReasonUserInfoKey: @(MPMovieFinishReasonPlaybackEnded)};
	[[NSNotificationCenter defaultCenter] postNotificationName:MPMoviePlayerPlaybackDidFinishNotification object:self.player userInfo:userInfo];
}

- (void) stopWithError:(NSError *)error
{
	NSDictionary *userInfo = @{ MPMoviePlayerPlaybackDidFinishReasonUserInfoKey: @(MPMovieFinishReasonPlaybackError),
	                            XCDMoviePlayerPlaybackDidFinishErrorUserInfoKey: error };
	[[NSNotificationCenter defaultCenter] postNotificationName:MPMoviePlayerPlaybackDidFinishNotification object:self.player userInfo:userInfo];
	
	if (self.isEmbedded)
		[self.view removeFromSuperview];
	else
		[self.presentingViewController dismissMoviePlayerViewControllerAnimated];
}

#pragma mark - UIViewController

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	if (![self isBeingPresented])
		return;
	
	[self.player play];
}

- (void) viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	if (![self isBeingDismissed])
		return;
	
	[self.videoOperation cancel];
}

#pragma mark Observer 
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	if([keyPath isEqualToString:@"status"]){
		NSNumber *newValue = [change valueForKey:NSKeyValueChangeNewKey];
		if (newValue && newValue.intValue == 1)
		{
			if ((self.player.rate == 0.0)  && self.shouldAutoPlay) {
				[self.player play];
			}
		}
	}
}
@end
