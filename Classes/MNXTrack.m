#import "MNXTrack.h"
#import "MNXPoint.h"
#import "NSLocale+MNXExtension.h"
#import "NSImage+MNXExtensions.h"
#include <math.h>

static CGFloat degreeToRadian(CGFloat degree)
{
	return (CGFloat)(degree * M_PI / 180.0);
}

static CGFloat radianToDegree(CGFloat radian)
{
	return (CGFloat)(radian / M_PI * 180);
}

static CGFloat distanceKM(CGFloat lat1, CGFloat lon1, CGFloat lat2, CGFloat lon2)
{
	CGFloat theta = lon1 - lon2;
	CGFloat dist = sin(degreeToRadian(lat1)) * sin(degreeToRadian(lat2)) + cos(degreeToRadian(lat1)) * cos(degreeToRadian(lat2)) * cos(degreeToRadian(theta));
	dist = acos(dist) * 6373.0;
	return dist;
}

static CGFloat distanceMile(CGFloat lat1, CGFloat lon1, CGFloat lat2, CGFloat lon2)
{
	CGFloat theta = lon1 - lon2;
	CGFloat dist = sin(degreeToRadian(lat1)) * sin(degreeToRadian(lat2)) + cos(degreeToRadian(lat1)) * cos(degreeToRadian(lat2)) * cos(degreeToRadian(theta));
	dist = acos(dist) * 3960.0;
	return dist;
}

static NSDateFormatter *sharedFormatter;

@implementation MNXTrack

