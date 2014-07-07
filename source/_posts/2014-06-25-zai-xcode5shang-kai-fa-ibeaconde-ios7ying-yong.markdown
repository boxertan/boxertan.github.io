---
layout: post
title: "在xcode5上开发iBeacon的ios7应用"
date: 2014-06-25 09:30:10 +0800
comments: true
categories: 
---

![titlepic](/images/iBeacon_2014-06-25/iBeacon_2014-06-25.jpg)

## 前言

iBeacon的用处和好处我就不介绍了，大家可以看我最后面附录的参考文章。

本文重点介绍如何写一个app，通过2台iphone来实现iBeancon的收发。

强调一点，就是ibeacon是不能进行数据交互的，只能广播信号。

#### 所需材料

iBeacon 使用低功耗的蓝牙技术，所以你必须要有一个内置有低功耗蓝牙的 iOS 设备以便与 iBeacon 协同工作。

为了做完这个实验，你需要其中2台如下的设备：

1. iPhone 4s 或更新的
2. 第三代 iPad 或更新的
3. iPad mini 或更新的
4. 第五代iPod touch 或更新的

另外，还需要一个开发者帐号进行真机调试，或者请同事亲戚朋友导出他的开发者证书到你机器上，又或者这2台设备都已经越狱。

#### 基本概念

iBeacon 需要掌握的基本概念只有3个：ProximityUUID、major、minor。

ProximityUUID：感应标识符，全球唯一的标识符，128bit，通过命令uuidgen即可生成。用这个来区别其它公司或者机构的iBeacon产品。例如我们的咖啡店用下面的感应标识符：

    boxertandeiMac:boxertan.github.io boxertan$ uuidgen
    E172F7F9-4F2F-4378-A3A8-737433C6F9B1

major：主要值，扩展字段，16bit，比如说用来区别公司下属的分公司或者分店。例如我们的咖啡店分店：1为南山店，2为福田店，3为罗湖店，等等。

minor：次要值，再细分的扩展字段，16bit，比如说咖啡店南山分店用了10个 iBeacon 发射器，那么分别为1-10。

## 思路

1. 实现发射器
2. 实现接收器

<!-- more -->


## 实现



### 实现发射器

#### 添加framework

1. 选中项目名称

2. 选中TARGETS

3. 选中Build Phases

4. 在Link Binary With Libraries中添加CoreBluetooth.framework 和 CoreLocation.framework


#### 添加头文件和所需的类

在ConfigViewController.h添加头文件：

```objective-c 
    #import <CoreLocation/CoreLocation.h>
    #import <CoreBluetooth/CoreBluetooth.h>
```

并添加所需的属性：

```objective-c 
	@property (strong, nonatomic) CLBeaconRegion *beaconRegion;
	@property (strong, nonatomic) NSDictionary *beaconPeripheralData;
	@property (strong, nonatomic) CBPeripheralManager *peripheralManager;
```

再加上各种UI界面，整个代码如下ConfigViewController.h：

```objective-c 
	#import <UIKit/UIKit.h>
	#import <CoreLocation/CoreLocation.h>
	#import <CoreBluetooth/CoreBluetooth.h>
	
	@interface ConfigViewController : UIViewController <
	CBPeripheralManagerDelegate
	>
	{
	    NSMutableString *uuid;
	    NSMutableString *major;
	    NSMutableString *minor;
	    NSMutableString *identity;
	}
	
	
	@property (weak, nonatomic) IBOutlet UILabel *uuidLabel;
	@property (weak, nonatomic) IBOutlet UILabel *majorLabel;
	@property (weak, nonatomic) IBOutlet UILabel *minorLabel;
	@property (weak, nonatomic) IBOutlet UILabel *identityLabel;
	@property (weak, nonatomic) IBOutlet UITextField *uuidText;
	@property (weak, nonatomic) IBOutlet UITextField *majorText;
	@property (weak, nonatomic) IBOutlet UITextField *minorText;
	@property (weak, nonatomic) IBOutlet UITextField *identityText;
	
	- (IBAction)ViewTouchDown:(id)sender;
	
	@property (strong, nonatomic) CLBeaconRegion *beaconRegion;
	@property (strong, nonatomic) NSDictionary *beaconPeripheralData;
	@property (strong, nonatomic) CBPeripheralManager *peripheralManager;
	
	@end
```

