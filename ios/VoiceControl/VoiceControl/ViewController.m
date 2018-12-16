//
//  ViewController.m
//  VoiceControl
//
//  Created by Silvio Hohne on 11/12/18.
//  Copyright © 2018 Silvio Hohne. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <os/log.h>
#import <WebKit/WebKit.h>

#define DOCUMENTS_FOLDER [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]

#define AGUARDANDO_CAPTURA_AUDIO  10
#define CAPTURA_AUDIO  20


@interface ViewController ()

@end

@implementation ViewController


@synthesize recorder,recorderSettings,recorderFilePath;
@synthesize player,audioFileName,enderecoServidor,sequence,estado,respostaDisponivel;


- (void)viewDidLoad {
    
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    self.enderecoServidor = @"http://192.168.25.113:19080/calculadora/voice";
    self.estado = AGUARDANDO_CAPTURA_AUDIO;
    
    self.btCommand = [[UIButton alloc] initWithFrame:CGRectMake(30, 70, self.view.frame.size.width - 60, 80)];
    [self.btCommand setTitle:@"Record" forState:UIControlStateNormal];
    [self.btCommand setBackgroundColor:[UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0]];
    self.btCommand.layer.cornerRadius = 20;
    self.btCommand.clipsToBounds = YES;
    [self.btCommand addTarget:self action:@selector(handleCommand:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.btCommand];
    
    self.btPlay = [[UIButton alloc] initWithFrame:CGRectMake(30, 170, self.view.frame.size.width - 60, 80)];
    [self.btPlay setTitle:@"Play" forState:UIControlStateNormal];
    [self.btPlay setBackgroundColor:[UIColor colorWithRed:1.0 green:0.0 blue:1.0 alpha:0.35]];
    self.btPlay.layer.cornerRadius = 20;
    self.btPlay.clipsToBounds = YES;
    [self.btPlay addTarget:self action:@selector(handlePlay:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.btPlay];
    [self.btPlay setEnabled:FALSE];
    
    self.btSettings = [[UIButton alloc] initWithFrame:CGRectMake(30, self.view.frame.size.height - 120, self.view.frame.size.width - 60, 80)];
    [self.btSettings setTitle:@"Settings" forState:UIControlStateNormal];
    [self.btSettings setBackgroundColor:[UIColor blueColor]];
    self.btSettings.layer.cornerRadius = 20;
    self.btSettings.clipsToBounds = YES;
    [self.btSettings addTarget:self action:@selector(handleSettings:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.btSettings];
    [self.btSettings setEnabled:YES];
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
}

- (void)handleCommand:(id)sender {
    os_log(OS_LOG_DEFAULT, "handleCommand");
    
    if (self.estado == AGUARDANDO_CAPTURA_AUDIO) {
        os_log(OS_LOG_DEFAULT, "handleCommand.1000");
        os_log(OS_LOG_DEFAULT, "AGUARDANDO_CAPTURA_AUDIO");
        
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        os_log(OS_LOG_DEFAULT, "handleCommand.1100");
        NSError *err = nil;
        [audioSession setCategory :AVAudioSessionCategoryPlayAndRecord error:&err];
        if (err)
        {
            os_log(OS_LOG_DEFAULT, "handleCommand.1200");
            os_log(OS_LOG_DEFAULT, "AGUARDANDO_CAPTURA_AUDIO   %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
            return;
        }
        os_log(OS_LOG_DEFAULT, "handleCommand.1300");
        [audioSession setActive:YES error:&err];
        err = nil;
        os_log(OS_LOG_DEFAULT, "handleCommand.1400");
        if(err)
        {
            os_log(OS_LOG_DEFAULT, "handleCommand.1500");
            os_log(OS_LOG_DEFAULT, "audioSession: %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
            return;
        }
        
        os_log(OS_LOG_DEFAULT, "handleCommand.1600");
        recorderSettings = [[NSMutableDictionary alloc] init];
        [recorderSettings setValue:[NSNumber numberWithInt:kAudioFormatOpus] forKey:AVFormatIDKey];
        [recorderSettings setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
        os_log(OS_LOG_DEFAULT, "handleCommand.1700");
        [recorderSettings setValue:[NSNumber numberWithFloat:48000.0] forKey:AVSampleRateKey];
        [recorderSettings setValue:[NSNumber numberWithInt: 1] forKey:AVNumberOfChannelsKey];
        
        // Create a new audio file
        os_log(OS_LOG_DEFAULT, "handleCommand.1800");
        audioFileName = @"recordingFile";
        recorderFilePath = [NSString stringWithFormat:@"%@/%@.caf", DOCUMENTS_FOLDER, audioFileName] ;
        
        os_log(OS_LOG_DEFAULT, "handleCommand.1900");
        NSURL *url = [NSURL fileURLWithPath:recorderFilePath];
        err = nil;
        os_log(OS_LOG_DEFAULT, "handleCommand.2000");
        recorder = [[ AVAudioRecorder alloc] initWithURL:url settings:recorderSettings error:&err];
        os_log(OS_LOG_DEFAULT, "handleCommand.2100");
        if (!recorder) {
            os_log(OS_LOG_DEFAULT, "handleCommand.2200");
            os_log(OS_LOG_DEFAULT, "AGUARDANDO_CAPTURA_AUDIO""recorder: %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
        }
        
        //prepare to record
        os_log(OS_LOG_DEFAULT, "handleCommand.2300");
        [recorder setDelegate:self];
        [recorder prepareToRecord];
        os_log(OS_LOG_DEFAULT, "handleCommand.2400");
        recorder.meteringEnabled = YES;
        
        // start recording
        [recorder recordForDuration:(NSTimeInterval) 60];//Maximum recording time : 60 seconds default
        os_log(OS_LOG_DEFAULT, "handleCommand.2500");
        self.estado = CAPTURA_AUDIO;
        self.respostaDisponivel = FALSE;
        
        os_log(OS_LOG_DEFAULT, "handleCommand.2600");
        [self.btCommand setTitle:@"Recording..." forState:UIControlStateNormal];
        [self.btCommand setBackgroundColor:[UIColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:1.0]];
        [self.btPlay setBackgroundColor:[UIColor colorWithRed:1.0 green:0.0 blue:1.0 alpha:0.35]];
        os_log(OS_LOG_DEFAULT, "handleCommand.2700");
        
        [self.btPlay setEnabled:NO];
        
        os_log(OS_LOG_DEFAULT, "handleCommand.2800");
        NSLog(@"Recording Started");
        os_log(OS_LOG_DEFAULT, "handleCommand.9999A");
        return;
    }
    os_log(OS_LOG_DEFAULT, "handleCommand.2900");
    
    if (self.estado == CAPTURA_AUDIO) {
        os_log(OS_LOG_DEFAULT, "CAPTURA_AUDIO");
        [recorder stop];
        os_log(OS_LOG_DEFAULT, "handleCommand.9999B");
        return;
    }
    os_log(OS_LOG_DEFAULT, "handleCommand.9999Z");
}


- (void)handlePlay:(id)sender {
    os_log(OS_LOG_DEFAULT, "handlePlay");
    os_log(OS_LOG_DEFAULT, "handlePlay");
    if (self.respostaDisponivel) {
        os_log(OS_LOG_DEFAULT, "handlePlay.1000");
        NSError *error = nil;
        [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
        os_log(OS_LOG_DEFAULT, "handlePlay.1100");
        NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        url = [url URLByAppendingPathComponent:@"result.mp3"];
        os_log(OS_LOG_DEFAULT, "handlePlay.1200");
        self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
        [self.player setVolume:1.0];
        os_log(OS_LOG_DEFAULT, "handlePlay.1300");
        [self.player play];
    }
    os_log(OS_LOG_DEFAULT, "handlePlay.9999");
}


- (void)handleSettings:(id)sender {
    os_log(OS_LOG_DEFAULT, "handleSettings");
    
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Settings" message:@"Server address" preferredStyle:UIAlertControllerStyleAlert];
    os_log(OS_LOG_DEFAULT, "handleSettings.1000");
    UIAlertAction *submit = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                             {
                                 os_log(OS_LOG_DEFAULT, "handleSettings.1100");
                                 if (alert.textFields.count > 0) {
                                     os_log(OS_LOG_DEFAULT, "handleSettings.1200");
                                     UITextField *textField = [alert.textFields firstObject];
                                     self.enderecoServidor = textField.text;
                                 }
                             }
                             ];
    os_log(OS_LOG_DEFAULT, "handleSettings.1300");
    [alert addAction:submit];
    os_log(OS_LOG_DEFAULT, "handleSettings.1400");
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    
    UIAlertAction *test = [UIAlertAction actionWithTitle:@"Test" style:UIAlertActionStyleDestructive  handler:^(UIAlertAction * action)
                           {
                               os_log(OS_LOG_DEFAULT, "handleSettings.1410");
                               WKWebView *webView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:[[WKWebViewConfiguration alloc] init]];
                               NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.enderecoServidor]];
                               [webView loadRequest:request];
                               [self.view addSubview:webView];
                               
                           }
                           ];
    
    [alert addAction:test];
    
    os_log(OS_LOG_DEFAULT, "handleSettings.1500");
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        os_log(OS_LOG_DEFAULT, "handleSettings.1600");
        textField.text = self.enderecoServidor;
    }];
    os_log(OS_LOG_DEFAULT, "handleSettings.1700");
    [self presentViewController:alert animated:YES completion:nil];
    os_log(OS_LOG_DEFAULT, "handleSettings.9999");
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *) aRecorder successfully:(BOOL)flag
{
    os_log(OS_LOG_DEFAULT, "audioRecorderDidFinishRecording");
    os_log(OS_LOG_DEFAULT, "audioRecorderDidFinishRecording %@", self.enderecoServidor);
    NSData *data = [NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/%@.caf", DOCUMENTS_FOLDER, audioFileName]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.enderecoServidor] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
    request.HTTPMethod = @"POST";
    os_log(OS_LOG_DEFAULT, "audioRecorderDidFinishRecording.1000");
    [request setValue:@"audio/ogg" forHTTPHeaderField:@"Content-Type"];
    request.HTTPBody = data;
    NSURLResponse *response = nil;
    os_log(OS_LOG_DEFAULT, "audioRecorderDidFinishRecording.1100");
    
    os_log(OS_LOG_DEFAULT, "data size %ld", data.length);
    
    [self.btCommand setTitle:@"Sending..." forState:UIControlStateNormal];
    [self.btCommand setBackgroundColor:[UIColor colorWithRed:1.0 green:0.0 blue:0.5 alpha:1.0]];
    os_log(OS_LOG_DEFAULT, "audioRecorderDidFinishRecording.1200");
    
    
    [NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc] init] completionHandler:
     ^(NSURLResponse *response, NSData *dataResponse, NSError *error) {
         os_log(OS_LOG_DEFAULT, "audioRecorderDidFinishRecording.1300");
         if ([data length] > 0 && error == nil) {
             os_log(OS_LOG_DEFAULT, "audioRecorderDidFinishRecording.1400");
             [dataResponse writeToFile:[NSString stringWithFormat:@"%@/result.mp3", DOCUMENTS_FOLDER] atomically:YES];
             os_log(OS_LOG_DEFAULT, "response saved to disk");
             
             os_log(OS_LOG_DEFAULT, "audioRecorderDidFinishRecording.1500");
             dispatch_async(dispatch_get_main_queue(), ^{
                 os_log(OS_LOG_DEFAULT, "audioRecorderDidFinishRecording.1600");
                 [self.btCommand setTitle:@"Record" forState:UIControlStateNormal];
                 [self.btCommand setBackgroundColor:[UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0]];
                 self.respostaDisponivel = TRUE;
                 [self.btPlay setEnabled:YES];
                 [self.btPlay setBackgroundColor:[UIColor colorWithRed:1.0 green:0.0 blue:1.0 alpha:1.0]];
                 [self handlePlay:nil];
                 os_log(OS_LOG_DEFAULT, "audioRecorderDidFinishRecording.1700");
             }
                            );
             os_log(OS_LOG_DEFAULT, "audioRecorderDidFinishRecording.1800");
             
             self.estado = AGUARDANDO_CAPTURA_AUDIO;
         }
         else if ([data length] == 0 && error == nil) {
             os_log(OS_LOG_DEFAULT, "audioRecorderDidFinishRecording.1900");
             os_log(OS_LOG_DEFAULT, "dataResponse length is 0");
         }
         else if (error != nil && error.code == NSURLErrorTimedOut) {
             os_log(OS_LOG_DEFAULT, "audioRecorderDidFinishRecording.2000  %@ %ld %@", [error domain], (long)[error code], [[error userInfo] description]);
             os_log(OS_LOG_DEFAULT, "timeout");
         }
         else if (error != nil) {
             os_log(OS_LOG_DEFAULT, "audioRecorderDidFinishRecording.2100  %@ %ld %@", [error domain], (long)[error code], [[error userInfo] description]);
             os_log(OS_LOG_DEFAULT, "connection error");
             os_log(OS_LOG_DEFAULT, "Error %@",[error localizedFailureReason]);
         }
         os_log(OS_LOG_DEFAULT, "audioRecorderDidFinishRecording.2200");
     }
     ];
    os_log(OS_LOG_DEFAULT, "audioRecorderDidFinishRecording.9999");
}

@end
