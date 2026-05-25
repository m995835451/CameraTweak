#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

#define LOG(fmt, ...) NSLog(@"[CameraTweak] " fmt, ##__VA_ARGS__)

static NSString *videoPath = @"/var/mobile/Media/hijack.mov";
static BOOL hijackEnabled = YES;
static AVAssetReader *reader = nil;
static AVAssetReaderTrackOutput *readerOutput = nil;

void initVideoReader() {
    if (reader) {
        [reader cancelReading];
        reader = nil;
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:videoPath]) {
        LOG(@"视频不存在: %@", videoPath);
        return;
    }
    NSURL *url = [NSURL fileURLWithPath:videoPath];
    AVAsset *asset = [AVAsset assetWithURL:url];
    AVAssetTrack *track = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    if (!track) return;
    NSError *error = nil;
    reader = [AVAssetReader assetReaderWithAsset:asset error:&error];
    NSDictionary *settings = @{
        (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)
    };
    readerOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:track
                                                               outputSettings:settings];
    [reader addOutput:readerOutput];
    [reader startReading];
    LOG(@"解码器初始化成功");
}

CMSampleBufferRef getNextFrame() {
    if (!reader || reader.status != AVAssetReaderStatusReading) {
        if (reader && reader.status == AVAssetReaderStatusCompleted) {
            initVideoReader();
        }
        return NULL;
    }
    return [readerOutput copyNextSampleBuffer];
}

%hook AVCaptureVideoDataOutput
- (void)setSampleBufferDelegate:(id)delegate queue:(dispatch_queue_t)queue {
    %orig;
    LOG(@"已钩住相机输出");
}
%end

%hook NSObject(AVCaptureVideoDataOutputSampleBufferDelegate)
- (void)captureOutput:(AVCaptureOutput *)output 
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer 
       fromConnection:(AVCaptureConnection *)connection {
    if (hijackEnabled) {
        CMSampleBufferRef fakeBuffer = getNextFrame();
        if (fakeBuffer) {
            %orig(output, fakeBuffer, connection);
            return;
        }
    }
    %orig;
}
%end
