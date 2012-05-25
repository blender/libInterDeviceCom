//
//  InterDeviceComController.h
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

#define kIDCPORT 40765

#import <Foundation/Foundation.h>
#import "GCDAsyncUdpSocket.h"
#import "DeviceInformation.h"

@protocol InterDeviceComProtocol <NSObject>

@required

-(void) receivedData:(NSData*) data fromHost:(NSString*) host;

@end


@interface InterDeviceComController : NSObject <GCDAsyncUdpSocketDelegate>
{
    NSMutableDictionary* _udpSockets;
    GCDAsyncUdpSocket* serverSocket;
    __weak id <InterDeviceComProtocol> _delegate;
}

@property (nonatomic, readonly) NSDictionary* udpSockets;
@property (weak, nonatomic) id<InterDeviceComProtocol> delegate;

+(id)sharedController;
-(void) startServer;
-(void) connectToDevice:(DeviceInformation*) device onPort:(int) port;
-(void) broadcastData:(NSData *) data;
-(void) sendData:(NSData *) data toDevice:(DeviceInformation*) device;
-(void) disconnectFromDevice:(DeviceInformation*) device;
-(void) disconnectAll;
@end
