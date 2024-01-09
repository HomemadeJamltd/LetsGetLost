//
//  AudioManager.h
//  KMLViewer
//
//  Created by Christian Lewcock on 24/06/2017.
//
//

#import <Foundation/Foundation.h>

@interface AudioManager : NSObject

-(id) init;
-(void) pause;
-(void) play;
-(void) kill;
-(void) resetOccupiedRegionFilenames:(NSArray*) regions;
@end
