#import "MNXAppConfig.h"

static MNXAppConfig *sharedConfig;

static NSString *const kMNXDeviceTimeZoneName = @"kMNXDeviceTimeZoneName";

@implementation MNXAppConfig

+ (MNXAppConfig *)sharedConfig
{
	if (!sharedConfig) {
		sharedConfig = [[MNXAppConfig alloc] init];
	}
	return sharedConfig;
}

- (id) init
{
	self = [super init];
	if (self != nil) {
		if (![[NSUserDefaults standardUserDefaults] objectForKey:kMNXDeviceTimeZoneName]) {
			[self setDeviceTimeZoneName:@""];
		}
	}
	return self;
}

- (void)setDeviceTimeZoneName:(NSString *)inAbbr
{
	[[NSUserDefaults standardUserDefaults] setObject:inAbbr forKey:kMNXDeviceTimeZoneName];
	[[NSUserDefaults standardUserDefaults] synchronize];
}
- (NSString *)deviceTimeZoneName
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:kMNXDeviceTimeZoneName];
}

@end

MNXAppConfig *AppConfig()
{
	return [MNXAppConfig sharedConfig];
}
