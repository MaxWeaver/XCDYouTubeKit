//
//  AVPlayerViewController+Migration.h
//  XCDYouTubeKit
//
//  Created by Dzmitry Artsiomchik on 10/30/15.
//  Copyright © 2015 Cédric Luthi. All rights reserved.
//

#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

@class AVPlayer;
@interface AVPlayerViewController (Migration)

- (instancetype)initWithContentURL:(NSURL *)url;
@end
