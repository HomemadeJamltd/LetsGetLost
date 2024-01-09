//
//  FadingAVPlayer.m
//  KMLViewer
//
//  Created by Christian Lewcock on 24/06/2017.
//
//

#import "FadingAVPlayer.h"

@interface FadingAVPlayer ()
@property (nonatomic) float desiredVolume;
@property (nonatomic) BOOL fading;
@end

@implementation FadingAVPlayer


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    if ([[object class] isSubclassOfClass:[FadingAVPlayer class] ] && [keyPath isEqualToString:@"status"]) {
        FadingAVPlayer* player = (FadingAVPlayer*) object;
        if (player.status == AVPlayerStatusReadyToPlay) {
            [player fadeToDesiredVolume];
        } else if (player.status == AVPlayerStatusFailed) {
            // something went wrong. player.error should contain some information
        }
    }
}

-(void) playerItemDidReachEnd:(NSNotification*) note
{
    [self seekToTime:kCMTimeZero];
    [super play];
}

-(id) initWithFilename:(NSString *)assetFilename{

    NSString *path = [[NSBundle mainBundle] pathForResource:[assetFilename stringByDeletingPathExtension] ofType:[assetFilename pathExtension]];
    if(!path)
        return nil;
    NSURL *url = [NSURL fileURLWithPath:path];
    if(!url)
        return nil;
    id asset = [AVAsset assetWithURL:url];
    if(!asset)
        return nil;
    NSArray *assetKeys = @[@"playable", @"hasProtectedContent"];
    
    // Create a new AVPlayerItem with the asset and an
    // array of asset keys to be automatically loaded
    AVPlayerItem* playerItem = [AVPlayerItem playerItemWithAsset:asset
                                    automaticallyLoadedAssetKeys:assetKeys];

    self = [super initWithPlayerItem:playerItem];
    [self addObserver:self forKeyPath:@"status" options:0 context:nil];
    self.assetFilename = assetFilename;
    self.volume = 0.0;
    self.fading = NO;
    self.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:nil];
    _desiredVolume = 0.0; //always fade in
    return self;
}

-(void)fadeToDesiredVolume
{
    self.fading = YES;
    float increment = 0.05;
    if (self.volume > (self.desiredVolume + increment)) {
        self.volume = self.volume - increment;
        [self performSelector:@selector(fadeToDesiredVolume) withObject:nil afterDelay:0.2];
    } else if (self.volume < (self.desiredVolume - increment)) {
        self.volume = self.volume + increment;
        [self performSelector:@selector(fadeToDesiredVolume) withObject:nil afterDelay:0.2];
    }
    else
    {
        self.fading = NO;
        self.volume = self.desiredVolume;
        if(self.volume == 0) {
            [self pause];
        }
    }
}


-(void) stop
{
    self.desiredVolume = 0.0;
    if (self.timeControlStatus ==  AVPlayerTimeControlStatusPaused)
        self.volume = self.desiredVolume;
    else if (self.timeControlStatus ==  AVPlayerTimeControlStatusPlaying)
    {
        if(!self.fading)
            [self fadeToDesiredVolume];
    }
}

-(void) play 
{
    self.desiredVolume = 1.0;
    if (self.timeControlStatus ==  AVPlayerTimeControlStatusPaused)
    {
        [super play];
        if(!self.fading && (self.status == AVPlayerStatusReadyToPlay))
            [self fadeToDesiredVolume];
    }
}

-(void) kill
{
    [self pause];
    [self replaceCurrentItemWithPlayerItem:nil];
}

@end
