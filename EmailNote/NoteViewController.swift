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
    
    var locationManager: CLLocationManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let image : UIImage = UIImage(named: "picture")!
//        let imageView = UIImageView(frame: CGRect(x: 100, y: 0, width: 40, height: 40))
//        imageView.contentMode = .scaleAspectFit
//        imageView.image = image
//        self.navigationItem.titleView = imageView
        
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.startUpdatingLocation()
        
        leftBarButton.title = "Logo Here"
        setRightButtonArray()
        
//        if sender.isOn {
//            temperatureLabel.text = "\(weatherDataModel.temperature)℉"
//        } else {
//            temperatureLabel.text = "\(weatherDataModel.temperature)℃"
//        }
        self.note.delegate = self
        note.text = ""
        note.becomeFirstResponder()
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
        Settings.archive?.append(n)
        
        if let iCloudID = Settings.iCloudID {
            let parameters: Parameters = [
                "iCloudID": iCloudID,
                "message": note.text,
                "email": Settings.email! // Can't get here without having an email set
            ]
            leftBarButton.title = "Message Sending"
            
            Alamofire.request("https://sendnote.brettdmeyer.com/notes", method: .post, parameters: parameters).responseJSON { response in
                
                self.leftBarButton.title = "Message Sent"
                self.note.text = ""
                
                let when = DispatchTime.now() + 1 // change 2 to desired number of seconds
                DispatchQueue.main.asyncAfter(deadline: when) {
                    self.leftBarButton.title = "Logo Here"
                }
//                print("Request: \(String(describing: response.request))")   // original url request
//                print("Response: \(String(describing: response.response))") // http url response
//                print("Result: \(response.result)")                         // response serialization result
//
//                if let json = response.result.value {
//                    print("JSON: \(json)") // serialized json response
//                }
//
//                if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
//                    print("Data: \(utf8Text)") // original server data as UTF8 string
//                }
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
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.selectAll(nil)
//        UIView.animate(withDuration: 1) {
////            self.sendButton.heightConstraint.constant = 308
//            self.sendButton.translatesAutoresizingMaskIntoConstraints = false
//            NSLayoutConstraint.activate([
//                self.sendButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 390)
//                ])
//            self.view.layoutIfNeeded()
//        }
    }
    
    
    
//    @IBAction func addImagePressed(_ sender: Any) {
//        let animator = UIViewPropertyAnimator(duration: 0.15, dampingRatio: 1) {
//            let radians = CGFloat(Int(-45)) * .pi / 180
//            self.addImageButton.transform = self.addImageButton.transform.rotated(by: CGFloat(radians))
//        }
//        animator.startAnimation()
//    }
    
    func getTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let myString = formatter.string(from: Date())
        let yourDate = formatter.date(from: myString)
        formatter.dateFormat = "HH:mm"
        let time = formatter.string(from: yourDate!)
        
        return time
    }
    
    func setRightButtonArray() {
        if let date = Settings.date {
            dateButton.title? = "\(date)"
        }
        if let weather = Settings.weather?.temperature {
            temperatureButton.title? = "\(weather)℃"
        }
    }
    
    func getWeather(_ lat: String, _ long: String) {
        let parameters: Parameters = [
            "coordinates": ["lat": lat, "lon": long]
        ]
        
        Alamofire.request("https://sendnote.brettdmeyer.com/weather", method: .post, parameters: parameters).responseJSON { response in
            if response.result.isSuccess {
                print("Success getting web data")
                
                let weatherJSON : JSON = JSON(response.result.value!)
                
                self.updateWeatherData(json: weatherJSON)
                
            } else {
                print("Error HERE: \(String(describing: response.result.error))")
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
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[locations.count - 1]
        if location.horizontalAccuracy > 0 {
            locationManager?.stopUpdatingLocation()
            locationManager = nil
            
            let latitude = String(location.coordinate.latitude)
            let longitude = String(location.coordinate.longitude)
            
            getWeather(latitude, longitude)
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        return
    }

}

