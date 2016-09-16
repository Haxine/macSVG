//
//  PathElementPlugin.m
//  PathElementPlugin
//
//  Created by Douglas Ward on 3/2/12.
//  Copyright © 2016 ArkPhone LLC. All rights reserved.
//

#import "PathElementEditor.h"
#import "MacSVGPlugin/MacSVGPluginCallbacks.h"
#import <WebKit/WebKit.h>
#import "PathSegmentEditorPopoverViewController.h"
#import "ArcSettingsPopoverViewController.h"
#import "MacSVGDocumentWindowController.h"
#import "SVGXMLDOMSelectionManager.h"
#import "DOMSelectionRectsAndHandlesManager.h"
#import "PathElementEditorFunctions.h"
#import "DOMMouseEventsController.h"
#import "SVGWebKitController.h"
#import "SVGPathEditor.h"

#define PathTableViewDataType @"NSMutableDictionary"

/* pathSegmentDictionary
{
    absoluteStartX = 486;
    absoluteStartY = 320;
    absoluteX = 366;
    absoluteX1 = 487;
    absoluteX2 = 461;
    absoluteY = 529;
    absoluteY1 = 394;
    absoluteY2 = 507;
    command = C;
    x = 366;
    x1 = 487;
    x2 = 461;
    y = 529;
    y1 = 394;
    y2 = 507;
}
*/

@implementation PathElementEditor

//==================================================================================
//	init
//==================================================================================

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        self.parametersMoveto = [[NSArray alloc] initWithObjects:@"x", @"y", NULL];
        self.parametersLineto = [[NSArray alloc] initWithObjects:@"x", @"y", NULL];
        self.parametersHorizontalLineto = [[NSArray alloc] initWithObjects:@"x", NULL];
        self.parametersVerticalLineto = [[NSArray alloc] initWithObjects:@"y", NULL];
        self.parametersCubicCurveto = [[NSArray alloc] initWithObjects:@"x1", @"y1", @"x2", @"y2", @"x", @"y", NULL];
        self.parametersCubicCurvetoSmooth = [[NSArray alloc] initWithObjects:@"x2", @"y2", @"x", @"y", NULL];
        self.parametersQuadraticCurveto = [[NSArray alloc] initWithObjects:@"x1", @"y1", @"x", @"y", NULL];
        self.parametersQuadraticCurvetoSmooth = [[NSArray alloc] initWithObjects:@"x", @"y", NULL];
        self.parametersEllipticalArc = [[NSArray alloc] initWithObjects:@"rx", @"ry", @"x-axis-rotation", @"large-arc-flag", @"sweep-flag", @"x", @"y", NULL];
        self.parametersClosepath = [[NSArray alloc] init];
    }
    
    return self;
}

//==================================================================================
//	dealloc
//==================================================================================

- (void)dealloc
{
    self.parametersMoveto = NULL;
    self.parametersLineto = NULL;
    self.parametersHorizontalLineto = NULL;
    self.parametersVerticalLineto = NULL;
    self.parametersCubicCurveto = NULL;
    self.parametersCubicCurvetoSmooth = NULL;
    self.parametersQuadraticCurveto = NULL;
    self.parametersQuadraticCurvetoSmooth = NULL;
    self.parametersEllipticalArc = NULL;
    self.parametersClosepath = NULL;

    self.pathFunctionsPopupButton = NULL;

    self.pathFunctionLabel1 = NULL;
    self.pathFunctionLabel2 = NULL;
    self.pathFunctionLabel3 = NULL;
    self.pathFunctionValue1 = NULL;
    self.pathFunctionValue2 = NULL;
    self.pathFunctionValue3 = NULL;
}

//==================================================================================
//	awakeFromNib
//==================================================================================

- (void)awakeFromNib 
{
    [super awakeFromNib];

    [self.pathTableView registerForDraggedTypes:[NSArray arrayWithObject:PathTableViewDataType]];

    [self.pathFunctions setInputFieldsForFunction];
}

//==================================================================================
//	pluginName
//==================================================================================

- (NSString *)pluginName
{
    return @"Path Element Editor";
}

//==================================================================================
//	isEditorForElement:elementName:
//==================================================================================

// return label if this editor can edit specified element tag name
- (NSString *)isEditorForElement:(NSXMLElement *)aElement elementName:(NSString *)elementName
{
    NSString * result = NULL;

    if ([elementName isEqualToString:@"path"] == YES)
    {
        result = [self pluginName];
    }

    return result;
}

//==================================================================================
//	isEditorForElement:elementName:attribute:
//==================================================================================

// return label if this editor can edit specified element and attribute
- (NSString *)isEditorForElement:(NSXMLElement *)aElement elementName:(NSString *)elementName attribute:(NSString *)attributeName
{   
    NSString * result = NULL;
    
    return result;
}

//==================================================================================
//	editorPriority:context:
//==================================================================================

- (NSInteger)editorPriority:(NSXMLElement *)targetElement context:(NSString *)context
{
    return 30;
}

//==================================================================================
//	unloadPluginView
//==================================================================================

- (void)unloadPluginView
{

}

//==================================================================================
//	updateEditForXMLElement:domElement:info:
//==================================================================================

- (void)updateEditForXMLElement:(NSXMLElement *)xmlElement domElement:(DOMElement *)domElement info:(id)infoData
{
    // subclasses can override as needed
    
    NSArray * aPathSegmentArray = infoData;
    #pragma unused(aPathSegmentArray)
    
    [self.pathTableView reloadData];

    [self updateTotalLengthForPathElement:xmlElement];
}

//==================================================================================
//	selectedPathMode
//==================================================================================

- (NSString *) selectedPathMode
{
    NSString * result = [pathModePopupButton titleOfSelectedItem];
    return result;
}

//==================================================================================
//	updateSVGPathEditorAction:
//==================================================================================

- (IBAction)updateSVGPathEditorAction:(id)sender
{
    NSString * newPathMode = [pathModePopupButton titleOfSelectedItem];
    [self.macSVGPluginCallbacks setSelectedPathMode:newPathMode];

    NSInteger useRelativePathCoordinatesCheckboxState =
            [useRelativePathCoordinatesButton state];
    if (useRelativePathCoordinatesCheckboxState == 0)
    {
        [self.macSVGPluginCallbacks setUseRelativePathCoordinates:NO];
    }
    else
    {
        [self.macSVGPluginCallbacks setUseRelativePathCoordinates:YES];
    }

    NSInteger closePathAutomaticallyCheckboxState =
            [closePathAutomaticallyCheckbox state];
    if (closePathAutomaticallyCheckboxState == 0)
    {
        [self.macSVGPluginCallbacks setClosePathAutomatically:NO];
    }
    else
    {
        [self.macSVGPluginCallbacks setClosePathAutomatically:YES];
    }

    NSInteger curveSegmentContinuityCheckboxState =
            [curveSegmentContinuityCheckbox state];
    if (curveSegmentContinuityCheckboxState == 0)
    {
        [self.macSVGPluginCallbacks setCurveSegmentContinuity:NO];
    }
    else
    {
        [self.macSVGPluginCallbacks setCurveSegmentContinuity:YES];
    }
    
    NSInteger pathLargeArcValue = [self.arcSettingsPopoverViewController.pathLargeArcCheckbox state];
    if (pathLargeArcValue == 0)
    {
        [self.macSVGPluginCallbacks setLargeArcFlagString:@"0"];
    }
    else
    {
        [self.macSVGPluginCallbacks setLargeArcFlagString:@"1"];
    }
    
    NSInteger pathSweepFlagValue = [self.arcSettingsPopoverViewController.pathSweepCheckbox state];
    if (pathSweepFlagValue == 0)
    {
        [self.macSVGPluginCallbacks setSweepFlagString:@"0"];
    }
    else
    {
        [self.macSVGPluginCallbacks setSweepFlagString:@"1"];
    }
    
    NSString * xAxisRotationString = [self.arcSettingsPopoverViewController.xAxisRotationTextField stringValue];
    [self.macSVGPluginCallbacks setXAxisRotationString:xAxisRotationString];
    
    NSString * pathRadiusXString = [self.arcSettingsPopoverViewController.pathRadiusXTextField stringValue];
    [self.macSVGPluginCallbacks setPathRadiusXString:pathRadiusXString];
    
    NSString * pathRadiusYString = [self.arcSettingsPopoverViewController.pathRadiusYTextField stringValue];
    [self.macSVGPluginCallbacks setPathRadiusYString:pathRadiusYString];

    [self.macSVGPluginCallbacks restartLastPathSegment];
}

//==================================================================================
//	updateWithPathSegmentsArray:
//==================================================================================

- (void)updateWithPathSegmentsArray:(NSMutableArray *)aPathSegmentsArray
{
    NSXMLElement * holdSelectedPathElement = [self.macSVGPluginCallbacks svgPathEditorSelectedPathElement];

    [self.macSVGPluginCallbacks svgPathEditorSetSelectedPathElement:self.pluginTargetXMLElement];
    
    [self.macSVGPluginCallbacks setPathSegmentsArray:aPathSegmentsArray];

    [self.macSVGPluginCallbacks updateSelectedPathInDOM];

    [self.macSVGPluginCallbacks svgPathEditorSetSelectedPathElement:holdSelectedPathElement];
    
    [self updateTotalLengthForPathElement:self.pluginTargetXMLElement];
}

//==================================================================================
//  updateTotalLengthForPathElement
//==================================================================================

