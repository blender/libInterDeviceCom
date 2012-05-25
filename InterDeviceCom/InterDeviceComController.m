//
//  InterDeviceComController.m
//  InterDeviceCom
//
//  Copyright (c) 2012 Tommaso Piazza <tommaso.piazza@gmail.com>
//
//  This file is part of InterDeviceCom software library.
//
//  InterDeviceCom software library is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  InterDeviceCom software library is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU Lesser General Public License
//  along with InterDeviceCom software library.  If not, see <http://www.gnu.org/licenses/>.

#import "InterDeviceComController.h"

@implementation InterDeviceComController

@synthesize udpSockets = _udpSockets;
@synthesize delegate = _delegate;

+ (InterDeviceComController *) sharedController
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

- (InterDeviceComController *)init
{
    self = [super init];
    if (self) {
        _udpSockets = [NSMutableDictionary dictionary];
    }
    
    return self;
}

-(void) startServer
{

    NSError* error;
    
    serverSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    if([serverSocket bindToPort:kIDCPORT error:&error]){
    
       [serverSocket beginReceiving:&error]; 
    }
    

}

- (void) connectToDevice:(DeviceInformation *)device onPort:(int)port
{

    NSNumber* descByteValue = [NSNumber numberWithUnsignedChar:device.contactDescriptorByteValue];
    
    GCDAsyncUdpSocket* sock = [_udpSockets objectForKey:descByteValue];
    if(sock == nil){
    
        sock = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        NSError* error;
        
        [sock connectToHost:device.ipAddr onPort:port error:&error];
        [_udpSockets setObject:sock forKey:descByteValue];
    
    }
    
}

-(void) disconnectFromDevice:(DeviceInformation *)device 
{

    NSNumber* descByteValue = [NSNumber numberWithUnsignedChar:device.contactDescriptorByteValue];
    GCDAsyncUdpSocket* sock = [_udpSockets objectForKey:descByteValue];
    
    if(sock != nil){
    
        [sock close];
    }
}

-(void) disconnectAll
{

    NSArray* sockarr = [_udpSockets allValues];
    NSArray* keyarr = [_udpSockets allKeys];
    
    //FIXME: This assumes one value per key
    //It could screw up the entire dictionary
    
    for(int i = 0; i  < keyarr.count; i++){
        
        GCDAsyncUdpSocket* sock = [sockarr objectAtIndex:i];
        DeviceInformation* device = [keyarr objectAtIndex:i];
        [sock close];
        
        [_udpSockets removeObjectForKey:device];
    }

}

-(void) sendData:(NSData *) data toDevice:(DeviceInformation*) device
{

    NSNumber* descByteValue = [NSNumber numberWithUnsignedChar:device.contactDescriptorByteValue];
    GCDAsyncUdpSocket* sock = [_udpSockets objectForKey:descByteValue];
    
    
    if(sock == nil){
        sock = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        [_udpSockets setObject:sock forKey:descByteValue];
    }
    
    
    if(sock != nil){
        NSError* error;
        
        [sock sendData:data toHost:device.ipAddr port:kIDCPORT withTimeout:-1 tag:0];
        if(error != nil)
            NSLog(@"%@", error.description);
    }
}

-(void) broadcastData:(NSData *)data 
{

    NSArray* array = [_udpSockets allValues];
    
    for(int i = 0; i  < array.count; i++){
        NSError* error;
        
        GCDAsyncUdpSocket* sock = [array objectAtIndex:i];
        [sock sendData:data withTimeout:-1 tag:0];
        [sock beginReceiving:&error];
    }

}

#pragma mark -
#pragma mark GCDAsyncUdpSocketDelegate Protocol

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext
{
    
    if ([_delegate conformsToProtocol:@protocol(InterDeviceComProtocol)]) {
        
        NSString* host = [GCDAsyncUdpSocket hostFromAddress:address];
        [_delegate receivedData:data fromHost:host];
    }
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    
    //NSLog(@"SpinchModel Sent");
}

-(void) udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{

     NSLog(@"%@", error.description);
}
@end
