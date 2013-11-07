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

    // Check for Open Graph Metadata first
    NSArray *metaElements = [MTDHTMLElement nodesForXPathQuery:@"//html/head/meta" onHTML:data];
    for (MTDHTMLElement *metaElement in metaElements) {
        NSString *property = [metaElement attributeWithName:@"property"];

        if ([property isEqualToString:@"og:title"]) {
            title = [metaElement attributeWithName:@"content"];
        } else if ([property isEqualToString:@"og:image"]) {
            NSString *imageAddress = [metaElement attributeWithName:@"content"];
            imageURL = [self sanitizedImageURLWithBaseURL:URL imageAddress:imageAddress];
        } else if ([property isEqualToString:@"og:description"]) {
            content = [metaElement attributeWithName:@"content"];
        }
    }

    if (title == nil) {
        MTDHTMLElement *titleElement = [MTDHTMLElement nodeForXPathQuery:@"//html/head/title" onHTML:data];
        title = titleElement.contentString;
    }

    if (imageURL == nil) {
        NSArray *imageElements = [MTDHTMLElement nodesForXPathQuery:@"//img" onHTML:data];
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"MTDURLPreview" ofType:@"bundle"];
        NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
        NSString *suffix = [UIScreen mainScreen].scale > 1.f ? @"@2x" : @"";

        // special cases
        if ([domain rangeOfString:@"imgur"].location != NSNotFound) {
            imageURL = [bundle URLForResource:[@"imgur-placeholder" stringByAppendingString:suffix] withExtension:@"jpg"];
        } else if ([domain rangeOfString:@"reddit"].location != NSNotFound) {
            imageURL = [bundle URLForResource:[@"reddit-placeholder" stringByAppendingString:suffix] withExtension:@"png"];
        }

        if (imageURL == nil) {
            // heuristic: give higher priority to jpg images
            for (MTDHTMLElement *element in imageElements) {
                NSString *imageAddress = [element attributeWithName:@"src"];
                NSString *lowercaseAddress = [imageAddress lowercaseString];

                if ([lowercaseAddress hasSuffix:@"jpg"] || [lowercaseAddress hasSuffix:@"jpeg"]) {
                    imageURL = [self sanitizedImageURLWithBaseURL:URL imageAddress:imageAddress];
                    break;
                }
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
    }

    if (content == nil) {
        MTDHTMLElement *firstPElement = [MTDHTMLElement nodeForXPathQuery:@"//p" onHTML:data];
        content = firstPElement.contentStringByUnifyingSubnodes;
    }

    return [[MTDURLPreview alloc] initWithTitle:title
                                         domain:domain
                                       imageURL:imageURL
                                        content:content];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Private
////////////////////////////////////////////////////////////////////////

+ (NSURL *)sanitizedImageURLWithBaseURL:(NSURL *)URL imageAddress:(NSString *)imageAddress {
    if (imageAddress == nil) {
        return nil;
    } else if ([imageAddress hasPrefix:@"//"]) {
        imageAddress = [imageAddress substringFromIndex:2];
    } else if ([imageAddress hasPrefix:@"/"]) {
        imageAddress = [[@"http://" stringByAppendingString:URL.host] stringByAppendingString:imageAddress];
    }
    
    return [NSURL URLWithString:imageAddress];
}

@end
