#import <Cocoa/Cocoa.h>

@class MNXAppConfig;

MNXAppConfig *AppConfig(void);

@interface MNXAppConfig : NSObject
{

}
+ (MNXAppConfig *)sharedConfig;

@property (retain, nonatomic) NSString *deviceTimeZoneName;

@end