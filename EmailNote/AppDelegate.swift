//
//  AppDelegate.swift
//  EmailNote
//
//  Created by Brett Meyer on 12/28/17.
//  Copyright © 2017 Brett Meyer. All rights reserved.
//

import UIKit
import CloudKit
import Alamofire
import SwiftyJSON

struct Settings {
    static var iCloudID: String?
    static var email: String?
    static var date: String?
    static var archive: [Note]?
    static var weather: WeatherDataModel?
    static var isFahrenheit: Bool?
}
let loginNotification = "brettdmeyer.login"
var sessionManager: SessionManager?
var requestURL: String?

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var iCloudKeyStore: NSUbiquitousKeyValueStore? = NSUbiquitousKeyValueStore()
    var token: String?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
        
        setEnvironment(isProduction: true)
        
        setDateSettings()
        loadArchive()
        getCSRFToken()

        let defaults = UserDefaults.standard
        Settings.email = defaults.object(forKey: "email") as? String ?? nil
        Settings.isFahrenheit = defaults.object(forKey: "isFahrenheight") as? Bool ?? true
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        saveArchive()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func iCloudUserIDAsync(complete: @escaping (_ instance: CKRecordID?, _ error: NSError?) -> ()) {
        let container = CKContainer.default()
        container.fetchUserRecordID() {
            recordID, error in
            if error != nil {
                print(error!.localizedDescription)
                complete(nil, error! as NSError)
            } else {
                complete(recordID, nil)
            }
        }
    }
    
    func setiCloudIDSetting() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        iCloudUserIDAsync() {
            recordID, error in
            if let userID = recordID?.recordName {
                Settings.iCloudID = userID
                self.loginAPI()
            } else {
                print("Fetched iCloudID was nil")
            }
        }
    }
    
    func setDateSettings() {
        let formatter = DateFormatter()
        
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let myString = formatter.string(from: Date())
        let yourDate = formatter.date(from: myString)
        formatter.dateFormat = "M/d"
        Settings.date = formatter.string(from: yourDate!)
    }
    
    func loadArchive() {
        let dataFilePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("Notes.plist")
        if let data = try? Data(contentsOf: dataFilePath!) {
            let decoder = PropertyListDecoder()
            do {
                Settings.archive = try decoder.decode([Note].self, from: data)
            } catch {
                print("error reading notes from local file \(error)")
            }
        }
    }
    
    func saveArchive() {
        let dataFilePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("Notes.plist")
        let encoder = PropertyListEncoder()
        do {
            let data = try encoder.encode(Settings.archive);
            try data.write(to: dataFilePath!)
        } catch {
            print("error writing notes to local file \(error)")
        }
    }
    
    func loginAPI() {
        if let savedString = iCloudKeyStore?.string(forKey: "token") {
            print(savedString)
            let parameters: Parameters = [
                "iCloudToken": Settings.iCloudID!,
                "password": savedString
            ]
            print(parameters)
            
            sessionManager!.request(requestURL! + "/login", method: .post, parameters: parameters).responseJSON { response in
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }

                if response.result.isSuccess {
                    // let json : JSON = JSON(response.result.value!)
                    print("LOGIN SUCCESSFUL")
                    NotificationCenter.default.post(name: Notification.Name(rawValue: loginNotification), object: self)
                } else {
                    print("Error: \(String(describing: response.result.error))")
                }
            }
        } else {
            let parameters: Parameters = [
                "iCloudToken": Settings.iCloudID!
            ]
            
            sessionManager!.request(requestURL! + "/register", method: .post, parameters: parameters).responseJSON { response in
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                if response.result.isSuccess {
                    let json : JSON = JSON(response.result.value!)
                    print("Registration successful \(json["token"])")
                    self.iCloudKeyStore?.set(json["token"].string, forKey: "token")
                    self.iCloudKeyStore?.synchronize()
                    NotificationCenter.default.post(name: Notification.Name(rawValue: loginNotification), object: self)
                } else {
                    print("Error: \(String(describing: response.result.error))")
                }
            }
        }
    }
    
    func getCSRFToken() {
        Alamofire.request(requestURL! + "/csrf", method: .get).responseJSON { response in
            if let json = response.result.value {
                print("JSON: \(json)") // serialized json response
                self.setupSessionManager("\(json)")
            }
        }
    }
    
    func setupSessionManager(_ csrfToken: String) {
        var defaultHeaders = Alamofire.SessionManager.defaultHTTPHeaders
        defaultHeaders["X-CSRF-TOKEN"] = csrfToken
        
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = defaultHeaders
        
        sessionManager = Alamofire.SessionManager(configuration: configuration)
        
        setiCloudIDSetting() // calls loginAPI() which needs this header to be set
    }
    
    func setEnvironment(isProduction: Bool) {
        if isProduction {
            requestURL = "https://sendnote.brettdmeyer.com"
        } else { // Local
            requestURL = "http://emailnote.test"
        }
    }
}
