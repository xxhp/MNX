#import "MNXSpeedView.h"

@implementation MNXSpeedView

- (void) dealloc
{
	[image release];
	[currentTrack release];
	[super dealloc];
}


- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		currentTrack = nil;
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
	[[NSColor whiteColor] setFill];
	[NSBezierPath fillRect:[self bounds]];
	
	[self.image drawInRect:[self bounds] fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	
}

#pragma mark -

- (void)generateImage
{
	if ([self.currentTrack.points count] < 2) {
		self.image = nil;
		[self performSelectorOnMainThread:@selector(refresh) withObject:nil waitUntilDone:YES];
	}	
	
	NSImage *anImage = [[NSImage alloc] initWithSize:NSMakeSize(500.0, 300.0)];
	[anImage lockFocus];
		
	CGFloat frameWidth = 30.0;	
	NSRect drawingFrame = CGRectMake(frameWidth, frameWidth, [anImage size].width - (frameWidth * 2) , [anImage size].height - (frameWidth * 2));
	
	CGFloat maxSpeed = 0.0;	
	NSInteger maxPointCount = 100.0;
	NSMutableArray *a = [NSMutableArray array];
	NSInteger pointPerSection = (NSInteger)([self.currentTrack.points count] / maxPointCount);
	NSUInteger count = 0;
	CGFloat aSpeed = 0.0;
	
	for (MNXPoint *point in self.currentTrack.points) {
		if (point == [self.currentTrack.points objectAtIndex:0]) {
			CGFloat speed = (point.speedKM > 0.0) ? point.speedKM : 0.0;
			NSMutableDictionary *p = [NSMutableDictionary dictionary];	
			[p setObject:[NSNumber numberWithFloat:point.distanceKM] forKey:@"distance"];
			[p setObject:[NSNumber numberWithFloat:speed] forKey:@"speed"];
			maxSpeed = speed;
			[a addObject:p];
		}
		else {
			CGFloat speed = 0.0;
			if (count < pointPerSection) {
				if (point.speedKM > 0.0) {
					aSpeed += point.speedKM;
				}
				count++;
				continue;
			}
			else {
				speed = aSpeed / count;
				count = 0;
				aSpeed = 0.0;
			}
			NSMutableDictionary *p = [NSMutableDictionary dictionary];	
			[p setObject:[NSNumber numberWithFloat:point.distanceKM] forKey:@"distance"];
			[p setObject:[NSNumber numberWithFloat:speed] forKey:@"speed"];
			if (speed > maxSpeed) {
				maxSpeed = speed;
			}
			[a addObject:p];
		}
	}
	
	if (maxSpeed < 5.0) {
		maxSpeed = 5.0;
	}
	
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path setLineJoinStyle:NSRoundLineJoinStyle];
	
	for (NSDictionary *p in a) {
		CGFloat x = frameWidth + ([[p objectForKey:@"distance"] floatValue] / self.currentTrack.totalDistance) * drawingFrame.size.width;
		CGFloat y = frameWidth + [[p objectForKey:@"speed"] floatValue] / maxSpeed * drawingFrame.size.height;
		if (p == [a objectAtIndex:0]) {
			[path moveToPoint:NSMakePoint(x, y)];
		}
		else {
			[path lineToPoint:NSMakePoint(x, y)];
		}
	}
			 
	
	NSColor *lineColor = [NSColor colorWithCalibratedHue:0.5 saturation:1.0 brightness:0.5 alpha:1.0];
	NSColor *backgroundColor = [NSColor colorWithCalibratedHue:0.5 saturation:1.0 brightness:0.5 alpha:0.7];
	
	NSBezierPath *backgroundPath = [[path copy] autorelease];
	[backgroundPath lineToPoint:NSMakePoint(NSMaxX(drawingFrame), NSMinY(drawingFrame))];
	[backgroundPath lineToPoint:NSMakePoint(NSMinX(drawingFrame), NSMinY(drawingFrame))];
	[backgroundPath closePath];
	[backgroundColor setFill];
	[backgroundPath fill];
	
	[lineColor setStroke];
	[path setLineWidth:3.0];
	[path stroke];
	
	[anImage unlockFocus];
	
	self.image = [anImage autorelease];
}

- (void)setCurrentTrack:(MNXTrack *)inTrack
{
	id tmp = currentTrack;
	currentTrack = [inTrack retain];
	[tmp release];
	[self generateImage];
	[self setNeedsDisplay:YES];
}

- (MNXTrack *)currentTrack
{
	return currentTrack;
}

@synthesize image;

@end

