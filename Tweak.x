#import <UIKit/UIKit.h>
#import "DHLayoutEngine.h"
#import "DHSpeedProvider.h"
#import "DHAppLauncher.h"

// A retained gesture target avoids the target being deallocated after setup.
@interface DHGestureTarget : NSObject
+ (instancetype)shared;
- (void)tap:(UITapGestureRecognizer *)gesture;
- (void)pan:(UIPanGestureRecognizer *)gesture;
@end

static UIWindow *gHUDWindow;
static UILabel *gMainLabel;
static UIView *gHUDCard;
static BOOL gExpanded = NO;

@interface DHDragGesture : UIPanGestureRecognizer
@end
@implementation DHDragGesture
@end

static UIScreen *DHTargetScreen(void) {
    NSArray<UIScreen *> *screens = UIScreen.screens;
    // Prefer an external display if present. On some CarPlay builds the system
    // UI uses a scene/window arrangement that this simple selection cannot overlay.
    return screens.count > 1 ? screens.lastObject : UIScreen.mainScreen;
}

static void DHRefreshHUD(void) {
    if (!gHUDWindow || !gMainLabel) return;
    DHLayoutEngine *layout = DHLayoutEngine.shared;
    gHUDWindow.alpha = layout.opacity;
    gMainLabel.text = gExpanded
        ? [NSString stringWithFormat:@"%@\\nDriveHUD · tap for shortcuts", DHSpeedProvider.displaySpeed]
        : DHSpeedProvider.displaySpeed;
}

static void DHShowShortcuts(void) {
    if (!gHUDWindow.rootViewController) return;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"DriveHUD"
        message:@"Open a navigation app" preferredStyle:UIAlertControllerStyleActionSheet];

    NSArray *shortcuts = [DHAppLauncher shortcuts];
    [shortcuts enumerateObjectsUsingBlock:^(NSDictionary *item, NSUInteger idx, BOOL *stop) {
        [alert addAction:[UIAlertAction actionWithTitle:item[@"title"]
            style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
                [DHAppLauncher openShortcutAtIndex:idx completion:^(__unused BOOL opened) {}];
            }]];
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    UIViewController *vc = gHUDWindow.rootViewController;
    if (vc.presentedViewController) [vc.presentedViewController dismissViewControllerAnimated:NO completion:nil];
    [vc presentViewController:alert animated:YES completion:nil];
}

static void DHHandleTap(void) {
    gExpanded = !gExpanded;
    DHRefreshHUD();
    if (gExpanded) DHShowShortcuts();
}

static void DHHandlePan(UIPanGestureRecognizer *gesture) {
    if (!gHUDWindow) return;
    CGPoint delta = [gesture translationInView:gHUDWindow.superview];
    CGRect frame = gHUDWindow.frame;
    frame.origin.x += delta.x;
    frame.origin.y += delta.y;
    CGRect bounds = gHUDWindow.screen.bounds;
    frame.origin.x = MIN(MAX(frame.origin.x, 0), MAX(0, bounds.size.width - frame.size.width));
    frame.origin.y = MIN(MAX(frame.origin.y, 0), MAX(0, bounds.size.height - frame.size.height));
    gHUDWindow.frame = frame;
    [gesture setTranslation:CGPointZero inView:gHUDWindow.superview];
    if (gesture.state == UIGestureRecognizerStateEnded) {
        [DHLayoutEngine.shared saveFrame:gHUDWindow.frame inScreenBounds:bounds];
    }
}

static void DHRemoveHUD(void) {
    gHUDWindow.hidden = YES;
    gHUDWindow = nil;
    gMainLabel = nil;
    gHUDCard = nil;
}

static void DHBuildHUD(void) {
    DHLayoutEngine *layout = DHLayoutEngine.shared;
    if (!layout.isEnabled || gHUDWindow) return;

    UIScreen *screen = DHTargetScreen();
    CGRect bounds = screen.bounds;
    CGRect frame = [layout frameForScreenBounds:bounds];

    gHUDWindow = [[UIWindow alloc] initWithFrame:frame];
    gHUDWindow.screen = screen;
    gHUDWindow.windowLevel = UIWindowLevelAlert + 10;
    gHUDWindow.backgroundColor = UIColor.clearColor;
    gHUDWindow.rootViewController = [UIViewController new];
    gHUDWindow.rootViewController.view.backgroundColor = UIColor.clearColor;
    gHUDWindow.userInteractionEnabled = YES;

    gHUDCard = [[UIView alloc] initWithFrame:gHUDWindow.bounds];
    gHUDCard.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    gHUDCard.backgroundColor = [UIColor colorWithWhite:0.04 alpha:0.9];
    gHUDCard.layer.cornerRadius = 12.0;
    gHUDCard.layer.borderWidth = 1.0;
    gHUDCard.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.25].CGColor;
    [gHUDWindow.rootViewController.view addSubview:gHUDCard];

    gMainLabel = [[UILabel alloc] initWithFrame:gHUDCard.bounds];
    gMainLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    gMainLabel.textAlignment = NSTextAlignmentCenter;
    gMainLabel.numberOfLines = 2;
    gMainLabel.textColor = UIColor.whiteColor;
    gMainLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    [gHUDCard addSubview:gMainLabel];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:[DHGestureTarget shared]
        action:@selector(tap:)];
    [gHUDWindow addGestureRecognizer:tap];

    DHDragGesture *pan = [[DHDragGesture alloc] initWithTarget:[DHGestureTarget shared]
        action:@selector(pan:)];
    [gHUDWindow addGestureRecognizer:pan];
    [tap requireGestureRecognizerToFail:pan];

    gHUDWindow.hidden = NO;
    DHRefreshHUD();
}

@implementation DHGestureTarget
+ (instancetype)shared {
    static DHGestureTarget *target;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ target = [DHGestureTarget new]; });
    return target;
}
- (void)tap:(UITapGestureRecognizer *)gesture { DHHandleTap(); }
- (void)pan:(UIPanGestureRecognizer *)gesture { DHHandlePan(gesture); }
@end

%ctor {
    @autoreleasepool {
        if (![DHLayoutEngine.shared isEnabled]) return;
        dispatch_async(dispatch_get_main_queue(), ^{ DHBuildHUD(); });

        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
            object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(__unused NSNotification *note) {
                DHRemoveHUD();
                DHBuildHUD();
            }];

        [[NSNotificationCenter defaultCenter] addObserverForName:UIScreenDidConnectNotification
            object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(__unused NSNotification *note) {
                DHRemoveHUD();
                DHBuildHUD();
            }];

        [[NSNotificationCenter defaultCenter] addObserverForName:UIScreenDidDisconnectNotification
            object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(__unused NSNotification *note) {
                DHRemoveHUD();
                DHBuildHUD();
            }];
    }
}
