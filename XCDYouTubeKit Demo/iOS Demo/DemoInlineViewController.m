//
//  Copyright (c) 2013-2015 Cédric Luthi. All rights reserved.
//

#import "DemoInlineViewController.h"

#import <XCDYouTubeKit/XCDYouTubeKit.h>

#import "MPMoviePlayerController+BackgroundPlayback.h"

@interface DemoInlineViewController ()

@property (nonatomic, strong) XCDYouTubeVideoPlayerViewController *videoPlayerViewController;

@end

@implementation DemoInlineViewController

- (void) viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	// Beware, viewWillDisappear: is called when the player view enters full screen on iOS 6+
	if ([self isMovingFromParentViewController])
		[self.videoPlayerViewController.player pause];
}

- (IBAction) load:(id)sender
{
	[self.videoContainerView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	
	NSString *videoIdentifier = [[NSUserDefaults standardUserDefaults] objectForKey:@"VideoIdentifier"];
	self.videoPlayerViewController = [[XCDYouTubeVideoPlayerViewController alloc] initWithVideoIdentifier:videoIdentifier];
	self.videoPlayerViewController.backgroundPlaybackEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"PlayVideoInBackground"];
	[self.videoPlayerViewController presentInView:self.videoContainerView];
	
	if (self.shouldAutoplaySwitch.on)
		self.videoPlayerViewController.shouldAutoPlay = YES;
}

- (IBAction) prepareToPlay:(UISwitch *)sender
{
}

@end
