//
//  MTDURLPreviewParser.h
//  MTDURLPreview
//
//  Created by Matthias Tretter on 09.07.13.
//  Copyright (c) 2013 @myell0w. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTDURLPreview.h"


@interface MTDURLPreviewParser : NSObject

+ (MTDURLPreview *)previewFromHTMLData:(NSData *)data URL:(NSURL *)URL;

@end
