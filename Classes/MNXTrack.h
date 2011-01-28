#import <Foundation/Foundation.h>

@interface MNXTrack : NSObject
{
	NSMutableArray *pointArray;
	NSMutableArray *splitKM;
	NSMutableArray *splitMile;

	NSTimeInterval duration;
	
	CGFloat totalDistanceKM;
	CGFloat averagePaceKM;
	CGFloat averageSpeedKM;
	CGFloat maxSpeedKM;

	CGFloat totalDistanceMile;
	CGFloat averagePaceMile;
	CGFloat averageSpeedMile;
	CGFloat maxSpeedMile;	
}

- (NSString *)title;
- (NSData *)GPXData;
- (NSData *)KMLData;
- (NSData *)TCXData;
- (NSString *)HTML;

@property (readonly, nonatomic) NSString *title;
@property (retain, nonatomic) NSArray *points;
@property (readonly, nonatomic) NSArray *splitKM;
@property (readonly, nonatomic) NSArray *splitMile;

@property (readonly, nonatomic) NSTimeInterval duration;

@property (readonly, nonatomic) CGFloat totalDistanceKM;
@property (readonly, nonatomic) NSTimeInterval averagePaceKM;
@property (readonly, nonatomic) CGFloat averageSpeedKM;
@property (readonly, nonatomic) CGFloat maxSpeedKM;

@property (readonly, nonatomic) CGFloat totalDistanceMile;
@property (readonly, nonatomic) NSTimeInterval averagePaceMile;
@property (readonly, nonatomic) CGFloat averageSpeedMile;
@property (readonly, nonatomic) CGFloat maxSpeedMile;


@end