- (void)updateTotalLengthForPathElement:(NSXMLElement *)pathElement
{
    //NSXMLElement * selectedPathElement = [self.macSVGPluginCallbacks svgPathEditorSelectedPathElement];

    if (pathElement != NULL)
    {
        NSXMLNode * pathIDAttributeNode = [pathElement attributeForName:@"id"];
        if (pathIDAttributeNode != NULL)
        {
            NSString * pathIDAttributeString = [pathIDAttributeNode stringValue];
            
            NSString * pathLengthFunction = [NSString stringWithFormat:
                    @"function f() {var path = document.getElementById('%@'); return path.getTotalLength();} f();",
                    pathIDAttributeString];

            NSString * totalLengthString = [self.svgWebView stringByEvaluatingJavaScriptFromString:pathLengthFunction];
            
            float totalStringFloat = [totalLengthString floatValue];
            
            if (totalStringFloat == 0.0f)
            {
                totalLengthString = @"0";
            }
            else
            {
                totalLengthString = [NSString stringWithFormat:@"%.2f", totalStringFloat];
            }

            [self.pathLengthTextField setStringValue:totalLengthString];
        }
    }
    else
    {
        [self.pathLengthTextField setStringValue:@"0"];
    }
}


//==================================================================================
//	closePathNowButtonAction:
//==================================================================================

- (IBAction)closePathNowButtonAction:(id)sender
{
    NSXMLNode * pathAttributeNode = [self.pluginTargetXMLElement attributeForName:@"d"];
    NSString * pathAttributeString = [pathAttributeNode stringValue];
    
    BOOL useRelativePathCoordinates = [self.macSVGPluginCallbacks useRelativePathCoordinates];
    
    NSMutableDictionary * closePathDictionary = [NSMutableDictionary dictionary];
    
    if (useRelativePathCoordinates == YES)
    {
        [closePathDictionary setObject:@"z" forKey:@"command"];
    }
    else
    {
        [closePathDictionary setObject:@"Z" forKey:@"command"];
    }

    NSMutableArray * pathSegmentsArray = [self.macSVGPluginCallbacks buildPathSegmentsArrayWithPathString:pathAttributeString];
    
    NSInteger pathSegmentsArrayCount = [pathSegmentsArray count];
    
    NSInteger lastSegmentIndex = pathSegmentsArrayCount;
    
    [pathSegmentsArray insertObject:closePathDictionary atIndex:lastSegmentIndex];

    [self.macSVGPluginCallbacks updatePathSegmentsAbsoluteValues:pathSegmentsArray];
    
    [self updateWithPathSegmentsArray:pathSegmentsArray];
    
    [self updateDocumentViews];
    
    [self.macSVGPluginCallbacks restartLastPathSegment];
}

// -------------------------------------------------------------------------------
//  arcSettingsButtonAction:
// -------------------------------------------------------------------------------

- (IBAction)arcSettingsButtonAction:(id)sender
{
    NSButton *targetButton = (NSButton *)sender;

    // configure the preferred position of the popover
    [arcSettingsPopover showRelativeToRect:[targetButton bounds] ofView:sender preferredEdge:NSMaxYEdge];
}


//==================================================================================
//	loadSettingsForElement
//==================================================================================

- (void) loadSettingsForElement
{
    NSString * selectedPathMode = [self.macSVGPluginCallbacks selectedPathMode];
    
    BOOL useRelativePathCoordinates = [self.macSVGPluginCallbacks useRelativePathCoordinates];
    
    BOOL closePathAutomatically = [self.macSVGPluginCallbacks closePathAutomatically];

    NSString * largeArcFlagString = [self.macSVGPluginCallbacks largeArcFlagString];
    
    NSString * sweepFlagString = [self.macSVGPluginCallbacks sweepFlagString];
    
    NSString * xAxisRotationString = [self.macSVGPluginCallbacks xAxisRotationString];
    
    NSString * pathRadiusXString = [self.macSVGPluginCallbacks pathRadiusXString];
    
    NSString * pathRadiusYString = [self.macSVGPluginCallbacks pathRadiusYString];
    
    [pathModePopupButton selectItemWithTitle:selectedPathMode];
    
    [useRelativePathCoordinatesButton setState:useRelativePathCoordinates];
    [closePathAutomaticallyCheckbox setState:closePathAutomatically];
    
    if ([largeArcFlagString isEqualToString:@"1"] == YES)
    {
        [self.arcSettingsPopoverViewController.pathLargeArcCheckbox setState:YES];
    }
    else
    {
        [self.arcSettingsPopoverViewController.pathLargeArcCheckbox setState:NO];
    }
    
    if ([sweepFlagString isEqualToString:@"1"] == YES)
    {
        [self.arcSettingsPopoverViewController.pathSweepCheckbox setState:YES];
    }
    else
    {
        [self.arcSettingsPopoverViewController.pathSweepCheckbox setState:NO];
    }
    
    if ([sweepFlagString isEqualToString:@"1"] == YES)
    {
        [self.arcSettingsPopoverViewController.pathSweepCheckbox setState:YES];
    }
    else
    {
        [self.arcSettingsPopoverViewController.pathSweepCheckbox setState:NO];
    }
    
    [self.arcSettingsPopoverViewController.xAxisRotationTextField setStringValue:xAxisRotationString];
    [self.arcSettingsPopoverViewController.pathRadiusXTextField setStringValue:pathRadiusXString];
    [self.arcSettingsPopoverViewController.pathRadiusYTextField setStringValue:pathRadiusYString];

    NSXMLNode * pathAttributeNode = [self.pluginTargetXMLElement attributeForName:@"d"];
    NSString * pathAttributeString = [pathAttributeNode stringValue];

    NSMutableArray * pathSegmentsArray = [self.macSVGPluginCallbacks buildPathSegmentsArrayWithPathString:pathAttributeString];

    [self.macSVGPluginCallbacks updatePathSegmentsAbsoluteValues:pathSegmentsArray];
    
    [self updateWithPathSegmentsArray:pathSegmentsArray];
    
    [self.pathTableView reloadData];
    
    NSInteger rowIndex = [self.pathTableView selectedRow];

    if (rowIndex >= 0)
    {
        pathSegmentsArray = [self pathSegmentsArray];

        NSMutableDictionary * pathSegmentDictionary = [pathSegmentsArray objectAtIndex:rowIndex];
            
        if (pathSegmentDictionary != NULL)
        {
            [self.pathSegmentEditorPopoverViewController loadPathSegmentData:pathSegmentDictionary];
        }
    }

    [self updateTotalLengthForPathElement:self.pluginTargetXMLElement];
}

//==================================================================================
//	beginEditForXMLElement:domElement:attributeName:existingValue:
//==================================================================================

- (BOOL)beginEditForXMLElement:(NSXMLElement *)newPluginTargetXMLElement
        domElement:(DOMElement *)newPluginTargetDOMElement
        attributeName:(NSString *)newAttributeName
        existingValue:(NSString *)existingValue
{
    BOOL result = [super beginEditForXMLElement:newPluginTargetXMLElement
            domElement:newPluginTargetDOMElement
            attributeName:newAttributeName 
            existingValue:existingValue];
            
    [self loadSettingsForElement];

    return result;
}

//==================================================================================
//	beginEditForXMLElement:domElement:nodeKind:
//==================================================================================

- (BOOL)beginEditForXMLElement:(NSXMLElement *)newPluginTargetXMLElement
        domElement:(DOMElement *)newPluginTargetDOMElement
{
    BOOL result = [super beginEditForXMLElement:newPluginTargetXMLElement
            domElement:newPluginTargetDOMElement];

    [self loadSettingsForElement];
            
    return result;
}

//==================================================================================
//	performPathFunctionButtonAction:
//==================================================================================

- (IBAction)performPathFunctionButtonAction:(id)sender
{
    [self.macSVGPluginCallbacks pushUndoRedoDocumentChanges];
    
    [self.pathFunctions performPathFunction];
}

//==================================================================================
//	pathFunctionPopUpButtonAction:
//==================================================================================

- (IBAction)pathFunctionPopUpButtonAction:(id)sender
{
    [self.pathFunctions setInputFieldsForFunction];
}

//==================================================================================
//	numberOfRowsInTableView
//==================================================================================

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    NSMutableArray * pathSegmentsArray = [self pathSegmentsArray];
    return [pathSegmentsArray count];
}

