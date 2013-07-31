//
//  MTDURLPreviewCache.h
//  MTDURLPreview
//
//  Created by Matthias Tretter on 31.07.13.
//  Copyright (c) 2013 @myell0w. All rights reserved.
//

#import <Foundation/Foundation.h>


@class MTDURLPreview;


@interface MTDURLPreviewCache : NSCache

- (MTDURLPreview *)cachedPreviewForURL:(NSURL *)URL;
- (void)cachePreview:(MTDURLPreview *)preview forURL:(NSURL *)URL;

@end
