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

class ArchiveTableViewCell: UITableViewCell {
    @IBOutlet weak var noteLabel: UILabel!
    @IBOutlet weak var subLabel: UILabel!
}

class NoteViewController: UIViewController, UITextViewDelegate, CLLocationManagerDelegate, UITableViewDataSource {

    @IBOutlet weak var note: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var logo: UIButton!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var weatherIcon: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var settingsButton: UIButton!
    
    @IBOutlet weak var noteView: UIView!
    @IBOutlet weak var archiveTableView: UITableView!
    
    @IBOutlet weak var sendButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var mainViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var noteTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var noteBottomConstraint: NSLayoutConstraint!
    
    var locationManager: CLLocationManager?
    var latitude: String?
    var longitude: String?
    var sendButtonBotConstraintStart: CGFloat?
    
    var panGR: UIPanGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        archiveTableView.dataSource = self
        note.isUserInteractionEnabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(NoteViewController.initLocationManager), name: NSNotification.Name(rawValue: loginNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        panGR = UIPanGestureRecognizer(target: self,
                                       action: #selector(handlePan(gestureRecognizer:)))
        self.view.addGestureRecognizer(panGR)
        
        logo.setTitle("Yoroshiku.",for: .normal)
        self.note.delegate = self
        note.text = ""
        temperatureLabel.text = ""
        note.becomeFirstResponder()
        settingsButton.alpha = 0
        archiveTableView.alpha = 0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setRightButtonArray()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        logo.isEnabled = false
        logo.isEnabled = true
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
        n.weather = temperatureLabel.text
        Settings.archive?.append(n)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true

        if Settings.iCloudID != nil {
            let parameters: Parameters = [
                "message": n.message!,
                "time": n.time!,
                "weather": n.weather!,
                "lat": latitude!,
                "long": longitude!,
                "email": Settings.email! // Can't get here without having an email set
            ]
            logo.setTitle("Sending your message!",for: .normal)

            
            sessionManager!.request(requestURL! + "/notes", method: .post, parameters: parameters).responseJSON { response in
                self.logo.setTitle("Sent!",for: .normal)
                self.note.text = ""
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self.archiveTableView.reloadData()

                let when = DispatchTime.now() + 1 // change 2 to desired number of seconds
                DispatchQueue.main.asyncAfter(deadline: when) {
                    self.logo.setTitle("Yoroshiku.",for: .normal)
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
            dateLabel.text = "\(date)"
        }
        if var weather = Settings.weather?.temperature {
            if Settings.isFahrenheit! {
                weather = (weather * 9/5) + 32
                temperatureLabel.text = "\(weather)℉"
            } else {
                temperatureLabel.text = "\(weather)℃"
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

            sessionManager!.request(requestURL! + "/weather", method: .post, parameters: parameters).responseJSON { response in
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
    
    @IBAction func logoPressed(_ sender: Any) {
        let window = UIApplication.shared.keyWindow
        let topPadding = window?.safeAreaInsets.top
        
        let finalX = noteView.frame.origin.x
        let finalY = topPadding! + topView.frame.height
        
        let animationDuration = 1.0
        let springDampening = CGFloat(1)
        
        note.becomeFirstResponder()
        self.noteView.layoutIfNeeded()
        UIView.animate(withDuration: animationDuration, delay: 0.0, usingSpringWithDamping: springDampening, initialSpringVelocity: 0.0, options: .curveLinear, animations: {
            self.noteView.layoutIfNeeded()
            self.mainViewTopConstraint.constant = 0
            var frame = self.noteView.frame
            frame.origin.x = finalX
            frame.origin.y = CGFloat(finalY)
            self.noteView.frame = frame
            self.weatherIcon.alpha = 1
            self.dateLabel.alpha = 1
            self.temperatureLabel.alpha = 1
            self.archiveTableView.alpha = 0
            self.settingsButton.alpha = 0
        }) { _ in
        }
//        self.view.layoutIfNeeded()
//        self.mainViewTopConstraint.constant = 0
//        UIView.animate(withDuration: 0.33, animations: { () -> Void in
//            self.view.layoutIfNeeded()
//            self.note.becomeFirstResponder()
//            self.weatherIcon.alpha = 1
//            self.dateLabel.alpha = 1
//            self.temperatureLabel.alpha = 1
//            self.settingsButton.alpha = 0
//            self.archiveTableView.alpha = 0
//        }) { (Finished) -> Void in
//            //            self.source.present(self.destination , animated: false, completion: nil)
//        }
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            self.sendButtonBottomConstraint.constant = keyboardHeight + 12
            self.noteBottomConstraint.constant = keyboardHeight + 50
            sendButtonBotConstraintStart = self.sendButtonBottomConstraint.constant
            UIView.animate(withDuration: 1.0, animations: { () -> Void in
                self.view.layoutIfNeeded()
            })
        }
    }
    
    @objc func handlePan(gestureRecognizer:UIPanGestureRecognizer) {
        let translation = panGR.translation(in: nil)
        let progress = translation.y / 2 / view.bounds.height
        switch panGR.state {
        case .began:
            var x = 0
            
        case .changed:
            // calculate the progress based on how far the user moved
            let translation = panGR.translation(in: nil)
            let progress = translation.y / 2 / view.bounds.height
            if translation.y > 0 {
                mainViewTopConstraint.constant =  translation.y
                weatherIcon.alpha = (300 - translation.y) / 300
                dateLabel.alpha = (300 - translation.y) / 300
                temperatureLabel.alpha = (300 - translation.y) / 300
                archiveTableView.alpha = 1 - ((archiveTableView.frame.height - translation.y) / archiveTableView.frame.height)
                note.resignFirstResponder()
                sendButtonBottomConstraint.constant = sendButtonBotConstraintStart! - (translation.y)
                view.layoutIfNeeded()
            }
            
        default:
            // end the transition when user ended their touch
//            print(translation.y)
//            print(mainViewTopConstraint.constant)
//            if let anim = POPSpringAnimation(propertyNamed: kPOPLayerBounds) {
//                let window = UIApplication.shared.keyWindow
//                let topPadding = window?.safeAreaInsets.top
//                anim.toValue = NSValue(cgRect: CGRect(x: 0, y: 0, width: noteView.frame.width, height: topPadding! + topView.frame.height))
//                noteView.pop_add(anim, forKey: "size")
//            }
            if progress + panGR.velocity(in: nil).y / view.bounds.height > 0.3 {

                mainViewTopConstraint.constant =  archiveTableView.frame.height
                sendButtonBottomConstraint.constant = -100
                UIView.animate(withDuration: 0.33, animations: { () -> Void in
                    self.view.layoutIfNeeded()
                    self.weatherIcon.alpha = 0
                    self.dateLabel.alpha = 0
                    self.temperatureLabel.alpha = 0
                    self.settingsButton.alpha = 1
                    self.archiveTableView.alpha = 1
                }) { (Finished) -> Void in
                }
            } else if mainViewTopConstraint.constant < archiveTableView.frame.height {
                let vel = panGR.velocity(in: self.view)
                let window = UIApplication.shared.keyWindow
                let topPadding = window?.safeAreaInsets.top
                
                let finalX = noteView.frame.origin.x
                let finalY = topPadding! + topView.frame.height
                let curY = noteView.frame.origin.y
                
                let distance = curY - CGFloat(finalY);
                let animationDuration = 1.0
                let springDampening = CGFloat(1)
                
                let springVelocity = -1.0 * vel.y / CGFloat(distance)
                
                self.noteView.layoutIfNeeded()
                UIView.animate(withDuration: animationDuration, delay: 0.0, usingSpringWithDamping: springDampening, initialSpringVelocity: springVelocity, options: .curveLinear, animations: {
                    //                    self.viewToAnimate.alpha = 0
                    self.noteView.layoutIfNeeded()
                    self.mainViewTopConstraint.constant = 0
                    var frame = self.noteView.frame
                    frame.origin.x = finalX
                    frame.origin.y = CGFloat(finalY)
                    self.noteView.frame = frame
                    self.weatherIcon.alpha = 1
                    self.dateLabel.alpha = 1
                    self.temperatureLabel.alpha = 1
                    self.archiveTableView.alpha = 0
//                    self.sendButtonBottomConstraint.constant = self.sendButtonBotConstraintStart!
                    self.note.becomeFirstResponder()
                }) { _ in
                    //                    self.viewToAnimate.removeFromSuperview()
                }
//                let when = DispatchTime.now() + 1 // change 2 to desired number of seconds
//                DispatchQueue.main.asyncAfter(deadline: when) {
//                   self.note.becomeFirstResponder()
//                }
//                mainViewTopConstraint.constant =  0
//                note.becomeFirstResponder()
//                UIView.animate(withDuration: 0.33, animations: { () -> Void in
//                    self.weatherIcon.alpha = 1
//                    self.dateLabel.alpha = 1
//                    self.temperatureLabel.alpha = 1
//                    self.archiveTableView.alpha = 0
//                }) { (Finished) -> Void in
//                }
            }
//            print(mainViewTopConstraint.constant)

        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count: Int
        if let notes = Settings.archive {
            count = notes.count
        } else {
            count = 0
        }
        return count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "noteCell", for: indexPath) as! ArchiveTableViewCell
        
        if let noteArray = Settings.archive {
            let count = noteArray.count
            cell.noteLabel?.text = noteArray[count - 1 - indexPath.row].message
            cell.subLabel?.text = noteArray[count - 1 - indexPath.row].time
        }
        
        return cell
    }
    
}

//class FadeSegue: UIStoryboardSegue {
//
//    override func perform() {
////        // Get the view of the source
////        let sourceViewControllerView = self.source.view
////        // Get the view of the destination
////        let destinationViewControllerView = self.destination.view
////
////        let screenWidth = UIScreen.main.bounds.size.width
////        let screenHeight = UIScreen.main.bounds.size.height
////
////        // Make the destination view the size of the screen
////        destinationViewControllerView?.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
////
////        // Insert destination below the source
////        // Without this line the animation works but the transition is not smooth as it jumps from white to the new view controller
////        destinationViewControllerView?.alpha = 0;
////        sourceViewControllerView?.addSubview(destinationViewControllerView!);
////
////        // Animate the fade, remove the destination view on completion and present the full view controller
////        UIView.animate(withDuration: 0.33, animations: {
////            destinationViewControllerView?.alpha = 1;
////        }, completion: { (finished) in
//////            destinationViewControllerView?.removeFromSuperview()
////            //            self.source.present(self.destination, animated: false, completion: nil)
////            if let navigationController = self.source.navigationController {
////            navigationController.pushViewController(self.destination, animated: false)
////        }
////        })
//
//        let firstVCView = self.source.view as UIView!
//        let secondVCView = self.destination.view as UIView!
//        let navHeight = self.source.navigationController?.navigationBar.frame.height
//
//
//        // Get the screen width and height.
//        let screenWidth = UIScreen.main.bounds.size.width
//        let screenHeight = UIScreen.main.bounds.size.height - navHeight!
//
//        // Specify the initial position of the destination view.
//        secondVCView?.frame = CGRect(origin: CGPoint(x:0.0, y:screenHeight), size: CGSize(width:screenWidth, height:screenHeight))
//
//        // Access the app's key window and insert the destination view above the current (source) one.
//        let window = UIApplication.shared.keyWindow
////        window?.insertSubview(secondVCView!, aboveSubview: firstVCView!)
//        window?.insertSubview(secondVCView!, at: Int(screenHeight))
//
//        // Animate the transition.
//        UIView.animate(withDuration: 0.7, animations: { () -> Void in
//            secondVCView?.frame = (secondVCView?.frame.offsetBy(dx:0.0, dy:0.0))!
//            firstVCView?.frame = (firstVCView?.frame.offsetBy(dx:0.0, dy:screenHeight))!
//            if let navigationController = self.source.navigationController {
//                navigationController.pushViewController(self.destination, animated: false)
//            }
//        }) { (Finished) -> Void in
////            self.source.present(self.destination , animated: false, completion: nil)
//        }
//    }
//}
//
//
