#import "MNXDownloadOperation.h"
#import "AMSerialPortAdditions.h"
#import "MNXPoint.h"
#import "MNXTrack.h"

static NSString *const kInitDownloadMainnavMG950DCommand=@"$1\r\n";
static NSString *const kInitDownloadQstartBTQ2000Command=@"$9\r\n";
static NSString *const kCheckStatusCommand = @"$3\r\n";

static unichar kDwonloadChunkFirst = 0x15; //NAK
static unichar kDownloadChunkNext = 0x06; //ACK

static NSString *const kOK = @"$OK!";
static NSString *const kFinish = @"$FINISH\r\n";
static NSString *const kAborted = @"\x06\x06\x06\x06";

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

@implementation MNXDownloadOperation

- (void)dealloc
{
	delegate = nil;
	[calendar release];
	[port release];
	[super dealloc];
}

- (id)init
{
	self = [super init];
	if (self != nil) {
		calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
//		NSTimeZone *timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
		NSTimeZone *timeZone = [NSTimeZone systemTimeZone];
		[calendar setTimeZone:timeZone];
		
	}
	return self;
}


- (void)parseData:(NSData *)inData logSize:(NSUInteger)inLogSize
{
	[delegate downloadOperationDidStartParsingData:self];
	
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
	NSLog(@"rows:%d", rows);
	for (NSUInteger i=0; i< rows; i++) {
		NSLog(@"%d %d", i, endOffsets[i]);
	}

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
	
	[delegate downloadOperation:self didFinishParsingData:tracks];
	
	free(p);
}

- (NSData *)_communicate:(NSString *)command
{
	[port writeString:command usingEncoding:NSUTF8StringEncoding error:NULL];
	NSError *e = nil;
	NSData *d = [port readAndReturnError:&e];
	return d;
}

- (NSData *)downloadDataWithError:(out NSString **)outErrorMessage logSize:(NSInteger *)outLogSize;
{
	[delegate downloadOperationDidStartDownloadingData:self];

	[port setSpeed:115200];
	[port setDataBits:8];
	[port setParity:kAMSerialParityNone];
	[port setStopBits:kAMSerialStopBitsOne];	
	[port setReadTimeout:0.3];
	
	NSInteger logSize = 0;
	if ([port isOpen]) {
		[port free];
	}
	if (![port open]) {
		*outErrorMessage = @"Unable to open the device.";
		return nil;
	}
	
	if ([port isOpen]) {
		NSData *d = [self _communicate:kCheckStatusCommand];
		NSString *r = [[[NSString alloc] initWithData:d encoding:NSASCIIStringEncoding] autorelease];
		if (![r hasPrefix:kOK]) {
			*outErrorMessage = @"Unable to open the device. Is the device turned on?";
			return nil;
		}
		Byte p[4];
		[d getBytes:&p range:NSMakeRange([d length] - 4, 4)];
		logSize = (p[0] << 24) + (p[1] << 16) + (p[2] << 8) + (p[3] << 0);
	}
	else {
		*outErrorMessage = @"Unable to open the device";
		return nil;
	}
	if (logSize <= 8192) {
		*outErrorMessage = @"No tracklogs";
		return nil;
	}

	NSData *d = [self _communicate:kInitDownloadMainnavMG950DCommand];
	NSString *r = [[[NSString alloc] initWithData:d encoding:NSASCIIStringEncoding] autorelease];
	if (![r hasPrefix:kOK]) {
		d = [self _communicate:kInitDownloadQstartBTQ2000Command];
		r = [[[NSString alloc] initWithData:d encoding:NSASCIIStringEncoding] autorelease];
	}
	if (![r hasPrefix:kOK]) {
		*outErrorMessage = @"unable to init download...";
		return nil;
	}
	
	NSMutableData *data = [NSMutableData data];
	
	NSString *NAK = [NSString stringWithCharacters:&kDwonloadChunkFirst length:1];
	NSString *CAN = [NSString stringWithCharacters:&kDownloadChunkNext length:1];
	[port writeString:NAK usingEncoding:NSUTF8StringEncoding error:NULL];	
	while ([data length] < logSize) {
		NSError *e = nil;
		NSData *d = [port readAndStopAfterBytes:NO bytes:132 stopAtChar:NO stopChar:0 error:&e];
		NSLog(@"d:%@ %d", [d description], [d length]);
		
		NSInteger *p = malloc([d length] - 4);
		[d getBytes:p range:NSMakeRange(3, [d length] - 4)];
		NSData *a = [NSData dataWithBytes:p length:[d length] - 4];
		[delegate downloadOperation:self didDownloadData:(CGFloat)[data length] / (CGFloat)logSize];
		[data appendData:a];
		NSLog(@"data :%d", [data length]);
		[port writeString:CAN usingEncoding:NSUTF8StringEncoding error:&e];
	}
	[delegate downloadOperationDidFinishDownloadingData:self];
	*outLogSize = logSize;
	return data;
}

- (void)main
{
	NSInteger logSize = 0;
	NSString *errorMessage = nil;
	NSData *data = [self downloadDataWithError:&errorMessage logSize:&logSize];
	if ([data length]) {
		[self parseData:data logSize:logSize];
	}
	else {
		[delegate downloadOperation:self didFailedWithMessage:errorMessage];
		NSLog(@"errorMessage:%@", errorMessage);
	}
	
//	NSString *path = [[NSBundle mainBundle] pathForResource:@"data" ofType:@"dat"];
//	NSData *d = [NSData dataWithContentsOfFile:path];
//	[self parseData:d logSize:354608];
	
}

@synthesize delegate;
@synthesize port;

@end
