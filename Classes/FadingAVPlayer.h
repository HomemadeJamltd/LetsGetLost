//
//  FadingAVPlayer.h
//  KMLViewer
//
//  Created by Christian Lewcock on 24/06/2017.
//
//

#import <AVFoundation/AVFoundation.h>

@interface FadingAVPlayer : AVPlayer

-(void) stop;
-(void) play;
-(void) kill;

-(id) initWithFilename:(NSString*) assetFilename;

@property (strong, nonatomic) NSString* assetFilename;

@end
