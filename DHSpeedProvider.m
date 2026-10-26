#import "DHSpeedProvider.h"

@implementation DHSpeedProvider
+ (NSString *)displaySpeed {
    // iOS does not provide a universal public API for the vehicle speed
    // in every CarPlay setup. Integrate an authorized navigation/OBD source here.
    return @"-- km/h";
}
@end
