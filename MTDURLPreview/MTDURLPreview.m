#import "MTDURLPreview.h"
#import "MTDURLPreviewParser.h"
#import "MTDURLPreviewCache.h"


static NSMutableSet *canceledURLs = nil;
static dispatch_queue_t mtd_url_preview_queue() {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("at.myell0w.url-preview-queue", DISPATCH_QUEUE_CONCURRENT);
    });

    return queue;
}

static MTDURLPreviewCache* mtd_preview_cache() {
    static MTDURLPreviewCache *cache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [MTDURLPreviewCache new];
        canceledURLs = [NSMutableSet new];
    });

    return cache;
}


@implementation MTDURLPreview

////////////////////////////////////////////////////////////////////////
#pragma mark - Lifecycle
////////////////////////////////////////////////////////////////////////

- (instancetype)initWithTitle:(NSString *)title
                       domain:(NSString *)domain
                     imageURL:(NSURL *)imageURL
                      content:(NSString *)content {
    if ((self = [super init])) {
        _title = [title copy];
        _domain = [domain copy];
        _imageURL = imageURL;
        _content = [content copy];
    }

    return self;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Class Methods
////////////////////////////////////////////////////////////////////////

+ (void)loadPreviewWithURL:(NSURL *)URL completion:(mtd_url_preview_block)completion {
    NSParameterAssert(URL != nil);
    NSParameterAssert(completion != nil);

    if (URL == nil || completion == nil) {
        return;
    }

    MTDURLPreview *cachedPreview = [mtd_preview_cache() cachedPreviewForURL:URL];

    if (cachedPreview != nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(cachedPreview, nil);
        });
    } else {
        [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:URL] queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *responseData, NSError *error) {
            dispatch_async(mtd_url_preview_queue(), ^{
                if (responseData != nil) {
                    MTDURLPreview *preview = [MTDURLPreviewParser previewFromHTMLData:responseData URL:URL];

                    [mtd_preview_cache() cachePreview:preview forURL:URL];

                    if (![canceledURLs containsObject:URL]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completion(preview, nil);
                        });
                    }
                } else {
                    if (![canceledURLs containsObject:URL]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completion(nil, error);
                        });
                    }
                }

                [canceledURLs removeObject:URL];
            });
        }];
    }
}

+ (void)cancelLoadOfPreviewWithURL:(NSURL *)URL {
    if (URL != nil) {
        [canceledURLs addObject:URL];
    }
}

@end
