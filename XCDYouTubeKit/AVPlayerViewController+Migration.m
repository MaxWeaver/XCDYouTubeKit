//
//  AVPlayerViewController+Migration.m
//  XCDYouTubeKit
//
//  Created by Dzmitry Artsiomchik on 10/30/15.
//  Copyright © 2015 Cédric Luthi. All rights reserved.
//

#import "AVPlayerViewController+Migration.h"

@implementation AVPlayerViewController (Migration)

- (instancetype)initWithContentURL:(NSURL *)url{
	AVPlayerViewController * controller = [AVPlayerViewController new];
	controller.player = [AVPlayer playerWithURL:url];
	return controller;
}

@end
