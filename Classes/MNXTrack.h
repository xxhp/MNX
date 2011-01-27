#import <Foundation/Foundation.h>

@interface MNXTrack : NSObject
{
	NSMutableArray *pointArray;
	NSMutableArray *splitKM;
	
	CGFloat totalDistance;
	NSTimeInterval duration;
	CGFloat averagePaceKM;
	CGFloat averageSpeedKM;
	CGFloat maxSpeedKM;
}

- (NSString *)title;
- (NSData *)GPXData;
- (NSData *)KMLData;
- (NSData *)TCXData;
- (NSString *)HTML;

@property (readonly, nonatomic) NSString *title;
@property (retain, nonatomic) NSArray *points;
@property (readonly, nonatomic) NSArray *splitKM;

@property (readonly, nonatomic) CGFloat totalDistance;
@property (readonly, nonatomic) NSTimeInterval duration;
@property (readonly, nonatomic) NSTimeInterval averagePaceKM;
@property (readonly, nonatomic) CGFloat averageSpeedKM;
@property (readonly, nonatomic) CGFloat maxSpeedKM;

@end
