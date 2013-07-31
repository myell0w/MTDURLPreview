#import "MTDURLPreviewCache.h"


static inline NSString* MTDCacheKeyFromURL(NSURL *URL) {
    return URL.absoluteString;
}


@implementation MTDURLPreviewCache

- (instancetype)init {
    if ((self = [super init])) {
        self.name = @"MTDURLPreviewCache";
    }

    return self;
}

- (MTDURLPreview *)cachedPreviewForURL:(NSURL *)URL {
    NSString *key = MTDCacheKeyFromURL(URL);
    return [self objectForKey:key];
}

- (void)cachePreview:(MTDURLPreview *)preview forURL:(NSURL *)URL {
    if (preview != nil && URL != nil) {
        NSString *key = MTDCacheKeyFromURL(URL);
        [self setObject:preview forKey:key];
    }
}

@end
