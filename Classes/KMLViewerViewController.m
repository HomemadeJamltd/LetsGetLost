/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  Displays an MKMapView and demonstrates how to use the included KMLParser class to place annotations and overlays from a parsed KML file on top of the MKMapView. 
 */

@import MapKit;

#import "KMLParser.h"
#import "KMLViewerViewController.h"
#import "AudioManager.h"
#import <QuartzCore/QuartzCore.h>

@interface KMLViewerViewController ()  <MKMapViewDelegate, CLLocationManagerDelegate,KMLParserDelegate>

@property (nonatomic, weak) IBOutlet MKMapView *map;
@property (nonatomic, strong) KMLParser *kmlParser;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) AudioManager* audioManager;
@property (strong, nonatomic) NSArray* regions;
@end


BOOL inTestRegion = NO;
BOOL animating = NO;
BOOL activeAudio;

@implementation KMLViewerViewController

-(IBAction)onTogglePressed:(id)sender
{
    [self.view.layer removeAllAnimations];
    self.labelOne.alpha = 0.0;
    self.labelTwo.alpha = 0.0;
    UIButton* button = (UIButton*) sender;
    if(button.tag == 0)//PAUSE
    {
        [self.audioManager pause];
        [button setTitle:@"PLAY" forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:@"button_play"] forState:UIControlStateNormal];
        button.tag = 1;
    } else
    {
        [self.audioManager play];
        [button setTitle:@"PAUSE" forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:@"button_pause"] forState:UIControlStateNormal];

        button.tag = 0;
        [self animateInstructions:YES];
    }
}

-(NSURL*) getKMLOnline
{
    /*
#ifdef DEBUG
    NSString *stringURL = @"https://www.google.com/maps/d/kml?forcekml=1&mid=1NrJhS-PRDk04vMl9G5udkRFaCyg&lid=DmCM0q-MupE";
#else
    NSString *stringURL = @"https://www.google.com/maps/d/kml?forcekml=1&mid=1_ZgKcCJrgTeWtOiOANh06cK3MBg&lid=DwKgeD6vAcM";
#endif
     */
    NSString *stringURL = @"https://www.google.com/maps/d/kml?forcekml=1&mid=1_ZgKcCJrgTeWtOiOANh06cK3MBg&lid=DwKgeD6vAcM";
        NSURL  *url = [NSURL URLWithString:stringURL];
    NSData *urlData = [NSData dataWithContentsOfURL:url];
    if ( NO || urlData )
    {
        NSArray       *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString  *documentsDirectory = [paths objectAtIndex:0];
        
        NSString  *filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory,@"beacons.kml"];
        [urlData writeToFile:filePath atomically:YES];
        return [NSURL fileURLWithPath:filePath];
    }
    return nil;
}

-(void) animateInstructions:(BOOL) andHideAgain
{
    animating  = YES;
    
    self.labelTwo.alpha = 0.0;
    self.labelOne.alpha = 0.0;
    [UIView animateWithDuration:2.0 animations:^(void) {
        self.labelOne.alpha = 1.0;
    } completion:^(BOOL onefinished){
        if(self.toggleButton.tag == 0)
            [UIView animateWithDuration:2.0 animations:^(void) {
                if(andHideAgain)
                    self.labelOne.alpha = 0.0;
                self.labelTwo.alpha = 0.5;
            } completion:^(BOOL twofinished){
                if(self.toggleButton.tag == 0)
                    [UIView animateWithDuration:1.0 animations:^(void) {
                        self.labelTwo.alpha = 1.0;
                    } completion:^(BOOL threefinished){
                        if(self.toggleButton.tag == 0)
                            [UIView animateWithDuration:2.0 animations:^(void) {
                                if(andHideAgain)
                                    self.labelTwo.alpha = 0.0;
                                self.map.alpha = 1.0;
                                self.toggleButton.alpha = 1.0;
                                animating  = NO;
                            }];
                    }];
            }];
     }];
}

-(void) skipAnimations
{
    [self.view.layer removeAllAnimations];
    self.labelTwo.alpha = 0.0;
    self.labelOne.alpha = 0.0;
}

-(void) alertUserOfIssue:(NSString*) message
{
    {
        UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Let's Get Lost"
                                 message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    
    
        UIAlertAction* okButton = [UIAlertAction
                                actionWithTitle:@"OK"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
                                    //Handle your yes please button action here
                                     [self performSegueWithIdentifier:@"backUpSegue" sender:self];
                                }];
    
    
        [alert addAction:okButton];
    
        [self presentViewController:alert animated:YES completion:^{
           
        }];
    }
}

-(void) startRegionMonitoring
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

    NSURL *url = [self getKMLOnline];//[NSURL fileURLWithPath:path];
    if(url==nil)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self alertUserOfIssue:@"We lost you! Please make sure you have mobile data switched on in App Settings"];
        });
    }
    else
    {
        self.kmlParser = [[KMLParser alloc] initWithURL:url];
        self.kmlParser.delegate = self;
        [self.kmlParser parseKML];
        self.regions = [self.kmlParser regions];
        [self startMap];
    
        NSLog(@"[CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]] %d", [CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]]);
        NSLog(@"[CLLocationManager isMonitoringAvailableForClass:[CLRegion class]] %d", [CLLocationManager isMonitoringAvailableForClass:[CLRegion class]]);
        NSLog(@"[CLLocationManager significantLocationChangeMonitoringAvailable:%d", [CLLocationManager significantLocationChangeMonitoringAvailable]);
        NSLog(@"[CLLocationManager locationServicesEnabled:%d", [CLLocationManager locationServicesEnabled]);
        self.locationManager.pausesLocationUpdatesAutomatically = NO;
    }
    });
}

