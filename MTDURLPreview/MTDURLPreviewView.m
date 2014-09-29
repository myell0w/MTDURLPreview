#import "MTDURLPreviewView.h"
#import "MTDURLPreview.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/message.h>


#define kMTDPadding                 10.f
#define kMTDImageDimension          60.f
#define kMTDTitleLineBreakMode      NSLineBreakByTruncatingTail | NSLineBreakByWordWrapping


static UIFont *titleFont = nil;
static UIFont *domainFont = nil;


@implementation MTDURLPreviewView

@synthesize imageView = _imageView;

////////////////////////////////////////////////////////////////////////
#pragma mark - Lifecycle
////////////////////////////////////////////////////////////////////////

+ (void)initialize {
    if (self == [MTDURLPreviewView class]) {
        titleFont = [UIFont boldSystemFontOfSize:16.f];
        domainFont = [UIFont systemFontOfSize:15.f];
    }
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:246.f/255.f green:246.f/255.f blue:246.f/255.f alpha:1.f];
        _textColor = [UIColor colorWithRed:62.f/255.f green:66.f/255.f blue:81.f/255.f alpha:1.f];
        _borderColor = [UIColor colorWithRed:209.f/255.f green:209.f/255.f blue:209.f/255.f alpha:1.f];

        _titleLabel = [self labelWithFont:titleFont
                                textColor:_textColor
                            numberOfLines:0
                            lineBreakMode:kMTDTitleLineBreakMode];
        [self addSubview:_titleLabel];

        _domainLabel = [self labelWithFont:domainFont
                                 textColor:_textColor
                             numberOfLines:1
                             lineBreakMode:NSLineBreakByTruncatingTail];
        [self addSubview:_domainLabel];


        self.layer.borderWidth = 1.f / [UIScreen mainScreen].scale;
        self.layer.borderColor = _borderColor.CGColor;
    }
    
    return self;
}