//==================================================================================
//	tableView:objectValueForTableColumn:rowIndex
//==================================================================================

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    NSString *  objectValue = NULL;
    
    NSMutableArray * pathSegmentsArray = [self pathSegmentsArray];
    
    NSInteger pathSegmentsArrayCount = [pathSegmentsArray count];
    
    if (rowIndex < pathSegmentsArrayCount)
    {
        NSDictionary * pathSegmentDictionary = [pathSegmentsArray objectAtIndex:rowIndex];

        
        if ([[aTableColumn identifier] isEqualToString:@"segmentIndex"] == YES)
        {
            objectValue = [NSString stringWithFormat:@"%ld", (rowIndex + 1)];
        }
        else if ([[aTableColumn identifier] isEqualToString:@"segmentCommand"] == YES)
        {
            if (pathSegmentDictionary != NULL)
            {
                NSString * segmentCommand = segmentCommand = [pathSegmentDictionary objectForKey:@"command"];

               if ([segmentCommand isEqualToString:@"M"] == YES) 
                {
                    objectValue = @"Moveto";
                }
                else if ([segmentCommand isEqualToString:@"m"] == YES) 
                {
                    objectValue = @"Moveto Relative";
                }
                else if ([segmentCommand isEqualToString:@"L"] == YES) 
                {
                    objectValue = @"Lineto";
                }
                else if ([segmentCommand isEqualToString:@"l"] == YES) 
                {
                    objectValue = @"Lineto Relative";
                }
                else if ([segmentCommand isEqualToString:@"H"] == YES) 
                {
                    objectValue = @"Horizontal Lineto";
                }
                else if ([segmentCommand isEqualToString:@"h"] == YES) 
                {
                    objectValue = @"Horizontal Lineto Relative";
                }
                else if ([segmentCommand isEqualToString:@"V"] == YES) 
                {
                    objectValue = @"Vertical Lineto";
                }
                else if ([segmentCommand isEqualToString:@"v"] == YES) 
                {
                    objectValue = @"Vertical Lineto Relative";
                }
                else if ([segmentCommand isEqualToString:@"C"] == YES) 
                {
                    objectValue = @"Cubic Curveto";
                }
                else if ([segmentCommand isEqualToString:@"c"] == YES) 
                {
                    objectValue = @"Cubic Curveto Relative";
                }
                else if ([segmentCommand isEqualToString:@"S"] == YES) 
                {
                    objectValue = @"Smooth Cubic Curveto";
                }
                else if ([segmentCommand isEqualToString:@"s"] == YES) 
                {
                    objectValue = @"Smooth Cubic Curveto Relative";
                }
                else if ([segmentCommand isEqualToString:@"Q"] == YES) 
                {
                    objectValue = @"Quadratic Curveto";
                }
                else if ([segmentCommand isEqualToString:@"q"] == YES) 
                {
                    objectValue = @"Quadratic Curveto Relative";
                }
                else if ([segmentCommand isEqualToString:@"T"] == YES) 
                {
                    objectValue = @"Smooth Quadratic Curveto";
                }
                else if ([segmentCommand isEqualToString:@"t"] == YES) 
                {
                    objectValue = @"Smooth Quadratic Curveto Relative";
                }
                else if ([segmentCommand isEqualToString:@"A"] == YES) 
                {
                    objectValue = @"Elliptical Arc";
                }
                else if ([segmentCommand isEqualToString:@"a"] == YES) 
                {
                    objectValue = @"Elliptical Arc Relative";
                }
                else if ([segmentCommand isEqualToString:@"Z"] == YES) 
                {
                    objectValue = @"Close Path";
                }
                else if ([segmentCommand isEqualToString:@"z"] == YES) 
                {
                    objectValue = @"Close Path Relative";
                }
            }
        }
        else if ([[aTableColumn identifier] isEqualToString:@"segmentData"] == YES)
        {
            if (pathSegmentDictionary != NULL)
            {
                NSString * segmentCommand = segmentCommand = [pathSegmentDictionary objectForKey:@"command"];
                
                NSString * segmentValues = @"";
                
                if ([segmentCommand isEqualToString:@"M"] == YES) 
                {
                    NSString * xString = [pathSegmentDictionary objectForKey:@"x"];
                    NSString * yString = [pathSegmentDictionary objectForKey:@"y"];
                    segmentValues = [NSString stringWithFormat:@"%@ %@",
                            xString, yString];
                }
                else if ([segmentCommand isEqualToString:@"m"] == YES) 
                {
                    NSString * xString = [pathSegmentDictionary objectForKey:@"x"];
                    NSString * yString = [pathSegmentDictionary objectForKey:@"y"];
                    segmentValues = [NSString stringWithFormat:@"%@ %@",
                            xString, yString];
                }
                else if ([segmentCommand isEqualToString:@"L"] == YES) 
                {
                    NSString * xString = [pathSegmentDictionary objectForKey:@"x"];
                    NSString * yString = [pathSegmentDictionary objectForKey:@"y"];
                    segmentValues = [NSString stringWithFormat:@"%@ %@",
                            xString, yString];
                }
                else if ([segmentCommand isEqualToString:@"l"] == YES) 
                {
                    NSString * xString = [pathSegmentDictionary objectForKey:@"x"];
                    NSString * yString = [pathSegmentDictionary objectForKey:@"y"];
                    segmentValues = [NSString stringWithFormat:@"%@ %@",
                            xString, yString];
                }
                else if ([segmentCommand isEqualToString:@"H"] == YES) 
                {
                    NSString * xString = [pathSegmentDictionary objectForKey:@"x"];
                    segmentValues = [NSString stringWithFormat:@"%@",
                            xString];
                }
                else if ([segmentCommand isEqualToString:@"h"] == YES) 
                {
                    NSString * xString = [pathSegmentDictionary objectForKey:@"x"];
                    segmentValues = [NSString stringWithFormat:@"%@",
                            xString];
                }
                else if ([segmentCommand isEqualToString:@"V"] == YES) 
                {
                    NSString * yString = [pathSegmentDictionary objectForKey:@"y"];
                    segmentValues = [NSString stringWithFormat:@"%@",
                            yString];
                }
                else if ([segmentCommand isEqualToString:@"v"] == YES) 
                {
                    NSString * yString = [pathSegmentDictionary objectForKey:@"y"];
                    segmentValues = [NSString stringWithFormat:@"%@",
                            yString];
                }
                else if ([segmentCommand isEqualToString:@"C"] == YES) 
                {
                    NSString * xString = [pathSegmentDictionary objectForKey:@"x"];
                    NSString * yString = [pathSegmentDictionary objectForKey:@"y"];
                    NSString * x1String = [pathSegmentDictionary objectForKey:@"x1"];
                    NSString * y1String = [pathSegmentDictionary objectForKey:@"y1"];
                    NSString * x2String = [pathSegmentDictionary objectForKey:@"x2"];
                    NSString * y2String = [pathSegmentDictionary objectForKey:@"y2"];
                    segmentValues = [NSString stringWithFormat:@"%@ %@ %@ %@ %@ %@",
                            x1String, y1String, x2String, y2String, xString, yString];
                }
                else if ([segmentCommand isEqualToString:@"c"] == YES) 
                {
                    NSString * xString = [pathSegmentDictionary objectForKey:@"x"];
                    NSString * yString = [pathSegmentDictionary objectForKey:@"y"];
                    NSString * x1String = [pathSegmentDictionary objectForKey:@"x1"];
                    NSString * y1String = [pathSegmentDictionary objectForKey:@"y1"];
                    NSString * x2String = [pathSegmentDictionary objectForKey:@"x2"];
                    NSString * y2String = [pathSegmentDictionary objectForKey:@"y2"];
                    segmentValues = [NSString stringWithFormat:@"%@ %@ %@ %@ %@ %@",
                            x1String, y1String, x2String, y2String, xString, yString];
                }
                else if ([segmentCommand isEqualToString:@"S"] == YES) 
                {
                    NSString * xString = [pathSegmentDictionary objectForKey:@"x"];
                    NSString * yString = [pathSegmentDictionary objectForKey:@"y"];
                    NSString * x2String = [pathSegmentDictionary objectForKey:@"x2"];
                    NSString * y2String = [pathSegmentDictionary objectForKey:@"y2"];
                    segmentValues = [NSString stringWithFormat:@"%@ %@ %@ %@",
                            x2String, y2String, xString, yString];
                }
                else if ([segmentCommand isEqualToString:@"s"] == YES) 
                {
                    NSString * xString = [pathSegmentDictionary objectForKey:@"x"];
                    NSString * yString = [pathSegmentDictionary objectForKey:@"y"];
                    NSString * x2String = [pathSegmentDictionary objectForKey:@"x2"];
                    NSString * y2String = [pathSegmentDictionary objectForKey:@"y2"];
                    segmentValues = [NSString stringWithFormat:@"%@ %@ %@ %@",
                            x2String, y2String, xString, yString];
                }
                else if ([segmentCommand isEqualToString:@"Q"] == YES) 
                {
                    NSString * xString = [pathSegmentDictionary objectForKey:@"x"];
                    NSString * yString = [pathSegmentDictionary objectForKey:@"y"];
                    NSString * x1String = [pathSegmentDictionary objectForKey:@"x1"];
                    NSString * y1String = [pathSegmentDictionary objectForKey:@"y1"];
                    segmentValues = [NSString stringWithFormat:@"%@ %@ %@ %@",
                            x1String, y1String, xString, yString];
                }
                else if ([segmentCommand isEqualToString:@"q"] == YES) 
                {
                    NSString * xString = [pathSegmentDictionary objectForKey:@"x"];
                    NSString * yString = [pathSegmentDictionary objectForKey:@"y"];
                    NSString * x1String = [pathSegmentDictionary objectForKey:@"x1"];
                    NSString * y1String = [pathSegmentDictionary objectForKey:@"y1"];
                    segmentValues = [NSString stringWithFormat:@"%@ %@ %@ %@",
                            x1String, y1String, xString, yString];
                }
                else if ([segmentCommand isEqualToString:@"T"] == YES) 
                {
                    NSString * xString = [pathSegmentDictionary objectForKey:@"x"];
                    NSString * yString = [pathSegmentDictionary objectForKey:@"y"];
                    segmentValues = [NSString stringWithFormat:@"%@ %@",
                            xString, yString];
                }
                else if ([segmentCommand isEqualToString:@"t"] == YES) 
                {
                    NSString * xString = [pathSegmentDictionary objectForKey:@"x"];
                    NSString * yString = [pathSegmentDictionary objectForKey:@"y"];
                    segmentValues = [NSString stringWithFormat:@"%@ %@",
                            xString, yString];
                }
                else if ([segmentCommand isEqualToString:@"A"] == YES) 
                {
                    NSString * rxString = [pathSegmentDictionary objectForKey:@"rx"];
                    NSString * ryString = [pathSegmentDictionary objectForKey:@"ry"];
                    NSString * xAxisRotationString = [pathSegmentDictionary objectForKey:@"x-axis-rotation"];
                    NSString * largeArcFlagString = [pathSegmentDictionary objectForKey:@"large-arc-flag"];
                    NSString * sweepFlagString = [pathSegmentDictionary objectForKey:@"sweep-flag"];
                    NSString * xString = [pathSegmentDictionary objectForKey:@"x"];
                    NSString * yString = [pathSegmentDictionary objectForKey:@"y"];
                    segmentValues = [NSString stringWithFormat:@"%@ %@ %@ %@ %@ %@ %@",
                            rxString, ryString, xAxisRotationString, largeArcFlagString, sweepFlagString, xString, yString];
                }
                else if ([segmentCommand isEqualToString:@"a"] == YES) 
                {
                    NSString * rxString = [pathSegmentDictionary objectForKey:@"rx"];
                    NSString * ryString = [pathSegmentDictionary objectForKey:@"ry"];
                    NSString * xAxisRotationString = [pathSegmentDictionary objectForKey:@"x-axis-rotation"];
                    NSString * largeArcFlagString = [pathSegmentDictionary objectForKey:@"large-arc-flag"];
                    NSString * sweepFlagString = [pathSegmentDictionary objectForKey:@"sweep-flag"];
                    NSString * xString = [pathSegmentDictionary objectForKey:@"x"];
                    NSString * yString = [pathSegmentDictionary objectForKey:@"y"];
                    segmentValues = [NSString stringWithFormat:@"%@ %@ %@ %@ %@ %@ %@",
                            rxString, ryString, xAxisRotationString, largeArcFlagString, sweepFlagString, xString, yString];
                }
                else if ([segmentCommand isEqualToString:@"Z"] == YES) 
                {
                    segmentValues = @"";
                }
                else if ([segmentCommand isEqualToString:@"z"] == YES) 
                {
                    segmentValues = @"";
                }
                
                objectValue = [NSString stringWithFormat:@"%@ %@", segmentCommand, segmentValues];
            } 
        }
    }
    
    return objectValue;
}

