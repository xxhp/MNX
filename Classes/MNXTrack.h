#import <Foundation/Foundation.h>

@interface MNXTrack : NSObject
{
	NSMutableArray *pointArray;
}

- (NSString *)title;
- (NSData *)GPXData;
- (NSString *)HTML;

@property (readonly, nonatomic) NSString *title;
@property (retain, nonatomic) NSArray *points;

@end
