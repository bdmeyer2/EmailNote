//
//  ViewController.swift
//  EmailNote
//
//  Created by Brett Meyer on 12/28/17.
//  Copyright © 2017 Brett Meyer. All rights reserved.
//

import UIKit
import CoreGraphics
import Alamofire
import CloudKit
import SwiftyJSON

class NoteViewController: UIViewController, UITextViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var note: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var dateButton: UIBarButtonItem!
    @IBOutlet weak var weatherIconButton: UIBarButtonItem!
    @IBOutlet weak var temperatureButton: UIBarButtonItem!
    @IBOutlet weak var leftBarButton: UIBarButtonItem!
    @IBOutlet weak var sendButtonBottomConstraint: NSLayoutConstraint!
    
    var locationManager: CLLocationManager?
    var latitude: String?
    var longitude: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(NoteViewController.initLocationManager), name: NSNotification.Name(rawValue: loginNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        leftBarButton.title = "Logo Here"
        
        self.note.delegate = self
        note.text = ""
        temperatureButton.title = ""
        note.becomeFirstResponder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setRightButtonArray()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        leftBarButton.isEnabled = false
        leftBarButton.isEnabled = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func sendEmailInBackground() {
        if Settings.archive == nil {
            Settings.archive = [Note]()
        }
        let n = Note()
        n.message = note.text
        n.time = getTime()
        n.weather = temperatureButton.title
        Settings.archive?.append(n)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true

        if let iCloudID = Settings.iCloudID {
            let parameters: Parameters = [
                "iCloudID": iCloudID,
                "message": n.message!,
                "time": n.time!,
                "weather": n.weather!,
                "lat": latitude!,
                "long": longitude!,
                "email": Settings.email! // Can't get here without having an email set
            ]
            leftBarButton.title = "Message Sending"
            
            sessionManager!.request("https://sendnote.brettdmeyer.com/notes", method: .post, parameters: parameters).responseJSON { response in
                
                self.leftBarButton.title = "Message Sent"
                self.note.text = ""
                UIApplication.shared.isNetworkActivityIndicatorVisible = false

                let when = DispatchTime.now() + 1 // change 2 to desired number of seconds
                DispatchQueue.main.asyncAfter(deadline: when) {
                    self.leftBarButton.title = "Logo Here"
                }
            }
        } else {
            print("userID is nil, make sure signed into icloud account");
        }

    }

    @IBAction func sendPressed(_ sender: Any) {
        if Settings.email == nil {
            performSegue(withIdentifier: "settings", sender: self)
        } else {
            sendEmailInBackground()
        }
    }

    
    func getTime() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.amSymbol = "am"
        formatter.pmSymbol = "pm"
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let myString = formatter.string(from: Date())
        let yourDate = formatter.date(from: myString)
        formatter.dateFormat = "MMM dd yyyy h:mm a"
        let time = formatter.string(from: yourDate!)
        
        return time
    }
    
    func setRightButtonArray() {
        if let date = Settings.date {
            dateButton.title? = "\(date)"
        }
        if var weather = Settings.weather?.temperature {
            if Settings.isFahrenheit! {
                weather = (weather * 9/5) + 32
                temperatureButton.title? = "\(weather)℉"
            } else {
                temperatureButton.title? = "\(weather)℃"
            }
        }
    }
    
    func getWeather(_ lat: String, _ long: String) {
        let when = DispatchTime.now() + 1 // change 2 to desired number of seconds
        DispatchQueue.main.asyncAfter(deadline: when) {
        
            let parameters: Parameters = [
                "coordinates": ["lat": lat, "lon": long]
            ]
            UIApplication.shared.isNetworkActivityIndicatorVisible = true

            sessionManager!.request("https://sendnote.brettdmeyer.com/weather", method: .post, parameters: parameters).responseJSON { response in
                if response.result.isSuccess {
                    print("Success getting web data")
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false

                    let weatherJSON : JSON = JSON(response.result.value!)
                    
                    self.updateWeatherData(json: weatherJSON)
                    
                } else {
                    print("Error HERE: \(String(describing: response.result.error))")
                }
            }
        }
    }
    
    func updateWeatherData(json: JSON) {
        Settings.weather = WeatherDataModel()
        
        if let weatherSetting = Settings.weather {
            weatherSetting.temperature = Int(json["temperature"]["value"].double!)
            weatherSetting.condition = json["weather"]["id"].intValue
            weatherSetting.weatherIconName = weatherSetting.updateWeatherIcon(condition: weatherSetting.condition)
        }
        setRightButtonArray()
    }
    
    @objc func initLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[locations.count - 1]
        if location.horizontalAccuracy > 0 {
            locationManager?.stopUpdatingLocation()
            locationManager = nil
            
            latitude = String(location.coordinate.latitude)
            longitude = String(location.coordinate.longitude)
            if let lat = latitude, let long = longitude {
                getWeather(lat, long)
            }

        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        return
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            self.sendButtonBottomConstraint.constant = keyboardHeight - view.safeAreaInsets.bottom + 10
        }
    }

}

