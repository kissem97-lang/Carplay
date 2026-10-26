#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Interface boundary for a future authorized speed source.
/// This prototype intentionally reports unavailable rather than inventing speed.
@interface DHSpeedProvider : NSObject
+ (NSString *)displaySpeed;
@end

NS_ASSUME_NONNULL_END