- (void)dealloc {
    // Support for SDWebImage
    if ([_imageView respondsToSelector:@selector(sd_cancelCurrentImageLoad)]) {
        [_imageView performSelector:@selector(sd_cancelCurrentImageLoad)];
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Class Methods
////////////////////////////////////////////////////////////////////////

+ (CGFloat)neededHeightForTitle:(NSString *)title
                         domain:(NSString *)domain
                        content:(NSString *)content
                   imageVisible:(BOOL)imageVisible
             constrainedToWidth:(CGFloat)width {

    CGFloat textX = kMTDPadding;
    CGFloat minHeight = 0.f;

    if (imageVisible) {
        textX = kMTDPadding + kMTDImageDimension + kMTDPadding;
        minHeight = kMTDPadding + 3.f + kMTDImageDimension + kMTDPadding;
    }

    CGFloat textWidth = width - textX - kMTDPadding;
    CGFloat domainHeight = ceil(domainFont.lineHeight);
    CGFloat maxTitleHeight = titleFont.lineHeight * 3.f;
    CGSize constraint = CGSizeMake(textWidth, maxTitleHeight);
    CGSize sizeTitle = [title sizeWithFont:titleFont constrainedToSize:constraint lineBreakMode:kMTDTitleLineBreakMode];

    return MAX(minHeight, kMTDPadding + ceil(sizeTitle.height) + domainHeight + kMTDPadding);
}

+ (void)setTitleFont:(UIFont *)titleFont {
    titleFont = titleFont;
}

+ (void)setDomainFont:(UIFont *)domainFont {
    domainFont = domainFont;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - UIView
////////////////////////////////////////////////////////////////////////

- (CGSize)sizeThatFits:(CGSize)size {
    return [self sizeOfContentsWithSize:size shouldLayout:NO];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    [self sizeOfContentsWithSize:self.bounds.size shouldLayout:YES];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];

    self.titleLabel.backgroundColor = backgroundColor;
    self.domainLabel.backgroundColor = backgroundColor;
    self.contentLabel.backgroundColor = backgroundColor;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - MTDURLPreviewView+MTDModelObject
////////////////////////////////////////////////////////////////////////

+ (CGFloat)neededHeightForURLPreview:(MTDURLPreview *)preview constrainedToWidth:(CGFloat)width {
    return [self neededHeightForTitle:preview.title
                               domain:preview.domain
                              content:preview.content
                         imageVisible:YES
                   constrainedToWidth:width];
}

- (void)setFromURLPreview:(MTDURLPreview *)preview {
    self.titleLabel.text = preview.title;
    self.domainLabel.text = preview.domain;
    self.contentLabel.text = preview.content;

    UIImage *placeholderImage = [UIImage imageNamed:@"MTDURLPreview.bundle/image-placeholder"];
    self.imageView.image = placeholderImage;
    if (preview.imageURL != nil) {
        // Support for SDWebImage
        if ([self.imageView respondsToSelector:@selector(sd_setImageWithURL:placeholderImage:)]) {
            [self.imageView performSelector:@selector(sd_setImageWithURL:placeholderImage:) withObject:preview.imageURL withObject:placeholderImage];
        }
    }

    [self sizeToFit];
    [self setNeedsLayout];
}

- (void)setTextColor:(UIColor *)textColor {
    if (textColor != _textColor) {
        _textColor = textColor;
        self.titleLabel.textColor = textColor;
        self.domainLabel.textColor = textColor;
        self.contentLabel.textColor = textColor;
    }
}

- (void)setBorderColor:(UIColor *)borderColor {
    if (borderColor != _borderColor) {
        _borderColor = borderColor;
        self.layer.borderColor = _borderColor.CGColor;
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Private
////////////////////////////////////////////////////////////////////////

- (UIImageView *)imageView {
    if (_imageView == nil) {
        _imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MTDURLPreview.bundle/image-placeholder"]];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        [self addSubview:_imageView];
    }

    return _imageView;
}

- (id)labelWithFont:(UIFont *)font
          textColor:(UIColor *)textColor
      numberOfLines:(NSUInteger)numberOfLines
      lineBreakMode:(NSLineBreakMode)lineBreakMode {
    UILabel *label =  [[UILabel alloc] initWithFrame:CGRectZero];

    label.opaque = YES;
    label.font = font;
    label.textColor = textColor;
    label.highlightedTextColor = textColor;
    label.lineBreakMode = lineBreakMode;
    label.numberOfLines = numberOfLines;

    return label;
}

- (CGSize)sizeOfContentsWithSize:(CGSize)size
                    shouldLayout:(BOOL)shouldLayout {
    CGFloat textX = kMTDPadding;
    CGFloat minHeight = 0.f;

    if (_imageView != nil) {
        textX = kMTDPadding + kMTDImageDimension + kMTDPadding;
        minHeight = kMTDPadding + 3.f + kMTDImageDimension + kMTDPadding;
    }

    CGFloat textWidth = size.width - textX - kMTDPadding;
    CGFloat domainHeight = ceil(self.domainLabel.font.lineHeight);
    CGFloat maxTitleHeight = self.titleLabel.font.lineHeight * 3.f;
    CGSize constraint = CGSizeMake(textWidth, maxTitleHeight);
    CGSize sizeTitle = [self.titleLabel.text sizeWithFont:self.titleLabel.font constrainedToSize:constraint lineBreakMode:self.titleLabel.lineBreakMode];
    sizeTitle = CGSizeMake(ceil(sizeTitle.width), ceil(sizeTitle.height));

    if (shouldLayout) {
        _imageView.frame = CGRectMake(kMTDPadding, kMTDPadding + 3.f, kMTDImageDimension, kMTDImageDimension);
        self.titleLabel.frame = CGRectMake(textX, kMTDPadding, textWidth, sizeTitle.height);
        self.domainLabel.frame = CGRectMake(textX, CGRectGetMaxY(self.titleLabel.frame), textWidth, domainHeight);
    }

    return CGSizeMake(size.width, MAX(minHeight, kMTDPadding + sizeTitle.height + domainHeight + kMTDPadding));
}

@end