//==================================================================================
//	tableViewSelectionDidChange:
//==================================================================================

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	id aTableView = [aNotification object];
	if (aTableView == self.pathTableView)
	{
        [self refreshSelectedRow];
    }
}

//==================================================================================
//	refreshSelectedRow
//==================================================================================

- (void)refreshSelectedRow
{
    NSInteger rowIndex = [self.pathTableView selectedRow];

    MacSVGDocumentWindowController * macSVGDocumentWindowController =
            [self.macSVGDocument macSVGDocumentWindowController];

    DOMSelectionRectsAndHandlesManager * domSelectionRectsAndHandlesManager =
            macSVGDocumentWindowController.svgXMLDOMSelectionManager.domSelectionRectsAndHandlesManager;
    
    id svgWebKitController = [macSVGDocumentWindowController svgWebKitController];
    id domMouseEventsController = [svgWebKitController domMouseEventsController];
    SVGPathEditor * svgPathEditor = [domMouseEventsController svgPathEditor];
    
    if (rowIndex >= 0)
    {
        if (highlightSelectedSegmentCheckbox.state == YES)
        {
            NSMutableArray * pathSegmentsArray = [self pathSegmentsArray];

            NSMutableDictionary * pathSegmentDictionary = [pathSegmentsArray objectAtIndex:rowIndex];
                
            if (pathSegmentDictionary != NULL)
            {
                [self.pathSegmentEditorPopoverViewController loadPathSegmentData:pathSegmentDictionary];
            }

            //domSelectionRectsAndHandlesManager.pathSegmentIndex = rowIndex;
            svgPathEditor.pathSegmentIndex = rowIndex;
            domSelectionRectsAndHandlesManager.segmentStrokeWidth =
                    [highlightStrokeWidthTextField.stringValue floatValue];
            domSelectionRectsAndHandlesManager.segmentStrokeHexColor =
                    [self hexColorFromColorWell:highlightColorWell];

            [self highlightPathSegment];
        }
        else
        {
            [self removeHighlightPathSegment];
        }
    }
    else
    {
        svgPathEditor.pathSegmentIndex = -1;
        
        [self removeHighlightPathSegment];
    }
}

// -------------------------------------------------------------------------------
//  editPathSegmentButtonAction:
// -------------------------------------------------------------------------------

- (IBAction)editPathSegmentButtonAction:(id)sender
{
    self.pathSegmentEditorMode = kEditPathSegment;

    NSButton *targetButton = (NSButton *)sender;

    NSInteger rowIndex = [self.pathTableView selectedRow];

    NSMutableArray * pathSegmentsArray = [self pathSegmentsArray];

    NSMutableDictionary * pathSegmentDictionary = [pathSegmentsArray objectAtIndex:rowIndex];
    
    [self.pathSegmentEditorPopoverViewController loadPathSegmentData:pathSegmentDictionary];
    
    [self.pathSegmentEditorPopoverViewController.applyButton setTitle:@"Apply"];
    
    // configure the preferred position of the popover
    [pathSegmentEditorPopover showRelativeToRect:[targetButton bounds] ofView:sender preferredEdge:NSMaxYEdge];
}

// -------------------------------------------------------------------------------
//  addPathSegmentButtonAction:
// -------------------------------------------------------------------------------

- (IBAction)addPathSegmentButtonAction:(id)sender
{
    self.pathSegmentEditorMode = kAddPathSegment;

    NSButton *targetButton = (NSButton *)sender;

    NSInteger rowIndex = [self.pathTableView selectedRow];

    NSMutableArray * pathSegmentsArray = [self pathSegmentsArray];

    NSMutableDictionary * pathSegmentDictionary = [pathSegmentsArray objectAtIndex:rowIndex];
    
    [self.pathSegmentEditorPopoverViewController loadPathSegmentData:pathSegmentDictionary];

    [self.pathSegmentEditorPopoverViewController.applyButton setTitle:@"Add"];
    
    // configure the preferred position of the popover
    [pathSegmentEditorPopover showRelativeToRect:[targetButton bounds] ofView:sender preferredEdge:NSMaxYEdge];
}

// -------------------------------------------------------------------------------
//  deletePathSegmentButtonAction:
// -------------------------------------------------------------------------------

- (IBAction)deletePathSegmentButtonAction:(id)sender
{
    NSInteger selectedRow = [self.pathTableView selectedRow];

    if (selectedRow >= 0)
    {
        [self.macSVGPluginCallbacks pushUndoRedoDocumentChanges];

        [self.pathSegmentsArray removeObjectAtIndex:selectedRow];
        
        [self.macSVGPluginCallbacks updatePathSegmentsAbsoluteValues:self.pathSegmentsArray];
        
        [self updateWithPathSegmentsArray:self.pathSegmentsArray];
    }
}

//==================================================================================
//	pathSegmentsArray
//==================================================================================

- (NSMutableArray * )pathSegmentsArray
{
    id macSVGDocumentWindowController = [self.macSVGDocument macSVGDocumentWindowController];
    id svgWebKitController = [macSVGDocumentWindowController svgWebKitController];
    
    NSMutableArray * pathSegmentsArray = [svgWebKitController pathSegmentsArray];
    
    return pathSegmentsArray;
}

//==================================================================================
//	syncDOMElementToXMLDocument:
//==================================================================================

-(void) syncDOMElementToXMLDocument
{
    NSMutableDictionary * newAttributesDictionary = [[NSMutableDictionary alloc] init];

    DOMNamedNodeMap * domAttributes = [self.pluginTargetDOMElement attributes];
    NSInteger attCount = [domAttributes length];
    
    for (unsigned int a = 0; a < attCount; a++) 
    {
        DOMNode * attributes = [domAttributes item:a];
        NSString * attributeName = [attributes nodeName];
        NSString * attributeValue = [attributes nodeValue];

        NSRange xmlnsRange = [attributeName rangeOfString:@"xmlns"];
        if (xmlnsRange.location != NSNotFound)
        {
            NSLog(@"syncDOMElementToXMLDocument - xmlns namespace found as attribute");
        }
        
        if ([attributeName length] > 0)
        {
            unichar firstChar = [attributeName characterAtIndex:0];
            if (firstChar != '_')
            {
                [newAttributesDictionary setObject:attributeValue forKey:attributeName];
            }
        }
    }
    
    [self.pluginTargetXMLElement setAttributesWithDictionary:newAttributesDictionary];
    
}

//==================================================================================
//	setPathDataAttribute
//==================================================================================

-(void) setPathDataAttribute
{
    [self syncDOMElementToXMLDocument];

    [self.macSVGDocument updateSelections]; // update selection rectangles and handles
    
    NSInteger selectedRow = [self.pathTableView selectedRow];
    [self.pathTableView setNeedsDisplayInRect:[self.pathTableView
            frameOfCellAtColumn:0 row:selectedRow]];

    [self updateTotalLengthForPathElement:[self.macSVGPluginCallbacks svgPathEditorSelectedPathElement]];
}

