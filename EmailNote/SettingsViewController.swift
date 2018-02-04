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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let email = Settings.email {
            emailField.text = email
        }
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        Settings.email = emailField.text;
        
        let defaults = UserDefaults.standard
        defaults.set(Settings.email, forKey: "email")
        
        self.navigationController?.popViewController(animated: true)
    }
}