+ (NSDateFormatter *)dateFormatter
{
	if (!sharedFormatter) {
		sharedFormatter = [[NSDateFormatter alloc] init];
		[sharedFormatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en"] autorelease]];
		[sharedFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
		[sharedFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];			
	}
	return sharedFormatter;
}

- (void)dealloc
{
	[pointArray release];
	[splitKM release];
	[splitMile release];
	[super dealloc];
}

- (id)init
{
	self = [super init];
	if (self != nil) {
		pointArray = [[NSMutableArray alloc] init];
		splitKM = [[NSMutableArray alloc] init];
		splitMile = [[NSMutableArray alloc] init];
	}
	return self;
}

- (NSString *)title
{
	if (![pointArray count]) {
		return @"Empty Track";
	}
	
	NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
	[formatter setDateStyle:NSDateFormatterShortStyle];
	[formatter setTimeStyle:NSDateFormatterShortStyle];
	MNXPoint *point = [pointArray objectAtIndex:0];
	return [formatter stringFromDate:point.date];
}

#pragma mark -
#pragma mark XML Data

+ (NSXMLNode *)GPXRootNode:(out NSXMLNode **)outTrackContainer
{
	NSXMLElement *root = (NSXMLElement *)[NSXMLNode elementWithName:@"gpx"];	
	[root addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"http://www.topografix.com/GPX/1/1"]];
	[root addNamespace:[NSXMLNode namespaceWithName:@"xsi" stringValue:@"http://www.w3.org/2001/XMLSchema-instance"]];
	[root addNamespace:[NSXMLNode namespaceWithName:@"gpxx" stringValue:@"http://www.garmin.com/xmlschemas/GpxExtensions/v3"]];
	[root addNamespace:[NSXMLNode namespaceWithName:@"gpxtpx" stringValue:@"http://www.garmin.com/xmlschemas/TrackPointExtension/v1"]];
	
	[root addAttribute:[NSXMLNode attributeWithName:@"xsi:schemaLocation" stringValue:@"http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd http://www.garmin.com/xmlschemas/GpxExtensions/v3 http://www.garmin.com/xmlschemas/GpxExtensionsv3.xsd http://www.garmin.com/xmlschemas/TrackPointExtension/v1 http://www.garmin.com/xmlschemas/TrackPointExtensionv1.xsd"]];
	[root addAttribute:[NSXMLNode attributeWithName:@"version" stringValue:@"1.1"]];
	[root addAttribute:[NSXMLNode attributeWithName:@"creator" stringValue:@"MNX"]];
	*outTrackContainer = root;
	return root;
}
+ (NSXMLNode *)KMLRootNode:(out NSXMLNode **)outTrackContainer
{
	NSXMLElement *root = (NSXMLElement *)[NSXMLNode elementWithName:@"kml"];
	[root addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"http://www.opengis.net/kml/2.2"]];
	[root addNamespace:[NSXMLNode namespaceWithName:@"gx" stringValue:@"http://www.google.com/kml/ext/2.2"]];
	[root addNamespace:[NSXMLNode namespaceWithName:@"kml" stringValue:@"http://www.opengis.net/kml/2.2"]];
	[root addNamespace:[NSXMLNode namespaceWithName:@"atom" stringValue:@"http://www.w3.org/2005/Atom"]];
	
	NSXMLElement *document = (NSXMLElement *)[NSXMLNode elementWithName:@"Document"];
	[root addChild:document];
	
//	[document addChild:[NSXMLNode elementWithName:@"name" stringValue:[self title]]];
	[document addChild:[NSXMLNode elementWithName:@"name" stringValue:@"Tracks"]];
	
	NSXMLElement *style = (NSXMLElement *)[NSXMLNode elementWithName:@"Style"];
	[style addAttribute:[NSXMLNode attributeWithName:@"id" stringValue:@"track_style"]];
	NSXMLElement *lineStyle = (NSXMLElement *)[NSXMLNode elementWithName:@"LineStyle"];	
	[lineStyle addChild:[NSXMLNode elementWithName:@"color" stringValue:@"99ffac59"]];
	[lineStyle addChild:[NSXMLNode elementWithName:@"width" stringValue:@"6"]];	 
	NSXMLElement *polyStyle = (NSXMLElement *)[NSXMLNode elementWithName:@"PolyStyle"];	
	[polyStyle addChild:[NSXMLNode elementWithName:@"color" stringValue:@"99ffac59"]];
	[polyStyle addChild:[NSXMLNode elementWithName:@"width" stringValue:@"6"]];	 
	
	NSXMLElement *iconStyle = (NSXMLElement *)[NSXMLNode elementWithName:@"IconStyle"];	
	NSXMLElement *icon = (NSXMLElement *)[NSXMLNode elementWithName:@"Icon"];
	[icon addChild:[NSXMLNode elementWithName:@"href" stringValue:@"http://earth.google.com/images/kml-icons/track-directional/track-0.png"]];
	[iconStyle addChild:icon];
	
	[style addChild:lineStyle];
	[style addChild:polyStyle];
	[style addChild:iconStyle];
	[document addChild:style];
	
	*outTrackContainer = document;
	return root;
}
+ (NSXMLNode *)TCXRootNode:(out NSXMLNode **)outTrackContainer
{
	NSXMLElement *root = (NSXMLElement *)[NSXMLNode elementWithName:@"TrainingCenterDatabase"];
	[root addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2"]];
	[root addNamespace:[NSXMLNode namespaceWithName:@"xsi" stringValue:@"http://www.w3.org/2001/XMLSchema-instance"]];
	[root addAttribute:[NSXMLNode attributeWithName:@"xsi:schemaLocation" stringValue:@"http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2 http://www.garmin.com/xmlschemas/TrainingCenterDatabasev2.xsd"]];
	NSXMLElement *activities = (NSXMLElement *)[NSXMLNode elementWithName:@"Activities"];
	[root addChild:activities];
	*outTrackContainer = activities;
	return root;
}

- (NSXMLNode *)GPXNode
{
	NSDateFormatter *formatter = [MNXTrack dateFormatter];
	NSXMLElement *trk = (NSXMLElement *)[NSXMLNode elementWithName:@"trk"];
	NSXMLElement *name = (NSXMLElement *)[NSXMLNode elementWithName:@"name" stringValue:[self title]];
	[trk addChild:name];
	NSXMLElement *trkseg = (NSXMLElement *)[NSXMLNode elementWithName:@"trkseg"];
	for (MNXPoint *point in pointArray) {
		NSXMLElement *time = (NSXMLElement *)[NSXMLNode elementWithName:@"time" stringValue:[formatter stringFromDate:point.date]];
		NSXMLElement *ele = (NSXMLElement *)[NSXMLNode elementWithName:@"ele" stringValue:[NSString stringWithFormat:@"%d", (NSInteger)point.elevation]];
		NSXMLNode *lon = [NSXMLNode attributeWithName:@"lon" stringValue:[NSString stringWithFormat:@"%f", point.longitude]];
		NSXMLNode *lat = [NSXMLNode attributeWithName:@"lat" stringValue:[NSString stringWithFormat:@"%f", point.latitude]];		
		NSXMLElement *trkpt = [NSXMLNode elementWithName:@"trkpt"];
		[trkpt addChild:time];
		[trkpt addChild:ele];
		[trkpt addAttribute:lat];	
		[trkpt addAttribute:lon];
		[trkseg addChild:trkpt];
	}
	[trk addChild:trkseg];
	return trk;
}
- (NSXMLNode *)KMLNode
{
	NSDateFormatter *formatter = [MNXTrack dateFormatter];
	NSXMLElement *placemark = (NSXMLElement *)[NSXMLNode elementWithName:@"Placemark"];
	[placemark addChild:[NSXMLNode elementWithName:@"styleUrl" stringValue:@"#track_style"]];
	[placemark addChild:[NSXMLNode elementWithName:@"name" stringValue:[self title]]];
	[placemark addChild:[NSXMLNode elementWithName:@"gx:balloonVisibility" stringValue:@"1"]];
	NSXMLElement *track = (NSXMLElement *)[NSXMLNode elementWithName:@"gx:Track"];
	for (MNXPoint *point in pointArray) {
		[track addChild:[NSXMLNode elementWithName:@"when" stringValue:[formatter stringFromDate:point.date]]];		
	}
	for (MNXPoint *point in pointArray) {
		NSString *line = [NSString stringWithFormat:@"%f %f %f", point.longitude, point.latitude, point.elevation];
		[track addChild:[NSXMLNode elementWithName:@"gx:coord" stringValue:line]];		
	}
	
	[placemark addChild:track];
	return placemark;
}
- (NSXMLNode *)TCXNode
{
	NSDateFormatter *formatter = [MNXTrack dateFormatter];
	
	if ([self.points count]) {
		NSXMLElement *activity = (NSXMLElement *)[NSXMLNode elementWithName:@"Activity"];
		
		NSString *activityID = [formatter stringFromDate:[(MNXPoint *)[self.points objectAtIndex:0] date]];
		[activity addChild:[NSXMLNode elementWithName:@"Id" stringValue:activityID]];
		
		NSXMLElement *lap = (NSXMLElement *)[NSXMLNode elementWithName:@"Lap"];
		[lap addAttribute:[NSXMLNode attributeWithName:@"StartTime" stringValue:activityID]];
		[lap addChild:[NSXMLNode elementWithName:@"TotalTimeSeconds" stringValue:[NSString stringWithFormat:@"%f", duration]]];
		[lap addChild:[NSXMLNode elementWithName:@"DistanceMeters" stringValue:[NSString stringWithFormat:@"%f", totalDistanceKM * 100.0]]];
		NSXMLElement *track = (NSXMLElement *)[NSXMLNode elementWithName:@"Track"];		
		for (MNXPoint *point in pointArray) {
			NSXMLElement *trackPoint = (NSXMLElement *)[NSXMLNode elementWithName:@"Trackpoint"];
			[trackPoint addChild:[NSXMLNode elementWithName:@"Time" stringValue:[formatter stringFromDate:point.date]]];
			[trackPoint addChild:[NSXMLNode elementWithName:@"AltitudeMeters" stringValue:[NSString stringWithFormat:@"%f", point.elevation]]];
			[trackPoint addChild:[NSXMLNode elementWithName:@"DistanceMeters" stringValue:[NSString stringWithFormat:@"%f", point.distanceKM * 100.0]]];
			NSXMLElement *position = (NSXMLElement *)[NSXMLNode elementWithName:@"Position"];
			[position addChild:[NSXMLNode elementWithName:@"LatitudeDegrees" stringValue:[NSString stringWithFormat:@"%f", point.latitude]]];
			[position addChild:[NSXMLNode elementWithName:@"LongitudeDegrees" stringValue:[NSString stringWithFormat:@"%f", point.longitude]]];
			[trackPoint addChild:position];
			[track addChild:trackPoint];
		}
		[lap addChild:track];
		[activity addChild:lap];
	}
	return nil;
}

- (NSData *)GPXData
{	
	NSXMLElement *container = nil;
	NSXMLElement *root = (NSXMLElement *)[MNXTrack GPXRootNode:&container];
	NSXMLDocument *xml = [[[NSXMLDocument alloc] initWithRootElement:root] autorelease];
	[xml setVersion:@"1.0"];
	[xml setCharacterEncoding:@"UTF-8"];
	NSXMLElement *trk = (NSXMLElement *)[self GPXNode];
	[root addChild:trk];
	NSData *data = [xml XMLData];
	return data;
}
- (NSData *)KMLData
{
	NSXMLElement *document = nil;
	NSXMLElement *root = (NSXMLElement *)[MNXTrack KMLRootNode:&document];
	NSXMLDocument *xml = [[[NSXMLDocument alloc] initWithRootElement:root] autorelease];
	[xml setVersion:@"1.0"];
	[xml setCharacterEncoding:@"UTF-8"];
	
	
	if (![pointArray count]) {
		NSData *data = [xml XMLData];
		return data;
	}
	
	NSXMLElement *lookAt = (NSXMLElement *)[NSXMLNode elementWithName:@"LookAt"];
	MNXPoint *point = [pointArray objectAtIndex:0];
	
	CGFloat top = point.latitude;
	CGFloat bottom = point.latitude;
	CGFloat left = point.longitude;
	CGFloat right = point.longitude;
	
	for (MNXPoint *point in pointArray) {
		if (point.latitude > top) {
			top = point.latitude;
		}
		if (point.latitude < bottom) {
			bottom = point.latitude;
		}
		if (point.longitude > right) {
			right = point.longitude;
		}
		if (point.longitude < left) {
			left = point.longitude;
		}		
	}
	
	[lookAt addChild:[NSXMLNode elementWithName:@"longitude" stringValue:[NSString stringWithFormat:@"%f", (right + (left - right) / 2.0)]]];
	[lookAt addChild:[NSXMLNode elementWithName:@"latitude" stringValue:[NSString stringWithFormat:@"%f", (bottom + (top - bottom) / 2.0)]]];
	[lookAt addChild:[NSXMLNode elementWithName:@"altitude" stringValue:@"0"]];
	[lookAt addChild:[NSXMLNode elementWithName:@"heading" stringValue:@"0"]];
	[lookAt addChild:[NSXMLNode elementWithName:@"tilt" stringValue:@"0"]];
	CGFloat dist = distanceKM(top, left, bottom, right);
	NSInteger range = (NSUInteger)(dist * 1.5 * 1000);
	[lookAt addChild:[NSXMLNode elementWithName:@"range" stringValue:[NSString stringWithFormat:@"%d", range]]];
	[document addChild:lookAt];
	
	[document addChild:[self KMLNode]];
	
	NSData *data = [xml XMLData];
	return data;
}
- (NSData *)TCXData
{
	NSXMLElement *activities = nil;
	NSXMLElement *root = (NSXMLElement *)[MNXTrack TCXRootNode:&activities];
	
	NSXMLDocument *xml = [[[NSXMLDocument alloc] initWithRootElement:root] autorelease];
	[xml setVersion:@"1.0"];
	[xml setCharacterEncoding:@"UTF-8"];
	
	NSXMLNode *activity = [self TCXNode];
	if (activity) {
		[activities addChild:activity];
	}

	NSData *data = [xml XMLData];
	return data;
}


- (NSString *)HTML
{
	NSString *template = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n\
<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1//EN\" \"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd\">\n\
<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\">\n\
<head>\n\
	<title>Map</title>\n\
	<script type=\"text/javascript\" src=\"http://maps.google.com/maps/api/js?sensor=true\"></script>\n\
	<script type=\"text/javascript\" charset=\"utf-8\">\n\
	window.init = function() {\n\
	var latlng = new google.maps.LatLng(%f, %f);\n\
	var myOptions = {\n\
	zoom: 13,\n\
	center: latlng,\n\
	mapTypeId: google.maps.MapTypeId.ROADMAP\n\
	};\n\
	var map = new google.maps.Map(document.getElementById(\"map\"), myOptions);\n\
	var polyOptions = {\n\
	strokeColor: '#6666aa',\n\
	strokeOpacity: 1.0,\n\
	strokeWeight: 6\n\
	}\n\
	var poly = new google.maps.Polyline(polyOptions);\n\
	poly.setMap(map);\n\
	%@\n\
	}\n\
	</script>\
	<style type=\"text/css\" media=\"screen\">\n\
	#map {\n\
		width: 100%%;\n\
		// min-height: 500px;\n\
		height: 100%%;\n\
	}\n\
	body, html {\n\
	width: 100%%;\n\
	// min-height: 500px;\n\
	height: 100%%;\n\
	margin: 0;\n\
		padding: 0;\n\
	}\n\
	</style>\n\
</head>\n\
<body onload=\"init()\">\n\
<div id=\"map\">\n\
</div>\n\
</body>\n\
</html>";
	NSMutableString *addLineString = [NSMutableString string];
	CGFloat top = 0.0;
	CGFloat bottom = 0.0;
	CGFloat left = 0.0;
	CGFloat right = 0.0;
	if ([pointArray count]) {
		MNXPoint *point = [pointArray objectAtIndex:0];
		top = point.latitude;
		bottom = point.latitude;
		left = point.longitude;
		right = point.longitude;
	}	
	for (MNXPoint *point in pointArray) {
		[addLineString appendFormat:@"\tpoly.getPath().push(new google.maps.LatLng(%f, %f));\n", point.latitude, point.longitude];
		if (point.latitude > top) {
			top = point.latitude;
		}
		if (point.latitude < bottom) {
			bottom = point.latitude;
		}
		if (point.longitude > right) {
			right = point.longitude;
		}
		if (point.longitude < left) {
			left = point.longitude;
		}	
	}
	NSArray *splits = splitKM;
	NSString *unit = NSLocalizedString(@"km", @"");
	
	if ([NSLocale usingUSMeasurementUnit]) {
		splits = splitMile;
		unit = NSLocalizedString(@"ml", @"");
	}
	
	NSColor *aColor = nil;
	if ([pointArray count]) {
		aColor = [NSColor redColor];
		MNXPoint *point = [pointArray objectAtIndex:0];
		NSString *base64Image = [NSImage base64ImageWithText:NSLocalizedString(@"Start", @"")  additionalText:@"" color:aColor];
		NSString *inlineString = [NSString stringWithFormat:@"data:image/tiff;base64,%@", base64Image];
		[addLineString appendFormat:@"\tnew google.maps.Marker({position:new google.maps.LatLng(%f, %f), map: map, icon: '%@', animation: google.maps.Animation.DROP})\n", point.latitude, point.longitude, inlineString];		
	}	
	if ([pointArray count] > 1) {
		aColor = [NSColor redColor];
		MNXPoint *point = [pointArray lastObject];
		NSString *base64Image = [NSImage base64ImageWithText:NSLocalizedString(@"End", @"")  additionalText:@"" color:aColor];
		NSString *inlineString = [NSString stringWithFormat:@"data:image/tiff;base64,%@", base64Image];
		[addLineString appendFormat:@"\tnew google.maps.Marker({position:new google.maps.LatLng(%f, %f), map: map, icon: '%@', animation: google.maps.Animation.DROP})\n", point.latitude, point.longitude, inlineString];		
	}
	
	aColor = [NSColor blueColor];
	if ([splits count] > 1) {	
		for (NSDictionary *d in splits) {
			MNXPoint *point = [d objectForKey:@"point"];
			NSString *base64Image = [NSImage base64ImageWithText:[NSString stringWithFormat:@"%d %@", [[d objectForKey:@"distance"] integerValue], unit]  additionalText:@"" color:aColor];
			NSString *inlineString = [NSString stringWithFormat:@"data:image/tiff;base64,%@", base64Image];
			[addLineString appendFormat:@"\tnew google.maps.Marker({position:new google.maps.LatLng(%f, %f), map: map, icon: '%@', animation: google.maps.Animation.DROP})\n", point.latitude, point.longitude, inlineString];
		}
	}
	
	NSString *boundsString = [NSString stringWithFormat:@"\tvar bounds = new google.maps.LatLngBounds(new google.maps.LatLng(%f, %f), new google.maps.LatLng(%f, %f));\n", top, left, bottom, right];
	[addLineString appendString:boundsString];
	[addLineString appendString:@"\tmap.fitBounds(bounds);\n"];
	
	NSString *HTML = [NSString stringWithFormat:template, (bottom + (top - bottom) / 2.0),
					  (right + (left - right) / 2.0),
					  addLineString];
	
	return HTML;
}

#pragma mark -
#pragma mark Properties

- (void)setPoints:(NSArray *)inPoints
{
	[pointArray setArray:inPoints];
	[splitKM removeAllObjects];
	[splitMile removeAllObjects];
	
	duration = 0.0;
	totalDistanceKM = 0.0;
	averagePaceKM = 0.0;
	averageSpeedKM = 0.0;
	maxSpeedKM = 0.0;
	totalDistanceMile = 0.0;
	averagePaceMile = 0.0;
	averageSpeedMile = 0.0;
	maxSpeedMile = 0.0;		
	
	if ([pointArray count] < 1) {
		return;
	}
	
	CGFloat newDistanceKM = 0.0;
	CGFloat newMaxSpeedKM = 0.0;
	CGFloat newDistanceMile = 0.0;
	CGFloat newMaxSpeedMile = 0.0;
	
	for (NSInteger i = 1; i < [pointArray count]; i++) {
		MNXPoint *currentPoint = [pointArray objectAtIndex:i];
		MNXPoint *previousPoint = [pointArray objectAtIndex:i - 1];

		/// KM
		
		CGFloat aDistanceKM = distanceKM(currentPoint.latitude, currentPoint.longitude, previousPoint.latitude, previousPoint.longitude);
		if (aDistanceKM > 0.0) {
			newDistanceKM += aDistanceKM;			
		}
		currentPoint.distanceKM = newDistanceKM;
		currentPoint.speedKM = aDistanceKM / fabs([currentPoint.date timeIntervalSinceDate:previousPoint.date]) * 60.0 * 60.0;
		if (currentPoint.speedKM > newMaxSpeedKM) {
			newMaxSpeedKM = currentPoint.speedKM;
		}

		/// Mile
		
		CGFloat aDistanceMile = distanceMile(currentPoint.latitude, currentPoint.longitude, previousPoint.latitude, previousPoint.longitude);
		if (aDistanceMile > 0.0) {
			newDistanceMile += aDistanceMile;			
		}
		currentPoint.distanceMile = newDistanceMile;
		currentPoint.speedMile = aDistanceMile / fabs([currentPoint.date timeIntervalSinceDate:previousPoint.date]) * 60.0 * 60.0;
		if (currentPoint.speedMile > newMaxSpeedMile) {
			newMaxSpeedMile = currentPoint.speedMile;
		}

		/// KM
		
		if ((NSInteger)newDistanceKM > [splitKM count]) {
			MNXPoint *pointAtLastSplit = [[splitKM lastObject] objectForKey:@"point"];
			if (!pointAtLastSplit) {
				pointAtLastSplit = [pointArray objectAtIndex:0];
			}
			NSMutableDictionary *split =[NSMutableDictionary dictionary];
			[split setObject:currentPoint forKey:@"point"];
			NSTimeInterval interval = [currentPoint.date timeIntervalSinceDate:pointAtLastSplit.date];
			[split setObject:[NSNumber numberWithDouble:interval] forKey:@"pace"];
			[split setObject:[NSNumber numberWithInt:(NSInteger)newDistanceKM] forKey:@"distance"];
			[splitKM addObject:split];
		}
		else if (i == [pointArray count] - 1 && ![splitKM count]) {
			MNXPoint *pointAtLastSplit = [[splitKM lastObject] objectForKey:@"point"];
			if (!pointAtLastSplit) {
				pointAtLastSplit = [pointArray objectAtIndex:0];
			}			
			NSMutableDictionary *split =[NSMutableDictionary dictionary];
			[split setObject:currentPoint forKey:@"point"];
			NSTimeInterval interval = [currentPoint.date timeIntervalSinceDate:pointAtLastSplit.date];
			[split setObject:[NSNumber numberWithDouble:interval] forKey:@"pace"];
			[split setObject:[NSNumber numberWithFloat:(CGFloat)newDistanceKM] forKey:@"distance"];			
			[splitKM addObject:split];
		}
		
		/// Mile
		
		if ((NSInteger)newDistanceMile > [splitMile count]) {
			MNXPoint *pointAtLastSplit = [[splitMile lastObject] objectForKey:@"point"];
			if (!pointAtLastSplit) {
				pointAtLastSplit = [pointArray objectAtIndex:0];
			}
			NSMutableDictionary *split =[NSMutableDictionary dictionary];
			[split setObject:currentPoint forKey:@"point"];
			NSTimeInterval interval = [currentPoint.date timeIntervalSinceDate:pointAtLastSplit.date];
			[split setObject:[NSNumber numberWithDouble:interval] forKey:@"pace"];
			[split setObject:[NSNumber numberWithInt:(NSInteger)newDistanceMile] forKey:@"distance"];
			[splitMile addObject:split];
		}
		else if (i == [pointArray count] - 1 && ![splitMile count]) {
			MNXPoint *pointAtLastSplit = [[splitMile lastObject] objectForKey:@"point"];
			if (!pointAtLastSplit) {
				pointAtLastSplit = [pointArray objectAtIndex:0];
			}			
			NSMutableDictionary *split =[NSMutableDictionary dictionary];
			[split setObject:currentPoint forKey:@"point"];
			NSTimeInterval interval = [currentPoint.date timeIntervalSinceDate:pointAtLastSplit.date];
			[split setObject:[NSNumber numberWithDouble:interval] forKey:@"pace"];
			[split setObject:[NSNumber numberWithFloat:(CGFloat)newDistanceMile] forKey:@"distance"];			
			[splitMile addObject:split];
		}
	}
	
	MNXPoint *firstPoint = [pointArray objectAtIndex:0];
	MNXPoint *lastPoint = [pointArray lastObject];
	
	NSTimeInterval newDuration = [lastPoint.date timeIntervalSinceDate:firstPoint.date];
	duration = newDuration;
	
	totalDistanceKM = newDistanceKM;
	totalDistanceMile = newDistanceMile;

	if (newDistanceKM > 0.0) {
		averagePaceKM = newDuration / newDistanceKM;
	}

	if (newDistanceMile > 0.0) {
		averagePaceMile = newDuration / newDistanceMile;
	}
	
	if (newDuration) {
		averageSpeedKM = (newDistanceKM / newDuration) * 60.0 * 60.0;
		averageSpeedMile = (newDistanceMile / newDuration) * 60.0 * 60.0;
	}
	maxSpeedKM = newMaxSpeedKM;
	maxSpeedMile = newMaxSpeedMile;
}

- (NSArray *)points
{
	return pointArray;
}

@synthesize splitKM;
@synthesize splitMile;
@synthesize duration;

@synthesize totalDistanceKM;
@synthesize averagePaceKM;
@synthesize averageSpeedKM;
@synthesize maxSpeedKM;

@synthesize totalDistanceMile;
@synthesize averagePaceMile;
@synthesize averageSpeedMile;
@synthesize maxSpeedMile;

@end
