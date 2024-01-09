//
//  AudioManager.m
//  KMLViewer
//
//  Created by Christian Lewcock on 24/06/2017.
//
//

//the AudioManager keeps two lists,
//the occupiedRegionFilenames is a list of all the occupied regions and their associated audio filename
// the audioPlayers is the players of those audio files
//note, these lists can differ in size as the user can occupy multiple regions with the same associated audio filename but there is only ever one player for any audio asset


#import "AudioManager.h"

#import "FadingAVPlayer.h"

@interface AudioManager ()

@property(strong, nonatomic) NSCountedSet <NSString*> * occupiedRegionFilenames;
@property(strong, nonatomic) NSMutableArray <FadingAVPlayer*>* audioPlayers;
@property() Boolean paused;

@end

@implementation AudioManager

-(id) init
{
    self = [super init];
    self.occupiedRegionFilenames = [[NSCountedSet alloc] init];
    self.audioPlayers = [[NSMutableArray alloc] init];
    self.paused = NO;
    return self;
}

-(void) resetOccupiedRegionFilenames:(NSArray*) newRegionFilnames
{
    self.occupiedRegionFilenames = [[NSCountedSet alloc] initWithArray:newRegionFilnames];
    for(NSString* assetFilename in self.occupiedRegionFilenames)
    {
        [self startAudioPlayer:assetFilename];
    }
    for(FadingAVPlayer* player in self.audioPlayers)
    {
        if([self.occupiedRegionFilenames countForObject:player.assetFilename] == 0)
            [player stop];
    }
}


-(void) startAudioPlayer:(NSString*) assetFilename
{
    FadingAVPlayer* player = [self getPlayerForFilename:assetFilename];
    if(player==nil) {
        player = [[FadingAVPlayer alloc] initWithFilename:assetFilename];
        if(player)
            [self.audioPlayers addObject:player];
    }
    if(player && !self.paused)
        [player play];
}

-(void) pause
{
    self.paused = YES;

    for(NSString* assetFilename in self.occupiedRegionFilenames)
    {
        FadingAVPlayer* player = [self getPlayerForFilename:assetFilename];
        [player pause];
    }
    
}

-(void) play
{
    self.paused = NO;

    for(NSString* assetFilename in self.occupiedRegionFilenames)
    {
        FadingAVPlayer* player = [self getPlayerForFilename:assetFilename];
        [player play];
    }
}

-(void) kill
{
    for(FadingAVPlayer* player in self.audioPlayers) {
        [player kill];
    }
}

-(FadingAVPlayer*) getPlayerForFilename:(NSString*) assetFilename {
    for(FadingAVPlayer* player in self.audioPlayers) {
        if([player.assetFilename isEqualToString:assetFilename])
            return player;
    }
    return nil;
}
@end

