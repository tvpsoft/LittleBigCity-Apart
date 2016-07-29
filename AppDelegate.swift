//
//  AppDelegate.swift
//  LittleBigCity
//
//  Created by Viet Phuong Tran on 12/29/15.
//  Copyright © 2015 Viet Phuong Tran. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKShareKit
import FBSDKLoginKit
import CoreLocation
import Siesta
import SwiftyJSON
import Fabric
import Crashlytics
import RealmSwift
import AWSCore
import Branch;


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    let locationManager = CLLocationManager();
    var needOpenActivity : Int = 0;
    
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // Realm migration:
        let config = Realm.Configuration(
            // Set the new schema version. This must be greater than the previously used
            // version (if you've never set a schema version before, the version is 0).
            schemaVersion: 2,
            // Set the block which will be called automatically when opening a Realm with
            // a schema version lower than the one set above
            migrationBlock: { migration, oldSchemaVersion in
                // We haven’t migrated anything yet, so oldSchemaVersion == 0
                if (oldSchemaVersion < 1) {
                    // Nothing to do!
                    // Realm will automatically detect new properties and removed properties
                    // And will update the schema on disk automatically
                }
                
                
                
                migration.enumerate(User.className()) { oldObject, newObject in
                    // Add the `fullName` property only to Realms with a schema version of 0
                    if oldSchemaVersion < 1 {
                        // Nothing todo
                    }
                    
                    // Add the `publicChannelNotif` and `publicChannelLastSeenId` property to Realms with a schema version of 0 or 1
                    if oldSchemaVersion < 2 {
                        newObject!["publicChannelNotif"] = false
                        newObject!["publicChannelLastSeenId"] = 0
                    }
                }
        })
        
        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = config
        
        // Now that we've told Realm how to handle the schema change, opening the file
        // will automatically perform the migration
        let realm = try! Realm()
        
        // Facebook
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        // Bug tracking
        Fabric.with([Crashlytics.self])

        mixpanel.showNotificationOnActive = true;
        mixpanel.miniNotificationPresentationTime = 10.0;
        
        // Update Location from background
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation //kCLLocationAccuracyBestForNavigation
        
        // Ask
        // locationManager.requestAlwaysAuthorization()
        // application .registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Sound , .Alert], categories: nil))
        
        if CLLocationManager.authorizationStatus() == .AuthorizedAlways {
            startMonitoringLocation()
        }
        
        // Open Chat or Detail screen from clicked in push Notification
        if let payload = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] as? NSDictionary, _aps = payload["aps"] as? NSDictionary, data = payload["payload"] as? String {
            let _data = JSON.parse(data)
            
            if( _aps["category"] as? String == "CATEGORY_CHAT"){    
                let _dis = Discussion().saveValueWhenOpenChat(_data["discussion"])
                Chat().saveOneValueFromJSON(_data["chat"])!
                // Add chat contents via call notification center
                let chatController = storyboardMain.instantiateViewControllerWithIdentifier("chatScreen") as! DetailChatViewController
                chatController.isOpenFromLaunch = true
                chatController.discussion = _dis
                
                let navigationController = UINavigationController(rootViewController: chatController)
                navigationController.navigationBarHidden = true
                
                window?.rootViewController = navigationController

            }else{
            
                if(_data["activity_id"].intValue > 0){
                    if ( application.applicationState == .Inactive || application.applicationState == .Background  )
                    {
                        //open Activity from push
                        let _vc = storyboardActivityDetail.instantiateViewControllerWithIdentifier("activityDetailView") as! DetailsViewController
                        _vc.activityId = _data["activity_id"].intValue
                        _vc.isOpenFromLaunch = true
                        let navigationController = UINavigationController(rootViewController: _vc)
                        navigationController.navigationBarHidden = true
                        window?.rootViewController = navigationController
                    }
                }
                
                if(_data["category_id"].stringValue.length > 0){
                    
                    if ( application.applicationState == .Inactive || application.applicationState == .Background  )
                    {
                        //open Activity from push
                        let _vc = storyboardLongList.instantiateViewControllerWithIdentifier("longListView") as! LongListViewController
                        var cate:Int = CATEGORY.ARTS;
                        switch(_data["category_id"].stringValue){
                        case "1":
                            cate = CATEGORY.ARTS
                            break;
                        case "2":
                            cate = CATEGORY.CONCERTS
                            break;
                        case "3":
                            cate = CATEGORY.DRINKS
                            break;
                        case "4":
                            cate = CATEGORY.FOODS
                            break;
                        case "5":
                            cate = CATEGORY.PARTIES
                            break;
                        case "6":
                            cate = CATEGORY.SHOPS
                            break;
                        case "7":
                            cate = CATEGORY.CAFE
                            break;
                        case "offer":
                            cate = CATEGORY.EXCLUSIVE_OFFERS
                            break;
                        default:
                            break
                        }
                        _vc.catSelected = cate
                        _vc.isOpenFromLaunch = true
                        let navigationController = UINavigationController(rootViewController: _vc)
                        navigationController.navigationBarHidden = true
                        window?.rootViewController = navigationController
                    }
                }
            }
        }
        
        
        // Branch
        let branch: Branch = Branch.getInstance()
        branch.initSessionWithLaunchOptions(launchOptions, andRegisterDeepLinkHandler: { optParams, error in
            if error == nil, let params = optParams {
                // params are the deep linked params associated with the link that the user clicked -> was re-directed to this app
                // params will be empty if no data found
                if(params["eid"] != nil && (User().getCurrentUser()?.id > 0)){
                
                    //open Activity from banner deeplink
                    let _vc = storyboardActivityDetail.instantiateViewControllerWithIdentifier("activityDetailView") as! DetailsViewController
                    _vc.activityId = (params["eid"]?.integerValue)!
                    _vc.isOpenFromLaunch = true
                    let navigationController = UINavigationController(rootViewController: _vc)
                    navigationController.navigationBarHidden = true
                    self.window?.rootViewController = navigationController
                
                }
            }
        })
    
        return true
    }
    
    
        

    
    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool
    {
        let parsedUrl = BFURL.init(inboundURL: url, sourceApplication: nil)
        
        if (parsedUrl != nil) {
            // this is an applink url, handle it here
            let targetUrl = parsedUrl.targetURL
            // UIAlertView.init(title: "Received link", message: targetUrl.absoluteString, delegate: nil, cancelButtonTitle: "OK").show()
            if(targetUrl.absoluteString.containsString("lbcity://")){
                let strEid = targetUrl.absoluteString.characters.split{$0 == "="}.map(String.init)
                let eid : Int = strEid.count > 0 ? Int(strEid[1])! : 0
                if (eid > 0 ){
                    //                    self.needOpenActivity = eid
                    //open Activity from lbcity
                    let _vc = storyboardActivityDetail.instantiateViewControllerWithIdentifier("activityDetailView") as! DetailsViewController
                    _vc.activityId = eid
                    _vc.isOpenFromLaunch = true
                    let navigationController = UINavigationController(rootViewController: _vc)
                    navigationController.navigationBarHidden = true
                    self.window?.rootViewController = navigationController
                }
            }
        }
        
        // pass the url to the handle deep link call
        // if handleDeepLink returns true, and you registered a callback in initSessionAndRegisterDeepLinkHandler, the callback will be called with the data associated with the deep link
        // pass the url to the handle deep link call
        Branch.getInstance().handleDeepLink(url);
        
        FBSDKApplicationDelegate.sharedInstance().application(app, openURL: url, sourceApplication: options["UIApplicationOpenURLOptionsSourceApplicationKey"] as! String, annotation: options["UIApplicationOpenURLOptionsAnnotationKey"])
        return true
    }
    
    
    func application(application: UIApplication, continueUserActivity userActivity: NSUserActivity, restorationHandler: ([AnyObject]?) -> Void) -> Bool {
        
        // pass the url to the handle deep link call
        Branch.getInstance().continueUserActivity(userActivity);
        return true
    }


    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        FBSDKAppEvents.activateApp()
        NSNotificationCenter.defaultCenter().postNotificationName("refreshConnection", object: nil)
        NSNotificationCenter.defaultCenter().postNotificationName("refreshChatContent", object: nil)
        NSNotificationCenter.defaultCenter().postNotificationName("bindDataForDateSelector", object: nil)
        
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    ////
    // Notification delegate
    ////
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        print("Got token data! \(deviceToken)")
        let characterSet: NSCharacterSet = NSCharacterSet( charactersInString: "<>" )
        let deviceTokenString: String = ( deviceToken.description as NSString )
            .stringByTrimmingCharactersInSet( characterSet )
            .stringByReplacingOccurrencesOfString( " ", withString: "" ) as String
        print("Device Token string: " + deviceTokenString )
        let currentUser = User().getCurrentUser()
        if(currentUser != nil){
            
            //First get the nsObject by defining as an optional anyObject
            let nsObject: AnyObject? = NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"]
            //Then just cast the object as a String, but be careful, you may want to double check for nil 
            let version = nsObject as! String
            
            let _d = LbcPushAPI.device
            _d.load(usingRequest: _d.request(.POST, json: [ "appId" : "com.littlebigcity.app", "appVersion" : version, "deviceToken" : deviceTokenString, "deviceType" : "ios", "status" : "Active", "userId" : currentUser!.id ]))
        }
        
        
        // Mix Panel
        mixpanel.identify(String(currentUser?.id));
        mixpanel.people.set(["$email": (currentUser?.email)!, "$first_name":(currentUser?.firstName)!, "$last_name":(currentUser?.lastName)!]);
        mixpanel.people.addPushDeviceToken(deviceToken);
        
        // UIAlertView(title: "LBC", message: deviceTokenString, delegate: nil, cancelButtonTitle: "OK").show()
        // TODO: Update device token
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print("ERROR: Token Device Couldn't register: \(error)")
    }
    
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        // inspect notificationSettings to see what the user said!
        print("Token didRegisterUserNotificationSettings ")
    }
    

    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {

        //Save in Realm
        if let  payload = userInfo["payload"] as? String, _aps = userInfo["aps"] as? NSDictionary {
            let _data = JSON.parse(payload)
            if( _aps["category"] as? String == "CATEGORY_CHAT"){
                let _dis = Discussion().saveValueWhenOpenChat(_data["discussion"])
                let _chat = Chat().saveOneValueFromJSON(_data["chat"])!
                NSNotificationCenter.defaultCenter().postNotificationName("newChatComming", object: ["data":_chat])
                NSNotificationCenter.defaultCenter().postNotificationName("reloadChatListData", object: nil)
                // Add chat contents via call notification center
                if ( application.applicationState == .Inactive || application.applicationState == .Background  )
                {
                    //open chat from push
                    let chatController = storyboardMain.instantiateViewControllerWithIdentifier("chatScreen") as! DetailChatViewController
                    chatController.isOpenFromLaunch = true
                    chatController.discussion = _dis
                    let navigationController = UINavigationController(rootViewController: chatController)
                    navigationController.navigationBarHidden = true
                    window?.rootViewController = navigationController
                }
                
            }else{
            
                if(_data["activity_id"].intValue > 0){
                
                    if ( application.applicationState == .Inactive || application.applicationState == .Background  )
                    {
                        //open Activity from push
                        let _vc = storyboardActivityDetail.instantiateViewControllerWithIdentifier("activityDetailView") as! DetailsViewController
                        _vc.activityId = _data["activity_id"].intValue
                        _vc.isOpenFromLaunch = true
                        let navigationController = UINavigationController(rootViewController: _vc)
                        navigationController.navigationBarHidden = true
                        window?.rootViewController = navigationController
                    }
                }
                
            }
        }
        
        
        completionHandler(UIBackgroundFetchResult.NoData)
        
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        
        print("localPush");
        print(notification)
        
    }
    
    
    func application(application: UIApplication, didReceiveRemoteNotification launchOptions: [NSObject: AnyObject]?) -> Void {
        Branch.getInstance().handlePushNotification(launchOptions)
    }
    

    
    ////
    // Location delegate
    ////
    func startMonitoringLocation() {
        locationManager.startMonitoringSignificantLocationChanges()
        // locationManager.startMonitoringVisits()
    }
    
    // MARK: CLLocationManagerDelegate functions
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if (status != CLAuthorizationStatus.AuthorizedAlways) {
            // TODO: Need to tell user by notification or NOT?
            UIApplication.sharedApplication().presentLocalNotificationNow(NotificationLocalFactory.localNotif("Need to allow location always", body: "We need your location to lead you to awesome experiences in your area. Please go to Settings -> Privacy -> Location and update Location to \"Always\""))
            // TODO: need to block by the location asking
        } else {
            self.startMonitoringLocation()
            NSNotificationCenter.defaultCenter().postNotificationName("updateLocationAndGoOn", object: nil)
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // TODO: Need to update longitude and latitude to server and Local DB
        let lo = locations.last! as CLLocation
        let currentUser = User().getCurrentUser()

        if(currentUser != nil){
            let userResource = Service(baseURL: apiUrl)
            userResource.configure{
                $0.config.headers["authorization"] = currentUser?.accessToken
                $0.config.expirationTime = 0.1 // default is 30 seconds
            }
            userResource.resource("/user/me").request(.POST, json: ["user": [ "latitude" : String(format: "%f", lo.coordinate.latitude), "longitude" : String(format: "%f", lo.coordinate.longitude) ]]).onSuccess(){  _data in

                if(_data.json.count > 0){
                    User().updateDataFromJSON(_data.json)
                }
                
            }
            
            // Call action that need update location
            NSNotificationCenter.defaultCenter().postNotificationName("locationUpdatedAndGoOn", object: ["data":lo])

        }
        // UIApplication.sharedApplication().presentLocalNotificationNow( NotificationLocalFactory.localNotifForSignificantChange(lo))
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {

        if (CLLocationManager.locationServicesEnabled()) {
            if( CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedWhenInUse ||
                CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedAlways ){
                    // Update Location
                    // Failed for some reason
                    NSNotificationCenter.defaultCenter().postNotificationName("locationUpdatedAndGoOn", object: nil)
                    
            }
        }
    }
    

}