##### 什么是CLBeaconRegion?

>CL就是CoreLocation的缩写。
CLBeaconRegion实现Beacon信号区域的功能。

##### 什么是CBPeripheralManager?

>CB就是CoreBluetooth的缩写。CBPeripheralManager实现Beacon发射广播信号的功能。


到此，我们准备用 beaconRegion 来设置UUID、主要值、次要值，用 peripheralManager 来发射信号。

#### 初始化发射的Beacon

```objective-c 
	- (void)initBeacon
	{
	    uuid = [NSMutableString stringWithString:@"23542266-18D1-4FE4-B4A1-23F8195B9D39"];
	    major = [NSMutableString stringWithString:@"11"];
	    minor = [NSMutableString stringWithString:@"12"];
	    identity = [NSMutableString stringWithString:@"com.BoXer.Test"];
	}
	
	- (void)setBeacon
	{
	    NSUUID *nsuuid = [[NSUUID alloc] initWithUUIDString:uuid];
	    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:nsuuid
	                                                                major:[major integerValue]
	                                                                minor:[minor integerValue]
	                                                           identifier:identity];
	}
	
	- (IBAction)transmitBeacon:(UIButton *)sender
	{
	    self.beaconPeripheralData = [self.beaconRegion peripheralDataWithMeasuredPower:nil];
	    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self
	                                                                                     queue:nil
	                                                                                   options:nil];
	    
	    [self setBeaconInfo];
	    [self updateLabels];
	    [self setBeacon];
	}
```

#### 接收发送广播的delegate

```objective-c 
	-(void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
	{
	    if (peripheral.state == CBPeripheralManagerStatePoweredOn)
	    {
	        NSLog(@"Powered On");
	        [self.peripheralManager startAdvertising:self.beaconPeripheralData];
	    }
	    else if (peripheral.state == CBPeripheralManagerStatePoweredOff)
	    {
	        NSLog(@"Powered Off");
	        [self.peripheralManager stopAdvertising];
	    }
	}
```

于是，整个ConfigViewController.m的代码如下：

```objective-c 
	#import "ConfigViewController.h"
	
	@interface ConfigViewController ()
	
	@end
	
	@implementation ConfigViewController
	
	- (void)viewDidLoad
	{
	    [super viewDidLoad];
		// Do any additional setup after loading the view.
	    
	    [self initBeacon];
	    [self setBeacon];
	    [self updateText];
	    [self updateLabels];
	    
	}
	
	- (void)initBeacon
	{
	    uuid = [NSMutableString stringWithString:@"23542266-18D1-4FE4-B4A1-23F8195B9D39"];
	    major = [NSMutableString stringWithString:@"11"];
	    minor = [NSMutableString stringWithString:@"12"];
	    identity = [NSMutableString stringWithString:@"com.BoXer.Test"];
	}
	
	- (void)setBeacon
	{
	    NSUUID *nsuuid = [[NSUUID alloc] initWithUUIDString:uuid];
	    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:nsuuid
	                                                                major:[major integerValue]
	                                                                minor:[minor integerValue]
	                                                           identifier:identity];
	}
	
	- (void)updateText
	{
	    self.uuidText.text = uuid;
	    self.majorText.text = major;
	    self.minorText.text = minor;
	    self.identityText.text = identity;
	}
	
	- (void)setBeaconInfo
	{
	    [uuid  setString: self.uuidText.text];
	    [major setString: self.majorText.text];
	    [minor setString: self.minorText.text];
	    [identity setString: self.identityText.text];
	}
	
	- (void)updateLabels
	{
	     self.uuidLabel.text = uuid;
	    self.majorLabel.text = major;
	    self.minorLabel.text = minor;
	    self.identityLabel.text = identity;
	}
	
	- (IBAction)transmitBeacon:(UIButton *)sender
	{
	    self.beaconPeripheralData = [self.beaconRegion peripheralDataWithMeasuredPower:nil];
	    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self
	                                                                                     queue:nil
	                                                                                   options:nil];
	    
	    [self setBeaconInfo];
	    [self updateLabels];
	    [self setBeacon];
	}
	
	-(void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
	{
	    if (peripheral.state == CBPeripheralManagerStatePoweredOn)
	    {
	        NSLog(@"Powered On");
	        [self.peripheralManager startAdvertising:self.beaconPeripheralData];
	    }
	    else if (peripheral.state == CBPeripheralManagerStatePoweredOff)
	    {
	        NSLog(@"Powered Off");
	        [self.peripheralManager stopAdvertising];
	    }
	}
	
	- (void)didReceiveMemoryWarning
	{
	    [super didReceiveMemoryWarning];
	    // Dispose of any resources that can be recreated.
	}
	
	- (IBAction)ViewTouchDown:(id)sender
	{
	    // 发送resignFirstResponder
	    // 这样使得点击空白处可收回键盘
	    [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
	}
	@end
```

