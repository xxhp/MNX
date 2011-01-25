#import <Foundation/Foundation.h>

@class MNXDataParser;

@protocol MNXDataParserDelegate <NSObject>

- (void)dataParserDidStartParsingData:(MNXDataParser *)inParser;
- (void)dataParser:(MNXDataParser *)inParser didFinishParsingData:(NSArray *)inTracks;
- (void)dataParserCancelled:(MNXDataParser *)inParser;

@end

@interface MNXDataParser : NSObject
{
	id <MNXDataParserDelegate> delegate;
	NSCalendar *calendar;
}

- (void)parseData:(NSData *)inData logSize:(NSUInteger)logSize;

@property (assign, nonatomic) id <MNXDataParserDelegate> delegate;

@end
