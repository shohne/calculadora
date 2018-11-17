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
    NSLog(@"handleCommand");

    if (self.estado == AGUARDANDO_CAPTURA_AUDIO) {
        NSLog(@"AGUARDANDO_CAPTURA_AUDIO");
        
        
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        NSError *err = nil;
        [audioSession setCategory :AVAudioSessionCategoryPlayAndRecord error:&err];
        if (err)
        {
            NSLog(@"audioSession: %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
            return;
        }
        [audioSession setActive:YES error:&err];
        err = nil;
        if(err)
        {
            NSLog(@"audioSession: %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
            return;
        }
    
        recorderSettings = [[NSMutableDictionary alloc] init];
        [recorderSettings setValue:[NSNumber numberWithInt:kAudioFormatOpus] forKey:AVFormatIDKey];
        [recorderSettings setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
        [recorderSettings setValue:[NSNumber numberWithFloat:48000.0] forKey:AVSampleRateKey];
        [recorderSettings setValue:[NSNumber numberWithInt: 1] forKey:AVNumberOfChannelsKey];
    
        // Create a new audio file
        audioFileName = @"recordingFile";
        recorderFilePath = [NSString stringWithFormat:@"%@/%@.caf", DOCUMENTS_FOLDER, audioFileName] ;
    
        NSURL *url = [NSURL fileURLWithPath:recorderFilePath];
        err = nil;
        recorder = [[ AVAudioRecorder alloc] initWithURL:url settings:recorderSettings error:&err];
        if (!recorder) {
            NSLog(@"recorder: %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
        }
    
        //prepare to record
        [recorder setDelegate:self];
        [recorder prepareToRecord];
        recorder.meteringEnabled = YES;
    
        // start recording
        [recorder recordForDuration:(NSTimeInterval) 60];//Maximum recording time : 60 seconds default
        self.estado = CAPTURA_AUDIO;
        self.respostaDisponivel = FALSE;
        
        [self.btCommand setTitle:@"Recording..." forState:UIControlStateNormal];
        [self.btCommand setBackgroundColor:[UIColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:1.0]];
        [self.btPlay setBackgroundColor:[UIColor colorWithRed:1.0 green:0.0 blue:1.0 alpha:0.35]];

        [self.btPlay setEnabled:NO];

        NSLog(@"Recording Started");
        return;
    }
    
    if (self.estado == CAPTURA_AUDIO) {
        NSLog(@"CAPTURA_AUDIO");
        [recorder stop];
        return;
    }

}


- (void)handlePlay:(id)sender {
    NSLog(@"handlePlay");
    if (self.respostaDisponivel) {
        NSError *error = nil;
        [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
        NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        url = [url URLByAppendingPathComponent:@"result.mp3"];
        self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
        [self.player setVolume:1.0];
        [self.player play];
    }
}


- (void)handleSettings:(id)sender {
    
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Settings" message:@"Server address" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *submit = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
        {
            if (alert.textFields.count > 0) {
                UITextField *textField = [alert.textFields firstObject];
                self.enderecoServidor = textField.text;
            }
        }
    ];
    [alert addAction:submit];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = self.enderecoServidor;
    }];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *) aRecorder successfully:(BOOL)flag
{
    NSLog (@"audioRecorderDidFinishRecording:successfully:");
    NSData *data = [NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/%@.caf", DOCUMENTS_FOLDER, audioFileName]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.enderecoServidor] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
    request.HTTPMethod = @"POST";
    [request setValue:@"audio/ogg" forHTTPHeaderField:@"Content-Type"];
    request.HTTPBody = data;
    NSURLResponse *response = nil;
    
    NSLog(@"data size %ld", data.length);
    
    [self.btCommand setTitle:@"Sending..." forState:UIControlStateNormal];
    [self.btCommand setBackgroundColor:[UIColor colorWithRed:1.0 green:0.0 blue:0.5 alpha:1.0]];

    
    [NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc] init] completionHandler:
        ^(NSURLResponse *response, NSData *dataResponse, NSError *error) {
            if ([data length] > 0 && error == nil) {
                [dataResponse writeToFile:[NSString stringWithFormat:@"%@/result.mp3", DOCUMENTS_FOLDER] atomically:YES];
                NSLog(@"response saved to disk");

                dispatch_async(dispatch_get_main_queue(), ^{
                        [self.btCommand setTitle:@"Record" forState:UIControlStateNormal];
                        [self.btCommand setBackgroundColor:[UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0]];
                        self.respostaDisponivel = TRUE;
                        [self.btPlay setEnabled:YES];
                        [self.btPlay setBackgroundColor:[UIColor colorWithRed:1.0 green:0.0 blue:1.0 alpha:1.0]];
                        [self handlePlay:nil];
                    }
                );

                self.estado = AGUARDANDO_CAPTURA_AUDIO;
            }
            else if ([data length] == 0 && error == nil)
                NSLog(@"dataResponse length is 0");
            else if (error != nil && error.code == NSURLErrorTimedOut)
                NSLog(@"timeout");
            else if (error != nil)
                NSLog(@"connection error");
                NSLog(@"Error %@",[error localizedFailureReason]);
        }
     ];
}

@end
