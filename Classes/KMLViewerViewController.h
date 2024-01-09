/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Displays an MKMapView and demonstrates how to use the included KMLParser class to place annotations and overlays from a parsed KML file on top of the MKMapView.
*/

@interface KMLViewerViewController : UIViewController

-(IBAction)onTogglePressed:(id)sender;

@property(strong, nonatomic) IBOutlet UIButton* toggleButton;

@property(strong, nonatomic) IBOutlet UIImageView* labelOne;
@property(strong, nonatomic) IBOutlet UIImageView* labelTwo;

-(void) updateAppearanceOfButtonsAccodingToPlayerState;
-(void) skipAnimations;
@end

