#import "MNXTrack.h"
#import "MNXPoint.h"

@implementation MNXTrack

- (void)dealloc
{
	[pointArray release];
	[super dealloc];
}

- (id)init
{
	self = [super init];
	if (self != nil) {
		pointArray = [[NSMutableArray alloc] init];
	}
	return self;
}

- (NSString *)title
{
	return nil;
}

- (NSData *)GPXData
{
	NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
	[formatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en"] autorelease]];
	[formatter setDateFormat:@"yyyy-MM-dd'T'hh:mm:ssZ"];
	
	NSXMLElement *root = (NSXMLElement *)[NSXMLNode elementWithName:@"gpx"];
	[root addNamespace:[NSXMLNode namespaceWithName:@"xsi" stringValue:@"http://www.w3.org/2001/XMLSchema-instance"]];
	[root addAttribute:[NSXMLNode attributeWithName:@"xsi:schemaLocation" stringValue:@"http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd"]];
	[root addAttribute:[NSXMLNode attributeWithName:@"version" stringValue:@"1.1"]];
	[root addAttribute:[NSXMLNode attributeWithName:@"creator" stringValue:@"MNX"]];
	
	NSXMLDocument *xml = [[[NSXMLDocument alloc] initWithRootElement:root] autorelease];
	[xml setVersion:@"1.0"];
	[xml setCharacterEncoding:@"UTF-8"];
	NSXMLElement *trk = (NSXMLElement *)[NSXMLNode elementWithName:@"trk"];
	[root addChild:trk];
	NSXMLElement *name = (NSXMLElement *)[NSXMLNode elementWithName:@"name" stringValue:@"Track"];
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
		[trkpt addAttribute:lon];
		[trkpt addAttribute:lat];
		[trkseg addChild:trkpt];
	}
	[trk addChild:trkseg];
	NSData *data = [xml XMLData];
	[data writeToFile:@"/tmp/a.gpx" atomically:YES];
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
	strokeColor: '#000000',\n\
	strokeOpacity: 1.0,\n\
	strokeWeight: 3\n\
	}\n\
	poly = new google.maps.Polyline(polyOptions);\n\
	poly.setMap(map);\n\
	%@\n\
	}\n\
	</script>\
	<style type=\"text/css\" media=\"screen\">\n\
	#map {\n\
		width: 100%;\n\
		min-height: 500px;\n\
		height: 100%;\n\
	}\n\
	body {\n\
	width: 100%;\n\
	min-height: 500px;\n\
	height: 100%;\n\
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
		[addLineString appendFormat:@"poly.getPath().push(new google.maps.LatLng(%f, %f));\n", point.latitude, point.longitude];
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
	
	NSString *HTML = [NSString stringWithFormat:template, (bottom + (top - bottom) / 2.0),
					  (right + (left - right) / 2.0),
					  addLineString];
	return HTML;
}


- (void)setPoints:(NSArray *)inPoints
{
	[pointArray setArray:inPoints];
}

- (NSArray *)points
{
	return [[pointArray copy] autorelease];
}

@end
