#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DHAppLauncher : NSObject
+ (NSArray<NSDictionary<NSString *, NSString *> *> *)shortcuts;
+ (void)openShortcutAtIndex:(NSUInteger)index completion:(void (^)(BOOL opened))completion;
@end

NS_ASSUME_NONNULL_END
