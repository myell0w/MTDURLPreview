//
//  MTDURLPreviewView.h
//  MTDURLPreview
//
//  Created by Matthias Tretter on 09.07.13.
//  Copyright (c) 2013 @myell0w. All rights reserved.
//


@class MTDURLPreview;


@interface MTDURLPreviewView : UIView

+ (CGFloat)neededHeightForTitle:(NSString *)title
                         domain:(NSString *)domain
                        content:(NSString *)content
                   imageVisible:(BOOL)imageVisible
             constrainedToWidth:(CGFloat)width;

+ (void)setTitleFont:(UIFont *)titleFont;
+ (void)setDomainFont:(UIFont *)domainFont;

@property (nonatomic, readonly) UILabel *titleLabel;
@property (nonatomic, readonly) UILabel *domainLabel;
@property (nonatomic, readonly) UILabel *contentLabel;
@property (nonatomic, readonly) UIImageView *imageView;

@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIColor *borderColor;

@end


@interface MTDURLPreviewView (MTDModelObject)

+ (CGFloat)neededHeightForURLPreview:(MTDURLPreview *)preview
                  constrainedToWidth:(CGFloat)width;

- (void)setFromURLPreview:(MTDURLPreview *)preview;

@end