//==================================================================================
//	tableView:writeRowsWithIndexes:toPasteboard
//==================================================================================

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
    // Copy the row numbers to the pasteboard.
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];

    [pboard declareTypes:[NSArray arrayWithObject:PathTableViewDataType] owner:self];

    [pboard setData:data forType:PathTableViewDataType];
    
    return YES;
}

//==================================================================================
//	tableView:acceptDrop:row:dropOperation
//==================================================================================

- (BOOL)tableView:(NSTableView*)tableView 
        acceptDrop:(id <NSDraggingInfo>)info 
        row:(NSInteger)row
        dropOperation:(NSTableViewDropOperation)operation
{
    // handle drag-and-drop reordering
    
    NSPasteboard * pboard = [info draggingPasteboard];
    NSData * rowData = [pboard dataForType:PathTableViewDataType];

    NSMutableArray * pathSegmentsArray = [self pathSegmentsArray];

    NSIndexSet * rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];

    NSInteger from = [rowIndexes firstIndex];

    NSMutableDictionary * traveller = [pathSegmentsArray objectAtIndex:from];
    
    NSInteger length = [pathSegmentsArray count];
    //NSMutableArray * replacement = [NSMutableArray new];

    NSInteger i;
    for (i = 0; i <= length; i++)
    {
        if (i == row)
        {
            if (from > row)
            {
                [pathSegmentsArray insertObject:traveller atIndex:row];
                [pathSegmentsArray removeObjectAtIndex:(from + 1)];
            }
            else
            {
                [pathSegmentsArray insertObject:traveller atIndex:row];
                [pathSegmentsArray removeObjectAtIndex:from];
            }
        }
    }
    
    [self.pathTableView reloadData];

    [self updateTotalLengthForPathElement:[self.macSVGPluginCallbacks svgPathEditorSelectedPathElement]];
    
    [self setPathDataAttribute];
    
    return YES;
}


//==================================================================================
//	tableView:validateDrop:proposedRow:proposedDropOperation:
//==================================================================================

- (NSDragOperation)tableView:(NSTableView*)tableView 
        validateDrop:(id <NSDraggingInfo>)info 
        proposedRow:(NSInteger)row
        proposedDropOperation:(NSTableViewDropOperation)operation
{
    return NSDragOperationEvery;
}


//==================================================================================
//	handlePluginEvent
//==================================================================================

-(void) handlePluginEvent:(DOMEvent *)event
{
    // Our callback from WebKit
    NSString * eventType = event.type;
    
    DOMNode * targetNode = self.pluginTargetDOMElement;
    
    DOMElement * targetElement = (DOMElement *)targetNode;
    NSString * tagName = [targetElement tagName];
    #pragma unused(tagName)

    if ([eventType isEqualToString:@"dblclick"] == YES)
    {
        //NSLog(@"handlePluginEvent dblclick");
    }
    else if ([eventType isEqualToString:@"mousedown"] == YES)
    {
        //NSLog(@"handlePluginEvent mousedown");
    }
    else if ([eventType isEqualToString:@"mousemove"] == YES)
    {
        //NSLog(@"handlePluginEvent mousemove");
    }
    else if ([eventType isEqualToString:@"mouseup"] == YES)
    {
        //NSLog(@"handlePluginEvent mouseup");
    }
    else if ([eventType isEqualToString:@"focus"] == YES)
    {
        //NSLog(@"handlePluginEvent focus");
    }
    else if ([eventType isEqualToString:@"blur"] == YES)
    {
        //NSLog(@"handlePluginEvent blur");
    }
    else if ([eventType isEqualToString:@"keydown"] == YES)
    {
        //NSLog(@"handlePluginEvent keydown");
    }
    else if ([eventType isEqualToString:@"keypress"] == YES)
    {
        //NSLog(@"handlePluginEvent keypress");
    }
    else if ([eventType isEqualToString:@"keyup"] == YES)
    {
        //NSLog(@"handlePluginEvent keyup");
    }
}

//==================================================================================
//	setTransformAttribute
//==================================================================================

-(void) setTransformAttribute
{
    NSLog(@"PathElementEditor - setTranformAttribute method needed here");
}

//==================================================================================
//	highlightSelectedSegmentCheckboxAction:
//==================================================================================

-(IBAction)highlightSelectedSegmentCheckboxAction:(id)sender
{
    MacSVGDocumentWindowController * macSVGDocumentWindowController =
            [self.macSVGDocument macSVGDocumentWindowController];

    id svgWebKitController = [macSVGDocumentWindowController svgWebKitController];
    id domMouseEventsController = [svgWebKitController domMouseEventsController];
    SVGPathEditor * svgPathEditor = [domMouseEventsController svgPathEditor];
    
    svgPathEditor.highlightSelectedSegment = highlightSelectedSegmentCheckbox.state;
    
    [self refreshSelectedRow];
}

//==================================================================================
//	highlightPathSegment
//==================================================================================

- (void)highlightPathSegment
{
    if (highlightSelectedSegmentCheckbox.state == YES)
    {
        NSInteger selectedRow = [self.pathTableView selectedRow];

        if (selectedRow != -1)
        {
            NSWindow * keyWindow = [NSApp keyWindow];
            id firstResponder = [keyWindow firstResponder];
            if (firstResponder != self.pathTableView)
            {
                [keyWindow makeFirstResponder:self.pathTableView];
            }

            MacSVGDocumentWindowController * macSVGDocumentWindowController = [self.macSVGDocument macSVGDocumentWindowController];
            
            DOMSelectionRectsAndHandlesManager * domSelectionRectsAndHandlesManager =
                    macSVGDocumentWindowController.svgXMLDOMSelectionManager.domSelectionRectsAndHandlesManager;
            
            domSelectionRectsAndHandlesManager.segmentStrokeWidth = 0;
            if (highlightUseCustomStrokeWidthCheckbox.state == YES)
            {
                domSelectionRectsAndHandlesManager.segmentStrokeWidth = [highlightStrokeWidthTextField.stringValue floatValue];
            }
    
            domSelectionRectsAndHandlesManager.segmentStrokeHexColor = [self hexColorFromColorWell:highlightColorWell];

            [domSelectionRectsAndHandlesManager highlightPathSegment];
        }
    }
    else
    {
        [self removeHighlightPathSegment];
    }
}

//==================================================================================
//	removeHighlightPathSegment
//==================================================================================

- (void)removeHighlightPathSegment
{
    NSInteger selectedRow = [self.pathTableView selectedRow];

    if (selectedRow != -1)
    {
        MacSVGDocumentWindowController * macSVGDocumentWindowController =
                [self.macSVGDocument macSVGDocumentWindowController];
        
        DOMSelectionRectsAndHandlesManager * domSelectionRectsAndHandlesManager =
                macSVGDocumentWindowController.svgXMLDOMSelectionManager.domSelectionRectsAndHandlesManager;
        
        [domSelectionRectsAndHandlesManager removeDOMPathSegmentHighlight];
    }
}

//==================================================================================
//	hexColorFromColorWell:
//==================================================================================

- (NSString *)hexColorFromColorWell:(NSColorWell *)aColorWell
{
    NSColor * aColor = [aColorWell color];
    
    NSString * hexColor = [self hexadecimalValueOfAnNSColor:aColor];
    
    return hexColor;
}

//==================================================================================
//	hexadecimalValueOfAnNSColor:
//==================================================================================

-(NSString *)hexadecimalValueOfAnNSColor:(NSColor *)aColor
{
    CGFloat redFloatValue, greenFloatValue, blueFloatValue;
    int redIntValue, greenIntValue, blueIntValue;
    NSString *redHexValue, *greenHexValue, *blueHexValue;

    // Convert the NSColor to the RGB color space before we can access its components
    NSColor * convertedColor = [aColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];

    if(convertedColor)
    {
        // Get the red, green, and blue components of the color
        [convertedColor getRed:&redFloatValue green:&greenFloatValue blue:&blueFloatValue alpha:NULL];

        // Convert the components to numbers (unsigned decimal integer) between 0 and 255
        redIntValue = redFloatValue * 255.99999f;
        greenIntValue = greenFloatValue * 255.99999f;
        blueIntValue = blueFloatValue * 255.99999f;

        // Convert the numbers to hex strings
        redHexValue=[NSString stringWithFormat:@"%02x", redIntValue]; 
        greenHexValue=[NSString stringWithFormat:@"%02x", greenIntValue];
        blueHexValue=[NSString stringWithFormat:@"%02x", blueIntValue];

        // Concatenate the red, green, and blue components' hex strings together with a "#"
        return [NSString stringWithFormat:@"#%@%@%@", redHexValue, greenHexValue, blueHexValue];
    }
    return nil;
}

//==================================================================================
//	subdivideSegmentButtonAction:
//==================================================================================

