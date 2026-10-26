#import "DHLayoutEngine.h"

static NSString * const kDomain = @"com.drivehud.tweak";

@implementation DHLayoutEngine

+ (instancetype)shared {
    static DHLayoutEngine *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [DHLayoutEngine new]; });
    return instance;
}

- (id)valueForKey:(NSString *)key fallback:(id)fallback {
    id value = CFBridgingRelease(CFPreferencesCopyAppValue((__bridge CFStringRef)key,
                                                           (__bridge CFStringRef)kDomain));
    return value ?: fallback;
}

- (CGFloat)scale {
    return MIN(MAX([[self valueForKey:@"scale" fallback:@1.0] doubleValue], 0.65), 1.8);
}

- (CGFloat)opacity {
    return MIN(MAX([[self valueForKey:@"opacity" fallback:@0.82] doubleValue], 0.2), 1.0);
}

- (BOOL)isEnabled {
    return [[self valueForKey:@"enabled" fallback:@YES] boolValue];
}

- (CGRect)frameForScreenBounds:(CGRect)bounds {
    CGFloat scale = self.scale;
    CGFloat width = 150.0 * scale;
    CGFloat height = 58.0 * scale;
    CGFloat nx = MIN(MAX([[self valueForKey:@"x" fallback:@0.78] doubleValue], 0.0), 1.0);
    CGFloat ny = MIN(MAX([[self valueForKey:@"y" fallback:@0.08] doubleValue], 0.0), 1.0);
    CGFloat x = (bounds.size.width - width) * nx;
    CGFloat y = (bounds.size.height - height) * ny;
    x = MIN(MAX(x, 0.0), MAX(0.0, bounds.size.width - width));
    y = MIN(MAX(y, 0.0), MAX(0.0, bounds.size.height - height));
    return CGRectMake(x, y, width, height);
}

- (void)write:(id)value key:(NSString *)key {
    CFPreferencesSetAppValue((__bridge CFStringRef)key, (__bridge CFPropertyListRef)value,
                             (__bridge CFStringRef)kDomain);
    CFPreferencesAppSynchronize((__bridge CFStringRef)kDomain);
}

- (void)saveFrame:(CGRect)frame inScreenBounds:(CGRect)bounds {
    CGFloat nx = bounds.size.width > frame.size.width
        ? frame.origin.x / (bounds.size.width - frame.size.width) : 0.5;
    CGFloat ny = bounds.size.height > frame.size.height
        ? frame.origin.y / (bounds.size.height - frame.size.height) : 0.5;
    [self write:@(MIN(MAX(nx, 0.0), 1.0)) key:@"x"];
    [self write:@(MIN(MAX(ny, 0.0), 1.0)) key:@"y"];
}

- (void)setScale:(CGFloat)scale {
    [self write:@(MIN(MAX(scale, 0.65), 1.8)) key:@"scale"];
}

- (void)setOpacity:(CGFloat)opacity {
    [self write:@(MIN(MAX(opacity, 0.2), 1.0)) key:@"opacity"];
}

- (void)setEnabled:(BOOL)enabled {
    [self write:@(enabled) key:@"enabled"];
}
@end
