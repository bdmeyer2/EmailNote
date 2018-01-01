//
//  ViewController.swift
//  EmailNote
//
//  Created by Brett Meyer on 12/28/17.
//  Copyright © 2017 Brett Meyer. All rights reserved.
//

import UIKit
import CoreGraphics
import skpsmtpmessage

class NoteViewController: UIViewController, SKPSMTPMessageDelegate {

    @IBOutlet weak var note: UITextView!
    @IBOutlet weak var pictureImage: UIImageView!
    @IBOutlet weak var photoImage: UIImageView!
    @IBOutlet weak var addImageButton: UIButton!
    
    var email = ""
    var emailMessage: SKPSMTPMessage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailMessage = SKPSMTPMessage()
        emailMessage.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func messageSent(_ message: SKPSMTPMessage!) {
    }
    
    func messageFailed(_ message: SKPSMTPMessage!, error: Error!) {
        let alert = UIAlertController(title: "Something went wrong", message: "Note not sent", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .`default`, handler: { _ in }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func sendEmailInBackground() {
        print(note.text)
        emailMessage.fromEmail = "emailnoteexample@gmail.com"; //sender email address
        emailMessage.toEmail = email;  //receiver email address
        emailMessage.relayHost = "smtp.gmail.com";
        emailMessage.requiresAuth = true;
        emailMessage.login = "emailnoteexample@gmail.com"; //sender email address
        emailMessage.pass = "!258%nes"; //sender email password
        emailMessage.subject = "email subject header message"
        emailMessage.wantsSecure = true
        let messageBody = note.text
        //for example :   NSString *messageBody = [NSString stringWithFormat:@"Tour Name: %@\nName: %@\nEmail: %@\nContact No: %@\nAddress: %@\nNote: %@",selectedTour,nameField.text,emailField.text,foneField.text,addField.text,txtView.text];
        // Now creating plain text email message
        let plainMsg = [
            kSKPSMTPPartContentTypeKey : "text/plain",
            kSKPSMTPPartMessageKey : messageBody,
            kSKPSMTPPartContentTransferEncodingKey : "8bit"
        ]
        emailMessage.parts = [plainMsg]
        //in addition : Logic for attaching file with email message.
        /*
         NSString *filePath = [[NSBundle mainBundle] pathForResource:@"filename" ofType:@"JPG"];
         NSData *fileData = [NSData dataWithContentsOfFile:filePath];
         NSDictionary *fileMsg = [NSDictionary dictionaryWithObjectsAndKeys:@"text/directory;\r\n\tx-
         unix-mode=0644;\r\n\tname=\"filename.JPG\"",kSKPSMTPPartContentTypeKey,@"attachment;\r\n\tfilename=\"filename.JPG\"",kSKPSMTPPartContentDispositionKey,[fileData encodeBase64ForData],kSKPSMTPPartMessageKey,@"base64",kSKPSMTPPartContentTransferEncodingKey,nil];
         emailMessage.parts = [NSArray arrayWithObjects:plainMsg,fileMsg,nil]; //including plain msg and attached file msg
         */
        emailMessage.send();
    }

    @IBAction func sendPressed(_ sender: Any) {
        if email == "" {
            performSegue(withIdentifier: "settings", sender: self)
        } else {
            sendEmailInBackground()
        }
    }
    
    @IBAction func addImagePressed(_ sender: Any) {
        let animator = UIViewPropertyAnimator(duration: 0.15, dampingRatio: 1) {
            let radians = CGFloat(Int(-45)) * .pi / 180
            self.addImageButton.transform = self.addImageButton.transform.rotated(by: CGFloat(radians))
        }
        animator.startAnimation()
    }
    
}

