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
        UIColor *textColor = [UIColor colorWithRed:62.f/255.f green:66.f/255.f blue:81.f/255.f alpha:1.f];

        _titleLabel = [self labelWithFont:titleFont
                                textColor:textColor
                            numberOfLines:0
                            lineBreakMode:kMTDTitleLineBreakMode];
        [self addSubview:_titleLabel];

        _domainLabel = [self labelWithFont:domainFont
                                 textColor:textColor
                             numberOfLines:1
                             lineBreakMode:NSLineBreakByTruncatingTail];
        [self addSubview:_domainLabel];

        self.backgroundColor = [UIColor colorWithRed:246.f/255.f green:246.f/255.f blue:246.f/255.f alpha:1.f];
        self.layer.borderWidth = 1.f;
        self.layer.borderColor = [UIColor colorWithRed:209.f/255.f green:209.f/255.f blue:209.f/255.f alpha:1.f].CGColor;
    }
    
    return self;
}

- (void)dealloc {
    // Support for SDWebImage
    if ([_imageView respondsToSelector:@selector(cancelCurrentImageLoad)]) {
        (void)objc_msgSend(_imageView, @selector(cancelCurrentImageLoad));
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
    CGFloat domainHeight = domainFont.lineHeight;
    CGFloat maxTitleHeight = titleFont.lineHeight * 3;
    CGSize constraint = CGSizeMake(textWidth, maxTitleHeight);
    CGSize sizeTitle = [title sizeWithFont:titleFont constrainedToSize:constraint lineBreakMode:kMTDTitleLineBreakMode];

    return MAX(minHeight, kMTDPadding + sizeTitle.height + domainHeight + kMTDPadding);
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
                         imageVisible:preview.imageURL != nil
                   constrainedToWidth:width];
}

- (void)setFromURLPreview:(MTDURLPreview *)preview {
    self.titleLabel.text = preview.title;
    self.domainLabel.text = preview.domain;
    self.contentLabel.text = preview.content;

    if (preview.imageURL != nil) {
        UIImage *placeholderImage = [UIImage imageNamed:@"MTDURLPreview.bundle/image-placeholder"];
        
        // Support for SDWebImage
        if ([self.imageView respondsToSelector:@selector(setImageWithURL:placeholderImage:)]) {
            (void)objc_msgSend(self.imageView, @selector(setImageWithURL:placeholderImage:), preview.imageURL, placeholderImage);
        } else {
            self.imageView.image = placeholderImage;
        }
    }

    [self sizeToFit];
    [self setNeedsLayout];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Private
////////////////////////////////////////////////////////////////////////

- (UIImageView *)imageView {
    if (_imageView == nil) {
        _imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MTDURLPreview.bundle/image-placeholder"]];
        _imageView.backgroundColor = [UIColor colorWithRed:209.f/255.f green:209.f/255.f blue:209.f/255.f alpha:1.f];
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
    CGFloat domainHeight = self.domainLabel.font.lineHeight;
    CGFloat maxTitleHeight = self.titleLabel.font.lineHeight * 3;
    CGSize constraint = CGSizeMake(textWidth, maxTitleHeight);
    CGSize sizeTitle = [self.titleLabel.text sizeWithFont:self.titleLabel.font constrainedToSize:constraint lineBreakMode:self.titleLabel.lineBreakMode];

    if (shouldLayout) {
        _imageView.frame = CGRectMake(kMTDPadding, kMTDPadding + 3.f, kMTDImageDimension, kMTDImageDimension);
        self.titleLabel.frame = CGRectMake(textX, kMTDPadding, textWidth, sizeTitle.height);
        self.domainLabel.frame = CGRectMake(textX, CGRectGetMaxY(self.titleLabel.frame), textWidth, domainHeight);
    }

    return CGSizeMake(size.width, MAX(minHeight, kMTDPadding + sizeTitle.height + domainHeight + kMTDPadding));
}

@end
