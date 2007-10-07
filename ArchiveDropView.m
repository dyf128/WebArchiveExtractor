//
//  Apple Public Source License
//  http://www.opensource.apple.com/apsl/
//
//  Created by Vitaly Davidenko on 12/10/06.
//  Copyright 2006 Vitaly Davidenko.
//
//	Updated and refactored by Rob Rohan on 2007-09-18

#import "ArchiveDropView.h"
#import "Extractor.h"

static void logMessage(NSTextView* log, NSColor* color, NSString* message)
{
	[log setEditable:YES];
	
	NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary: [log typingAttributes]];
	[dict setValue:color forKey:NSForegroundColorAttributeName];
	[log setTypingAttributes:dict];
	[log insertText: message ];
	[log insertText: @"\n" ];
	[log setEditable:NO];
	[log displayIfNeeded];
}

@implementation ArchiveDropView

- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect]) != nil) {
		// Add initialization code here
		[self registerForDraggedTypes:[NSArray arrayWithObjects: NSFilenamesPboardType, nil]];
		
		//set the drop target image
		NSImage *newImage = [[NSImage alloc] initByReferencingFile:[[NSBundle mainBundle] pathForImageResource:@"extract_archive.png"]];
		[self setImage:newImage];
		[newImage release];
	}
	return self;
}

- (void)drawRect:(NSRect)rect
{
	NSRect ourBounds = [self bounds];
    NSImage *image = [self image];
    [super drawRect:rect];
    [image compositeToPoint:(ourBounds.origin) operation:NSCompositeSourceOver];
}

- (void)setImage:(NSImage *)newImage
{
    NSImage *temp = [newImage retain];
    [_dropImage release];
    _dropImage = temp;
}

- (NSImage *)image
{
    return _dropImage;
}

////////////////////////////////////////////////////////////////

- (void)logError:(NSString*) message
{
	logMessage(logOutput, [NSColor redColor], message);
}

- (void)logWarning:(NSString*) message
{
	logMessage(logOutput, [NSColor orangeColor], message);
}

- (void)logInfo:(NSString*) message
{
	logMessage(logOutput, [NSColor blueColor], message);
}

- (void)logResult:(NSString*) message
{
	logMessage(logOutput, [NSColor darkGrayColor], message);
}


- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	[logOutput selectAll:self];
	[logOutput insertText:@""];
    NSPasteboard *pboard = [sender draggingPasteboard];
	
	NSString * indexFileName = [[userDefaults values] valueForKey:@"WAEIndexName"];
	if (indexFileName == nil || [indexFileName length] == 0) {
		indexFileName = @"index.html";
	}
	
	NSLog(@"%@", indexFileName);
	
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        int numberOfFiles = [files count];
		NSLog(@"%i\n", numberOfFiles);
		int i;
		for (i=0; i<numberOfFiles; i++)
		{
			NSString* fileName = [files objectAtIndex:i];
			[self logInfo:[NSString stringWithFormat:@"Processing %@...", fileName] ];
			
			if ([fileName hasSuffix:@"webarchive"])
			{
				NSFileManager * fm = [NSFileManager defaultManager];
				NSString * dirPath = [fileName stringByDeletingLastPathComponent];
				
				if ([fm isWritableFileAtPath:dirPath])
				{
					NSString * archiveName = [[fileName lastPathComponent] stringByDeletingPathExtension];
					NSString * outputPath  =  [dirPath stringByAppendingPathComponent: archiveName];
					
					int i = 0;
					while([fm fileExistsAtPath:outputPath])
					{
						[self logWarning:[NSString stringWithFormat:@"\tFolder %@ already exists", outputPath] ];
						NSString * dirName = [archiveName stringByAppendingString:@"-%i"]; 
						outputPath  = [dirPath stringByAppendingPathComponent: [NSString stringWithFormat: dirName, i++]];
					}
					
					Extractor * extr = [[[Extractor alloc] autorelease ] init];
					[extr loadWebArchive: fileName];
					NSString * mainResourcePath = [extr extractResources: outputPath indexName: indexFileName ];
					
					[self logResult:[NSString stringWithFormat: @"\tExtracted into %@.\n\tMain resource: %@",outputPath ,mainResourcePath]];
					
				}
			}
			else
			{
				[self logError:@"\tNot Web Archive"];
			}
		}
    }
    return YES;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
	
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
	
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
		/*
		 if (sourceDragMask & NSDragOperationLink) {
			 return NSDragOperationLink;
		 } else if (sourceDragMask & NSDragOperationCopy) {
			 return NSDragOperationCopy;
		 }
		 */
		return NSDragOperationCopy;
    }
    return NSDragOperationNone;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {}

- (void)draggingEnded:(id <NSDraggingInfo>)sender {}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    return YES;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
	//[self setNeedsDisplay:YES];
}

@end
