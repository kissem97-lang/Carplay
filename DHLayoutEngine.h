#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DHLayoutEngine : NSObject
+ (instancetype)shared;
- (CGRect)frameForScreenBounds:(CGRect)bounds;
- (CGFloat)scale;
- (CGFloat)opacity;
- (BOOL)isEnabled;
- (void)saveFrame:(CGRect)frame inScreenBounds:(CGRect)bounds;
- (void)setScale:(CGFloat)scale;
- (void)setOpacity:(CGFloat)opacity;
- (void)setEnabled:(BOOL)enabled;
@end

NS_ASSUME_NONNULL_END