- (IBAction)subdivideSegmentButtonAction:(id)sender
{
    // adapted from http://antigrain.com/research/adaptive_bezier/#toc0003
    // and http://www.ericeastwood.com/blog/25/curves-and-arcs-quadratic-cubic-elliptical-svg-implementations
    
    NSInteger selectedRow = [self.pathTableView selectedRow];

    NSMutableArray * pathSegmentsArray = [self pathSegmentsArray];
    
    if (selectedRow != -1)
    {
        NSMutableDictionary * pathSegmentDictionary = [pathSegmentsArray objectAtIndex:selectedRow];

        NSMutableDictionary * newPathSegmentDictionary = [NSMutableDictionary dictionary];
        NSArray * allKeys = [pathSegmentDictionary allKeys];
        for (NSString * aKey in allKeys)
        {
            NSString * aValue = [pathSegmentDictionary objectForKey:aKey];
            NSString * copyValue = [aValue copy];
            [newPathSegmentDictionary setObject:copyValue forKey:aKey];
        }

        // get starting point of segment

        NSString * startXString = [pathSegmentDictionary objectForKey:@"x"];
        NSString * startYString = [pathSegmentDictionary objectForKey:@"y"];
        NSString * previousX1String = [pathSegmentDictionary objectForKey:@"x1"];
        NSString * previousY1String = [pathSegmentDictionary objectForKey:@"y1"];
        NSString * previousX2String = [pathSegmentDictionary objectForKey:@"x2"];
        NSString * previousY2String = [pathSegmentDictionary objectForKey:@"y2"];
        
        unichar previousPathCommand = ' ';
        
        if (selectedRow > 0)
        {
            // get current starting point from previous segment
            
            NSMutableDictionary * previousPathSegmentDictionary = [pathSegmentsArray objectAtIndex:(selectedRow - 1)];

            startXString = [previousPathSegmentDictionary objectForKey:@"x"];
            startYString = [previousPathSegmentDictionary objectForKey:@"y"];
            previousX1String = [pathSegmentDictionary objectForKey:@"x1"];
            previousY1String = [pathSegmentDictionary objectForKey:@"y1"];
            previousX2String = [pathSegmentDictionary objectForKey:@"x2"];
            previousY2String = [pathSegmentDictionary objectForKey:@"y2"];
            NSString * previousPathCommandString = [pathSegmentDictionary objectForKey:@"command"];
            previousPathCommand = [previousPathCommandString characterAtIndex:0];
        }
        
        if ([startXString length] == 0)
        {
            startXString = @"0";
        }
        if ([startYString length] == 0)
        {
            startYString = @"0";
        }
        if ([previousX1String length] == 0)
        {
            previousX1String = @"0";
        }
        if ([previousY1String length] == 0)
        {
            previousY1String = @"0";
        }
        if ([previousX2String length] == 0)
        {
            previousX2String = @"0";
        }
        if ([previousY2String length] == 0)
        {
            previousY2String = @"0";
        }
        
        CGFloat startX = [startXString floatValue];
        CGFloat startY = [startYString floatValue];
        CGFloat previousX1 = [previousX1String floatValue];
        CGFloat previousY1 = [previousY1String floatValue];
        
        NSString * pathCommandString = [pathSegmentDictionary objectForKey:@"command"];
        unichar commandChar = [pathCommandString characterAtIndex:0];
        
        BOOL subdividablePathFound = NO;
        
        // define the path segment
        switch (commandChar) 
        {
            case 'M':     // absolute moveto
            case 'm':     // relative moveto
            {
                // we can't subdivide a move path segment
                
                subdividablePathFound = NO;
                
                break;
            }
            case 'L':     // absolute lineto
            case 'l':     // relative lineto
            {
                subdividablePathFound = YES;

                NSString * xString = [pathSegmentDictionary objectForKey:@"x"];
                NSString * yString = [pathSegmentDictionary objectForKey:@"y"];
                
                CGFloat x = [xString floatValue];
                CGFloat y = [yString floatValue];
                
                CGFloat midX = (x + startX) / 2.0f;
                CGFloat midY = (y + startY) / 2.0f;
                
                NSString * midXString = [self allocFloatString:midX];
                NSString * midYString = [self allocFloatString:midY];
                
                [pathSegmentDictionary setObject:midXString forKey:@"x"];
                [pathSegmentDictionary setObject:midYString forKey:@"y"];

                [newPathSegmentDictionary setObject:xString forKey:@"x"];
                [newPathSegmentDictionary setObject:yString forKey:@"y"];

                break;
            }
            case 'H':     // absolute horizontal lineto
            case 'h':     // absolute horizontal lineto
            {
                subdividablePathFound = YES;

                NSString * xString = [pathSegmentDictionary objectForKey:@"x"];
                CGFloat x = [xString floatValue];

                CGFloat midX = (x + startX) / 2.0f;
                NSString * midXString = [self allocFloatString:midX];

                [pathSegmentDictionary setObject:midXString forKey:@"x"];
                [newPathSegmentDictionary setObject:xString forKey:@"x"];
                
                break;
            }
            case 'V':     // absolute vertical lineto
            case 'v':     // absolute vertical lineto
            {
                subdividablePathFound = YES;

                NSString * yString = [pathSegmentDictionary objectForKey:@"y"];
                CGFloat y = [yString floatValue];

                CGFloat midY = (y + startY) / 2.0f;
                NSString * midYString = [self allocFloatString:midY];

                [pathSegmentDictionary setObject:midYString forKey:@"y"];
                [newPathSegmentDictionary setObject:yString forKey:@"y"];

                break;
            }
            case 'C':     // absolute cubic curveto
            case 'c':     // absolute cubic curveto
            {
                subdividablePathFound = YES;

                NSString * x1String = [pathSegmentDictionary objectForKey:@"x1"];
                NSString * y1String = [pathSegmentDictionary objectForKey:@"y1"];
                NSString * x2String = [pathSegmentDictionary objectForKey:@"x2"];
                NSString * y2String = [pathSegmentDictionary objectForKey:@"y2"];
                NSString * xString = [pathSegmentDictionary objectForKey:@"x"];
                NSString * yString = [pathSegmentDictionary objectForKey:@"y"];
                
                CGFloat x1 = [x1String floatValue];
                CGFloat y1 = [y1String floatValue];
                CGFloat x2 = [x2String floatValue];
                CGFloat y2 = [y2String floatValue];
                CGFloat x = [xString floatValue];
                CGFloat y = [yString floatValue];
                
                CGFloat x12 = (startX + x1) / 2.0f;
                CGFloat y12 = (startY + y1) / 2.0f;
                CGFloat x23 = (x1 + x2) / 2.0f;
                CGFloat y23 = (y1 + y2) / 2.0f;
                CGFloat x34 = (x2 + x) / 2.0f;
                CGFloat y34 = (y2 + y) / 2.0f;
                CGFloat x123  = (x12 + x23) / 2.0f;
                CGFloat y123  = (y12 + y23) / 2.0f;
                CGFloat x234  = (x23 + x34) / 2.0f;
                CGFloat y234  = (y23 + y34) / 2.0f;
                CGFloat x1234 = (x123 + x234) / 2.0f;
                CGFloat y1234 = (y123 + y234) / 2.0f;
                
                NSString * x12String = [self allocFloatString:x12];
                NSString * y12String = [self allocFloatString:y12];
                //NSString * x23String = [self allocFloatString:x23];
                //NSString * y23String = [self allocFloatString:y23];
                NSString * x34String = [self allocFloatString:x34];
                NSString * y34String = [self allocFloatString:y34];
                NSString * x123String = [self allocFloatString:x123];
                NSString * y123String = [self allocFloatString:y123];
                NSString * x234String = [self allocFloatString:x234];
                NSString * y234String = [self allocFloatString:y234];
                NSString * x1234String = [self allocFloatString:x1234];
                NSString * y1234String = [self allocFloatString:y1234];
                
                [pathSegmentDictionary setObject:x12String forKey:@"x1"];
                [pathSegmentDictionary setObject:y12String forKey:@"y1"];
                [pathSegmentDictionary setObject:x123String forKey:@"x2"];
                [pathSegmentDictionary setObject:y123String forKey:@"y2"];
                [pathSegmentDictionary setObject:x1234String forKey:@"x"];
                [pathSegmentDictionary setObject:y1234String forKey:@"y"];

                [newPathSegmentDictionary setObject:x234String forKey:@"x1"];
                [newPathSegmentDictionary setObject:y234String forKey:@"y1"];
                [newPathSegmentDictionary setObject:x34String forKey:@"x2"];
                [newPathSegmentDictionary setObject:y34String forKey:@"y2"];
                [newPathSegmentDictionary setObject:xString forKey:@"x"];
                [newPathSegmentDictionary setObject:yString forKey:@"y"];
                break;
            }
            case 'S':     // absolute smooth cubic curveto
            case 's':     // relative smooth cubic curveto
            {
                subdividablePathFound = YES;

                CGFloat x1 = startX - previousX1;
                CGFloat y1 = startY - previousY1;

                NSString * x2String = [pathSegmentDictionary objectForKey:@"x2"];
                NSString * y2String = [pathSegmentDictionary objectForKey:@"y2"];
                NSString * xString = [pathSegmentDictionary objectForKey:@"x"];
                NSString * yString = [pathSegmentDictionary objectForKey:@"y"];
                
                CGFloat x2 = [x2String floatValue];
                CGFloat y2 = [y2String floatValue];
                CGFloat x = [xString floatValue];
                CGFloat y = [yString floatValue];
                
                CGFloat x12 = (startX + x1) / 2.0f;
                CGFloat y12 = (startY + y1) / 2.0f;
                CGFloat x23 = (x1 + x2) / 2.0f;
                CGFloat y23 = (y1 + y2) / 2.0f;
                CGFloat x34 = (x2 + x) / 2.0f;
                CGFloat y34 = (y2 + y) / 2.0f;
                CGFloat x123  = (x12 + x23) / 2.0f;
                CGFloat y123  = (y12 + y23) / 2.0f;
                CGFloat x234  = (x23 + x34) / 2.0f;
                CGFloat y234  = (y23 + y34) / 2.0f;
                CGFloat x1234 = (x123 + x234) / 2.0f;
                CGFloat y1234 = (y123 + y234) / 2.0f;
                
                NSString * x34String = [self allocFloatString:x34];
                NSString * y34String = [self allocFloatString:y34];
                NSString * x123String = [self allocFloatString:x123];
                NSString * y123String = [self allocFloatString:y123];
                NSString * x1234String = [self allocFloatString:x1234];
                NSString * y1234String = [self allocFloatString:y1234];

                [pathSegmentDictionary setObject:x123String forKey:@"x2"];
                [pathSegmentDictionary setObject:y123String forKey:@"y2"];
                [pathSegmentDictionary setObject:x1234String forKey:@"x"];
                [pathSegmentDictionary setObject:y1234String forKey:@"y"];

                [newPathSegmentDictionary setObject:x34String forKey:@"x2"];
                [newPathSegmentDictionary setObject:y34String forKey:@"y2"];
                [newPathSegmentDictionary setObject:xString forKey:@"x"];
                [newPathSegmentDictionary setObject:yString forKey:@"y"];
                break;
            }
            case 'Q':     // absolute quadratic Bezier curve
            case 'q':     // quadratic Bezier curve
            {
                subdividablePathFound = YES;

                NSString * x1String = [pathSegmentDictionary objectForKey:@"x1"];
                NSString * y1String = [pathSegmentDictionary objectForKey:@"y1"];
                NSString * xString = [pathSegmentDictionary objectForKey:@"x"];
                NSString * yString = [pathSegmentDictionary objectForKey:@"y"];

                CGFloat x1 = [x1String floatValue];
                CGFloat y1 = [y1String floatValue];
                CGFloat x = [xString floatValue];
                CGFloat y = [yString floatValue];
                
                CGFloat control1MidpointX = (startX + x1) / 2.0f;
                CGFloat control1MidpointY = (startY + y1) / 2.0f;

                CGFloat control2MidpointX = (x1 + x) / 2.0f;
                CGFloat control2MidpointY = (x1 + x) / 2.0f;
                
                CGFloat midpointX = [self calculateQuadraticBezierParameterAtx0:startX x1:x1 x2:x t:0.5f];
                CGFloat midpointY = [self calculateQuadraticBezierParameterAtx0:startY x1:y1 x2:y t:0.5f];
                
                NSString * control1MidpointXString = [self allocFloatString:control1MidpointX];
                NSString * control1MidpointYString = [self allocFloatString:control1MidpointY];
                NSString * control2MidpointXString = [self allocFloatString:control2MidpointX];
                NSString * control2MidpointYString = [self allocFloatString:control2MidpointY];
                NSString * midpointXString = [self allocFloatString:midpointX];
                NSString * midpointYString = [self allocFloatString:midpointY];

                [pathSegmentDictionary setObject:control1MidpointXString forKey:@"x1"];
                [pathSegmentDictionary setObject:control1MidpointYString forKey:@"y1"];
                [pathSegmentDictionary setObject:midpointXString forKey:@"x"];
                [pathSegmentDictionary setObject:midpointYString forKey:@"y"];

                [newPathSegmentDictionary setObject:control2MidpointXString forKey:@"x1"];
                [newPathSegmentDictionary setObject:control2MidpointYString forKey:@"y1"];
                [newPathSegmentDictionary setObject:xString forKey:@"x"];
                [newPathSegmentDictionary setObject:yString forKey:@"y"];
                break;
            }

            case 'T':     // absolute smooth quadratic Bezier curve
            case 't':     // relative smooth quadratic Bezier curve
            {
                subdividablePathFound = NO; // this is managed in the subroutine instead
                
                [self subdivideSmoothQuadraticAtSegementIndex:selectedRow pathSegmentsArray:pathSegmentsArray];
            
                break;
            }

            
            case 'A':     // absolute elliptical arc
            case 'a':     // relative elliptical arc
            {
                subdividablePathFound = YES;
                
                NSString * rxString = [pathSegmentDictionary objectForKey:@"rx"];
                NSString * ryString = [pathSegmentDictionary objectForKey:@"ry"];
                NSString * dataXAxisRotationString = [pathSegmentDictionary objectForKey:@"x-axis-rotation"];
                NSString * dataLargeArcString = [pathSegmentDictionary objectForKey:@"large-arc-flag"];
                NSString * sweepString = [pathSegmentDictionary objectForKey:@"sweep-flag"];
                NSString * xString = [pathSegmentDictionary objectForKey:@"x"];
                NSString * yString = [pathSegmentDictionary objectForKey:@"y"];

                CGFloat rx = [rxString floatValue];
                CGFloat ry = [ryString floatValue];
                CGFloat x = [xString floatValue];
                CGFloat y = [yString floatValue];
                CGFloat dataXAxisRotation = [dataXAxisRotationString floatValue];
                BOOL largeArcFlag = [dataLargeArcString boolValue];
                BOOL sweepFlag = [sweepString boolValue];
                
                CGPoint startPoint = CGPointMake(startX, startY);
                CGPoint endPoint = CGPointMake(x, y);
                
                NSDictionary * arcCenterDictionary = [self.macSVGPluginCallbacks convertArcToCenterPointWithStart:startPoint end:endPoint
                        rx:rx ry:ry rotation:dataXAxisRotation isLarge:largeArcFlag isCounterClockwise:sweepFlag];
                
                NSNumber * angleStartNumber = [arcCenterDictionary objectForKey:@"angleStart"];
                NSNumber * angleExtentNumber = [arcCenterDictionary objectForKey:@"angleExtent"];
                NSNumber * cxNumber = [arcCenterDictionary objectForKey:@"cx"];
                NSNumber * cyNumber = [arcCenterDictionary objectForKey:@"cy"];
                
                CGFloat angleStart = [angleStartNumber floatValue];
                CGFloat angleExtent = [angleExtentNumber floatValue];
                CGFloat cx = [cxNumber floatValue];
                CGFloat cy = [cyNumber floatValue];
                
                CGFloat halfAngleExtent = angleExtent / 2.0f;

                CGFloat angle1Start = angleStart;
                CGFloat angle2Start = angleStart + halfAngleExtent;
                
                NSDictionary * arc1Dictionary = [self.macSVGPluginCallbacks convertArcToEndPointWithRotation:dataXAxisRotation
                        angleStart:angle1Start angleExtent:halfAngleExtent cx:cx cy:cy rx:rx ry:ry];
                
                NSNumber * arc1EndXNumber = [arc1Dictionary objectForKey:@"endX"];
                NSNumber * arc1EndYNumber = [arc1Dictionary objectForKey:@"endY"];
                NSNumber * arc1IsCounterClockwiseNumber = [arc1Dictionary objectForKey:@"isCounterClockwise"];
                NSNumber * arc1IsLargeNumber = [arc1Dictionary objectForKey:@"isLarge"];
                
                CGFloat arc1EndX = [arc1EndXNumber floatValue];
                CGFloat arc1EndY = [arc1EndYNumber floatValue];
                BOOL arc1SweepFlag = [arc1IsCounterClockwiseNumber boolValue];
                BOOL arc1LargeArcFlag = [arc1IsLargeNumber boolValue];
                
                NSString * arc1EndXString = [self allocFloatString:arc1EndX];
                NSString * arc1EndYString = [self allocFloatString:arc1EndY];
                NSString * arc1SweepFlagString = [NSString stringWithFormat:@"%hhd", arc1SweepFlag];
                NSString * arc1LargeArcFlagString = [NSString stringWithFormat:@"%hhd", arc1LargeArcFlag];

                [pathSegmentDictionary setObject:rxString forKey:@"rx"];
                [pathSegmentDictionary setObject:ryString forKey:@"ry"];
                [pathSegmentDictionary setObject:dataXAxisRotationString forKey:@"x-axis-rotation"];
                [pathSegmentDictionary setObject:arc1LargeArcFlagString forKey:@"large-arc-flag"];
                [pathSegmentDictionary setObject:arc1SweepFlagString forKey:@"sweep-flag"];
                [pathSegmentDictionary setObject:arc1EndXString forKey:@"x"];
                [pathSegmentDictionary setObject:arc1EndYString forKey:@"y"];
                
                NSDictionary * arc2Dictionary = [self.macSVGPluginCallbacks convertArcToEndPointWithRotation:dataXAxisRotation angleStart:angle2Start angleExtent:halfAngleExtent cx:cx cy:cy rx:rx ry:ry];

                NSNumber * arc2EndXNumber = [arc2Dictionary objectForKey:@"endX"];
                NSNumber * arc2EndYNumber = [arc2Dictionary objectForKey:@"endY"];
                NSNumber * arc2IsCounterClockwiseNumber = [arc2Dictionary objectForKey:@"isCounterClockwise"];
                NSNumber * arc2IsLargeNumber = [arc2Dictionary objectForKey:@"isLarge"];

                CGFloat arc2EndX = [arc2EndXNumber floatValue];
                CGFloat arc2EndY = [arc2EndYNumber floatValue];
                BOOL arc2SweepFlag = [arc2IsCounterClockwiseNumber boolValue];
                BOOL arc2LargeArcFlag = [arc2IsLargeNumber boolValue];
                
                NSString * arc2EndXString = [self allocFloatString:arc2EndX];
                NSString * arc2EndYString = [self allocFloatString:arc2EndY];
                NSString * arc2SweepFlagString = [NSString stringWithFormat:@"%hhd", arc2SweepFlag];
                NSString * arc2LargeArcFlagString = [NSString stringWithFormat:@"%hhd", arc2LargeArcFlag];

                [newPathSegmentDictionary setObject:rxString forKey:@"rx"];
                [newPathSegmentDictionary setObject:ryString forKey:@"ry"];
                [newPathSegmentDictionary setObject:dataXAxisRotationString forKey:@"x-axis-rotation"];
                [newPathSegmentDictionary setObject:arc2LargeArcFlagString forKey:@"large-arc-flag"];
                [newPathSegmentDictionary setObject:arc2SweepFlagString forKey:@"sweep-flag"];
                [newPathSegmentDictionary setObject:arc2EndXString forKey:@"x"];
                [newPathSegmentDictionary setObject:arc2EndYString forKey:@"y"];
                break;
            }
            case 'Z':     // absolute closepath
            case 'z':     // relative closepath
            {
                // we can't subdivide a close-path segment
                
                subdividablePathFound = NO;
                break;
            }
        }
        
        if (subdividablePathFound == YES)
        {
            [pathSegmentsArray insertObject:newPathSegmentDictionary atIndex:(selectedRow + 1)];
        }

            
        [self.macSVGPluginCallbacks updatePathSegmentsAbsoluteValues:pathSegmentsArray];
        
        [self updateWithPathSegmentsArray:pathSegmentsArray];

        [self.pathTableView reloadData];

        [self updateTotalLengthForPathElement:[self.macSVGPluginCallbacks svgPathEditorSelectedPathElement]];
        
        [self.macSVGPluginCallbacks setActiveXMLElement:self.pluginTargetXMLElement];

        [self.macSVGPluginCallbacks setToolMode:toolModeCrosshairCursor];
        
        [self highlightPathSegment];
    }
}

