#import "MNXPoint.h"

@implementation MNXPoint

+ (MNXPoint *)pointWithDictionary:(NSDictionary *)inDictionary
{
	MNXPoint *aPoint = [[MNXPoint alloc] init];
	aPoint.longitude = [[inDictionary valueForKey:@"longitude"] floatValue];
	aPoint.latitude = [[inDictionary valueForKey:@"latitude"] floatValue];
	aPoint.date = [inDictionary valueForKey:@"date"];
	aPoint.speed = [[inDictionary valueForKey:@"speed"] floatValue];
	aPoint.elevation = [[inDictionary valueForKey:@"elevation"] floatValue];
	[aPoint autorelease];
	return aPoint;
}

- (void)dealloc
{
	[date release];
	[super dealloc];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%p longitude:%f, latitude:%f, date:%@, speed:%f, elevation:%f", self, longitude, latitude, date, speed, elevation];
}

- (NSDictionary *)dictionary
{
	NSMutableDictionary *d = [NSMutableDictionary dictionary];
	[d setObject:[NSNumber numberWithFloat:longitude] forKey:@"longitude"];
	[d setObject:[NSNumber numberWithFloat:latitude] forKey:@"latitude"];
	[d setObject:date forKey:@"date"];
	[d setObject:[NSNumber numberWithFloat:speed] forKey:@"speed"];
	[d setObject:[NSNumber numberWithFloat:elevation] forKey:@"elevation"];
	return d;
}

@synthesize longitude;
@synthesize latitude;
@synthesize date;
@synthesize speed;
@synthesize elevation;

@synthesize speedKM;
@synthesize speedMile;
@synthesize distanceKM;
@synthesize distanceMile;

@end