做出来的界面是这样的：

![发射器截图](/images/iBeacon_2014-06-25/fasheqi.png)

### 实现接收器

在TrackViewController.h添加头文件：

```objective-c 
    #import <CoreLocation/CoreLocation.h>
```

并添加所需的属性：

```objective-c 
	@property (strong, nonatomic) CLBeaconRegion *beaconRegion;
	@property (strong, nonatomic) CLLocationManager *locationManager;
```
	
##### 什么是CLLocationManager?

>CL就是CoreLocation的缩写。
CLLocationManager实现位置管理。在这里主要是监控区域进出。

再加上一个UITableView，显示周围有多说个iBeacon发射器，于是 TrackViewController.h 代码如下：

```objective-c 
	#import <UIKit/UIKit.h>
	#import <CoreLocation/CoreLocation.h>
	
	@interface TrackViewController : UIViewController <
	CLLocationManagerDelegate,
	UITableViewDataSource,
	UITableViewDelegate>
	{
	    IBOutlet UITableView *tv;
	    
	    NSMutableArray *iBeaconsInfo;
	}
	
	@property (strong, nonatomic) CLBeaconRegion *beaconRegion;
	@property (strong, nonatomic) CLLocationManager *locationManager;
	
	@end
```

#### 初始化region

```objective-c 
	- (void)initRegion
	{
	    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:@"23542266-18D1-4FE4-B4A1-23F8195B9D39"];
	    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:@"123"];
	    [self.locationManager startMonitoringForRegion:self.beaconRegion];
	
	    if (iBeaconsInfo == nil)
	    {
	        iBeaconsInfo = [[NSMutableArray alloc] init];
	    }
	    
	}
```
#### 初始化locationManager

```objective-c 
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    [self initRegion];
    [self locationManager:self.locationManager didStartMonitoringForRegion:self.beaconRegion];
```

设置locationMagager的各种delegate

```objective-c 
	- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
	{
	    [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
	}
	
	- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
	{
	    NSLog(@"Beacon Found");
	    [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
	
	}
	
	-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
	{
	    NSLog(@"Left Region");
	    [self.locationManager stopRangingBeaconsInRegion:self.beaconRegion];
	
	    [tv reloadData];
	}
	
	-(void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
	{
	    if ([beacons count] > 0)
	    {
	        [iBeaconsInfo setArray:beacons];
	        [tv reloadData];
	    }
	}
```

整个 TrackViewController.m 如下：

