#import "DHAppLauncher.h"

@implementation DHAppLauncher

+ (NSArray<NSDictionary<NSString *,NSString *> *> *)shortcuts {
    // URL schemes are best-effort and depend on which apps are installed.
    return @[
        @{@"title": @"Apple Maps", @"url": @"maps://"},
        @{@"title": @"Google Maps", @"url": @"comgooglemaps://"},
        @{@"title": @"Waze", @"url": @"waze://"}
    ];
}

+ (void)openShortcutAtIndex:(NSUInteger)index completion:(void (^)(BOOL))completion {
    NSArray *items = [self shortcuts];
    if (index >= items.count) {
        if (completion) completion(NO);
        return;
    }
    NSURL *url = [NSURL URLWithString:items[index][@"url"]];
    if (!url) {
        if (completion) completion(NO);
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        UIApplication *app = UIApplication.sharedApplication;
        if ([app canOpenURL:url]) {
            [app openURL:url options:@{} completionHandler:^(BOOL success) {
                if (completion) completion(success);
            }];
        } else if (completion) {
            completion(NO);
        }
    });
}
@end
