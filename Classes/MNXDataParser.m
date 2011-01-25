#import "MNXDataParser.h"
#import "MNXPoint.h"
#import "MNXTrack.h"

static NSArray *boolArrayFromChar(char inChar)
{
	NSMutableArray *a = [NSMutableArray arrayWithCapacity:8];
	for (NSInteger i = 1; i < 9; i++) {
		((inChar | (1 << (8 - i))) == inChar)?
		[a addObject:[NSNumber numberWithBool:YES]]:
		[a addObject:[NSNumber numberWithBool:NO]];
	}
	return a;
}

static NSUInteger intFromBoolArray(NSArray *array)
{
	NSUInteger r = 0;
	for (NSInteger i = 0; i < [array count]; i++) {
		BOOL aBool = [[array objectAtIndex:i] boolValue];
		if (aBool) {
			int shift = ([array count] - i - 1);
			r += (1 << shift);
		}
	}
	return r;
}

@implementation MNXDataParser

- (void) dealloc
{
	[calendar release];
	[delegate release];
	[super dealloc];
}

- (id)init
{
	self = [super init];
	if (self != nil) {
		calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
		NSTimeZone *timeZone = [NSTimeZone systemTimeZone];
		[calendar setTimeZone:timeZone];
		
	}
	return self;
}

- (void)parseData:(NSData *)inData logSize:(NSUInteger)inLogSize
{
	[delegate dataParserDidStartParsingData:self];
	
	Byte *p = malloc([inData length]);
	[inData getBytes:p length:[inData length]];
	// 8192 / 16 = 512
	NSUInteger endOffsets[512];
	int rows = 0;
	for (int i = 0; i < 512; i++) {
		unsigned char entry[4];
		for (int j = 0; j < 4; j++) {
			entry[j] = p[i * 16 + j];
		}
		if (entry[0] == 255 && entry[1] == 255 && entry[2] == 255 && entry[3] == 255) {
			break;
		}
		if (entry[3] == 255) {
			entry[3] = 0;
		}
		endOffsets[i] = (entry[0] << 0) | (entry[1] << 8) | (entry[2] << 16) | (entry[3] << 24);
		rows++;
	}
//	NSLog(@"rows:%d", rows);
//	for (NSUInteger i=0; i< rows; i++) {
//		NSLog(@"%d %d", i, endOffsets[i]);
//	}
	
	NSMutableArray *tracks = [NSMutableArray array];
	NSUInteger currentTrack = 0;
	NSMutableArray *points = [NSMutableArray array];
	
	for (NSUInteger i = 8192; i < inLogSize; i += 16) {
		if (i == endOffsets[currentTrack]) {
			MNXTrack *track = [[MNXTrack alloc] init];
			track.points = points;
			[tracks addObject:track];
			currentTrack += 1;
			points = [NSMutableArray array];
		}
		
		unsigned char track[16];
		for (int j = 0; j < 16; j++) {
			track[j] = (char)p[i + j];
		}		
		NSMutableArray *a = [NSMutableArray arrayWithCapacity:32];
		for (int j = 0; j < 4; j++) {
			NSArray *bools = boolArrayFromChar(track[j]);
			[a addObjectsFromArray:bools];
		}
		
		NSUInteger year = intFromBoolArray([a objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 6)]]) + 2006;
		NSUInteger month = intFromBoolArray([a objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(6, 4)]]);		
		NSUInteger day = intFromBoolArray([a objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(10, 5)]]);				
		NSUInteger hour = intFromBoolArray([a objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(15, 5)]]);
		NSUInteger min = intFromBoolArray([a objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(20, 6)]]);
		NSUInteger sec = intFromBoolArray([a objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(26, 6)]]);
		
		NSDateComponents *dateComponents = [[[NSDateComponents alloc] init] autorelease];
		[dateComponents setYear:year];
		[dateComponents setMonth:month];
		[dateComponents setDay:day];
		[dateComponents setHour:hour];
		[dateComponents setMinute:min];
		[dateComponents setSecond:sec];
		
		NSDate *date = [calendar dateFromComponents:dateComponents];
		
		char longitude[4];
		for (int j = 0; j < 4; j++) {
			longitude[j] = track[j + 4];
		}
		float longitudef = *((float *)longitude);
		
		char latitude[4];
		for (int j = 0; j < 4; j++) {
			latitude[j] = track[j + 8];
		}
		float latitudef = *((float *)latitude);
		
		NSUInteger speed = track[12] + (track[13] >> 7);
		
		a = [NSMutableArray arrayWithCapacity:16];
		
		[a addObjectsFromArray:boolArrayFromChar(track[13])];
		[a addObjectsFromArray:boolArrayFromChar(track[14])];
		[a setArray:[a objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(2, 14)]]];
		NSInteger elevation = 0;
		
		if ([[a objectAtIndex:0] boolValue]) {
			NSMutableArray *reverseArray = [NSMutableArray array];
			for (NSNumber *n in a) {
				if ([n boolValue]) {
					[reverseArray addObject:[NSNumber numberWithBool:NO]];
				}
				else {
					[reverseArray addObject:[NSNumber numberWithBool:YES]];
				}
			}
			elevation = intFromBoolArray(reverseArray) * -1;
		}
		else {
			elevation = intFromBoolArray(a);
		}
		
		MNXPoint *point = [[[MNXPoint alloc] init] autorelease];
		point.date = date;
		point.latitude = (CGFloat)latitudef;
		point.longitude = (CGFloat)longitudef;
		point.elevation = elevation;
		point.speed = speed;
		[points addObject:point];
		
		if (i+ 16 >= inLogSize) {
			MNXTrack *track = [[MNXTrack alloc] init];
			track.points = points;
			[tracks addObject:track];			
		}
	}
	
	[delegate dataParser:self didFinishParsingData:tracks];
	
	free(p);
}

@synthesize delegate;

@end