```objective-c 
	#import "TrackViewController.h"
	
	@interface TrackViewController ()
	
	@end
	
	@implementation TrackViewController
	
	- (void)viewDidLoad
	{
	    [super viewDidLoad];
	
	    tv.delegate = self;
	    tv.dataSource = self;
	    [tv setBackgroundColor:[UIColor grayColor]];
	    
	    self.locationManager = [[CLLocationManager alloc] init];
	    self.locationManager.delegate = self;
	    [self initRegion];
	    [self locationManager:self.locationManager didStartMonitoringForRegion:self.beaconRegion];
	}
	
	
	
	- (void)initRegion
	{
	    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:@"23542266-18D1-4FE4-B4A1-23F8195B9D39"];
	    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:@"123"];
	    [self.locationManager startMonitoringForRegion:self.beaconRegion];
	
	    if (iBeaconsInfo == nil)
	    {
	        iBeaconsInfo = [[NSMutableArray alloc] init];
	    }
	    
	}
	
	- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
	{
	    [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
	}
	
	- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
	{
	    NSLog(@"Beacon Found");
	    [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
	
	}
	
	-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
	{
	    NSLog(@"Left Region");
	    [self.locationManager stopRangingBeaconsInRegion:self.beaconRegion];
	
	    [tv reloadData];
	}
	
	-(void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
	{
	    if ([beacons count] > 0)
	    {
	        [iBeaconsInfo setArray:beacons];
	        [tv reloadData];
	    }
	}
	
	#pragma mark - UITableView
	
	- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
	{
	    return 1;
	}
	
	- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
	{
	    return [iBeaconsInfo count];
	}
	
	- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
	{
	    static NSString *cellIdentifier = @"iBeaconsCell";
	    
	    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:cellIdentifier];
	    if (cell == nil)
	    {
	        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
	    }
	    
	    return [self prepareCellForBeaconInfo:cell index:indexPath];
	}
	
	- (UITableViewCell *)prepareCellForBeaconInfo:(UITableViewCell *)cell index:(NSIndexPath *)indexPath
	{
	    CLBeacon *beacon = [iBeaconsInfo objectAtIndex:indexPath.row];
	    NSString *distanceText = [[NSString alloc] init];
	    if (beacon.proximity == CLProximityUnknown)
	    {
	        distanceText = @"未知距离";
	    }
	    else if (beacon.proximity == CLProximityImmediate)
	    {
	        distanceText = @"非常近";
	    }
	    else if (beacon.proximity == CLProximityNear)
	    {
	        distanceText = @"近";
	    }
	    else if (beacon.proximity == CLProximityFar)
	    {
	        distanceText = @"远";
	    }
	    
	    cell.textLabel.numberOfLines = 0;
	    cell.detailTextLabel.numberOfLines = 0;
	    cell.textLabel.text = [NSString stringWithFormat:@"%@", beacon.proximityUUID.UUIDString];
	    cell.detailTextLabel.text = [NSString stringWithFormat:@"主要值：%@    次要值：%@\r\n感应距离：%f\r\n大概距离：%@    信号强度：%ld", beacon.major, beacon.minor, beacon.accuracy, distanceText, (long)beacon.rssi];
	    [cell sizeToFit];
	    
	    return cell;
	}
	
	- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
	{
	    return 100;
	}
	
	- (void)didReceiveMemoryWarning
	{
	    [super didReceiveMemoryWarning];
	    // Dispose of any resources that can be recreated.
	}
	
	@end
```

实际应用的界面如下：

![接收器截图](/images/iBeacon_2014-06-25/jieshouqi.png)

## 附录

[Region Monitoring and iBeacon](https://developer.apple.com/library/mac/documentation/UserExperience/Conceptual/LocationAwarenessPG/RegionMonitoring/RegionMonitoring.html)

[Developing iOS 7 Applications with iBeacons Tutorial](http://www.raywenderlich.com/66584/ios7-ibeacons-tutorial)

[What is iBeacon? An explanation and tutorial for iOS 7](http://createdineden.com/blog/2014/february/21/what-is-ibeacon-an-explanation-and-tutorial-for-ios-7/)

[iBeacons Tutorial for iOS 7 with CLBeaconRegion and CLBeacon](http://www.devfright.com/ibeacons-tutorial-ios-7-clbeaconregion-clbeacon/)
