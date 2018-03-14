//
//  SettingsViewController.swift
//  EmailNote
//
//  Created by Brett Meyer on 12/30/17.
//  Copyright © 2017 Brett Meyer. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var fahrenheitSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let email = Settings.email {
            emailField.text = email
        }
        if let isFahrenheit = Settings.isFahrenheit {
            fahrenheitSwitch.isOn = isFahrenheit
        }
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func handleViewTransition() {
//        navigationController?.navigationBar.barTintColor = UIColor.white
//        navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.black]
//        navigationController?.navigationBar.tintColor = UIColor.black
//        UIApplication.shared.statusBarStyle = UIStatusBarStyle.default
        
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        Settings.email = emailField.text;
        Settings.isFahrenheit = fahrenheitSwitch.isOn
        
        let defaults = UserDefaults.standard
        defaults.set(Settings.email, forKey: "email")
        defaults.set(Settings.isFahrenheit, forKey: "isFahrenheight")
        
        handleViewTransition()
    }
    
    
    @IBAction func backButtonPressed(_ sender: Any) {
        handleViewTransition()
    }
}
