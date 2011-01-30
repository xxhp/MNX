#import <Foundation/Foundation.h>

@interface MNXPoint : NSObject
{
	CGFloat longitude;
	CGFloat latitude;
	NSDate *date;
	CGFloat speed;
	CGFloat elevation;

	CGFloat speedKM;
	CGFloat speedMile;
	CGFloat distanceKM;
	CGFloat distanceMile;
}

+ (MNXPoint *)pointWithDictionary:(NSDictionary *)inDictionary;
- (NSDictionary *)dictionary;

@property (assign, nonatomic) CGFloat longitude;
@property (assign, nonatomic) CGFloat latitude;
@property (retain, nonatomic) NSDate *date;
@property (assign, nonatomic) CGFloat speed;
@property (assign, nonatomic) CGFloat elevation;

@property (assign, nonatomic) CGFloat speedKM;
@property (assign, nonatomic) CGFloat speedMile;
@property (assign, nonatomic) CGFloat distanceKM;
@property (assign, nonatomic) CGFloat distanceMile;


@end