-(void) startMap
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray *circles = [self.kmlParser circleOverlays];
        [self.map addOverlays:circles];
        
        // Add all of the MKAnnotation objects parsed from the KML file to the map.
        NSArray *annotations = [self.kmlParser points];
        [self.map addAnnotations:annotations];
        
        // Walk the list of overlays and annotations and create a MKMapRect that
        // bounds all of them and store it into flyTo.
        MKMapRect rectThatFitsRegions = MKMapRectNull;
        for (id <MKOverlay> overlay in circles) {
            if (MKMapRectIsNull(rectThatFitsRegions)) {
                rectThatFitsRegions = [overlay boundingMapRect];
            } else {
                rectThatFitsRegions = MKMapRectUnion(rectThatFitsRegions, [overlay boundingMapRect]);
            }
        }
        
        // Position the map so that all overlays and annotations are visible on screen.
        self.map.visibleMapRect = rectThatFitsRegions;
        
    });
}

-(void) viewWillDisappear:(BOOL)animated
{
    [self.locationManager stopUpdatingLocation];
    if(self.audioManager)
        [self.audioManager kill];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if(![CLLocationManager locationServicesEnabled])
    {
        [self alertUserOfIssue:@"We can't find you! Please ensure that location services are enabled for your device."];
        return;
    }
    self.locationManager = [[CLLocationManager alloc] init];
    // Configure the location manager.
    self.locationManager.delegate = self;
    self.locationManager.distanceFilter = kCLLocationAccuracyBestForNavigation;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.toggleButton.alpha = 0.0;
    self.toggleButton.hidden = YES;
    self.labelOne.alpha = 0.0;
    self.labelTwo.alpha = 0.0;
    self.map.delegate = self;
    self.map.showsUserLocation = YES;
    self.map.alpha = 0.0;
    self.map.hidden = YES;
    self.audioManager = [[AudioManager alloc] init];
    // Create location manager early, so we can check and ask for location services authorization.
}


#pragma mark MKMapViewDelegate

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    return [self.kmlParser rendererForOverlay:overlay];
}


- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    return nil;
    return [self.kmlParser viewForAnnotation:annotation];
}

// Return the map overlay that depicts the region.
- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay {
    
    return [[MKOverlayView alloc] init];
}


#pragma mark - CLLocationManagerDelegate


// When the user has granted authorization, start the standard location service.
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    switch([CLLocationManager authorizationStatus])
    {
        case kCLAuthorizationStatusDenied:
        {
            [self alertUserOfIssue:@"We can't find you! Please go to your app settings and Allow Location Access"];
            break;
        }
        case  kCLAuthorizationStatusRestricted:
        {
            [self alertUserOfIssue:@"We can't find you! Please re-start the application and come out of the bushes!"];
            break;
        }
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        {
            [self alertUserOfIssue:@"Our app will need to know where you are when your phone is locked, please change your app settings to Allow Location Access"];
            break;
        }
        case kCLAuthorizationStatusNotDetermined:
        {
            [self.locationManager requestAlwaysAuthorization];
            break;
        }
        case kCLAuthorizationStatusAuthorizedAlways:
        {
            [self startRegionMonitoring];
            [self.locationManager startUpdatingLocation];
            [self animateInstructions:YES];
            break;
        }
    }
}

// A core location error occurred.
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"didFailWithError: %@", error.description);
}

-(void) updateAppearanceOfButtonsAccodingToPlayerState
{
    self.toggleButton.hidden = !activeAudio;
    if(!animating)
    {
        if(activeAudio)
        {
            self.labelOne.alpha = 0.0;
            self.labelTwo.alpha = 0.0;
        }
        else
        {
            [self animateInstructions:NO];
        }
    }
}


// The system delivered a new location.
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    
    if(oldLocation!=nil && self.regions!=nil && self.kmlParser!=nil)
    {
        
        /* non ragion monitoring solution */
        
        NSMutableArray* occupiedRegionFilenames = [[NSMutableArray alloc] init];
        for(CLCircularRegion* region in self.regions )
        {
            //if((region == self.regions.firstObject) || [region containsCoordinate:newLocation.coordinate])
            if( [region containsCoordinate:newLocation.coordinate])
            {
                NSString* audioFilename = [self.kmlParser audioFilenameForRegionIdentifier:region.identifier];
                   [occupiedRegionFilenames addObject:audioFilename];
            }
        }
        [self.audioManager resetOccupiedRegionFilenames:occupiedRegionFilenames];
        if(activeAudio != (occupiedRegionFilenames.count > 0))
        {
            activeAudio = (occupiedRegionFilenames.count > 0);
            [self updateAppearanceOfButtonsAccodingToPlayerState];
        }
    }
}


-(void) KMLParserFilenameError:(NSString*) assetFilename
{
    NSString* message = [NSString stringWithFormat:@"Hello Joey and Granty. The app found an unrecognised filename:'%@'. Please correct/remove it in the googlemap or send me the missing audio.NB the filenames are case sensitive. Thanks Lewdsx", assetFilename];
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Homemade Jam"
                                     message:message
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        
        
        UIAlertAction* okButton = [UIAlertAction
                                   actionWithTitle:@"OK"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {
                                       //Handle your yes please button action here
                                   }];
        
        
        [alert addAction:okButton];
        
        [self presentViewController:alert animated:YES completion:^{
            
        }];
    
}


@end