//==================================================================================
//	subdivideSmoothQuadraticAtSegementIndex:pathSegmentsArray:
//==================================================================================

- (void)subdivideSmoothQuadraticAtSegementIndex:(NSInteger)segmentIndex pathSegmentsArray:(NSMutableArray *)pathSegmentsArray
{
    [self.macSVGPluginCallbacks updatePathSegmentsAbsoluteValues:pathSegmentsArray];

    unichar previousCommandCharacter = ' ';
    NSDictionary * previousSegmentDictionary = NULL;
    CGPoint controlPoint = NSZeroPoint;

    for (NSInteger currentSegmentIndex = 0; currentSegmentIndex <= segmentIndex; currentSegmentIndex++)
    {
        NSMutableDictionary * pathSegmentDictionary = [pathSegmentsArray objectAtIndex:currentSegmentIndex];
    
        NSNumber * absoluteStartXNumber = [pathSegmentDictionary objectForKey:@"absoluteStartX"];
        NSNumber * absoluteStartYNumber = [pathSegmentDictionary objectForKey:@"absoluteStartY"];
        
        NSNumber * absoluteXNumber = [pathSegmentDictionary objectForKey:@"absoluteX"];
        NSNumber * absoluteYNumber = [pathSegmentDictionary objectForKey:@"absoluteY"];
        
        CGFloat absoluteStartXFloat = [absoluteStartXNumber floatValue];
        CGFloat absoluteStartYFloat = [absoluteStartYNumber floatValue];
        
        CGFloat absoluteXFloat = [absoluteXNumber floatValue];
        CGFloat absoluteYFloat = [absoluteYNumber floatValue];

        NSNumber * xString = [pathSegmentDictionary objectForKey:@"x"];
        NSNumber * yString = [pathSegmentDictionary objectForKey:@"y"];
        
        if (currentSegmentIndex == 0)
        {
            controlPoint = CGPointMake(absoluteStartXFloat, absoluteStartYFloat);
        }

        NSString * commandString = [pathSegmentDictionary objectForKey:@"command"];
        unichar commandCharacter = [commandString characterAtIndex:0];

        switch (commandCharacter)
        {
            case 'M':     // moveto
            case 'm':     // moveto
                break;
            
            case 'L':     // lineto
            case 'l':     // lineto
                break;

            case 'H':     // horizontal lineto
            case 'h':     // horizontal lineto
                break;

            case 'V':     // vertical lineto
            case 'v':     // vertical lineto
                break;

            case 'C':     // curveto
            case 'c':     // curveto
                break;

            case 'S':     // smooth curveto
            case 's':     // smooth curveto
                break;

            case 'Q':     // quadratic Bezier curve
            case 'q':     // quadratic Bezier curve
            {
                NSNumber * oldAbsoluteX1Number = [pathSegmentDictionary objectForKey:@"absoluteX1"];    // quadratic x1,y1
                NSNumber * oldAbsoluteY1Number = [pathSegmentDictionary objectForKey:@"absoluteY1"];
                
                CGFloat oldAbsoluteX1Float = [oldAbsoluteX1Number floatValue];
                CGFloat oldAbsoluteY1Float = [oldAbsoluteY1Number floatValue];

                controlPoint = CGPointMake(oldAbsoluteX1Float, oldAbsoluteY1Float);
                
                break;
            }

            case 'T':     // smooth quadratic Bezier curve
            case 't':     // smooth quadratic Bezier curve
            {
                // Based on WebKitSVGPathParser::parseCurveToQuadraticSmoothSegment()
                // to get cubic x1,x2 and quadratic control point for a quadratic smooth segment
                // from https://github.com/WebKit/webkit/blob/master/Source/WebCore/svg/SVGPathParser.cpp

                CGPoint currentPoint = CGPointMake(absoluteStartXFloat, absoluteStartYFloat);
                CGPoint targetPoint = CGPointMake(absoluteXFloat, absoluteYFloat);
                
                CGPoint point1 = currentPoint;
                CGPoint point2 = targetPoint;

                if (currentSegmentIndex > 0)
                {
                    switch (previousCommandCharacter)
                    {
                        case 'Q':
                        case 'q':
                        case 'T':
                        case 't':
                        {
                            break;
                        }
                        default:
                        {
                            controlPoint = currentPoint;
                        }
                    }
                    
                    CGPoint cubicPoint = currentPoint;
                    cubicPoint.x *= 2.0f;
                    cubicPoint.y *= 2.0f;
                    cubicPoint.x -= controlPoint.x;
                    cubicPoint.y -= controlPoint.y;
                    
                    point1 = CGPointMake((currentPoint.x + (2.0f * cubicPoint.x)), (currentPoint.y + (2.0f * cubicPoint.y)));
                    point2 = CGPointMake((targetPoint.x + (2.0f * cubicPoint.x)), (targetPoint.y + (2.0f * cubicPoint.y)));
                    
                    point1.x /= 3.0f;
                    point1.y /= 3.0f;
                    point2.x /= 3.0f;
                    point2.y /= 3.0f;
                    
                    controlPoint = cubicPoint;
                }

                if (currentSegmentIndex == segmentIndex)
                {
                    NSString * controlPointXString = [self allocFloatString:controlPoint.x];
                    NSString * controlPointYString = [self allocFloatString:controlPoint.y];
                    
                    NSString * newCommandString = @"Q";
                    if (commandCharacter == 't')
                    {
                        newCommandString = @"q";
                    }

                    [pathSegmentDictionary setObject:controlPointXString forKey:@"x1"];
                    [pathSegmentDictionary setObject:controlPointYString forKey:@"y1"];
                    [pathSegmentDictionary setObject:newCommandString forKey:@"command"];
                    
                    NSMutableDictionary * newPathSegmentDictionary = [NSMutableDictionary dictionary];
                    [newPathSegmentDictionary setObject:xString forKey:@"x"];
                    [newPathSegmentDictionary setObject:yString forKey:@"y"];
                    [newPathSegmentDictionary setObject:controlPointXString forKey:@"x1"];
                    [newPathSegmentDictionary setObject:controlPointYString forKey:@"y1"];
                    [newPathSegmentDictionary setObject:newCommandString forKey:@"command"];
                    
                    [pathSegmentsArray insertObject:newPathSegmentDictionary atIndex:(segmentIndex + 1)];
                }
                
                break;
            }

            case 'A':     // elliptical arc
            case 'a':     // elliptical arc
                break;

            case 'Z':     // closepath
            case 'z':     // closepath
                break;
        }
        
        previousCommandCharacter = commandCharacter;
        previousSegmentDictionary = pathSegmentDictionary;
    }

    [self.macSVGPluginCallbacks updatePathSegmentsAbsoluteValues:pathSegmentsArray];
}

//==================================================================================
//	calculateQuadraticBezierParameterAtx0:x1:x2:t:
//==================================================================================

- (CGFloat)calculateQuadraticBezierParameterAtx0:(CGFloat)x0 x1:(CGFloat)x1 x2:(CGFloat)x2 t:(CGFloat)t
{
    CGFloat result = pow(1 - t, 2) * x0 + 2 * t * (1 - t) * x1 + pow(t, 2) * x2;
    
    return result;
}

//==================================================================================
//	pointOnQuadraticBezierCurveAtp0:p1:p2:t:
//==================================================================================

- (CGPoint)pointOnQuadraticBezierCurveAtp0:(CGPoint)p0 p1:(CGPoint)p1 p2:(CGPoint)p2 t:(CGFloat)t
{
    CGFloat x = [self calculateQuadraticBezierParameterAtx0:p0.x x1:p1.x x2:p2.x t:t];
    CGFloat y = [self calculateQuadraticBezierParameterAtx0:p0.y x1:p1.y x2:p2.y t:t];
    
    CGPoint resultPoint = CGPointMake(x, y);
    return resultPoint;
};





@end