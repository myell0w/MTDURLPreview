#import "MTDURLPreviewParser.h"
#import "MTDHTMLElement.h"



static BOOL MTDStringHasImageExtension(NSString *string) {
    static NSSet *imageExtensions = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imageExtensions = [NSSet setWithObjects:@"tiff", @"tif", @"jpg", @"jpeg", @"png", @"bmp", @"bmpf", @"ico", nil];
    });


    NSString *extension = [string.pathExtension lowercaseString];
    NSRange parameterRange = [extension rangeOfString:@"?"];

    if (parameterRange.location != NSNotFound) {
        extension = [extension substringToIndex:parameterRange.location];
    }

    return [imageExtensions containsObject:extension];
}


@implementation MTDURLPreviewParser

+ (MTDURLPreview *)previewFromHTMLData:(NSData *)data URL:(NSURL *)URL {
    NSString *title = nil;
    NSString *domain = [URL host];
    NSURL *imageURL = nil;
    NSString *content = nil;

    MTDHTMLElement *titleElement = [MTDHTMLElement nodeForXPathQuery:@"//html/head/title" onHTML:data];
    title = titleElement.contentString;

    NSArray *imageElements = [MTDHTMLElement nodesForXPathQuery:@"//img" onHTML:data];

    // heuristic: give higher priority to jpg images
    for (MTDHTMLElement *element in imageElements) {
        NSString *imageAddress = [element attributeWithName:@"src"];
        NSString *lowercaseAddress = [imageAddress lowercaseString];

        if ([lowercaseAddress hasSuffix:@"jpg"] || [lowercaseAddress hasSuffix:@"jpeg"]) {
            imageURL = [self sanitizedImageURLWithBaseURL:URL imageAddress:imageAddress];
            break;
        }
    }

    if (imageURL == nil) {
        for (MTDHTMLElement *element in imageElements) {
            NSString *imageAddress = [element attributeWithName:@"src"];

            if (MTDStringHasImageExtension(imageAddress)) {
                imageURL = [self sanitizedImageURLWithBaseURL:URL imageAddress:imageAddress];
                break;
            }
        }
    }

    MTDHTMLElement *firstPElement = [MTDHTMLElement nodeForXPathQuery:@"//p" onHTML:data];
    content = firstPElement.contentStringByUnifyingSubnodes;

    return [[MTDURLPreview alloc] initWithTitle:title
                                         domain:domain
                                       imageURL:imageURL
                                        content:content];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Private
////////////////////////////////////////////////////////////////////////

+ (NSURL *)sanitizedImageURLWithBaseURL:(NSURL *)URL imageAddress:(NSString *)imageAddress {
    if ([imageAddress hasPrefix:@"//"]) {
        imageAddress = [imageAddress substringFromIndex:2];
    } else if ([imageAddress hasPrefix:@"/"]) {
        imageAddress = [[@"http://" stringByAppendingString:URL.host] stringByAppendingString:imageAddress];
    }

    return [NSURL URLWithString:imageAddress];
}

@end
