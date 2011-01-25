#import <Foundation/Foundation.h>

@interface MNXTrack : NSObject
{
	NSMutableArray *pointArray;
	CGFloat totalDistance;
	NSTimeInterval duration;
	CGFloat averagePaceKM;
	CGFloat averageSpeedKM;
}

- (NSString *)title;
- (NSData *)GPXData;
- (NSData *)KMLData;
- (NSString *)HTML;

@property (readonly, nonatomic) NSString *title;
@property (retain, nonatomic) NSArray *points;

@property (assign, nonatomic) CGFloat totalDistance;
@property (assign, nonatomic) NSTimeInterval duration;
@property (assign, nonatomic) NSTimeInterval averagePaceKM;
@property (assign, nonatomic) CGFloat averageSpeedKM;

@end
