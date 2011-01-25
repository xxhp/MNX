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

@implementation MNXDownloadOperation

- (void)dealloc
{
	delegate = nil;
	[port release];
	[super dealloc];
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
	while ([data length] < logSize && ![self isCancelled]) {
		NSError *e = nil;
		NSData *d = [port readBytes:132 error:&e];
		NSInteger *p = malloc([d length] - 4);
		[d getBytes:p range:NSMakeRange(3, [d length] - 4)];
		NSData *a = [NSData dataWithBytes:p length:[d length] - 4];
		[delegate downloadOperation:self didDownloadData:(CGFloat)[data length] / (CGFloat)logSize];
		[data appendData:a];
		[port writeString:CAN usingEncoding:NSUTF8StringEncoding error:&e];
	}
	if ([self isCancelled]) {
		[delegate downloadOperationCancelled:self];
		return nil;
	}
	
	*outLogSize = logSize;
	return data;
}

- (void)main
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSInteger logSize = 0;
	NSString *errorMessage = nil;
	NSData *data = [self downloadDataWithError:&errorMessage logSize:&logSize];
	if ([data length]) {
		[delegate downloadOperation:self didFinishDownloadingData:data logSize:logSize];
	}
	else if (errorMessage) {
		[delegate downloadOperation:self didFailedWithMessage:errorMessage];
		NSLog(@"errorMessage:%@", errorMessage);
	}
	[pool drain];	
}

- (void)cancel
{
	[super cancel];
}

@synthesize delegate;
@synthesize port;

@end
