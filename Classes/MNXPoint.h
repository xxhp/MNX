#import <Foundation/Foundation.h>

@interface MNXPoint : NSObject
{
	CGFloat longitude;
	CGFloat latitude;
	NSDate *date;
	CGFloat speed;
	CGFloat elevation;
}

- (NSDictionary *)dictionary;

@property (assign, nonatomic) CGFloat longitude;
@property (assign, nonatomic) CGFloat latitude;
@property (retain, nonatomic) NSDate *date;
@property (assign, nonatomic) CGFloat speed;
@property (assign, nonatomic) CGFloat elevation;

@end
