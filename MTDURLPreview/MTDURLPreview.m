#import "MTDURLPreview.h"
#import "MTDURLPreviewParser.h"


static dispatch_queue_t mtd_url_preview_queue() {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("at.myell0w.url-preview-queue", DISPATCH_QUEUE_CONCURRENT);
    });

    return queue;
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

    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:URL] queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *responseData, NSError *error) {
        dispatch_async(mtd_url_preview_queue(), ^{
            if (responseData != nil) {
                MTDURLPreview *preview = [MTDURLPreviewParser previewFromHTMLData:responseData URL:URL];

                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(preview, nil);
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, error);
                });
            }
        });
    }];
}

@end
